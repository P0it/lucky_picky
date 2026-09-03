import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/data/demo_game_backend.dart';
import 'package:luckypicky/models/app_state.dart';

/// 웹 데모 백엔드 — 서버 없이 브라우저 안에서만 돌되, 새로고침을 넘겨
/// 진행 상황이 이어지고 무료 코인이 하루 한 번으로 묶여 있어야 한다.
void main() {
  const cacheKey = 'luckypicky_state_cache_v1';
  const freeCoinKey = 'luckypicky_demo_free_coin_date';

  String today() {
    final d = DateTime.now().toUtc();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${p(d.month)}.${p(d.day)}';
  }

  test('사본이 있으면 그 상태로 이어서 시작한다 (새로고침)', () async {
    SharedPreferences.setMockInitialValues({
      cacheKey: jsonEncode(
          const AppState(leaves: 3, clovers: 6, coins: 2).toJson()),
    });

    final backend = DemoGameBackend();
    await backend.ensureSignedIn();
    final snap = await backend.fetchState();

    expect(snap.data.leaves, 3);
    expect(snap.data.clovers, 6);
    expect(snap.data.coins, 2);
  });

  test('사본이 없으면 빈 상태로 시작한다', () async {
    SharedPreferences.setMockInitialValues({});

    final backend = DemoGameBackend();
    await backend.ensureSignedIn();
    final snap = await backend.fetchState();

    expect(snap.data.coins, 0);
    expect(snap.data.clovers, 0);
  });

  test('무료 코인은 하루 한 번 — 새로고침해도 다시 주지 않는다', () async {
    SharedPreferences.setMockInitialValues({});

    final first = DemoGameBackend();
    await first.ensureSignedIn();
    final claimed = await first.claimDailyCoin();
    expect(claimed.claimed, isTrue);
    expect(claimed.coins, 1);

    // 새로고침 = 백엔드 인스턴스가 새로 생긴다. 받은 날짜는 prefs 에 남아 있다.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(freeCoinKey), today());

    final second = DemoGameBackend();
    await second.ensureSignedIn();
    final again = await second.claimDailyCoin();
    expect(again.claimed, isFalse);
  });
}
