import 'deed.dart';
import 'owned_ticket.dart';

enum AppTab { home, gacha, dex, archive }

enum ArchiveView { timeline, calendar }

/// 앱 전역 상태.
class AppState {
  final AppTab tab;
  final ArchiveView archiveView;
  final int leaves; // 현재 클로버에 채워진 잎 (0~4)
  final int clovers; // 보유한 완성 클로버 (= 뽑기 코인)
  final bool celebrate; // 4잎 완성 축하 애니메이션 트리거
  final int bounceKey; // 잎 팝 애니메이션 재생용 키

  final int statLeaves; // 총 채운 잎
  final int statClovers; // 탄생한 클로버
  final int statPulls; // 총 뽑기 횟수

  final List<OwnedTicket> tickets; // 도감에 등록된 행운권 (최신 획득순)
  final List<HistoryEntry> history;

  final int freePullsUsedToday; // 오늘 사용한 무료(광고) 뽑기 수
  final String lastFreePullDate; // 무료 뽑기 카운트 기준일 'YYYY.MM.DD'

  const AppState({
    this.tab = AppTab.home,
    this.archiveView = ArchiveView.timeline,
    this.leaves = 0,
    this.clovers = 0,
    this.celebrate = false,
    this.bounceKey = 0,
    this.statLeaves = 0,
    this.statClovers = 0,
    this.statPulls = 0,
    this.tickets = const [],
    this.history = const [],
    this.freePullsUsedToday = 0,
    this.lastFreePullDate = '',
  });

  /// 빈 초기 상태 — 실데이터는 서버에서 로드된다.
  factory AppState.initial() => const AppState();

  AppState copyWith({
    AppTab? tab,
    ArchiveView? archiveView,
    int? leaves,
    int? clovers,
    bool? celebrate,
    int? bounceKey,
    int? statLeaves,
    int? statClovers,
    int? statPulls,
    List<OwnedTicket>? tickets,
    List<HistoryEntry>? history,
    int? freePullsUsedToday,
    String? lastFreePullDate,
  }) {
    return AppState(
      tab: tab ?? this.tab,
      archiveView: archiveView ?? this.archiveView,
      leaves: leaves ?? this.leaves,
      clovers: clovers ?? this.clovers,
      celebrate: celebrate ?? this.celebrate,
      bounceKey: bounceKey ?? this.bounceKey,
      statLeaves: statLeaves ?? this.statLeaves,
      statClovers: statClovers ?? this.statClovers,
      statPulls: statPulls ?? this.statPulls,
      tickets: tickets ?? this.tickets,
      history: history ?? this.history,
      freePullsUsedToday: freePullsUsedToday ?? this.freePullsUsedToday,
      lastFreePullDate: lastFreePullDate ?? this.lastFreePullDate,
    );
  }

  /// 영구 저장 대상(탭/애니메이션 등 UI 휘발 상태는 제외).
  Map<String, dynamic> toJson() => {
        'leaves': leaves,
        'clovers': clovers,
        'statLeaves': statLeaves,
        'statClovers': statClovers,
        'statPulls': statPulls,
        'tickets': tickets.map((t) => t.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
        'freePullsUsedToday': freePullsUsedToday,
        'lastFreePullDate': lastFreePullDate,
      };

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
        leaves: j['leaves'] as int? ?? 0,
        clovers: j['clovers'] as int? ?? 0,
        statLeaves: j['statLeaves'] as int? ?? 0,
        statClovers: j['statClovers'] as int? ?? 0,
        statPulls: j['statPulls'] as int? ?? 0,
        tickets: (j['tickets'] as List<dynamic>?)
                ?.map((e) => OwnedTicket.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        history: (j['history'] as List<dynamic>?)
                ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        freePullsUsedToday: j['freePullsUsedToday'] as int? ?? 0,
        lastFreePullDate: j['lastFreePullDate'] as String? ?? '',
      );
}
