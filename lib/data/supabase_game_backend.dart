import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_state.dart';
import '../models/custom_ticket.dart';
import '../models/deed.dart';
import '../models/ticket_instance.dart';
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
            .from('ticket_instances')
            .select()
            .order('created_at', ascending: false);
        final customs = await _client
            .from('custom_tickets')
            .select()
            .order('created_at', ascending: false);
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
            coins: profile['coins'] as int? ?? 0,
            statLeaves: profile['stat_leaves'] as int? ?? 0,
            statClovers: profile['stat_clovers'] as int? ?? 0,
            statPulls: profile['stat_pulls'] as int? ?? 0,
            adCoinsToday: profile['ad_coins_today'] as int? ?? 0,
            lastAdCoinDate: _dotDate(profile['last_ad_coin_date'] as String?),
            tickets: [
              for (final t in tickets)
                TicketInstance(
                  id: t['id'] as String,
                  ticketId: t['ticket_id'] as String,
                  level: t['level'] as int? ?? 1,
                  pulledAt: _dotDate(t['pulled_at'] as String?),
                ),
            ],
            customTickets: [
              for (final c in customs)
                CustomTicket(
                  id: c['id'] as String,
                  text: c['text'] as String? ?? '',
                  level: c['level'] as int? ?? 1,
                  createdAt: _dotDate(c['created_at'] as String?),
                ),
            ],
            history: [
              for (final h in history)
                HistoryEntry(
                  id: h['id'] as int,
                  date: _dotDate(h['happened_on'] as String?),
                  kind: historyKindOf(h['kind']),
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
  Future<GachaOutcome> pullGacha() => _guard(() async {
        final r = await _rpc('pull_gacha');
        return GachaOutcome(
          instanceId: r['instance_id'] as String,
          ticketId: r['ticket_id'] as String,
          isNew: r['is_new'] as bool,
          copies: r['copies'] as int,
          level: r['level'] as int,
        );
      });

  @override
  Future<AdCoinResult> grantAdCoin() => _guard(() async {
        final r = await _rpc('grant_ad_coin');
        return AdCoinResult(
          coins: r['coins'] as int,
          usedToday: r['ad_coins_today'] as int,
        );
      });

  @override
  Future<CustomTicketResult> createCustomTicket(String text) =>
      _guard(() async {
        final r = await _rpc('create_custom_ticket', {'p_text': text});
        return CustomTicketResult(
          ticket: CustomTicket(
            id: r['id'] as String,
            text: r['text'] as String? ?? '',
            level: r['level'] as int? ?? 1,
            createdAt: _dotDate(r['created_at'] as String?),
          ),
          clovers: r['clovers'] as int,
        );
      });

  @override
  Future<CustomEnhanceResult> enhanceCustomTicket(String id) =>
      _guard(() async {
        final r = await _rpc('enhance_custom_ticket', {'p_id': id});
        return CustomEnhanceResult(
          id: r['id'] as String,
          level: r['level'] as int,
          clovers: r['clovers'] as int,
        );
      });

  @override
  Future<EnhanceOutcome> enhanceTicket(
          String instanceId, List<String> materialIds) =>
      _guard(() async {
        final r = await _rpc('enhance_ticket', {
          'p_target': instanceId,
          'p_materials': materialIds,
        });
        return EnhanceOutcome(
          instanceId: r['instance_id'] as String,
          ticketId: r['ticket_id'] as String,
          success: r['success'] as bool,
          level: r['level'] as int,
          rate: r['rate'] as int,
        );
      });

  @override
  Future<ReforgeOutcome> reforgeTickets(List<String> materialIds) =>
      _guard(() async {
        final r = await _rpc('reforge_tickets', {'p_materials': materialIds});
        return ReforgeOutcome(
          instance: TicketInstance(
            id: r['instance_id'] as String,
            ticketId: r['ticket_id'] as String,
            pulledAt: '',
          ),
          isNew: r['is_new'] as bool,
          upgraded: r['upgraded'] as bool,
        );
      });

  @override
  Future<void> importLocalState(Map<String, dynamic> payload) => _guard(
      () async => _rpc('import_local_state', {'p_payload': payload}));

  @override
  Future<String> issueRecoveryCode() => _guard(() async {
        final r = await _rpc('issue_recovery_code');
        return r['code'] as String;
      });

  @override
  Future<void> redeemRecoveryCode(String code) => _guard(
      () async => _rpc('redeem_recovery_code', {'p_code': code}));

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
      // 함수 누락·권한·스키마 불일치가 전부 "연결 실패"로 보이면 원인 추적이 불가능하다.
      // 사용자 문구는 그대로 두고, 개발 빌드에서만 원본을 남긴다.
      if (kDebugMode) {
        debugPrint('[backend] PostgrestException '
            'code=${e.code} message=${e.message} details=${e.details}');
      }
      throw GameConnectionException(e);
    } on GameRuleException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[backend] ${e.runtimeType}: $e');
      throw GameConnectionException(e);
    }
  }
}
