import 'custom_ticket.dart';
import 'deed.dart';
import 'ticket_instance.dart';

enum AppTab { home, gacha, fortune, dex, archive }

enum ArchiveView { timeline, calendar }

/// 앱 전역 상태.
class AppState {
  final AppTab tab;
  final ArchiveView archiveView;
  final int leaves; // 현재 클로버에 채워진 잎 (0~4)
  final int clovers; // 보유한 완성 클로버 — 커스텀 행운권 제작·강화에만 쓴다
  final int coins; // 보유한 코인 — 뽑기에만 쓴다 (광고로만 얻는다)
  final bool celebrate; // 4잎 완성 축하 애니메이션 트리거
  final int bounceKey; // 잎 팝 애니메이션 재생용 키
  final int flightKey; // 완성 클로버가 배지로 날아가는 연출 재생용 키.
  // 서버 확정이 성공했을 때만 증가한다 — 이 값이 오르면 clovers 도 반드시 올랐다.

  final int statLeaves; // 총 채운 잎
  final int statClovers; // 탄생한 클로버
  final int statPulls; // 총 뽑기 횟수

  final List<TicketInstance> tickets; // 보유 카드 (한 장 = 한 인스턴스, 최신 획득순)
  final List<CustomTicket> customTickets; // 내가 만든 행운권 (최신순)
  final List<HistoryEntry> history;

  final int adCoinsToday; // 오늘 광고로 받은 코인 수
  final String lastAdCoinDate; // 광고 코인 카운트 기준일 'YYYY.MM.DD'

  const AppState({
    this.tab = AppTab.home,
    this.archiveView = ArchiveView.timeline,
    this.leaves = 0,
    this.clovers = 0,
    this.coins = 0,
    this.celebrate = false,
    this.bounceKey = 0,
    this.flightKey = 0,
    this.statLeaves = 0,
    this.statClovers = 0,
    this.statPulls = 0,
    this.tickets = const [],
    this.customTickets = const [],
    this.history = const [],
    this.adCoinsToday = 0,
    this.lastAdCoinDate = '',
  });

  /// 빈 초기 상태 — 실데이터는 서버에서 로드된다.
  factory AppState.initial() => const AppState();

  AppState copyWith({
    AppTab? tab,
    ArchiveView? archiveView,
    int? leaves,
    int? clovers,
    int? coins,
    bool? celebrate,
    int? bounceKey,
    int? flightKey,
    int? statLeaves,
    int? statClovers,
    int? statPulls,
    List<TicketInstance>? tickets,
    List<CustomTicket>? customTickets,
    List<HistoryEntry>? history,
    int? adCoinsToday,
    String? lastAdCoinDate,
  }) {
    return AppState(
      tab: tab ?? this.tab,
      archiveView: archiveView ?? this.archiveView,
      leaves: leaves ?? this.leaves,
      clovers: clovers ?? this.clovers,
      coins: coins ?? this.coins,
      celebrate: celebrate ?? this.celebrate,
      bounceKey: bounceKey ?? this.bounceKey,
      flightKey: flightKey ?? this.flightKey,
      statLeaves: statLeaves ?? this.statLeaves,
      statClovers: statClovers ?? this.statClovers,
      statPulls: statPulls ?? this.statPulls,
      tickets: tickets ?? this.tickets,
      customTickets: customTickets ?? this.customTickets,
      history: history ?? this.history,
      adCoinsToday: adCoinsToday ?? this.adCoinsToday,
      lastAdCoinDate: lastAdCoinDate ?? this.lastAdCoinDate,
    );
  }

  /// 영구 저장 대상(탭/애니메이션 등 UI 휘발 상태는 제외).
  Map<String, dynamic> toJson() => {
        'leaves': leaves,
        'clovers': clovers,
        'coins': coins,
        'statLeaves': statLeaves,
        'statClovers': statClovers,
        'statPulls': statPulls,
        'tickets': tickets.map((t) => t.toJson()).toList(),
        'customTickets': customTickets.map((t) => t.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
        'adCoinsToday': adCoinsToday,
        'lastAdCoinDate': lastAdCoinDate,
      };

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
        leaves: j['leaves'] as int? ?? 0,
        clovers: j['clovers'] as int? ?? 0,
        coins: j['coins'] as int? ?? 0,
        statLeaves: j['statLeaves'] as int? ?? 0,
        statClovers: j['statClovers'] as int? ?? 0,
        statPulls: j['statPulls'] as int? ?? 0,
        tickets: _ticketsFromJson(j['tickets'] as List<dynamic>?),
        customTickets: (j['customTickets'] as List<dynamic>?)
                ?.map((e) => CustomTicket.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        history: (j['history'] as List<dynamic>?)
                ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        // 구버전의 adClovers* 카운터는 옮기지 않는다. 그건 클로버 지급 한도였고
        // 코인 한도로 계승하면 오늘 받을 수 있는 코인이 부당하게 깎인다.
        adCoinsToday: j['adCoinsToday'] as int? ?? 0,
        lastAdCoinDate: j['lastAdCoinDate'] as String? ?? '',
      );

  /// 카드 목록 복원. 구버전 payload 는 {ticketId, copies, level} 합산 형태라
  /// (강화된 1장 + 남은 여분) 인스턴스로 펼친다 — 서버 import_local_state 와 동일 규칙.
  static List<TicketInstance> _ticketsFromJson(List<dynamic>? raw) {
    if (raw == null) return const [];
    final out = <TicketInstance>[];
    for (final e in raw) {
      final j = e as Map<String, dynamic>;
      final copies = j['copies'] as int?;
      if (copies == null) {
        out.add(TicketInstance.fromJson(j));
        continue;
      }
      final ticketId = j['ticketId'] as String;
      final date = j['firstPulledAt'] as String? ?? '';
      var level = j['level'] as int? ?? 1;
      while (level > 1 && level * (level - 1) ~/ 2 > copies - 1) {
        level--;
      }
      final spare = copies - 1 - (level * (level - 1) ~/ 2);
      out.add(TicketInstance(
          id: '${ticketId}_0', ticketId: ticketId, level: level, pulledAt: date));
      for (var i = 0; i < (spare < 0 ? 0 : spare); i++) {
        out.add(TicketInstance(
            id: '${ticketId}_${i + 1}', ticketId: ticketId, pulledAt: date));
      }
    }
    return out;
  }
}
