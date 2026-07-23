/// 사용자가 문구를 직접 써서 만든 행운권.
///
/// 뽑기로 얻는 [TicketInstance] 와 **별개 타입**이다. 등급이 없고, 재조합·강화의
/// 재료가 되지 않는다 — 타입이 다르므로 실수로 재료 목록에 섞일 수 없다.
/// 강화는 클로버를 소모하며 실패하지 않는다 (서버 enhance_custom_ticket).
class CustomTicket {
  final String id;
  final String text; // 사용자가 쓴 원문. 번역하지 않는다.
  final int level; // 1 = 무강화, L = +(L-1) 강화
  final String createdAt; // 'YYYY.MM.DD'

  const CustomTicket({
    required this.id,
    required this.text,
    this.level = 1,
    this.createdAt = '',
  });

  /// 문구 입력 상한. 카탈로그 문구가 한국어 기준 최대 29자이고 카드가 2줄까지
  /// 보여주므로 40자면 넉넉하다. (서버 custom_tickets.text 제약과 동치)
  static const int maxTextLength = 40;

  /// 최대 레벨 — 뽑기 카드와 동일 (서버 game_config.max_level).
  static const int maxLevel = 5;

  /// 제작 비용(클로버) — 서버 game_config.custom_ticket_cost 와 동치.
  static const int createCost = 1;

  bool get isMaxLevel => level >= maxLevel;

  /// 표시용 강화 수치 — Lv.1 은 0.
  int get plus => level - 1;

  /// 다음 레벨에 필요한 클로버 수 = 현재 레벨.
  int get enhanceCost => level;

  CustomTicket copyWith({String? text, int? level}) => CustomTicket(
        id: id,
        text: text ?? this.text,
        level: level ?? this.level,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'level': level,
        'createdAt': createdAt,
      };

  factory CustomTicket.fromJson(Map<String, dynamic> j) => CustomTicket(
        id: j['id'] as String,
        text: j['text'] as String? ?? '',
        level: j['level'] as int? ?? 1,
        createdAt: j['createdAt'] as String? ?? '',
      );
}
