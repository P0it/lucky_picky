import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../models/deed.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_mark.dart';
import '../widgets/pressable.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appControllerProvider);
    final notifier = ref.read(appControllerProvider.notifier);
    final isEarn = s.archiveFilter == ArchiveFilter.earn;
    final filtered = s.history.where((h) => isEarn ? h.positive : !h.positive).toList();

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
          child: Text('나의 선행 기록',
              style: AppText.base(size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
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
                _stat('${s.statLeaves}', '총 채운 잎', AppColors.title),
                _divider(),
                _stat('${s.statClovers}', '탄생한 클로버', AppColors.accent),
                _divider(),
                _stat('${s.statWishes}', '이룬 소원', AppColors.title),
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
                    _segTab('모은 기록', isEarn,
                        () => notifier.setArchiveFilter(ArchiveFilter.earn), AppColors.accent),
                    _segTab('사용 기록', !isEarn,
                        () => notifier.setArchiveFilter(ArchiveFilter.spend), AppColors.title),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                _emptyState(isEarn)
              else
                _Timeline(entries: filtered),
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

  Widget _emptyState(bool isEarn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46),
      child: Column(
        children: [
          Opacity(opacity: 0.5, child: const CloverMark(size: 30, withStem: true)),
          const SizedBox(height: 10),
          Text(isEarn ? '아직 모은 기록이 없어요.' : '아직 사용한 기록이 없어요.',
              style: AppText.base(size: 14, weight: FontWeight.w500, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _Timeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Stack(
        children: [
          // 세로 라인
          Positioned(
            left: 5,
            top: 8,
            bottom: 10,
            child: Container(width: 2, color: AppColors.border),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final h in entries) _row(h),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(HistoryEntry h) {
    final color = h.positive ? AppColors.accent : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 타임라인 점
          Positioned(
            left: -24,
            top: 3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h.date,
                  style: AppText.base(
                      size: 12, weight: FontWeight.w600, color: AppColors.muted, letterSpacingEm: -0.01)),
              const SizedBox(height: 5),
              Text(h.text,
                  style: AppText.base(size: 15, weight: FontWeight.w500, height: 1.45)),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: h.positive ? AppColors.accentSoft : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
                child: Text(h.delta,
                    style: AppText.base(
                        size: 12,
                        weight: FontWeight.w700,
                        color: h.positive ? AppColors.accent : AppColors.muted,
                        letterSpacingEm: -0.01)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
