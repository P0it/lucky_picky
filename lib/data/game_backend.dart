import '../models/app_state.dart';

/// 서버가 거부한 게임 규칙 위반 — 재화 부족, 한도 초과 등.
/// 코드는 supabase/migrations/20260710000003_game_rpcs.sql 의 예외 메시지와 1:1.
class GameRuleException implements Exception {
  final String code;
  const GameRuleException(this.code);

  static const noClover = 'NO_CLOVERS';
  static const noFreePulls = 'NO_FREE_PULLS';
  static const noCloverReady = 'NO_CLOVER_READY';
  static const invalidDeed = 'INVALID_DEED';
  static const ticketNotOwned = 'TICKET_NOT_OWNED';
  static const cannotEnhance = 'CANNOT_ENHANCE';
  static const alreadyImported = 'ALREADY_IMPORTED';

  static const known = {
    noClover, noFreePulls, noCloverReady, invalidDeed,
    ticketNotOwned, cannotEnhance, alreadyImported, 'AUTH_REQUIRED',
  };

  @override
  String toString() => 'GameRuleException($code)';
}

/// 서버에 닿지 못한 실패 — 오프라인, 타임아웃 등. UI 는 연결 안내 토스트를 띄운다.
class GameConnectionException implements Exception {
  final Object? cause;
  const GameConnectionException([this.cause]);

  @override
  String toString() => 'GameConnectionException($cause)';
}

/// 서버에서 읽어온 전체 상태 스냅샷.
class BackendSnapshot {
  final AppState data; // 데이터 필드만 유효 (탭 등 UI 휘발 필드는 기본값)
  final bool importedLocal; // 로컬 데이터 1회 이관을 이미 마쳤는지
  const BackendSnapshot({required this.data, required this.importedLocal});
}

class DeedResult {
  final int leaves;
  final bool cloverCompleted;
  const DeedResult({required this.leaves, required this.cloverCompleted});
}

class CloverResult {
  final int leaves;
  final int clovers;
  const CloverResult({required this.leaves, required this.clovers});
}

class GachaOutcome {
  final String ticketId;
  final bool isNew;
  final int copies; // 반영 후 보유 장수
  final int level;
  final bool free;
  const GachaOutcome({
    required this.ticketId,
    required this.isNew,
    required this.copies,
    required this.level,
    required this.free,
  });
}

class EnhanceOutcome {
  final String ticketId;
  final int copies;
  final int level; // 반영 후 레벨
  const EnhanceOutcome(
      {required this.ticketId, required this.copies, required this.level});
}

/// 게임 상태의 단일 진실 공급원 — 실서비스는 Supabase RPC(서버 권위),
/// 테스트는 동일 규칙의 로컬 구현([LocalGameBackend])을 쓴다.
abstract class GameBackend {
  Future<void> ensureSignedIn();
  Future<BackendSnapshot> fetchState();
  Future<DeedResult> recordDeed(String text);
  Future<CloverResult> finishClover();
  Future<GachaOutcome> pullGacha({required bool free});
  Future<EnhanceOutcome> enhanceTicket(String ticketId);
  Future<void> importLocalState(Map<String, dynamic> payload);
}
