import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/deed.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// 선행 업적 히트맵 달력 — 그 달의 선행을 날짜별 농도로 보여준다.
/// 색이 칠해진(선행이 있는) 날을 누르면 그날의 기록을 시트로 펼친다.
class DeedHeatmap extends StatefulWidget {
  final List<HistoryEntry> history;
  const DeedHeatmap({super.key, required this.history});

  @override
  State<DeedHeatmap> createState() => _DeedHeatmapState();
}

class _DeedHeatmapState extends State<DeedHeatmap> {
  /// 로케일별 요일 머리글(좁은 형태). 2024-01-07 이 일요일이라 거기서 7일치를 뽑는다.
  static List<String> _weekdayLabels(String locale) {
    final fmt = DateFormat('EEEEE', locale);
    return [for (var i = 0; i < 7; i++) fmt.format(DateTime(2024, 1, 7 + i))];
  }

  /// 문장 속 숫자만 강조색으로 그린다 — 번역문마다 숫자 위치가 달라서,
  /// 문장을 조각내는 대신 완성된 문장에서 숫자를 찾아 스팬을 나눈다.
  static List<TextSpan> _accentNumber(String text, int value) {
    final needle = '$value';
    final at = text.indexOf(needle);
    if (at < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, at)),
      TextSpan(
          text: needle,
          style: AppText.base(
              size: 13, weight: FontWeight.w800, color: AppColors.accent)),
      TextSpan(text: text.substring(at + needle.length)),
    ];
  }

  // 히트맵 4단계 — 옅은 연두 → 포인트 그린.
  static const _l1 = Color(0xFFDDEFCF);
  static const _l2 = Color(0xFFB6E29A);
  static const _l3 = Color(0xFF8BCD60);
  static final _l4 = AppColors.accent;

  late DateTime _month; // 보이는 달(1일 기준).

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _step(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  /// 해당 달의 '선행(positive)' 기록을 날짜별로 모은다.
  Map<int, List<HistoryEntry>> _byDay() {
    final map = <int, List<HistoryEntry>>{};
    for (final h in widget.history) {
      if (!h.positive) continue;
      final p = h.date.split('.');
      if (p.length != 3) continue;
      final y = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      final d = int.tryParse(p[2]);
      if (y == null || m == null || d == null) continue;
      if (y != _month.year || m != _month.month) continue;
      (map[d] ??= []).add(h);
    }
    return map;
  }

  Color _fill(int count) {
    if (count <= 0) return AppColors.card;
    if (count == 1) return _l1;
    if (count == 2) return _l2;
    if (count == 3) return _l3;
    return _l4;
  }

  Color _numColor(int count) {
    if (count <= 0) return AppColors.disabled;
    if (count >= 3) return Colors.white;
    return const Color(0xFF3F6B1F); // 옅은 칸 위의 진한 초록 숫자.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final byDay = _byDay();
    final total = byDay.values.fold<int>(0, (a, b) => a + b.length);
    final now = DateTime.now();
    final isThisMonth = now.year == _month.year && now.month == _month.month;

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadBlanks = DateTime(_month.year, _month.month, 1).weekday % 7; // 일=0

    final cells = <Widget>[
      for (var i = 0; i < leadBlanks; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: d,
          fill: _fill(byDay[d]?.length ?? 0),
          numColor: _numColor(byDay[d]?.length ?? 0),
          isToday: isThisMonth && now.day == d,
          onTap: (byDay[d]?.isNotEmpty ?? false)
              ? () => _showDay(d, byDay[d]!)
              : null,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- 월 네비게이션 ----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _navBtn(Icons.chevron_left_rounded, () => _step(-1)),
            const SizedBox(width: 18),
            Text(DateFormat.yMMMM(locale).format(_month),
                style: AppText.base(
                    size: 18, weight: FontWeight.w800, letterSpacingEm: -0.03)),
            const SizedBox(width: 18),
            _navBtn(Icons.chevron_right_rounded, () => _step(1)),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: RichText(
            text: TextSpan(
              style: AppText.base(
                  size: 13, weight: FontWeight.w600, color: AppColors.muted),
              children: _accentNumber(l.heatmapMonthTotal(total), total),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // ---- 요일 헤더 ----
        Row(
          children: [
            for (final w in _weekdayLabels(locale))
              Expanded(
                child: Center(
                  child: Text(w,
                      style: AppText.base(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.muted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // ---- 날짜 그리드 ----
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          children: cells,
        ),
        const SizedBox(height: 16),
        // ---- 범례 ----
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(l.heatmapLegendLow,
                style: AppText.base(
                    size: 11, weight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(width: 7),
            for (final c in [_l1, _l2, _l3, _l4]) ...[
              _swatch(c),
              const SizedBox(width: 4),
            ],
            const SizedBox(width: 3),
            Text(l.heatmapLegendHigh,
                style: AppText.base(
                    size: 11, weight: FontWeight.w600, color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(l.heatmapTapHint,
              style: AppText.base(
                  size: 12, weight: FontWeight.w500, color: AppColors.muted)),
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: AppColors.sub),
        ),
      );

  Widget _swatch(Color c) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(4),
        ),
      );

  void _showDay(int day, List<HistoryEntry> entries) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.backdrop,
      builder: (_) => _DaySheet(month: _month, day: day, entries: entries),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final Color fill;
  final Color numColor;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.fill,
    required this.numColor,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: AppColors.accent, width: 1.6)
              : null,
        ),
        child: Text('$day',
            style: AppText.base(
                size: 14, weight: FontWeight.w700, color: numColor)),
      ),
    );
  }
}

/// 선택한 날짜의 선행 목록을 펼치는 하프 시트.
class _DaySheet extends StatelessWidget {
  final DateTime month;
  final int day;
  final List<HistoryEntry> entries;
  const _DaySheet({required this.month, required this.day, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: [BoxShadow(color: Color(0x24191F28), blurRadius: 30, offset: Offset(0, -8))],
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 18),
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
              ),
            ),
          ),
          Text(l.heatmapDayTitle(DateTime(month.year, month.month, day)),
              style: AppText.base(size: 22, weight: FontWeight.w700, letterSpacingEm: -0.03)),
          const SizedBox(height: 6),
          Text(l.heatmapDayCount(entries.length),
              style: AppText.base(size: 14, weight: FontWeight.w500, color: AppColors.muted)),
          const SizedBox(height: 18),
          for (final h in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(h.text,
                        style: AppText.base(size: 15, weight: FontWeight.w500, height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
