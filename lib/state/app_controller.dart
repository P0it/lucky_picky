import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../config/luck_tickets.dart';
import '../data/game_backend.dart';
import '../data/supabase_game_backend.dart';
import '../models/app_state.dart';
import '../models/deed.dart';
import '../models/owned_ticket.dart';
import 'ads_controller.dart';

/// 서버 도입 전 로컬 저장 키 — 최초 로그인 시 서버로 1회 이관하는 데만 쓴다.
const _legacyPrefsKey = 'luckypicky_app_state_v1';

/// 하루에 광고 시청으로 뽑을 수 있는 무료 뽑기 수.
/// (서버 game_config 의 free_pulls_per_day 와 동치 — UI 표시/사전 차단용)
const int kFreePullsPerDay = 3;

/// 몇 회 뽑을 때마다 결과 확정 후 전면광고를 보여줄지.
const int kPullAdInterval = 3;

/// 게임 상태 백엔드 — 실서비스는 Supabase RPC(서버 권위).
/// 테스트는 LocalGameBackend 로 override 한다.
final gameBackendProvider = Provider<GameBackend>(
    (ref) => SupabaseGameBackend(Supabase.instance.client));

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);

/// 뽑기 1회의 결과.
class PullResult {
  final LuckTicket ticket;
  final OwnedTicket owned; // 반영 후의 보유 상태
  final bool isNew; // 첫 획득 여부
  final bool free; // 무료(광고) 뽑기였는지

  const PullResult({
    required this.ticket,
    required this.owned,
    required this.isNew,
    required this.free,
  });
}

class AppController extends Notifier<AppState> {
  Future<void>? _bootstrap;

  GameBackend get _backend => ref.read(gameBackendProvider);

  @override
  AppState build() {
    // 시작 시 백그라운드로 로그인+서버 상태 로드. 실패(오프라인)해도
    // 앱은 뜨고, 이후 mutation 시점에 재시도된다.
    unawaited(_ensureReady().catchError((_) {}));
    return const AppState();
  }

  /// 테스트에서 부트스트랩 완료를 기다릴 때 사용.
  @visibleForTesting
  Future<void> get ready => _ensureReady();

  /// 익명 로그인 → (필요 시) 로컬 데이터 이관 → 서버 상태 로드.
  /// 실패하면 다음 호출에서 처음부터 재시도한다.
  Future<void> _ensureReady() {
    final existing = _bootstrap;
    if (existing != null) return existing;
    final run = _runBootstrap();
    _bootstrap = run;
    run.catchError((_) => _bootstrap = null);
    return run;
  }

  Future<void> _runBootstrap() async {
    await _backend.ensureSignedIn();
    var snap = await _backend.fetchState();
    if (!snap.importedLocal) {
      final legacy = await _readLegacyBlob();
      if (legacy != null) {
        try {
          await _backend.importLocalState(legacy);
          snap = await _backend.fetchState();
        } on GameRuleException {
          // ALREADY_IMPORTED 등 — 서버 상태를 그대로 쓴다.
        }
      }
    }
    _applySnapshot(snap.data);
  }

  /// 서버 스냅샷을 반영한다 (탭/애니메이션 등 UI 휘발 필드는 보존).
  void _applySnapshot(AppState data) {
    state = state.copyWith(
      leaves: data.leaves,
      clovers: data.clovers,
      statLeaves: data.statLeaves,
      statClovers: data.statClovers,
      statPulls: data.statPulls,
      tickets: data.tickets,
      history: data.history,
      freePullsUsedToday: data.freePullsUsedToday,
      lastFreePullDate: data.lastFreePullDate,
    );
    // 지난 세션에서 클로버 확정(finish_clover)이 오프라인으로 끊겼다면 복구.
    if (data.leaves >= 4) {
      state = state.copyWith(celebrate: true);
      _scheduleCloverFinish();
    }
  }

  Future<Map<String, dynamic>?> _readLegacyBlob() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyPrefsKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null; // corrupted — 이관 포기
    }
  }

  static String _fmt(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${p(d.month)}.${p(d.day)}';
  }

  /// 표시용 날짜(사용자 로컬).
  String _todayLocal() => _fmt(DateTime.now());

  /// 무료 뽑기 리셋 기준일 — 서버(pull_gacha)의 current_date(UTC)와 맞춘다.
  String _todayUtc() => _fmt(DateTime.now().toUtc());

  // ---- navigation ----
  void setTab(AppTab t) => state = state.copyWith(tab: t);
  void setArchiveView(ArchiveView v) =>
      state = state.copyWith(archiveView: v);

  // ---- 선행 기록 ----
  /// 잎 하나를 채운다. 반환값: 이번 기록으로 클로버가 완성되었는지 여부.
  /// 오프라인이면 [GameConnectionException] 을 던진다.
  Future<bool> recordDeed(String rawDeed) async {
    final deed = rawDeed.trim();
    if (deed.isEmpty) return false;
    await _ensureReady();

    final DeedResult r;
    try {
      r = await _backend.recordDeed(deed);
    } on GameRuleException {
      return false;
    }

    state = state.copyWith(
      leaves: r.leaves,
      statLeaves: state.statLeaves + 1,
      bounceKey: state.bounceKey + 1,
      celebrate: r.cloverCompleted,
      history: [
        HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch,
            date: _todayLocal(),
            kind: HistoryKind.deed,
            text: deed,
            amount: 1),
        ...state.history,
      ],
    );
    if (r.cloverCompleted) _scheduleCloverFinish();
    return r.cloverCompleted;
  }

  /// 완성 축하 연출 → 전면광고 → 클로버 확정.
  /// (선행 기록은 자가 신고라 클로버 생산을 광고로 게이팅한다.)
  void _scheduleCloverFinish() {
    Future.delayed(const Duration(milliseconds: 1100), () {
      AdsController.instance.showInterstitial(onDone: finishCloverCelebration);
    });
  }

  /// 클로버 완성 연출 후 잎 4개 차감 + 보유 클로버 +1 (서버 확정).
  Future<void> finishCloverCelebration() async {
    if (state.leaves < 4) return;
    try {
      final r = await _backend.finishClover();
      state = state.copyWith(
        leaves: r.leaves,
        clovers: r.clovers,
        celebrate: false,
        statClovers: state.statClovers + 1,
      );
    } on GameRuleException {
      state = state.copyWith(celebrate: false);
    } on GameConnectionException {
      // 오프라인 — 연출만 닫는다. 서버 잎 수는 그대로라 다음 실행 시
      // _applySnapshot 이 leaves>=4 를 감지해 확정 플로우를 재개한다.
      state = state.copyWith(celebrate: false);
    }
  }

  // ---- 가챠 ----
  /// 오늘 남은 무료(광고) 뽑기 횟수 (서버 기준일=UTC 과 동일 규칙).
  int get freePullsLeft {
    final used =
        state.lastFreePullDate == _todayUtc() ? state.freePullsUsedToday : 0;
    return (kFreePullsPerDay - used).clamp(0, kFreePullsPerDay);
  }

  /// 이번 뽑기 결과 확정 후 전면광고를 보여줄 차례인지.
  bool get shouldShowPullAd =>
      state.statPulls > 0 && state.statPulls % kPullAdInterval == 0;

  /// 뽑기 1회 — 추첨은 서버에서 실행된다.
  /// 뽑을 수 없으면(재화/한도 부족) null, 오프라인이면 [GameConnectionException].
  Future<PullResult?> pullGacha({bool free = false}) async {
    await _ensureReady();

    final GachaOutcome r;
    try {
      r = await _backend.pullGacha(free: free);
    } on GameRuleException {
      return null;
    }

    final ticket = LuckCatalog.byId(r.ticketId);
    if (ticket == null) {
      // 서버 카탈로그가 앱보다 새 버전 — 결과를 그릴 수 없다. 상태만 재동기화.
      unawaited(refresh());
      return null;
    }

    final today = _todayUtc();
    final tickets = [...state.tickets];
    final idx = tickets.indexWhere((t) => t.ticketId == r.ticketId);
    final OwnedTicket owned;
    if (idx < 0) {
      owned = OwnedTicket(
          ticketId: r.ticketId,
          copies: r.copies,
          level: r.level,
          firstPulledAt: _todayLocal());
      tickets.insert(0, owned);
    } else {
      owned = tickets[idx].copyWith(copies: r.copies, level: r.level);
      tickets[idx] = owned;
    }

    state = state.copyWith(
      clovers: free ? state.clovers : state.clovers - 1,
      statPulls: state.statPulls + 1,
      tickets: tickets,
      freePullsUsedToday: free
          ? (state.lastFreePullDate == today ? state.freePullsUsedToday : 0) + 1
          : state.freePullsUsedToday,
      lastFreePullDate: free ? today : state.lastFreePullDate,
      history: [
        HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch,
            date: _todayLocal(),
            kind: HistoryKind.pull,
            text: r.ticketId,
            amount: free ? 0 : 1),
        ...state.history,
      ],
    );
    return PullResult(ticket: ticket, owned: owned, isNew: r.isNew, free: free);
  }

  /// 행운권 강화 — 여분 중복을 소모해 레벨 +1 (서버 검증).
  /// 성공 시 반영 후 보유 상태, 불가하면 null, 오프라인이면 예외.
  Future<OwnedTicket?> enhanceTicket(String ticketId) async {
    await _ensureReady();

    final EnhanceOutcome r;
    try {
      r = await _backend.enhanceTicket(ticketId);
    } on GameRuleException {
      return null;
    }

    final tickets = [...state.tickets];
    final idx = tickets.indexWhere((t) => t.ticketId == ticketId);
    if (idx < 0) return null;
    final upgraded = tickets[idx].copyWith(copies: r.copies, level: r.level);
    tickets[idx] = upgraded;
    state = state.copyWith(tickets: tickets);
    return upgraded;
  }

  /// 서버 상태 강제 재동기화.
  Future<void> refresh() async {
    await _ensureReady();
    final snap = await _backend.fetchState();
    _applySnapshot(snap.data);
  }
}
