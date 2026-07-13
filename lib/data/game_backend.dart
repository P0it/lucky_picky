import '../models/app_state.dart';
import '../models/ticket_instance.dart';

/// 서버가 거부한 게임 규칙 위반 — 재화 부족, 한도 초과 등.
/// 코드는 supabase/migrations/20260710000003_game_rpcs.sql 의 예외 메시지와 1:1.
class GameRuleException implements Exception {
  final String code;
  const GameRuleException(this.code);

  static const noClover = 'NO_CLOVERS';
  static const noAdClovers = 'NO_AD_CLOVERS';
  static const noCloverReady = 'NO_CLOVER_READY';
  static const invalidDeed = 'INVALID_DEED';
  static const ticketNotOwned = 'TICKET_NOT_OWNED';
  static const cannotEnhance = 'CANNOT_ENHANCE';
  static const cannotReforge = 'CANNOT_REFORGE';
  static const alreadyImported = 'ALREADY_IMPORTED';

  static const known = {
    noClover, noAdClovers, noCloverReady, invalidDeed,
    ticketNotOwned, cannotEnhance, cannotReforge, alreadyImported,
    'AUTH_REQUIRED',
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
  final String instanceId; // 이번에 생긴 카드 한 장
  final String ticketId;
  final bool isNew;
  final int copies; // 반영 후 같은 행운권 보유 장수
  final int level;
  const GachaOutcome({
    required this.instanceId,
    required this.ticketId,
    required this.isNew,
    required this.copies,
    required this.level,
  });
}

/// 광고 보상으로 지급된 클로버 — 뽑기는 이 클로버를 쓴다.
class AdCloverResult {
  final int clovers; // 반영 후 보유 클로버
  final int usedToday; // 오늘 받은 광고 클로버 수
  const AdCloverResult({required this.clovers, required this.usedToday});
}

/// 강화 결과 — 판정은 서버가 한다. 실패해도 재료는 소모된다.
class EnhanceOutcome {
  final String instanceId; // 강화 대상
  final String ticketId;
  final bool success;
  final int level; // 반영 후 레벨 (실패 시 그대로)
  final int rate; // 적용된 성공 확률(%)
  const EnhanceOutcome({
    required this.instanceId,
    required this.ticketId,
    required this.success,
    required this.level,
    required this.rate,
  });
}

/// 재조합 결과 — 카드 여러 장을 갈아 만든 새 카드.
class ReforgeOutcome {
  final TicketInstance instance; // 새로 만들어진 카드
  final bool isNew; // 지갑에 처음 들어온 행운권인지
  final bool upgraded; // 등급이 한 단계 올라갔는지
  const ReforgeOutcome({
    required this.instance,
    required this.isNew,
    required this.upgraded,
  });
}

/// 게임 상태의 단일 진실 공급원 — 실서비스는 Supabase RPC(서버 권위),
/// 테스트는 동일 규칙의 로컬 구현([LocalGameBackend])을 쓴다.
abstract class GameBackend {
  Future<void> ensureSignedIn();
  Future<BackendSnapshot> fetchState();
  Future<DeedResult> recordDeed(String text);
  Future<CloverResult> finishClover();

  /// 뽑기 1회 — 언제나 클로버 1개를 소모한다.
  Future<GachaOutcome> pullGacha();

  /// 광고 시청 보상 — 클로버 1개 지급 (하루 한도).
  Future<AdCloverResult> grantAdClover();
  /// 카드 [instanceId] 를 대상으로, 재료 카드 [materialIds] 를 소모해 강화한다.
  Future<EnhanceOutcome> enhanceTicket(
      String instanceId, List<String> materialIds);

  /// 카드 [materialIds] 를 갈아 새 카드 1장을 만든다.
  Future<ReforgeOutcome> reforgeTickets(List<String> materialIds);
  Future<void> importLocalState(Map<String, dynamic> payload);
}
