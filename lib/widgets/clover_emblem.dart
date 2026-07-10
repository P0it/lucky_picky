import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'clover_paths.dart';

/// 도감용 "완성된 행운" 엠블럼 — 같은 네잎클로버 지오메트리를 쓰되
/// flat-illustration(LottieFiles) 톤으로 끌어올린다:
/// 잎마다 그라데이션 + 광택 하이라이트, 잎 뒤 소프트 그림자, 골드/민트 스파클.
/// CloverMark(단색 실루엣)와 달리 한 장의 작은 일러스트로 읽히게 한다.
class CloverEmblem extends StatelessWidget {
  final double size;

  /// 주변에 떠 있는 반짝임(별/점). 카드/빈 상태에서 분위기를 더한다.
  final bool sparkles;

  /// 뒤에 은은하게 깔리는 민트 후광 디스크.
  final bool disc;

  /// 0~1. 빈 상태처럼 통째로 흐리게 쓰고 싶을 때.
  final double opacity;

  const CloverEmblem({
    super.key,
    this.size = 96,
    this.sparkles = true,
    this.disc = true,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmblemPainter(sparkles: sparkles, disc: disc, opacity: opacity),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  final bool sparkles;
  final bool disc;
  final double opacity;
  _EmblemPainter({required this.sparkles, required this.disc, required this.opacity});

  // 잎 음영 팔레트 (바깥 림 밝게 → 중심 깊게).
  static const _base = AppColors.accent; // 0xFF6FC143
  static const _light = Color(0xFF9FDE74);
  static const _deep = Color(0xFF53A52C);
  static const _gold = Color(0xFFFFCF5E);
  static const _mint = Color(0xFFBFE6A0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0; // viewBox 120
    canvas.save();
    canvas.scale(s, s);

    final layered = opacity < 1;
    if (layered) {
      canvas.saveLayer(
        const Rect.fromLTWH(-4, -4, 128, 128),
        Paint()..color = Colors.black.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }

    // ---- 뒤 후광 디스크 ----
    if (disc) {
      canvas.drawCircle(
        const Offset(60, 57),
        58,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(60, 57),
            58,
            const [Color(0xFFEAF7DD), Color(0x00EAF7DD)],
          ),
      );
    }

    // 살짝 기운 원근감(메인 클로버와 같은 결).
    canvas.save();
    canvas.translate(60, 60);
    canvas.scale(1.04, 0.94);
    canvas.translate(-60, -60);

    _drawLeaves(canvas, shadow: true);

    // 줄기 — 위→아래 그라데이션.
    canvas.drawPath(
      stemPath(),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(60, 58),
          const Offset(64, 105),
          const [_base, _deep],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    _drawLeaves(canvas, shadow: false);

    canvas.restore();

    if (sparkles) _drawSparkles(canvas);

    if (layered) canvas.restore();
    canvas.restore();
  }

  void _drawLeaves(Canvas canvas, {required bool shadow}) {
    final heart = heartPath();
    const sc = 1.8;
    for (final a in kLeafAngles) {
      canvas.save();
      canvas.translate(60, 58);
      canvas.rotate(a * math.pi / 180);
      canvas.translate(0, 0.5);
      canvas.scale(sc * 0.92, sc * 1.12);
      canvas.translate(-12, -21.35);

      if (shadow) {
        canvas.save();
        canvas.translate(0.6, 2.6); // 살짝 아래로 깔리는 접지 그림자
        canvas.drawPath(
          heart,
          Paint()
            ..color = const Color(0xFF3C7A1E).withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
            ..isAntiAlias = true,
        );
        canvas.restore();
      } else {
        // 잎 본체 — 바깥 림(밝게) → 중심(깊게).
        canvas.drawPath(
          heart,
          Paint()
            ..shader = ui.Gradient.linear(
              const Offset(12, 2),
              const Offset(12, 22),
              const [_light, _base, _deep],
              const [0.0, 0.5, 1.0],
            )
            ..isAntiAlias = true,
        );
        // 광택 — 위쪽 잎엽에 부드러운 흰 하이라이트.
        canvas.drawPath(
          heart,
          Paint()
            ..shader = ui.Gradient.radial(
              const Offset(7.5, 7),
              6.5,
              const [Color(0x66FFFFFF), Color(0x00FFFFFF)],
            )
            ..isAntiAlias = true,
        );
      }
      canvas.restore();
    }
  }

  void _drawSparkles(Canvas canvas) {
    void star(Offset c, double r, Color col) {
      final k = r * 0.32; // 오목한 변 → 4각 반짝임
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(p, Paint()..color = col..isAntiAlias = true);
    }

    void dot(Offset c, double r, Color col) =>
        canvas.drawCircle(c, r, Paint()..color = col..isAntiAlias = true);

    star(const Offset(98, 30), 6.5, _gold);
    star(const Offset(26, 90), 4.4, _base);
    dot(const Offset(95, 83), 2.4, _gold);
    dot(const Offset(22, 37), 2.6, _mint);
    dot(const Offset(104, 57), 1.8, _mint);
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.sparkles != sparkles || old.disc != disc || old.opacity != opacity;
}
