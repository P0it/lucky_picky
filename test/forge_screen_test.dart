import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/data/game_backend.dart';
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

/// 규칙은 로컬 백엔드 그대로 두고, 강화·재조합 **호출 자체**를 세는 스파이.
/// 장수가 모자란 상태에서 CTA 를 눌렀을 때 서버 호출이 아예 없어야 게이트가 산 것이다
/// (규칙 위반은 백엔드가 어차피 거절하므로, 지갑 상태만으로는 게이트를 검증할 수 없다).
class _SpyBackend implements GameBackend {
  final LocalGameBackend _inner;
  int enhanceCalls = 0;
  int reforgeCalls = 0;

  _SpyBackend(this._inner);

  @override
  Future<EnhanceOutcome> enhanceTicket(
      String instanceId, List<String> materialIds) {
    enhanceCalls++;
    return _inner.enhanceTicket(instanceId, materialIds);
  }

  @override
  Future<ReforgeOutcome> reforgeTickets(List<String> materialIds) {
    reforgeCalls++;
    return _inner.reforgeTickets(materialIds);
  }

  @override
  Future<void> ensureSignedIn() => _inner.ensureSignedIn();
  @override
  Future<BackendSnapshot> fetchState() => _inner.fetchState();
  @override
  Future<DeedResult> recordDeed(String text) => _inner.recordDeed(text);
  @override
  Future<CloverResult> finishClover() => _inner.finishClover();
  @override
  Future<GachaOutcome> pullGacha() => _inner.pullGacha();
  @override
  Future<AdCloverResult> grantAdClover() => _inner.grantAdClover();
  @override
  Future<void> importLocalState(Map<String, dynamic> payload) =>
      _inner.importLocalState(payload);
}

/// 한국어 로케일 고정 + 서버와 같은 규칙의 로컬 백엔드 주입.
Widget _host(Widget child, GameBackend backend) => ProviderScope(
      overrides: [gameBackendProvider.overrideWithValue(backend)],
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

  Future<_SpyBackend> pump(WidgetTester tester, Widget screen) async {
    final backend = _SpyBackend(LocalGameBackend(seed: _seed()));
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(screen, backend));
    await tester.pumpAndSettle();
    return backend;
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

  /// CTA 라벨의 글자색으로 활성/비활성을 읽는다 (비활성이면 AppColors.disabled).
  Color? ctaColor(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color;

  testWidgets('다음 is inert on the target step until a card is picked',
      (tester) async {
    await pump(tester, const ForgeScreen(mode: ForgeMode.enhance));

    // 대상을 안 골랐으면 CTA 는 죽어 있어야 한다.
    expect(ctaColor(tester, '다음'), AppColors.disabled);

    // 눌러도 STEP 2 로 넘어가지 않는다.
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('강화할 카드를 고르세요'), findsOneWidget);
    expect(find.text('재료로 태울 카드를 고르세요'), findsNothing);

    // 대상을 고르면 그제서야 살아난다.
    await tester.tap(find.byType(ForgePickCard).first);
    await tester.pumpAndSettle();
    expect(ctaColor(tester, '다음'), AppColors.white);
  });

  testWidgets('reforge CTA does not run until 3 cards are picked',
      (tester) async {
    final backend =
        await pump(tester, const ForgeScreen(mode: ForgeMode.reforge));

    expect(find.text('재조합하기 (0/3)'), findsOneWidget);

    // 0/3 에서 실행 금지.
    await tester.tap(find.text('재조합하기 (0/3)'));
    await tester.pumpAndSettle();
    expect(backend.reforgeCalls, 0);

    await tester.tap(find.byType(ForgePickCard).at(0));
    await tester.pumpAndSettle();
    expect(find.text('재조합하기 (1/3)'), findsOneWidget);

    // 1/3 에서도 실행 금지 — 서버 호출이 나가면 안 되고, 화면·지갑도 그대로다.
    await tester.tap(find.text('재조합하기 (1/3)'));
    await tester.pumpAndSettle();
    expect(backend.reforgeCalls, 0);
    expect(find.text('재조합하기 (1/3)'), findsOneWidget);
    expect(find.byType(ForgePickCard), findsNWidgets(3)); // 소모된 카드 없음
  });

  testWidgets('enhance CTA does not run until the material count is met',
      (tester) async {
    final backend = await pump(
      tester,
      const ForgeScreen(mode: ForgeMode.enhance, initialTargetId: 'a'),
    );

    // 재료 0/1 — CTA 를 눌러도 서버 호출이 나가면 안 된다.
    await tester.tap(find.text('강화하기 (0/1)'));
    await tester.pumpAndSettle();
    expect(backend.enhanceCalls, 0);
    expect(find.text('강화하기 (0/1)'), findsOneWidget);
    expect(find.text('재료로 태울 카드를 고르세요'), findsOneWidget);
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
