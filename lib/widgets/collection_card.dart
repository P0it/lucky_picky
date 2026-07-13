import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rarity_style.dart';

/// 플랫 컬렉션 카드 — 절취선/스텁 없는 둥근 사각형에 등급색을 "전체"에 칠한다.
/// 테두리는 두지 않는다. 면은 그림자로 띄워 분리하고, 등급은 그라데이션이 말한다.
/// 등급이 오를수록 화려해진다:
///   · 전 등급: 대각선 등급색 그라데이션 + 등급색 글로우 그림자
///   · 오라 등급(유니크+): 홀로그램 그라데이션 링 + 대각선 유리 광택(시머)
class CollectionCard extends StatelessWidget {
  final RarityStyle style;
  final Widget child;
  final double borderRadius;

  const CollectionCard({
    super.key,
    required this.style,
    required this.child,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final aura = style.aura;

    final face = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.panel,
        ),
        borderRadius:
            BorderRadius.circular(borderRadius - (aura != null ? 1.6 : 0)),
      ),
      child: Stack(
        children: [
          // 대각선 유리 광택 — 오라 등급 전용.
          if (aura != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius - 1.6),
                  child: const CustomPaint(painter: _SheenPainter()),
                ),
              ),
            ),
          child,
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // 오라 등급은 홀로그램 테두리(그라데이션 링).
        gradient: aura,
        // 테두리 대신 그림자 두 겹 — 중립 잉크로 면을 띄우고, 등급색을 옅게 흘려
        // 테두리가 하던 등급 신호를 대신한다.
        boxShadow: [
          const BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: style.color.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: aura != null ? const EdgeInsets.all(1.6) : EdgeInsets.zero,
      child: face,
    );
  }
}

/// 카드 위를 비스듬히 지나가는 반투명 광택 띠 두 줄 — 홀로그램 카드의 유리 반사.
class _SheenPainter extends CustomPainter {
  const _SheenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.08, 0.22, 0.36, 0.55, 0.68, 0.82],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SheenPainter old) => false;
}
