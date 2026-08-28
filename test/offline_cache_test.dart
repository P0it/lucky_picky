import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/data/game_backend.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/models/deed.dart';
import 'package:luckypicky/state/app_controller.dart';

/// 서버에 닿지 못하는 백엔드 — 비행기 모드로 앱을 여는 상황.
class _OfflineBackend implements GameBackend {
  @override
  Future<void> ensureSignedIn() async =>
      throw const GameConnectionException(null);

  @override
  noSuchMethod(Invocation invocation) =>
      throw const GameConnectionException(null);
}

void main() {
  const cacheKey = 'luckypicky_state_cache_v1';

  const cached = AppState(
    leaves: 3,
    clovers: 6,
    coins: 2,
    statLeaves: 31,
    statClovers: 7,
    statPulls: 11,
    history: [
      HistoryEntry(
          id: 1,
          date: '2026.08.20',
          kind: HistoryKind.deed,
          text: '우산을 씌워드렸다',
          amount: 1),
    ],
  );

  ProviderContainer containerWith(GameBackend backend) {
    final c = ProviderContainer(
      overrides: [gameBackendProvider.overrideWithValue(backend)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('오프라인으로 열면 마지막 사본이 화면을 채우고 오프라인 표시가 켜진다', () async {
    SharedPreferences.setMockInitialValues({
      cacheKey: jsonEncode(cached.toJson()),
    });
    final c = containerWith(_OfflineBackend());
    final n = c.read(appControllerProvider.notifier);

    // 부트스트랩은 실패한다 — 그래도 앱은 계속 돈다.
    await n.retrySync();
    await Future<void>.delayed(Duration.zero);

    final s = c.read(appControllerProvider);
    expect(s.offline, true);
    // 재화가 0 으로 보이면 "데이터가 날아갔다"로 읽힌다. 사본이 그걸 막는다.
    expect(s.clovers, 6);
    expect(s.coins, 2);
    expect(s.statLeaves, 31);
    expect(s.history.single.text, '우산을 씌워드렸다');
  });

  test('서버에 붙으면 사본을 덮어쓰고 오프라인 표시가 꺼진다', () async {
    SharedPreferences.setMockInitialValues({
      cacheKey: jsonEncode(cached.toJson()),
    });
    final c = containerWith(
        LocalGameBackend(seed: const AppState(leaves: 1, clovers: 9, coins: 4)));
    final n = c.read(appControllerProvider.notifier);
    await n.ready;

    final s = c.read(appControllerProvider);
    expect(s.offline, false);
    expect(s.clovers, 9); // 사본(6)이 아니라 서버 값
    expect(s.leaves, 1);
  });

  test('상태가 바뀌면 사본이 갱신된다', () async {
    SharedPreferences.setMockInitialValues({});
    final c = containerWith(
        LocalGameBackend(seed: const AppState(leaves: 0, clovers: 0, coins: 0)));
    final n = c.read(appControllerProvider.notifier);
    await n.ready;
    await n.recordDeed('쓰레기를 주웠다');
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    expect(raw, isNotNull);
    final restored =
        AppState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
    expect(restored.leaves, 1);
    expect(restored.history.first.text, '쓰레기를 주웠다');
  });
}
