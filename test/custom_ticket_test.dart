import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/screens/dex_screen.dart';
import 'package:luckypicky/state/ads_controller.dart';
import 'package:luckypicky/state/app_controller.dart';
import 'package:luckypicky/theme/app_theme.dart';
import 'package:luckypicky/widgets/custom_ticket_card.dart';

/// 광고 게이트가 불렸는지 세는 스파이.
///
/// 소원 만들기에는 광고가 없다 — 클로버 한 개는 이미 선행 네 건으로 치른
/// 값이라, 그 위에 광고를 또 얹으면 내 손으로 얻은 것이 아니게 된다.
/// 이 카운터가 0 이 아니면 그 규칙이 깨진 것이다.
int _adCalls = 0;
void _adSpy({required VoidCallback onReward, VoidCallback? onDone}) {
  _adCalls++;
  onReward();
  onDone?.call();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _adCalls = 0;
  });

  Widget host(RewardedAdGate gate, {int clovers = 3}) {
    final backend = LocalGameBackend(seed: AppState(clovers: clovers));
    return ProviderScope(
      overrides: [
        gameBackendProvider.overrideWithValue(backend),
        rewardedAdProvider.overrideWithValue(gate),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DexScreen()),
      ),
    );
  }

  /// 보관함 → "행운권 만들기" → 시트에 문구 입력 → 만들기.
  Future<ProviderContainer> write(WidgetTester tester, String text) async {
    await tester.pumpAndSettle();
    final c =
        ProviderScope.containerOf(tester.element(find.byType(DexScreen)));

    await tester.tap(find.text('행운권 만들기'));
    await tester.pumpAndSettle();
    if (find.byType(TextField).evaluate().isEmpty) return c; // 시트가 안 열림

    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    await tester.tap(find.text('만들기 (클로버 1개)'));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('소원을 만들면 카드가 생기고 클로버가 1개 줄어든다', (tester) async {
    await tester.pumpWidget(host(_adSpy));
    final c = await write(tester, '오늘은 좋은 일이 생긴다');

    final s = c.read(appControllerProvider);
    expect(s.clovers, 2);
    expect(s.customTickets.single.text, '오늘은 좋은 일이 생긴다');
    // 시트는 닫히고 카드가 보관함에 들어와 있다.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(CustomTicketCard), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2200)); // 토스트 타이머 flush
  });

  testWidgets('소원 만들기 경로에는 광고가 없다', (tester) async {
    await tester.pumpWidget(host(_adSpy));
    final c = await write(tester, '오늘은 좋은 일이 생긴다');

    expect(_adCalls, 0,
        reason: '클로버는 이미 선행 네 건으로 치른 값이다 — 광고는 뽑기 쪽에만 둔다');
    // 그래도 카드는 정상적으로 만들어진다.
    expect(c.read(appControllerProvider).customTickets, hasLength(1));
    await tester.pump(const Duration(milliseconds: 2200));
  });

  testWidgets('클로버가 없으면 시트가 아예 열리지 않는다', (tester) async {
    await tester.pumpWidget(host(_adSpy, clovers: 0));
    final c = await write(tester, '행운');

    expect(find.byType(TextField), findsNothing); // 입력 시트 없음
    expect(c.read(appControllerProvider).customTickets, isEmpty);
    await tester.pump(const Duration(milliseconds: 2200));
  });
}
