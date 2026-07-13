import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/models/ticket_instance.dart';
import 'package:luckypicky/screens/forge_screen.dart';
import 'package:luckypicky/state/app_controller.dart';
import 'package:luckypicky/theme/app_theme.dart';

/// 카드 3장을 가진 상태 — 강화 대상/재료, 재조합 재료 모두 여기서 고른다.
AppState _seed() => const AppState(clovers: 5, tickets: [
      TicketInstance(id: 'a', ticketId: 'c01', pulledAt: '2026.01.01'),
      TicketInstance(id: 'b', ticketId: 'c02', pulledAt: '2026.01.01'),
      TicketInstance(id: 'c', ticketId: 'c03', pulledAt: '2026.01.01'),
    ]);

/// 한국어 로케일 고정 + 서버와 같은 규칙의 로컬 백엔드 주입.
Widget _host(Widget child) => ProviderScope(
      overrides: [
        gameBackendProvider.overrideWithValue(LocalGameBackend(seed: _seed())),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(screen));
    await tester.pumpAndSettle();
  }

  testWidgets('enhance flow moves from target step to material step',
      (tester) async {
    await pump(tester, const ForgeScreen(mode: ForgeMode.enhance));

    expect(find.text('강화할 카드를 고르세요'), findsOneWidget);

    await tester.tap(find.byType(ForgePickCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('재료로 태울 카드를 고르세요'), findsOneWidget);
  });

  testWidgets('reforge CTA stays disabled until 3 cards are picked',
      (tester) async {
    await pump(tester, const ForgeScreen(mode: ForgeMode.reforge));

    expect(find.text('재조합하기 (0/3)'), findsOneWidget);

    await tester.tap(find.byType(ForgePickCard).at(0));
    await tester.pumpAndSettle();
    expect(find.text('재조합하기 (1/3)'), findsOneWidget);
  });

  testWidgets('initialTargetId opens straight on the material step',
      (tester) async {
    await pump(
      tester,
      const ForgeScreen(mode: ForgeMode.enhance, initialTargetId: 'a'),
    );

    expect(find.text('강화할 카드를 고르세요'), findsNothing);
    expect(find.text('재료로 태울 카드를 고르세요'), findsOneWidget);
    // +0 → +1 은 재료 1장. 대상('a')은 후보에서 빠지므로 2장이 남는다.
    expect(find.text('강화하기 (0/1)'), findsOneWidget);
  });
}
