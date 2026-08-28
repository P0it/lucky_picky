import '../models/app_state.dart';
import '../models/custom_ticket.dart';
import '../models/deed.dart';
import '../models/ticket_instance.dart';

/// 서버가 거부한 게임 규칙 위반 — 재화 부족, 한도 초과 등.
/// 코드는 supabase/migrations/20260710000003_game_rpcs.sql 의 예외 메시지와 1:1.
class GameRuleException implements Exception {
  final String code;
  const GameRuleException(this.code);

  static const noClover = 'NO_CLOVERS';
  static const noCoins = 'NO_COINS';
  static const noAdCoins = 'NO_AD_COINS';
  static const noCloverReady = 'NO_CLOVER_READY';
  static const invalidDeed = 'INVALID_DEED';
  static const invalidText = 'INVALID_TEXT';
  static const ticketNotOwned = 'TICKET_NOT_OWNED';
  static const cannotEnhance = 'CANNOT_ENHANCE';
  static const cannotReforge = 'CANNOT_REFORGE';
  static const alreadyImported = 'ALREADY_IMPORTED';
  static const recoveryNotFound = 'RECOVERY_NOT_FOUND';
  static const recoveryRateLimited = 'RECOVERY_RATE_LIMITED';

  static const known = {
    noClover, noCoins, noAdCoins, noCloverReady, invalidDeed, invalidText,
    ticketNotOwned, cannotEnhance, cannotReforge, alreadyImported,
    recoveryNotFound, recoveryRateLimited, 'AUTH_REQUIRED',
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

/// 광고 보상으로 지급된 코인 — 뽑기는 이 코인을 쓴다.
class AdCoinResult {
  final int coins; // 반영 후 보유 코인
  final int usedToday; // 오늘 받은 광고 코인 수
  const AdCoinResult({required this.coins, required this.usedToday});
}

/// 커스텀 행운권 제작 결과.
class CustomTicketResult {
  final CustomTicket ticket;
  final int clovers; // 반영 후 보유 클로버
  const CustomTicketResult({required this.ticket, required this.clovers});
}

/// 커스텀 행운권 강화 결과 — 실패가 없으므로 성공 여부 필드가 없다.
class CustomEnhanceResult {
  final String id;
  final int level; // 반영 후 레벨
  final int clovers; // 반영 후 보유 클로버
  const CustomEnhanceResult({
    required this.id,
    required this.level,
    required this.clovers,
  });
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

  /// 뽑기 1회 — 언제나 코인 1개를 소모한다.
  Future<GachaOutcome> pullGacha();

  /// 광고 시청 보상 — 코인 1개 지급 (하루 한도).
  Future<AdCoinResult> grantAdCoin();

  /// 커스텀 행운권 제작 — 클로버를 소모해 [text] 문구의 카드를 만든다.
  Future<CustomTicketResult> createCustomTicket(String text);

  /// 커스텀 행운권 강화 — 클로버(현재 레벨 수)를 소모해 레벨을 1 올린다.
  /// 실패하지 않는다.
  Future<CustomEnhanceResult> enhanceCustomTicket(String id);

  /// 카드 [instanceId] 를 대상으로, 재료 카드 [materialIds] 를 소모해 강화한다.
  Future<EnhanceOutcome> enhanceTicket(
      String instanceId, List<String> materialIds);

  /// 카드 [materialIds] 를 갈아 새 카드 1장을 만든다.
  Future<ReforgeOutcome> reforgeTickets(List<String> materialIds);
  Future<void> importLocalState(Map<String, dynamic> payload);

  /// 타임라인 기록을 최신순으로 받아온다.
  ///
  /// [fetchState] 는 이걸 포함하지 않는다 — 기록은 '나의 기록' 탭에서만 쓰는데
  /// 콜드 스타트 스냅샷에서 가장 큰 덩어리(300건)라, 대부분의 세션이 쓰지도
  /// 않는 데이터를 매번 내려받게 된다.
  Future<List<HistoryEntry>> fetchHistory({int limit = 300});

  /// 이 계정의 복구 코드를 발급한다(계정당 1개, 재사용). 표시용 원문을 반환한다.
  /// [lang] 은 코드 단어를 만들 언어 — 읽고 입력할 수 있어야 코드가 쓸모 있다.
  /// 한 번 발급되면 언어를 바꿔도 코드는 그대로다(적어둔 코드가 바뀌면 안 된다).
  Future<String> issueRecoveryCode([String lang = 'en']);

  /// 복구 코드가 가리키는 계정의 자산을 현재 세션으로 이관한다.
  /// 코드를 찾을 수 없으면 [GameRuleException](RECOVERY_NOT_FOUND).
  Future<void> redeemRecoveryCode(String code);
}

/// 복구 코드 정규화 — 공백·구두점을 지우고 소문자로 내린다.
/// 서버 normalize_recovery_code 와 동일 규칙이라야 같은 코드로 인식된다.
///
/// 허용 목록(`[^0-9a-zA-Z가-힣]`)이 아니라 제거 목록인 이유: 허용 방식은 새 문자
/// 체계를 넣을 때마다 규칙을 고쳐야 하고, 빠뜨리면 그 언어 코드가 통째로 빈
/// 문자열이 된다(일본어가 그랬다).
String normalizeRecoveryCode(String code) => code
    .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
    .toLowerCase();
