import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_fortune.dart';

/// 오늘의 행운지수 — 로컬 전용 상태 (게임 보상과 무관한 콘텐츠 기능이라
/// 서버 권위 AppController와 분리, locale_controller 패턴을 따른다).
///
/// 점수는 유저가 게이지에서 직접 잡은 값이라 시드로 재계산할 수 없으므로
/// 날짜와 함께 저장한다. 날짜가 바뀌면 자동으로 리셋된 상태가 된다.
const _prefsKey = 'luckypicky_fortune_v1';

final fortuneControllerProvider =
    NotifierProvider<FortuneController, FortuneState>(FortuneController.new);

class FortuneState {
  final bool loaded; // prefs 읽기 완료 여부
  final int? todayScore; // 오늘 확정된 행운지수 (null = 아직 안 잡음)
  final bool retryUsed; // 오늘 광고 재도전을 이미 썼는지

  const FortuneState({
    this.loaded = false,
    this.todayScore,
    this.retryUsed = false,
  });

  FortuneState copyWith({bool? loaded, int? todayScore, bool? retryUsed}) {
    return FortuneState(
      loaded: loaded ?? this.loaded,
      todayScore: todayScore ?? this.todayScore,
      retryUsed: retryUsed ?? this.retryUsed,
    );
  }
}

class FortuneController extends Notifier<FortuneState> {
  SharedPreferences? _prefs;

  @override
  FortuneState build() {
    _load();
    return const FortuneState();
  }

  String get _todayKey => DailyFortune.dateKeyOf(DateTime.now());

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if (j['date'] == _todayKey) {
          state = FortuneState(
            loaded: true,
            todayScore: j['score'] as int?,
            retryUsed: j['retryUsed'] as bool? ?? false,
          );
          return;
        }
      } catch (_) {
        // 손상된 저장값은 무시하고 새로 시작.
      }
    }
    state = const FortuneState(loaded: true);
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _prefsKey,
      jsonEncode({
        'date': _todayKey,
        'score': state.todayScore,
        'retryUsed': state.retryUsed,
      }),
    );
  }

  /// 게이지에서 잡은 점수를 오늘의 행운지수로 확정한다.
  /// (재도전으로 다시 잡으면 마지막 값으로 덮어쓴다.)
  Future<void> commitScore(int score) async {
    state = state.copyWith(todayScore: score.clamp(0, 100));
    await _persist();
  }

  /// 리워드 광고 시청 성공 시 호출 — 오늘의 재도전 기회를 소진 처리.
  Future<void> markRetryUsed() async {
    state = state.copyWith(retryUsed: true);
    await _persist();
  }

  /// 개발 전용 — 오늘 기록(점수·재도전 소진)을 지워 처음부터 다시 돌린다.
  /// 디버그 빌드에서만 노출된다 (fortune_screen 의 kDebugMode 가드).
  Future<void> devResetToday() async {
    state = const FortuneState(loaded: true);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_prefsKey);
  }
}
