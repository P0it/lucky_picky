import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'clover_mark.dart';
import 'logo_wordmark.dart';

/// 초기화 구간(네이티브 스플래시 이후 ~ 첫 화면)을 덮는 로딩 화면.
///
/// 네이티브 스플래시와 배경색·마크를 맞춰 두 화면이 이어져 보이게 한다.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 바람에 흔들리듯 좌우로 기울며 살짝 떠오르는 모션.
            AnimatedBuilder(
              animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
              builder: (_, child) {
                final t = Curves.easeInOut.transform(_c.value);
                return Transform.translate(
                  offset: Offset(0, lerpDouble(4, -4, t)!),
                  child: Transform.rotate(
                    angle: lerpDouble(-0.075, 0.075, t)!,
                    // 줄기 끝을 축으로 삼아야 잎이 흔들리는 것처럼 보인다.
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: lerpDouble(0.97, 1.03, t)!,
                      child: child,
                    ),
                  ),
                );
              },
              // 네이티브 스플래시 PNG 와 같은 비율 — 두 화면이 넘어갈 때 크기가 튀지 않게.
              // (PNG: 캔버스 대비 클로버 0.52 / 간격 0.18 / 글자 0.145)
              child: const CloverMark(size: 140, withStem: true),
            ),
            // 간격 = 클로버 140 × (0.18/0.52) ≈ 48. PNG 의 클로버-글자 간격과 맞춘다.
            const SizedBox(height: 48),
            const LogoWordmark(size: 39),
          ],
        ),
      ),
    );
  }
}

/// 초기화가 실패했을 때(네트워크 없음 등) 다시 시도할 수 있는 화면.
class AppLoadingErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const AppLoadingErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CloverMark(size: 72, withStem: true, color: AppColors.emptyLeaf),
            const SizedBox(height: 20),
            Text(
              l10n.loadingErrorTitle,
              style: AppText.base(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.loadingErrorBody,
              style: AppText.base(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  l10n.loadingRetry,
                  style: AppText.base(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
