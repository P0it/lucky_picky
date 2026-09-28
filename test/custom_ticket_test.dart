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

/// 광고를 끝까지 본 경우 — 보상 콜백이 온다.
void _adWatched({required VoidCallback onReward, VoidCallback? onDone}) {
  onReward();
  onDone?.call();
}

/// 광고를 건너뛰거나 로드되지 않은 경우 — 보상 없이 종료된다.
void _adSkipped({required VoidCallback onReward, VoidCallback? onDone}) {
  onDone?.call();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('광고를 끝까지 보면 카드가 만들어지고 클로버가 1개 줄어든다', (tester) async {
    await tester.pumpWidget(host(_adWatched));
    final c = await write(tester, '오늘은 좋은 일이 생긴다');

    final s = c.read(appControllerProvider);
    expect(s.clovers, 2);
    expect(s.customTickets.single.text, '오늘은 좋은 일이 생긴다');
    // 시트는 닫히고 카드가 보관함에 들어와 있다.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(CustomTicketCard), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2200)); // 토스트 타이머 flush
  });

  testWidgets('광고를 완료하지 않으면 클로버가 차감되지 않고 카드도 생기지 않는다', (tester) async {
    await tester.pumpWidget(host(_adSkipped));
    final c = await write(tester, '오늘은 좋은 일이 생긴다');

    final s = c.read(appControllerProvider);
    expect(s.clovers, 3); // 그대로
    expect(s.customTickets, isEmpty);
    expect(find.byType(CustomTicketCard), findsNothing);
    await tester.pump(const Duration(milliseconds: 2200));
  });

  testWidgets('클로버가 없으면 시트가 아예 열리지 않는다', (tester) async {
    await tester.pumpWidget(host(_adWatched, clovers: 0));
    final c = await write(tester, '행운');

    expect(find.byType(TextField), findsNothing); // 입력 시트 없음
    expect(c.read(appControllerProvider).customTickets, isEmpty);
    await tester.pump(const Duration(milliseconds: 2200));
  });

  testWidgets('문구 길이는 서버와 같이 코드포인트로 센다 — 이모지가 섞여도 한도 안이면 만들어진다',
      (tester) async {
    await tester.pumpWidget(host(_adWatched));
    final fits = '${'가' * 38}❤️'; // ❤️ = 코드포인트 2개 → 딱 40
    final c = await write(tester, fits);

    expect(c.read(appControllerProvider).customTickets.single.text, fits);
    await tester.pump(const Duration(milliseconds: 2200));
  });

  testWidgets('코드포인트 40개를 넘는 문구는 입력되지 않아 광고도 서버 거절도 없다',
      (tester) async {
    var adShown = false;
    await tester.pumpWidget(host(({required onReward, onDone}) {
      adShown = true;
      _adWatched(onReward: onReward, onDone: onDone);
    }));
    // 글자(grapheme)로는 40자지만 코드포인트로는 42개 — 서버가 거절하는 길이.
    final c = await write(tester, '${'가' * 38}❤️❤️');

    expect(adShown, isFalse);
    expect(c.read(appControllerProvider).customTickets, isEmpty);
    expect(c.read(appControllerProvider).clovers, 3);
    await tester.pump(const Duration(milliseconds: 2200));
  });
}
