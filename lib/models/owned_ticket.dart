import '../config/luck_tickets.dart';

/// 도감에 등록된 행운권 — 카탈로그의 [LuckTicket.id] 를 참조한다.
/// 같은 행운권을 중복으로 뽑으면 [copies] 가 늘고, 중복분은 강화 재료가 된다.
class OwnedTicket {
  final String ticketId;
  final int copies; // 지금까지 뽑은 총 장수 (첫 획득 포함)
  final int level; // 강화 레벨 1~[LuckCatalog.maxLevel]
  final String firstPulledAt; // 첫 획득일 'YYYY.MM.DD'

  const OwnedTicket({
    required this.ticketId,
    this.copies = 1,
    this.level = 1,
    required this.firstPulledAt,
  });

  /// Lv.L → Lv.L+1 에 필요한 중복 수 = L. (1/2/3/4)
  static int costForNextLevel(int level) => level;

  /// 현재 레벨까지 강화에 소모한 중복 수. (Lv.1=0, Lv.2=1, Lv.3=3, Lv.4=6, Lv.5=10)
  static int consumedForLevel(int level) => level * (level - 1) ~/ 2;

  /// 아직 소모하지 않은 강화 재료(여분 중복) 수.
  int get spareCopies => copies - 1 - consumedForLevel(level);

  bool get isMaxLevel => level >= LuckCatalog.maxLevel;

  /// 지금 강화할 수 있는지 — 재료가 다음 레벨 요구량 이상이면 가능.
  bool get canEnhance => !isMaxLevel && spareCopies >= costForNextLevel(level);

  OwnedTicket copyWith({int? copies, int? level, String? firstPulledAt}) =>
      OwnedTicket(
        ticketId: ticketId,
        copies: copies ?? this.copies,
        level: level ?? this.level,
        firstPulledAt: firstPulledAt ?? this.firstPulledAt,
      );

  Map<String, dynamic> toJson() => {
        'ticketId': ticketId,
        'copies': copies,
        'level': level,
        'firstPulledAt': firstPulledAt,
      };

  factory OwnedTicket.fromJson(Map<String, dynamic> j) => OwnedTicket(
        ticketId: j['ticketId'] as String,
        copies: j['copies'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        firstPulledAt: j['firstPulledAt'] as String? ?? '',
      );
}
