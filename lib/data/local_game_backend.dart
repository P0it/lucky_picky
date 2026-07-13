import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/luck_tickets.dart';
import '../models/app_state.dart';
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

  LocalGameBackend({AppState? seed, math.Random? rng, this.importedLocal = false})
      : _data = seed ?? const AppState(),
        rng = rng ?? math.Random();

  static String _fmt(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${p(d.month)}.${p(d.day)}';
  }

  String get _today => _fmt(DateTime.now().toUtc());

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<BackendSnapshot> fetchState() async =>
      BackendSnapshot(data: _data, importedLocal: importedLocal);

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
    if (_data.clovers < 1) {
      throw const GameRuleException(GameRuleException.noClover);
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
      clovers: _data.clovers - 1,
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

  /// 광고 보상 — 클로버 1개 지급. 선행으로 만든 클로버(statClovers)에는 넣지 않는다.
  @override
  Future<AdCloverResult> grantAdClover() async {
    final today = _today;
    final used =
        _data.lastAdCloverDate == today ? _data.adCloversToday : 0;
    if (used >= kAdCloversPerDayRule) {
      throw const GameRuleException(GameRuleException.noAdClovers);
    }
    _data = _data.copyWith(
      clovers: _data.clovers + 1,
      adCloversToday: used + 1,
      lastAdCloverDate: today,
    );
    return AdCloverResult(clovers: _data.clovers, usedToday: used + 1);
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

  /// 하루 광고 클로버 지급 한도 — 서버 game_config 의 ad_clovers_per_day 와 동치.
  static const int kAdCloversPerDayRule = 3;

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
}
