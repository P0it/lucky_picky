import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';

// ════════════════════════════════════════════════════════════════
//  마지막으로 본 서버 상태의 로컬 사본.
//
//  왜: 상태는 전부 서버에 있고 기기에는 세션 토큰뿐이라, 오프라인으로 앱을 열면
//  재화도 카드도 0으로 보였다. "데이터가 날아갔다"로 읽히는 화면이다.
//  사본을 두면 연결이 없어도 마지막으로 본 화면이 그대로 뜬다.
//
//  이건 캐시일 뿐 진실이 아니다 — 쓰기는 전부 서버 RPC 를 거치고, 서버 응답이
//  오면 무조건 덮어쓴다. 사본으로 재화를 늘려도 서버가 인정하지 않는다.
// ════════════════════════════════════════════════════════════════

const _cacheKey = 'luckypicky_state_cache_v1';

/// 사본에 남길 기록 건수. 타임라인 첫 화면을 채울 만큼이면 충분하고,
/// 그 이상은 SharedPreferences 에 넣기엔 크다.
const _historyCacheLimit = 100;

class StateCache {
  const StateCache();

  Future<AppState?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // 손상된 사본은 없는 것으로 친다.
    }
  }

  Future<void> write(AppState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = state.history.length > _historyCacheLimit
          ? state.copyWith(
              history: state.history.take(_historyCacheLimit).toList())
          : state;
      await prefs.setString(_cacheKey, jsonEncode(trimmed.toJson()));
    } catch (_) {
      // 저장 실패는 조용히 넘어간다 — 사본이 없으면 다음 실행이 빈 화면일 뿐이다.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}
