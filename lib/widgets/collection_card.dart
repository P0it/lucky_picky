import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rarity_style.dart';

/// 컬렉션 카드 — 면은 앱 전체와 같은 흰 톤으로 두고, 등급은 **테두리**로만 말한다.
/// 등급색 1.4px 라인에 같은 색 글로우를 깔아 테두리만 은은하게 빛난다.
/// (예전에는 카드 면 전체가 등급별 파스텔 오로라였는데, 앱의 담백한 톤과
///  부딪혀서 면을 비우고 색을 가장자리로 몰았다.)
class CollectionCard extends StatelessWidget {
  final RarityStyle style;
  final Widget child;
  final double borderRadius;

  /// 0~1을 넣으면 광택 띠 하나가 카드를 가로질러 지나간다 (뽑기 결과처럼
  /// "지금 막 얻은 카드"를 살아 있게 보여줄 때만). null 이면 정지 상태.
  final double? sweepT;

  const CollectionCard({
    super.key,
    required this.style,
    required this.child,
    this.borderRadius = 20,
    this.sweepT,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          // 등급색 글로우 — 테두리 바깥으로 번져 카드가 그 색으로 빛나 보인다.
          BoxShadow(
            color: style.color.withValues(alpha: 0.22),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 등급색 테두리 — 카드에서 등급을 말하는 건 이 선 하나뿐이다.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
            color: style.color.withValues(alpha: 0.85), width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardFacePainter(tint: style.color, sweepT: sweepT),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// 카드 표면 — 흰 면에 등급색을 아주 옅게 안쪽 가장자리로만 흘리고,
/// 지나가는 광택 한 줄(뽑기 결과)만 추가로 얹는다.
class _CardFacePainter extends CustomPainter {
  final Color tint;
  final double? sweepT; // null 이면 지나가는 광택 없음

  const _CardFacePainter({required this.tint, required this.sweepT});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) 테두리 안쪽으로만 스며드는 등급색 — 면 한가운데는 흰색 그대로다.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.98,
          colors: [
            tint.withValues(alpha: 0),
            tint.withValues(alpha: 0),
            tint.withValues(alpha: 0.055),
          ],
          stops: const [0, 0.78, 1],
        ).createShader(rect),
    );

    // 2) 지나가는 광택 — 앞 60% 동안만 띠가 지나가고 나머지는 쉰다.
    final t = sweepT;
    if (t == null) return;
    final p = t / 0.6;
    if (p > 1) return;
    final c = -0.25 + 1.5 * p;
    var s0 = c - 0.14, s1 = c, s2 = c + 0.14;
    if (s2 <= 0 || s0 >= 1) return;
    s0 = s0.clamp(0.0, 1.0);
    s1 = s1.clamp(0.0, 1.0);
    s2 = s2.clamp(0.0, 1.0);
    if (s1 <= s0) s1 = s0 + 0.0001;
    if (s2 <= s1) s2 = s1 + 0.0001;
    if (s2 > 1) return;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0),
            tint.withValues(alpha: 0.16),
            tint.withValues(alpha: 0),
          ],
          stops: [s0, s1, s2],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CardFacePainter old) =>
      old.sweepT != sweepT || old.tint != tint;
}
