import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rarity_style.dart';

/// 플랫 컬렉션 카드 — 절취선/스텁 없는 둥근 사각형에 등급색을 "전체"에 칠한다.
/// 테두리는 두지 않는다. 면은 그림자로 띄워 분리하고, 등급은 그라데이션이 말한다.
/// 등급이 오를수록 화려해진다:
///   · 전 등급: 대각선 등급색 그라데이션 + 등급색 글로우 그림자
///   · 오라 등급(유니크+): 홀로그램 그라데이션 링 + 포일 줄무늬 + 대각선 유리 광택(시머)
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
    final aura = style.aura;
    final innerRadius = borderRadius - (aura != null ? 1.6 : 0);

    final face = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.panel,
        ),
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Stack(
        children: [
          // 포일 질감 + 유리 광택. 오라 등급이거나, 지나가는 광택이 필요할 때만.
          if (aura != null || sweepT != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: CustomPaint(
                    painter: _SheenPainter(
                      sweepT: sweepT,
                      holo: aura != null,
                      foil: aura is LinearGradient
                          ? aura.colors
                          : [style.color],
                    ),
                  ),
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

/// 카드 표면 — 포일 줄무늬(홀로 등급) + 정지 광택 두 줄 + 지나가는 광택 한 줄.
class _SheenPainter extends CustomPainter {
  final double? sweepT; // null 이면 지나가는 광택 없음
  final bool holo; // 오라(유니크+) 등급인가
  final List<Color> foil; // 포일 줄무늬 색

  const _SheenPainter({
    required this.sweepT,
    required this.holo,
    required this.foil,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (holo) {
      // 포일 — 가는 무지개 사선. 아주 옅게 깔아 색이 아니라 질감으로만 읽히게 한다.
      final stripe = Paint()..strokeWidth = 2.6;
      for (var i = 0; i * 8.0 < size.width + size.height; i++) {
        final x = i * 8.0;
        stripe.color = foil[i % foil.length].withValues(alpha: 0.13);
        canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), stripe);
      }
      // 정지 광택 두 줄 — 유리에 비친 창처럼.
      canvas.drawRect(
        rect,
        Paint()
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
          ).createShader(rect),
      );
    }

    final t = sweepT;
    if (t == null) return;
    // 앞 60% 동안만 띠가 지나가고 나머지는 쉰다 — 쉼 없이 번쩍이면 눈이 피로하다.
    final p = t / 0.6;
    if (p > 1) return;
    final c = -0.25 + 1.5 * p;
    var s0 = c - 0.14, s1 = c, s2 = c + 0.14;
    if (s2 <= 0 || s0 >= 1) return;
    // 그라데이션 스톱은 0~1 안에서 반드시 증가해야 한다.
    s0 = s0.clamp(0.0, 1.0);
    s1 = s1.clamp(0.0, 1.0);
    s2 = s2.clamp(0.0, 1.0);
    if (s1 <= s0) s1 = s0 + 0.0001;
    if (s2 <= s1) s2 = s1 + 0.0001;
    if (s2 > 1) return; // 카드 끝을 벗어난 띠 — 어차피 안 보인다

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: holo ? 0.6 : 0.34),
            Colors.white.withValues(alpha: 0),
          ],
          stops: [s0, s1, s2],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) =>
      old.sweepT != sweepT || old.holo != holo;
}
