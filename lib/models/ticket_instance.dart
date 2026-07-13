import '../config/luck_tickets.dart';

/// 행운권 카드 한 장. 뽑을 때마다 한 장씩 생기며, 같은 행운권이라도 각각 별개다.
/// 강화는 이 카드 한 장을 대상으로 하고, 같은 행운권의 다른 카드를 재료로 소모한다.
///
/// [level] 1 = 무강화, L = +(L-1) 강화. (서버 ticket_instances.level 과 동일)
class TicketInstance {
  final String id; // 서버 uuid (로컬 백엔드는 자체 발급)
  final String ticketId; // 카탈로그 id
  final int level;
  final String pulledAt; // 'YYYY.MM.DD'

  const TicketInstance({
    required this.id,
    required this.ticketId,
    this.level = 1,
    required this.pulledAt,
  });

  /// 강화 단계 — 0 이면 무강화, 그 외에는 '+N'.
  int get plus => level - 1;

  bool get isMaxLevel => level >= LuckCatalog.maxLevel;

  /// L → L+1 에 필요한 재료(같은 행운권 카드) 장수 = L.
  static int materialsFor(int level) => level;

  int get materialsNeeded => materialsFor(level);

  /// 도달 레벨별 기본 성공 확률(%). 서버 game_config.enhance_rates 와 동치 —
  /// 값을 바꿀 때는 SQL 과 이 표를 함께 바꾼다. (판정은 서버가 한다)
  static const Map<int, int> successRates = {2: 100, 3: 80, 4: 60, 5: 40};

  /// 재료 보정 — 같은 행운권이면 +15%p, 등급 한 단계당 ±10%p.
  /// (서버 game_config.material_mods 와 동치)
  static const int sameTicketBonus = 15;
  static const int perRarityStep = 10;

  /// 재조합에 필요한 카드 수와 등급 승급 확률(%).
  static const int reforgeMaterials = 3;
  static const int reforgeUpgradeRate = 25;

  /// 다음 강화의 기본 성공 확률(%) — 재료 보정 전.
  int get baseSuccessRate => successRates[level + 1] ?? 100;

  /// 재료 [materials] 를 넣었을 때의 최종 성공 확률(%).
  /// 서버 enhance_ticket 과 같은 식: clamp(기본 + 보정 합, 5, 100).
  int successRateWith(Iterable<TicketInstance> materials) {
    final targetRank = _rank(ticketId);
    var mod = 0;
    for (final m in materials) {
      mod += (_rank(m.ticketId) - targetRank) * perRarityStep;
      if (m.ticketId == ticketId) mod += sameTicketBonus;
    }
    return (baseSuccessRate + mod).clamp(5, 100);
  }

  static int _rank(String ticketId) =>
      LuckCatalog.byId(ticketId)?.rarity.index ?? 0;

  TicketInstance copyWith({int? level}) => TicketInstance(
        id: id,
        ticketId: ticketId,
        level: level ?? this.level,
        pulledAt: pulledAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketId': ticketId,
        'level': level,
        'pulledAt': pulledAt,
      };

  factory TicketInstance.fromJson(Map<String, dynamic> j) => TicketInstance(
        id: j['id'] as String? ?? '',
        ticketId: j['ticketId'] as String,
        level: j['level'] as int? ?? 1,
        pulledAt: j['pulledAt'] as String? ?? j['firstPulledAt'] as String? ?? '',
      );
}
