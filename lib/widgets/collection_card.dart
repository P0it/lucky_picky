import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rarity_style.dart';

/// 파스텔 오로라 글래스 카드 — 밝은 파스텔 베이스([RarityStyle.panel]) 위에
/// 오로라 색 덩어리([RarityStyle.blobs])를 겹쳐 이리데센스를 낸다.
/// 흰 테두리(림)와 그림자로 유리처럼 떠 보이게 하고, 대각선 광택 한 줄이
/// 표면에 정지해 있다. 등급이 오를수록 오로라가 화려해진다.
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // 테두리 대신 그림자 두 겹 — 중립 잉크로 면을 띄우고, 등급색을 옅게 흘려
        // 파스텔 면이 흰 배경에서 붕 뜨지 않게 잡아준다.
        boxShadow: [
          const BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: style.color.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // 밝은 유리 림 — 파스텔 면 위에 얹혀 카드를 유리처럼 마감한다.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xE6FFFFFF), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AuroraFacePainter(
                    base: style.panel,
                    blobs: style.blobs,
                    sweepT: sweepT,
                  ),
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

/// 카드 표면 — 파스텔 베이스 + 오로라 덩어리 + 정지 광택 + 지나가는 광택.
class _AuroraFacePainter extends CustomPainter {
  final List<Color> base;
  final List<AuroraBlob> blobs;
  final double? sweepT; // null 이면 지나가는 광택 없음

  const _AuroraFacePainter({
    required this.base,
    required this.blobs,
    required this.sweepT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) 파스텔 베이스 그라데이션.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: base,
        ).createShader(rect),
    );

    // 2) 오로라 덩어리 — 여러 방사형 색을 겹쳐 이음새 없는 이리데센스.
    final short = size.shortestSide;
    for (final b in blobs) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: b.center,
            radius: b.radius * size.longestSide / short,
            colors: [b.color, b.color.withValues(alpha: 0)],
            stops: const [0, 0.72],
          ).createShader(rect),
      );
    }

    // 3) 정지 광택 — 유리에 비친 창처럼 대각선 한 줄.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.9, -1),
          end: Alignment(0.9, 1),
          colors: [
            Color(0x00FFFFFF),
            Color(0x66FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.34, 0.47, 0.60],
        ).createShader(rect),
    );

    // 4) 지나가는 광택 — 앞 60% 동안만 띠가 지나가고 나머지는 쉰다.
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
          colors: const [
            Color(0x00FFFFFF),
            Color(0x8CFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [s0, s1, s2],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuroraFacePainter old) =>
      old.sweepT != sweepT || old.base != base || old.blobs != blobs;
}
