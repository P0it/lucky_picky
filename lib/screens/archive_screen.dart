import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/deed.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_mark.dart';
import '../widgets/deed_heatmap.dart';
import '../widgets/language_sheet.dart';
import '../widgets/pressable.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(appControllerProvider);
    final notifier = ref.read(appControllerProvider.notifier);
    final isCalendar = s.archiveView == ArchiveView.calendar;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(l.archiveTitle,
                    style: AppText.base(
                        size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
              ),
              // 언어 설정 진입점 — 탭/플로팅 없이 헤더 우상단에.
              Pressable(
                onTap: () => showLanguageSheet(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.language_rounded, size: 24, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
        // ---- 통계 대시보드 ----
        Container(
          margin: const EdgeInsets.fromLTRB(24, 18, 24, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stat('${s.statLeaves}', l.archiveStatLeaves, AppColors.title),
                _divider(),
                _stat('${s.statClovers}', l.archiveStatClovers, AppColors.accent),
                _divider(),
                _stat('${s.statPulls}', l.archiveStatPulls, AppColors.title),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
          child: Column(
            children: [
              // 세그먼트 탭
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    _segTab(l.archiveTimeline, !isCalendar,
                        () => notifier.setArchiveView(ArchiveView.timeline), AppColors.title),
                    _segTab(l.archiveCalendar, isCalendar,
                        () => notifier.setArchiveView(ArchiveView.calendar), AppColors.title),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isCalendar)
                DeedHeatmap(history: s.history)
              else if (s.history.isEmpty)
                _emptyState(context)
              else
                _Timeline(entries: s.history),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppText.base(
                  size: 25, weight: FontWeight.w800, color: valueColor, letterSpacingEm: -0.03)),
          const SizedBox(height: 7),
          Text(label,
              style: AppText.base(size: 12, weight: FontWeight.w600, color: AppColors.sub)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, color: const Color(0x14191F28), margin: const EdgeInsets.symmetric(vertical: 2));

  Widget _segTab(String label, bool active, VoidCallback onTap, Color activeColor) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x14191F28), blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(label,
              style: AppText.base(
                  size: 14,
                  weight: FontWeight.w700,
                  color: active ? activeColor : AppColors.muted)),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46),
      child: Column(
        children: [
          Opacity(opacity: 0.5, child: const CloverMark(size: 30, withStem: true)),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context).archiveEmpty,
              style: AppText.base(size: 14, weight: FontWeight.w500, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _Timeline({required this.entries});

  // 좌측 레일(점+세로선) 치수 — 점과 선이 같은 중심을 공유한다.
  static const double _rail = 28;
  static const double _dot = 12;
  static const double _dotTop = 3;
  static const double _dotCenter = _dotTop + _dot / 2; // 점의 세로 중심

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++)
          _row(l, entries[i], i == 0, i == entries.length - 1),
      ],
    );
  }

  /// 구버전 데이터는 저장된 원문을, 신규 데이터는 언어별로 포맷한 본문을 만든다.
  /// 뽑기 기록은 행운권 ID 만 저장하므로 표시 시점에 현재 언어로 풀어낸다.
  String _displayText(AppLocalizations l, HistoryEntry h) {
    if (h.legacyDelta != null) return h.text;
    if (h.kind == HistoryKind.pull) {
      final text = LuckCatalog.byId(h.text)?.text(l.localeName) ?? h.text;
      return l.historyPullDone(text);
    }
    return h.text;
  }

  String _displayDelta(AppLocalizations l, HistoryEntry h) {
    if (h.legacyDelta != null) return h.legacyDelta!;
    if (h.kind == HistoryKind.deed) return l.historyLeafDelta(h.amount);
    // 무료(광고) 뽑기는 클로버 소모 0.
    return h.amount > 0 ? l.historyCloverDelta(h.amount) : l.historyFreePull;
  }

  Widget _row(AppLocalizations l, HistoryEntry h, bool isFirst, bool isLast) {
    final color = h.positive ? AppColors.accent : AppColors.muted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- 레일: 세로 연결선 + 점 ----
          SizedBox(
            width: _rail,
            child: Stack(
              children: [
                // 연결선 — 첫 행은 점부터 아래로, 마지막 행은 위에서 점까지.
                if (!(isFirst && isLast))
                  Positioned(
                    left: _rail / 2 - 1,
                    top: isFirst ? _dotCenter : 0,
                    bottom: isLast ? null : 0,
                    height: isLast ? _dotCenter : null,
                    child: Container(width: 2, color: AppColors.border),
                  ),
                // 점 (선 위에 올라타도록 마지막에 그린다)
                Positioned(
                  left: _rail / 2 - _dot / 2,
                  top: _dotTop,
                  child: Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ---- 본문 ----
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.date,
                      style: AppText.base(
                          size: 12, weight: FontWeight.w600, color: AppColors.muted, letterSpacingEm: -0.01)),
                  const SizedBox(height: 5),
                  Text(_displayText(l, h),
                      style: AppText.base(size: 15, weight: FontWeight.w500, height: 1.45)),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: h.positive ? AppColors.accentSoft : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.chipFull),
                    ),
                    child: Text(_displayDelta(l, h),
                        style: AppText.base(
                            size: 12,
                            weight: FontWeight.w700,
                            color: h.positive ? AppColors.accent : AppColors.muted,
                            letterSpacingEm: -0.01)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
