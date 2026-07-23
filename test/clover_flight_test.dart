import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/data/game_backend.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/screens/home_screen.dart';
import 'package:luckypicky/state/app_controller.dart';
import 'package:luckypicky/theme/app_theme.dart';
import 'package:luckypicky/widgets/clover_flight.dart';

/// 잎 3장 — 한 번만 더 기록하면 클로버가 완성된다.
AppState _almostDone() => const AppState(leaves: 3, clovers: 12);

/// 확정(finishClover)만 실패시키는 백엔드 — 오프라인 상황 재현용.
class _OfflineOnFinishBackend implements GameBackend {
  final LocalGameBackend _inner;
  _OfflineOnFinishBackend(this._inner);

  @override
  Future<CloverResult> finishClover() async =>
      throw const GameConnectionException();

  @override
  Future<void> ensureSignedIn() => _inner.ensureSignedIn();
  @override
  Future<BackendSnapshot> fetchState() => _inner.fetchState();
  @override
  Future<DeedResult> recordDeed(String text) => _inner.recordDeed(text);
  @override
  Future<GachaOutcome> pullGacha() => _inner.pullGacha();
  @override
  Future<AdCloverResult> grantAdClover() => _inner.grantAdClover();
  @override
  Future<EnhanceOutcome> enhanceTicket(String id, List<String> materialIds) =>
      _inner.enhanceTicket(id, materialIds);
  @override
  Future<ReforgeOutcome> reforgeTickets(List<String> materialIds) =>
      _inner.reforgeTickets(materialIds);
  @override
  Future<void> importLocalState(Map<String, dynamic> payload) =>
      _inner.importLocalState(payload);
}

Widget _host(GameBackend backend) => ProviderScope(
      overrides: [gameBackendProvider.overrideWithValue(backend)],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: HomeScreen()),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// 홈 화면의 숨쉬기 애니메이션이 무한 반복이라 [WidgetTester.pumpAndSettle] 은
  /// 영영 끝나지 않는다. 대신 필요한 만큼만 프레임을 진행시킨다.
  Future<void> advance(WidgetTester tester, int ms) async {
    for (var left = ms; left > 0; left -= 20) {
      await tester.pump(Duration(milliseconds: left < 20 ? left : 20));
    }
  }

  Future<ProviderContainer> pump(WidgetTester tester, GameBackend backend) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(backend));
    await advance(tester, 120); // 서버 스냅샷 로드 반영
    return ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)));
  }

  testWidgets('4잎을 채우면 클로버가 배지로 날아가고 착지 후 숫자가 1 오른다',
      (tester) async {
    final c = await pump(tester, LocalGameBackend(seed: _almostDone()));
    final n = c.read(appControllerProvider.notifier);

    expect(find.text('× 12'), findsOneWidget);

    await n.recordDeed('길에 떨어진 쓰레기를 주웠다');
    // 축하 연출(700ms) → 서버 확정 → 좌표 측정 프레임까지 넘긴다.
    await advance(tester, 820);

    expect(find.byType(CloverFlight), findsOneWidget,
        reason: '확정에 성공했으면 비행이 떠야 한다');

    await advance(tester, 600); // 비행 520ms + 여유

    expect(find.byType(CloverFlight), findsNothing, reason: '착지 후 걷혀야 한다');
    expect(find.text('× 13'), findsOneWidget);
  });

  testWidgets('비행이 끝나기 전에는 배지가 이전 숫자를 붙들고 있다', (tester) async {
    final c = await pump(tester, LocalGameBackend(seed: _almostDone()));
    final n = c.read(appControllerProvider.notifier);

    await n.recordDeed('버스에서 자리를 양보했다');
    await advance(tester, 820);

    expect(find.byType(CloverFlight), findsOneWidget);
    // 서버 값은 이미 13 이지만 화면은 아직 12 여야 한다.
    expect(c.read(appControllerProvider).clovers, 13);
    expect(find.text('× 12'), findsOneWidget);
    expect(find.text('× 13'), findsNothing);

    await advance(tester, 600);
    expect(find.text('× 13'), findsOneWidget);
  });

  testWidgets('확정이 실패하면 비행도 숫자 변화도 없다', (tester) async {
    final c = await pump(
        tester, _OfflineOnFinishBackend(LocalGameBackend(seed: _almostDone())));
    final n = c.read(appControllerProvider.notifier);

    await n.recordDeed('아파트 계단을 쓸었다');
    await advance(tester, 1400);

    expect(find.byType(CloverFlight), findsNothing);
    expect(find.text('× 12'), findsOneWidget);
    // 잎은 그대로 남아 다음 실행에서 확정 흐름이 재개된다.
    expect(c.read(appControllerProvider).leaves, 4);
  });
}
