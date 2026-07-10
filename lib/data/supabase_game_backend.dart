import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_state.dart';
import '../models/deed.dart';
import '../models/owned_ticket.dart';
import 'game_backend.dart';

/// Supabase 실구현 — 모든 상태 변경은 서버 RPC(서버 권위)를 호출한다.
/// 스키마/함수: supabase/migrations/ 참고.
class SupabaseGameBackend implements GameBackend {
  final SupabaseClient _client;
  SupabaseGameBackend(this._client);

  /// 'YYYY-MM-DD'(서버 date) → 'YYYY.MM.DD'(앱 표시 포맷).
  static String _dotDate(String? iso) =>
      (iso == null || iso.isEmpty) ? '' : iso.substring(0, 10).replaceAll('-', '.');

  @override
  Future<void> ensureSignedIn() => _guard(() async {
        if (_client.auth.currentSession == null) {
          await _client.auth.signInAnonymously();
        }
      });

  @override
  Future<BackendSnapshot> fetchState() => _guard(() async {
        final profile = await _client.from('profiles').select().single();
        final tickets = await _client
            .from('owned_tickets')
            .select()
            .order('first_pulled_at', ascending: false)
            .order('ticket_id');
        final history = await _client
            .from('history')
            .select()
            .order('created_at', ascending: false)
            .limit(300);

        return BackendSnapshot(
          importedLocal: profile['imported_local'] as bool? ?? false,
          data: AppState(
            leaves: profile['leaves'] as int? ?? 0,
            clovers: profile['clovers'] as int? ?? 0,
            statLeaves: profile['stat_leaves'] as int? ?? 0,
            statClovers: profile['stat_clovers'] as int? ?? 0,
            statPulls: profile['stat_pulls'] as int? ?? 0,
            freePullsUsedToday: profile['free_pulls_used_today'] as int? ?? 0,
            lastFreePullDate:
                _dotDate(profile['last_free_pull_date'] as String?),
            tickets: [
              for (final t in tickets)
                OwnedTicket(
                  ticketId: t['ticket_id'] as String,
                  copies: t['copies'] as int? ?? 1,
                  level: t['level'] as int? ?? 1,
                  firstPulledAt: _dotDate(t['first_pulled_at'] as String?),
                ),
            ],
            history: [
              for (final h in history)
                HistoryEntry(
                  id: h['id'] as int,
                  date: _dotDate(h['happened_on'] as String?),
                  kind: h['kind'] == 'deed' ? HistoryKind.deed : HistoryKind.pull,
                  text: h['text'] as String? ?? '',
                  amount: h['amount'] as int? ?? 0,
                ),
            ],
          ),
        );
      });

  @override
  Future<DeedResult> recordDeed(String text) => _guard(() async {
        final r = await _rpc('record_deed', {'p_text': text});
        return DeedResult(
          leaves: r['leaves'] as int,
          cloverCompleted: r['clover_completed'] as bool,
        );
      });

  @override
  Future<CloverResult> finishClover() => _guard(() async {
        final r = await _rpc('finish_clover');
        return CloverResult(
            leaves: r['leaves'] as int, clovers: r['clovers'] as int);
      });

  @override
  Future<GachaOutcome> pullGacha({required bool free}) => _guard(() async {
        final r = await _rpc('pull_gacha', {'p_free': free});
        return GachaOutcome(
          ticketId: r['ticket_id'] as String,
          isNew: r['is_new'] as bool,
          copies: r['copies'] as int,
          level: r['level'] as int,
          free: r['free'] as bool,
        );
      });

  @override
  Future<EnhanceOutcome> enhanceTicket(String ticketId) => _guard(() async {
        final r = await _rpc('enhance_ticket', {'p_ticket_id': ticketId});
        return EnhanceOutcome(
          ticketId: r['ticket_id'] as String,
          copies: r['copies'] as int,
          level: r['level'] as int,
        );
      });

  @override
  Future<void> importLocalState(Map<String, dynamic> payload) => _guard(
      () async => _rpc('import_local_state', {'p_payload': payload}));

  Future<Map<String, dynamic>> _rpc(String fn,
      [Map<String, dynamic>? params]) async {
    final r = await _client.rpc(fn, params: params);
    return (r as Map).cast<String, dynamic>();
  }

  /// 예외 정규화: 게임 규칙 위반 → [GameRuleException],
  /// 그 외(네트워크/타임아웃/서버 오류) → [GameConnectionException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      final code = e.message.trim();
      if (GameRuleException.known.contains(code)) {
        throw GameRuleException(code);
      }
      throw GameConnectionException(e);
    } on GameRuleException {
      rethrow;
    } catch (e) {
      throw GameConnectionException(e);
    }
  }
}
