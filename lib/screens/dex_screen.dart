import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/wish.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_mark.dart';
import '../widgets/pressable.dart';
import 'wish_talisman_screen.dart';

/// 소원 도감 — 완성되어 모인 소원을 2열 그리드로 보여준다.
class DexScreen extends ConsumerWidget {
  const DexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final done = ref.watch(appControllerProvider.select((s) => s.completedWishes));

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 4),
          child: Text(l.dexTitle,
              style: AppText.base(size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(l.dexSubtitle,
              style: AppText.base(size: 14, weight: FontWeight.w500, color: AppColors.muted)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
          child: done.isEmpty
              ? _emptyState(context)
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                  children: [for (final w in done) _DexCard(wish: w)],
                ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Opacity(opacity: 0.5, child: const CloverMark(size: 30, withStem: true)),
          const SizedBox(height: 12),
          Text(l.dexEmptyTitle,
              style: AppText.base(size: 15, weight: FontWeight.w600, color: AppColors.sub)),
          const SizedBox(height: 6),
          Text(l.dexEmptyDesc,
              style: AppText.base(size: 13, weight: FontWeight.w500, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _DexCard extends StatelessWidget {
  final Wish wish;
  const _DexCard({required this.wish});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 도감 카드 자체를 한 장의 미니 부적으로 — 부적 상세와 같은 시각 언어
    // (그라데이션 + 클로버 워터마크 + 내부 프레임)를 써서 겉에서도 부적으로 읽힌다.
    return Pressable(
      onTap: () => Navigator.of(context).push(wishTalismanRoute(wish)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            // 부적 바탕 — 은은한 세로 그라데이션.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF7FBF3), Color(0xFFE9F2DF)],
                  ),
                ),
              ),
            ),
            // 배경에 깔리는 큰 클로버 워터마크.
            Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: -12 * math.pi / 180,
                  child: CloverMark(
                    size: 150,
                    withStem: true,
                    color: AppColors.accent.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            // 부적 느낌의 얇은 내부 프레임.
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.20), width: 1.2),
                ),
              ),
            ),
            // 본문 — 부적 라벨 / 중앙 클로버 엠블럼 / 소원 한 줄 / 완성일.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: [
                    Text(
                      l.talismanLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.base(
                        size: 9.5,
                        weight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacingEm: 0.24,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CloverMark(size: 46, withStem: true),
                          const SizedBox(height: 14),
                          Text(
                            wish.text,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.base(
                              size: 14,
                              weight: FontWeight.w800,
                              height: 1.36,
                              letterSpacingEm: -0.03,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      wish.completedAt ?? '',
                      style: AppText.base(
                          size: 11, weight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
