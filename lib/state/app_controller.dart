import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../config/app_mode.dart';
import '../config/luck_tickets.dart';
import '../data/demo_game_backend.dart';
import '../data/game_backend.dart';
import '../data/state_cache.dart';
import '../data/supabase_game_backend.dart';
import '../models/app_state.dart';
import '../models/custom_ticket.dart';
import '../models/deed.dart';
import '../models/ticket_instance.dart';

/// 서버 도입 전 로컬 저장 키 — 최초 로그인 시 서버로 1회 이관하는 데만 쓴다.
const _legacyPrefsKey = 'luckypicky_app_state_v1';

/// 하루에 광고 시청으로 받을 수 있는 코인 수.
/// (서버 game_config 의 ad_coins_per_day 와 동치 — UI 표시/사전 차단용)
const int kAdCoinsPerDay = 5;

/// 게임 상태 백엔드 — 실서비스는 Supabase RPC(서버 권위).
/// 데모 모드(웹)는 같은 규칙을 브라우저 안에서 도는 [DemoGameBackend] 로 —
/// 서버에 쓰지 않는다(config/app_mode.dart 참고).
/// 테스트는 LocalGameBackend 로 override 한다.
final gameBackendProvider = Provider<GameBackend>((ref) => kDemoMode
    ? DemoGameBackend()
    : SupabaseGameBackend(Supabase.instance.client));

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);

/// 뽑기 1회의 결과.
class PullResult {
  final LuckTicket ticket;
  final TicketInstance instance; // 이번에 얻은 카드 한 장
  final int copies; // 반영 후 같은 행운권 보유 장수
  final bool isNew; // 첫 획득 여부

  const PullResult({
    required this.ticket,
    required this.instance,
    required this.copies,
    required this.isNew,
  });
}

class AppController extends Notifier<AppState> {
  Future<void>? _bootstrap;
  Future<void>? _historyLoad;

  /// 서버 스냅샷을 한 번이라도 반영했는지 — 늦게 도착한 로컬 사본이
  /// 최신 서버 상태를 덮어쓰지 않게 막는다.
  bool _serverApplied = false;

  final _cache = const StateCache();

  GameBackend get _backend => ref.read(gameBackendProvider);

  @override
  AppState build() {
    // 상태 변화를 로컬 사본에 남긴다. 다음 실행(특히 오프라인)에서 이 사본으로
    // 화면을 채운다. 저장 대상(toJson)이 바뀐 경우만 쓴다.
    listenSelf((prev, next) {
      if (prev == null) return;
      if (!_persistedEquals(prev, next)) unawaited(_cache.write(next));
    });

    // 사본 먼저(즉시), 서버는 그 다음. 실패(오프라인)해도 앱은 뜬다.
    unawaited(_restoreCache());
    unawaited(_ensureReady().catchError((_) {}));
    return const AppState();
  }

  /// 마지막 사본으로 화면을 채운다. 서버 응답이 이미 도착했으면 아무것도 안 한다.
  Future<void> _restoreCache() async {
    final cached = await _cache.read();
    if (cached == null || _serverApplied) return;
    state = state.copyWith(
      leaves: cached.leaves,
      clovers: cached.clovers,
      coins: cached.coins,
      statLeaves: cached.statLeaves,
      statClovers: cached.statClovers,
      statPulls: cached.statPulls,
      tickets: cached.tickets,
      customTickets: cached.customTickets,
      // 사본의 기록은 바로 보여주되 '받았다'고 표시하지 않는다 —
      // '나의 기록' 탭에 들어가면 서버 최신본으로 다시 채운다.
      history: cached.history,
      adCoinsToday: cached.adCoinsToday,
      lastAdCoinDate: cached.lastAdCoinDate,
    );
  }

  /// 사본에 남기는 필드만 비교한다 — 탭 전환·애니메이션 키 때문에
  /// 매번 디스크에 쓰지 않도록.
  static bool _persistedEquals(AppState a, AppState b) =>
      a.leaves == b.leaves &&
      a.clovers == b.clovers &&
      a.coins == b.coins &&
      a.statLeaves == b.statLeaves &&
      a.statClovers == b.statClovers &&
      a.statPulls == b.statPulls &&
      a.adCoinsToday == b.adCoinsToday &&
      a.lastAdCoinDate == b.lastAdCoinDate &&
      identical(a.tickets, b.tickets) &&
      identical(a.customTickets, b.customTickets) &&
      identical(a.history, b.history);

  /// 연결이 끊겨 있을 때 다시 시도한다 (오프라인 띠를 눌렀을 때).
  Future<void> retrySync() async {
    try {
      await _ensureReady();
    } catch (_) {
      // 여전히 오프라인 — 띠가 그대로 남는다.
    }
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
    run.catchError((Object e) {
      _bootstrap = null;
      // 서버에 못 붙었다 — 사본으로 계속 돌되 그 사실을 화면에 알린다.
      state = state.copyWith(offline: true);
    });
    return run;
  }

  Future<void> _runBootstrap() async {
    await _backend.ensureSignedIn();

    // 오늘 몫의 무료 코인. 스냅샷보다 먼저 받아야 방금 받은 코인이 첫 화면에
    // 반영된다. 실패해도 부트스트랩을 세우지 않는다 — 곁가지 하나 때문에
    // 앱 전체가 못 뜨면 안 된다.
    try {
      await _backend.claimDailyCoin();
    } catch (_) {}

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
    _serverApplied = true;
  }

  /// 서버 스냅샷을 반영한다 (탭/애니메이션 등 UI 휘발 필드는 보존).
  void _applySnapshot(AppState data) {
    state = state.copyWith(
      leaves: data.leaves,
      clovers: data.clovers,
      coins: data.coins,
      statLeaves: data.statLeaves,
      statClovers: data.statClovers,
      statPulls: data.statPulls,
      tickets: data.tickets,
      customTickets: data.customTickets,
      // 기록은 스냅샷에 없다 — 여기서 비우면 복구 코드로 계정이 바뀐 뒤에도
      // 옛 계정 타임라인이 남지 않고, 다음에 탭을 열 때 다시 받는다.
      history: const [],
      historyLoaded: false,
      offline: false, // 서버 응답이 왔다 = 연결됨
      adCoinsToday: data.adCoinsToday,
      lastAdCoinDate: data.lastAdCoinDate,
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

  /// 광고 코인 리셋 기준일 — 서버(grant_ad_coin)의 current_date(UTC)와 맞춘다.
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

  /// 완성 축하 연출 → 클로버 확정 → 배지로 날아가는 연출.
  /// 클로버 생산에는 광고를 넣지 않는다 (광고는 소비 시점에만).
  void _scheduleCloverFinish() {
    Future.delayed(const Duration(milliseconds: 700), finishCloverCelebration);
  }

  /// 클로버 완성 연출 후 잎 4개 차감 + 보유 클로버 +1 (서버 확정).
  ///
  /// 확정에 성공해야만 [AppState.flightKey] 를 올린다. 덕분에 "비행을 봤다"는
  /// 곧 "클로버가 실제로 적립됐다"와 같은 뜻이 되고, 헛되이 날아가는 일이 없다.
  Future<void> finishCloverCelebration() async {
    if (state.leaves < 4) return;
    try {
      final r = await _backend.finishClover();
      state = state.copyWith(
        leaves: r.leaves,
        clovers: r.clovers,
        celebrate: false,
        statClovers: state.statClovers + 1,
        flightKey: state.flightKey + 1,
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
  /// 오늘 광고로 더 받을 수 있는 코인 수 (서버 기준일=UTC 과 동일 규칙).
  int get adCoinsLeft {
    final used = state.lastAdCoinDate == _todayUtc() ? state.adCoinsToday : 0;
    return (kAdCoinsPerDay - used).clamp(0, kAdCoinsPerDay);
  }

  /// 광고 시청 보상으로 코인 1개를 받는다 (하루 [kAdCoinsPerDay] 회).
  /// 한도 초과면 false, 오프라인이면 [GameConnectionException].
  Future<bool> grantAdCoin() async {
    await _ensureReady();

    final AdCoinResult r;
    try {
      r = await _backend.grantAdCoin();
    } on GameRuleException {
      return false;
    }

    state = state.copyWith(
      coins: r.coins,
      adCoinsToday: r.usedToday,
      lastAdCoinDate: _todayUtc(),
    );
    return true;
  }

  /// 뽑기 1회 — 코인 1개를 소모하고, 추첨은 서버에서 실행된다.
  /// 뽑을 수 없으면(코인 부족) null, 오프라인이면 [GameConnectionException].
  Future<PullResult?> pullGacha() async {
    await _ensureReady();

    final GachaOutcome r;
    try {
      r = await _backend.pullGacha();
    } on GameRuleException {
      return null;
    }

    final ticket = LuckCatalog.byId(r.ticketId);
    if (ticket == null) {
      // 서버 카탈로그가 앱보다 새 버전 — 결과를 그릴 수 없다. 상태만 재동기화.
      unawaited(refresh());
      return null;
    }

    final instance = TicketInstance(
      id: r.instanceId,
      ticketId: r.ticketId,
      level: r.level,
      pulledAt: _todayLocal(),
    );

    state = state.copyWith(
      coins: state.coins - 1,
      statPulls: state.statPulls + 1,
      tickets: [instance, ...state.tickets],
      history: [
        HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch,
            date: _todayLocal(),
            kind: HistoryKind.pull,
            text: r.ticketId,
            amount: 1),
        ...state.history,
      ],
    );
    return PullResult(
      ticket: ticket,
      instance: instance,
      copies: r.copies,
      isNew: r.isNew,
    );
  }

  // ---- 커스텀 행운권 ----
  /// 문구 [text] 로 나만의 행운권을 만든다 (클로버 1개).
  ///
  /// **광고 시청이 끝난 뒤에만 호출한다.** 광고를 건너뛰거나 실패한 채 부르면
  /// 게이트 없이 카드가 만들어진다. 규칙 위반(문구 길이/클로버 부족)이면 null,
  /// 오프라인이면 [GameConnectionException].
  Future<CustomTicket?> createCustomTicket(String text) async {
    await _ensureReady();

    final CustomTicketResult r;
    try {
      r = await _backend.createCustomTicket(text);
    } on GameRuleException {
      return null;
    }

    state = state.copyWith(
      clovers: r.clovers,
      customTickets: [r.ticket, ...state.customTickets],
      history: [
        HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch,
            date: _todayLocal(),
            kind: HistoryKind.custom,
            text: r.ticket.text,
            amount: state.clovers - r.clovers),
        ...state.history,
      ],
    );
    return r.ticket;
  }

  /// 커스텀 행운권 강화 — 클로버를 현재 레벨 수만큼 쓰고 한 단계 오른다.
  /// 실패 판정이 없으므로 성공하면 반드시 레벨이 오른다.
  /// 규칙 위반(최고 단계/클로버 부족)이면 null, 오프라인이면 예외.
  Future<CustomEnhanceResult?> enhanceCustomTicket(String id) async {
    await _ensureReady();

    final CustomEnhanceResult r;
    try {
      r = await _backend.enhanceCustomTicket(id);
    } on GameRuleException {
      return null;
    }

    state = state.copyWith(
      clovers: r.clovers,
      customTickets: [
        for (final t in state.customTickets)
          t.id == id ? t.copyWith(level: r.level) : t,
      ],
    );
    return r;
  }

  /// 카드 [instanceId] 강화 — 같은 행운권 카드 [materialIds] 를 재료로 소모한다.
  /// 판정은 서버가 하고, 실패해도 재료는 사라진다.
  /// 규칙 위반(재료 불일치/최고 단계)이면 null, 오프라인이면 예외.
  Future<EnhanceOutcome?> enhanceTicket(
      String instanceId, List<String> materialIds) async {
    await _ensureReady();

    final EnhanceOutcome r;
    try {
      r = await _backend.enhanceTicket(instanceId, materialIds);
    } on GameRuleException {
      return null;
    }

    final consumed = materialIds.toSet()..remove(instanceId);
    final tickets = [
      for (final t in state.tickets)
        if (!consumed.contains(t.id))
          t.id == instanceId ? t.copyWith(level: r.level) : t,
    ];
    state = state.copyWith(tickets: tickets);
    return r;
  }

  /// 재조합 — 카드 [materialIds] 를 갈아 새 카드 1장을 만든다(서버 추첨).
  /// 규칙 위반(장수 불일치)이면 null, 오프라인이면 예외.
  Future<ReforgeOutcome?> reforgeTickets(List<String> materialIds) async {
    await _ensureReady();

    final ReforgeOutcome r;
    try {
      r = await _backend.reforgeTickets(materialIds);
    } on GameRuleException {
      return null;
    }

    final consumed = materialIds.toSet();
    final made = TicketInstance(
      id: r.instance.id,
      ticketId: r.instance.ticketId,
      pulledAt: _todayLocal(),
    );
    state = state.copyWith(tickets: [
      made,
      for (final t in state.tickets)
        if (!consumed.contains(t.id)) t,
    ]);
    return ReforgeOutcome(instance: made, isNew: r.isNew, upgraded: r.upgraded);
  }

  // ---- 복구 코드 ----
  /// 이 계정의 복구 코드를 발급/조회한다(계정당 1개, 재사용).
  /// [lang] 은 코드 단어를 만들 언어 — 읽을 수 없는 코드는 복구에 쓸모가 없다.
  /// 오프라인이면 [GameConnectionException].
  Future<String> issueRecoveryCode(String lang) async {
    await _ensureReady();
    return _backend.issueRecoveryCode(lang);
  }

  /// 복구 코드로 옛 계정의 자산을 지금 세션으로 가져온다.
  /// 오프라인이면 [GameConnectionException].
  Future<RecoveryOutcome> redeemRecoveryCode(String code) async {
    await _ensureReady();
    try {
      await _backend.redeemRecoveryCode(code);
    } on GameRuleException catch (e) {
      // 시도 제한과 코드 오류는 사용자에게 다르게 안내해야 한다 —
      // 전자는 기다리면 풀리고, 후자는 코드를 다시 확인해야 한다.
      return e.code == GameRuleException.recoveryRateLimited
          ? RecoveryOutcome.rateLimited
          : RecoveryOutcome.notFound;
    }
    await refresh();
    return RecoveryOutcome.restored;
  }

  /// 타임라인 기록을 (아직 안 받았으면) 받아온다. '나의 기록' 탭 진입 시 호출.
  ///
  /// 콜드 스타트 스냅샷에서 기록 300건이 가장 큰 덩어리인데, 대부분의 세션은
  /// 그 탭을 열지도 않는다. 그래서 볼 때 받는다.
  /// 실패(오프라인 등)는 삼킨다 — 화면이 비어 보일 뿐 앱은 계속 돈다.
  Future<void> ensureHistoryLoaded() async {
    if (state.historyLoaded) return;
    final running = _historyLoad;
    if (running != null) return running;
    final run = _loadHistory();
    _historyLoad = run;
    try {
      await run;
    } catch (_) {
      // 다음 진입에서 다시 시도한다.
    } finally {
      _historyLoad = null;
    }
  }

  Future<void> _loadHistory() async {
    await _ensureReady();
    final rows = await _backend.fetchHistory();
    // 서버 목록이 권위다 — 로딩 중에 낙관적으로 끼워 넣은 항목이 있어도
    // 그건 이미 서버에 쓰인 것이라 다음 목록에 포함된다.
    state = state.copyWith(history: rows, historyLoaded: true);
  }

  /// 서버 상태 강제 재동기화.
  Future<void> refresh() async {
    await _ensureReady();
    final snap = await _backend.fetchState();
    _applySnapshot(snap.data);
  }
}

/// 복구 코드 사용 결과 — UI 는 이 셋을 각각 다른 문구로 안내한다.
enum RecoveryOutcome { restored, notFound, rateLimited }
