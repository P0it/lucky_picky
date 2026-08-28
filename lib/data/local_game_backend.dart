import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/luck_tickets.dart';
import '../models/app_state.dart';
import '../models/custom_ticket.dart';
import '../models/deed.dart';
import '../models/ticket_instance.dart';
import 'game_backend.dart';

/// 서버 RPC 와 동일한 규칙의 로컬 구현.
/// 테스트의 기준 구현이자 SQL(20260710000003_game_rpcs.sql)의 실행 가능한 명세다 —
/// 규칙을 바꿀 때는 SQL 과 이 파일을 함께 바꾼다.
class LocalGameBackend implements GameBackend {
  AppState _data;
  bool importedLocal;

  /// 추첨/강화 판정용 난수원 — 테스트에서 시드 고정용으로 교체한다.
  @visibleForTesting
  math.Random rng;

  /// 로컬 인스턴스 id 발급기 (서버는 uuid).
  int _instanceSeq = 0;

  /// 복구 코드 저장소 — 여러 계정(백엔드 인스턴스)이 코드로 서로를 찾을 수 있게
  /// 공유한다. 테스트에서 두 계정 간 이관을 확인하려면 같은 store 를 넘긴다.
  final LocalRecoveryStore _recovery;

  /// 이 계정이 발급받은 복구 코드(표시용 원문). 없으면 아직 미발급.
  String? _recoveryCode;
  /// 마지막으로 무료 코인을 받은 날 'YYYY.MM.DD' (서버 profiles.last_free_coin_date).
  String? _lastFreeCoinDate;

  LocalGameBackend(
      {AppState? seed,
      math.Random? rng,
      this.importedLocal = false,
      LocalRecoveryStore? recovery})
      : _data = seed ?? const AppState(),
        rng = rng ?? math.Random(),
        _recovery = recovery ?? LocalRecoveryStore();

  static String _fmt(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${p(d.month)}.${p(d.day)}';
  }

  String get _today => _fmt(DateTime.now().toUtc());

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<BackendSnapshot> fetchState() async =>
      // 서버와 같은 모양으로 — 기록은 스냅샷에 싣지 않는다 (fetchHistory 참고).
      BackendSnapshot(
          data: _data.copyWith(history: const []), importedLocal: importedLocal);

  @override
  Future<List<HistoryEntry>> fetchHistory({int limit = 300}) async =>
      _data.history.take(limit).toList(growable: false);

  @override
  Future<DeedResult> recordDeed(String text) async {
    final deed = text.trim();
    if (deed.isEmpty || deed.length > 200) {
      throw const GameRuleException(GameRuleException.invalidDeed);
    }
    final leaves = _data.leaves + 1;
    _data = _data.copyWith(
      leaves: leaves,
      statLeaves: _data.statLeaves + 1,
      history: [
        HistoryEntryOf.deed(deed, _today),
        ..._data.history,
      ],
    );
    return DeedResult(leaves: leaves, cloverCompleted: leaves >= 4);
  }

  @override
  Future<CloverResult> finishClover() async {
    if (_data.leaves < 4) {
      throw const GameRuleException(GameRuleException.noCloverReady);
    }
    _data = _data.copyWith(
      leaves: _data.leaves - 4,
      clovers: _data.clovers + 1,
      statClovers: _data.statClovers + 1,
    );
    return CloverResult(leaves: _data.leaves, clovers: _data.clovers);
  }

  @override
  Future<GachaOutcome> pullGacha() async {
    if (_data.coins < 1) {
      throw const GameRuleException(GameRuleException.noCoins);
    }

    final today = _today;
    final ticket = drawTicket(rng);

    final tickets = [..._data.tickets];
    final isNew = !tickets.any((t) => t.ticketId == ticket.id);
    final instance = TicketInstance(
      id: 'local_${++_instanceSeq}',
      ticketId: ticket.id,
      pulledAt: today,
    );
    tickets.insert(0, instance);
    final copies = tickets.where((t) => t.ticketId == ticket.id).length;

    _data = _data.copyWith(
      coins: _data.coins - 1,
      statPulls: _data.statPulls + 1,
      tickets: tickets,
      history: [
        HistoryEntryOf.pull(ticket.id, 1, today),
        ..._data.history,
      ],
    );
    return GachaOutcome(
      instanceId: instance.id,
      ticketId: ticket.id,
      isNew: isNew,
      copies: copies,
      level: instance.level,
    );
  }

  /// 광고 보상 — 코인 1개 지급. 코인은 뽑기에만 쓰이고 클로버와 섞이지 않는다.
  @override
  Future<AdCoinResult> grantAdCoin() async {
    final today = _today;
    final used = _data.lastAdCoinDate == today ? _data.adCoinsToday : 0;
    if (used >= kAdCoinsPerDayRule) {
      throw const GameRuleException(GameRuleException.noAdCoins);
    }
    _data = _data.copyWith(
      coins: _data.coins + 1,
      adCoinsToday: used + 1,
      lastAdCoinDate: today,
    );
    return AdCoinResult(coins: _data.coins, usedToday: used + 1);
  }

  /// 하루 무료 코인 — 날짜가 바뀌면 다시 받을 수 있다.
  /// 서버 claim_daily_coin 과 같은 규칙(UTC 기준일).
  @override
  Future<DailyCoinResult> claimDailyCoin() async {
    final today = _today;
    if (_lastFreeCoinDate == today) {
      return DailyCoinResult(claimed: false, coins: _data.coins);
    }
    _lastFreeCoinDate = today;
    _data = _data.copyWith(coins: _data.coins + kFreeCoinsPerDayRule);
    return DailyCoinResult(claimed: true, coins: _data.coins);
  }

  /// 커스텀 행운권 제작 — 클로버 1개 소모. 문구는 트림 후 1~40자.
  @override
  Future<CustomTicketResult> createCustomTicket(String text) async {
    final body = text.trim();
    if (body.isEmpty || body.length > CustomTicket.maxTextLength) {
      throw const GameRuleException(GameRuleException.invalidText);
    }
    if (_data.clovers < kCustomTicketCost) {
      throw const GameRuleException(GameRuleException.noClover);
    }

    final today = _today;
    final made = CustomTicket(
      id: 'custom_${++_instanceSeq}',
      text: body,
      createdAt: today,
    );
    _data = _data.copyWith(
      clovers: _data.clovers - kCustomTicketCost,
      customTickets: [made, ..._data.customTickets],
      history: [
        HistoryEntryOf.custom(body, kCustomTicketCost, today),
        ..._data.history,
      ],
    );
    return CustomTicketResult(ticket: made, clovers: _data.clovers);
  }

  /// 커스텀 행운권 강화 — 클로버를 현재 레벨 수만큼 쓰고 무조건 한 단계 오른다.
  /// 등급이 없는 카드라 확률 판정을 두지 않는다.
  @override
  Future<CustomEnhanceResult> enhanceCustomTicket(String id) async {
    final cards = [..._data.customTickets];
    final idx = cards.indexWhere((t) => t.id == id);
    if (idx < 0) {
      throw const GameRuleException(GameRuleException.ticketNotOwned);
    }
    final target = cards[idx];
    if (target.isMaxLevel) {
      throw const GameRuleException(GameRuleException.cannotEnhance);
    }
    if (_data.clovers < target.enhanceCost) {
      throw const GameRuleException(GameRuleException.noClover);
    }

    cards[idx] = target.copyWith(level: target.level + 1);
    _data = _data.copyWith(
      clovers: _data.clovers - target.enhanceCost,
      customTickets: cards,
    );
    return CustomEnhanceResult(
      id: id,
      level: target.level + 1,
      clovers: _data.clovers,
    );
  }

  /// 대상 카드 1장 + 재료 카드 N장(아무 카드나)을 소모해 강화한다.
  /// 재료의 등급이 성공 확률을 좌우하고(TicketInstance.successRateWith),
  /// 재료는 성공/실패와 무관하게 사라진다.
  @override
  Future<EnhanceOutcome> enhanceTicket(
      String instanceId, List<String> materialIds) async {
    final tickets = [..._data.tickets];
    final idx = tickets.indexWhere((t) => t.id == instanceId);
    if (idx < 0) {
      throw const GameRuleException(GameRuleException.ticketNotOwned);
    }
    final target = tickets[idx];
    if (target.isMaxLevel) {
      throw const GameRuleException(GameRuleException.cannotEnhance);
    }

    // 재료 검증 — 본인 소유 · 대상 제외 · 요구 장수와 일치. 종류/등급 제한은 없다.
    final ids = materialIds.toSet()..remove(instanceId);
    final materials = tickets.where((t) => ids.contains(t.id)).toList();
    if (materials.length != target.materialsNeeded) {
      throw const GameRuleException(GameRuleException.cannotEnhance);
    }

    final consumed = materials.map((t) => t.id).toSet();
    tickets.removeWhere((t) => consumed.contains(t.id));

    final rate = target.successRateWith(materials);
    final success = rng.nextInt(100) < rate;
    if (success) {
      final at = tickets.indexWhere((t) => t.id == instanceId);
      tickets[at] = target.copyWith(level: target.level + 1);
    }

    _data = _data.copyWith(tickets: tickets);
    return EnhanceOutcome(
      instanceId: instanceId,
      ticketId: target.ticketId,
      success: success,
      level: success ? target.level + 1 : target.level,
      rate: rate,
    );
  }

  /// 재조합 — 카드 3장을 갈아 새 카드 1장을 만든다.
  /// 등급은 재료 중 최고 등급을 따르고, 25% 확률로 한 단계 올라간다.
  @override
  Future<ReforgeOutcome> reforgeTickets(List<String> materialIds) async {
    final tickets = [..._data.tickets];
    final ids = materialIds.toSet();
    final materials = tickets.where((t) => ids.contains(t.id)).toList();
    if (materials.length != TicketInstance.reforgeMaterials) {
      throw const GameRuleException(GameRuleException.cannotReforge);
    }

    tickets.removeWhere((t) => ids.contains(t.id));

    final top = materials
        .map((t) => LuckCatalog.byId(t.ticketId)!.rarity.index)
        .reduce(math.max);
    final canUpgrade = top + 1 < Rarity.values.length;
    final upgraded =
        canUpgrade && rng.nextInt(100) < TicketInstance.reforgeUpgradeRate;
    final rarity = Rarity.values[upgraded ? top + 1 : top];

    final pool = LuckCatalog.byRarity(rarity);
    final ticket = pool[rng.nextInt(pool.length)];
    final isNew = !tickets.any((t) => t.ticketId == ticket.id);
    final instance = TicketInstance(
      id: 'local_${++_instanceSeq}',
      ticketId: ticket.id,
      pulledAt: _today,
    );
    tickets.insert(0, instance);

    _data = _data.copyWith(tickets: tickets);
    return ReforgeOutcome(
      instance: instance,
      isNew: isNew,
      upgraded: upgraded,
    );
  }

  @override
  Future<void> importLocalState(Map<String, dynamic> payload) async {
    if (importedLocal) {
      throw const GameRuleException(GameRuleException.alreadyImported);
    }
    _data = AppState.fromJson(payload);
    importedLocal = true;
  }

  @override
  Future<String> issueRecoveryCode([String lang = 'en']) async {
    if (_recoveryCode != null) return _recoveryCode!;
    String words;
    do {
      words = _genRecoveryCode(rng, lang);
    } while (_recovery.byNorm.containsKey(normalizeRecoveryCode(words)));
    _recoveryCode = words;
    _recovery.byNorm[normalizeRecoveryCode(words)] = this;
    return words;
  }

  @override
  Future<void> redeemRecoveryCode(String code) async {
    final owner = _recovery.byNorm[normalizeRecoveryCode(code)];
    if (owner == null) {
      throw const GameRuleException(GameRuleException.recoveryNotFound);
    }
    if (identical(owner, this)) return;

    final norm = normalizeRecoveryCode(owner._recoveryCode!);
    // 자산을 이곳으로 옮기고, 원본은 빈 계정으로 되돌린다.
    _data = owner._data;
    owner._data = const AppState();

    // 코드는 늘 자산이 있는 곳을 가리킨다: 내 옛 코드는 버리고 이 코드를 넘겨받는다.
    if (_recoveryCode != null) {
      _recovery.byNorm.remove(normalizeRecoveryCode(_recoveryCode!));
    }
    _recoveryCode = owner._recoveryCode;
    owner._recoveryCode = null;
    _recovery.byNorm[norm] = this;
  }

  /// 하루 광고 코인 지급 한도 — 서버 game_config 의 ad_coins_per_day 와 동치.
  static const int kAdCoinsPerDayRule = 5;

  /// 하루 무료 코인 — 서버 game_config 의 free_coins_per_day 와 동치.
  static const int kFreeCoinsPerDayRule = 1;

  /// 커스텀 행운권 제작 비용 — 서버 game_config 의 custom_ticket_cost 와 동치.
  static const int kCustomTicketCost = CustomTicket.createCost;

  /// 가중치 추첨 — 등급을 가중치로 뽑고, 등급 내에서 균등 추첨.
  /// (서버 pull_gacha 의 추첨 규칙과 동일)
  @visibleForTesting
  static LuckTicket drawTicket(math.Random rng) {
    final total = LuckCatalog.weights.values.reduce((a, b) => a + b);
    var roll = rng.nextInt(total);
    var rarity = Rarity.common;
    for (final entry in LuckCatalog.weights.entries) {
      if (roll < entry.value) {
        rarity = entry.key;
        break;
      }
      roll -= entry.value;
    }
    final pool = LuckCatalog.byRarity(rarity);
    return pool[rng.nextInt(pool.length)];
  }
}

/// history 항목 생성 헬퍼 (id 는 로컬 구현에서만 쓰는 타임스탬프).
class HistoryEntryOf {
  const HistoryEntryOf._();

  static HistoryEntry deed(String text, String date) => HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      date: date,
      kind: HistoryKind.deed,
      text: text,
      amount: 1);

  static HistoryEntry pull(String ticketId, int amount, String date) =>
      HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch,
          date: date,
          kind: HistoryKind.pull,
          text: ticketId,
          amount: amount);

  static HistoryEntry custom(String text, int amount, String date) =>
      HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch,
          date: date,
          kind: HistoryKind.custom,
          text: text,
          amount: amount);
}

/// 복구 코드로 계정(백엔드 인스턴스)을 찾는 공유 저장소 — 서버의 recovery_codes
/// 테이블에 해당한다. 키는 정규화된 코드.
class LocalRecoveryStore {
  final Map<String, LocalGameBackend> byNorm = {};
}

// 서버는 recovery_words 테이블에 언어별 44+44 단어를 들고 있다. 로컬 구현은
// 테스트·개발용 거울이라 언어별로 몇 개씩만 둔다 — 형식(3쌍)과 언어 분기가
// 서버와 같은지 확인하는 것이 목적이지, 대입 공간을 재현하는 게 아니다.
const _recoveryAdjectives = <String, List<String>>{
  'ko': ['느긋한', '억울한', '수줍은', '엉뚱한', '새침한', '나른한', '얼큰한', '담백한'],
  'en': ['brave', 'sleepy', 'jolly', 'crispy', 'fluffy', 'grumpy', 'shiny', 'mellow'],
  'ja': ['のんきな', 'しずかな', 'はでな', 'すなおな', 'へんな', 'げんきな', 'ゆかいな', 'まじめな'],
};

const _recoveryNouns = <String, List<String>>{
  'ko': ['참치마요', '스파게티', '형광등', '소화전', '고등어', '세탁기', '코뿔소', '우체통'],
  'en': ['tunafish', 'spaghetti', 'lightbulb', 'hydrant', 'mackerel', 'washer', 'rhino', 'mailbox'],
  'ja': ['ツナマヨ', 'スパゲティ', 'けいこうとう', 'しょうかせん', 'さば', 'せんたくき', 'サイ', 'ポスト'],
};

/// "형용사 + 뜬금없는 개념" 세 쌍 조합. 서버 issue_recovery_code 와 같은 형식.
/// 두 쌍(44^4 ≈ 375만)은 대입으로 뚫려서 세 쌍(44^6 ≈ 72.6억)으로 늘렸다.
/// 모르는 언어는 영어로 — 읽고 입력할 수 있는 범위가 가장 넓다.
String _genRecoveryCode(math.Random rng, String lang) {
  final code = _recoveryAdjectives.containsKey(lang) ? lang : 'en';
  final adj = _recoveryAdjectives[code]!;
  final noun = _recoveryNouns[code]!;
  // 일본어는 형용사와 명사를 붙여 쓴다.
  final glue = code == 'ja' ? '' : ' ';
  String pair() =>
      '${adj[rng.nextInt(adj.length)]}$glue${noun[rng.nextInt(noun.length)]}';
  return '${pair()} ${pair()} ${pair()}';
}
