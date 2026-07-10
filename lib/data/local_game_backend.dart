import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/luck_tickets.dart';
import '../models/app_state.dart';
import '../models/deed.dart';
import '../models/owned_ticket.dart';
import 'game_backend.dart';

/// 서버 RPC 와 동일한 규칙의 로컬 구현.
/// 테스트의 기준 구현이자 SQL(20260710000003_game_rpcs.sql)의 실행 가능한 명세다 —
/// 규칙을 바꿀 때는 SQL 과 이 파일을 함께 바꾼다.
class LocalGameBackend implements GameBackend {
  AppState _data;
  bool importedLocal;

  /// 추첨용 난수원 — 테스트에서 시드 고정용으로 교체한다.
  @visibleForTesting
  math.Random rng;

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
  Future<GachaOutcome> pullGacha({required bool free}) async {
    final today = _today;
    if (free) {
      final used =
          _data.lastFreePullDate == today ? _data.freePullsUsedToday : 0;
      if (used >= kFreePullsPerDayRule) {
        throw const GameRuleException(GameRuleException.noFreePulls);
      }
    } else {
      if (_data.clovers < 1) {
        throw const GameRuleException(GameRuleException.noClover);
      }
    }

    final ticket = drawTicket(rng);

    final tickets = [..._data.tickets];
    final idx = tickets.indexWhere((t) => t.ticketId == ticket.id);
    final isNew = idx < 0;
    final OwnedTicket owned;
    if (isNew) {
      owned = OwnedTicket(ticketId: ticket.id, firstPulledAt: today);
      tickets.insert(0, owned);
    } else {
      owned = tickets[idx].copyWith(copies: tickets[idx].copies + 1);
      tickets[idx] = owned;
    }

    _data = _data.copyWith(
      clovers: free ? _data.clovers : _data.clovers - 1,
      statPulls: _data.statPulls + 1,
      tickets: tickets,
      freePullsUsedToday: free
          ? (_data.lastFreePullDate == today ? _data.freePullsUsedToday : 0) + 1
          : _data.freePullsUsedToday,
      lastFreePullDate: free ? today : _data.lastFreePullDate,
      history: [
        HistoryEntryOf.pull(ticket.id, free ? 0 : 1, _today),
        ..._data.history,
      ],
    );
    return GachaOutcome(
      ticketId: ticket.id,
      isNew: isNew,
      copies: owned.copies,
      level: owned.level,
      free: free,
    );
  }

  @override
  Future<EnhanceOutcome> enhanceTicket(String ticketId) async {
    final tickets = [..._data.tickets];
    final idx = tickets.indexWhere((t) => t.ticketId == ticketId);
    if (idx < 0) {
      throw const GameRuleException(GameRuleException.ticketNotOwned);
    }
    final cur = tickets[idx];
    if (!cur.canEnhance) {
      throw const GameRuleException(GameRuleException.cannotEnhance);
    }
    final upgraded = cur.copyWith(level: cur.level + 1);
    tickets[idx] = upgraded;
    _data = _data.copyWith(tickets: tickets);
    return EnhanceOutcome(
        ticketId: ticketId, copies: upgraded.copies, level: upgraded.level);
  }

  @override
  Future<void> importLocalState(Map<String, dynamic> payload) async {
    if (importedLocal) {
      throw const GameRuleException(GameRuleException.alreadyImported);
    }
    _data = AppState.fromJson(payload);
    importedLocal = true;
  }

  /// 하루 무료(광고) 뽑기 한도 — 서버 game_config 의 free_pulls_per_day 와 동치.
  static const int kFreePullsPerDayRule = 3;

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
