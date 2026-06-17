import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'clover_paths.dart';

/// 로고/배지용 작은 클로버 마크 (채움 상태 없이 전부 accent).
class CloverMark extends StatelessWidget {
  final double size;
  final bool withStem;
  final Color? color;

  const CloverMark({super.key, required this.size, this.withStem = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter(color ?? AppColors.accent, withStem)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color color;
  final bool withStem;
  _MarkPainter(this.color, this.withStem);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0; // viewBox 120
    canvas.scale(s, s);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (withStem) {
      canvas.drawPath(
        stemPath(),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }

    final heart = heartPath();
    const sc = 1.8;
    for (final a in kLeafAngles) {
      canvas.save();
      canvas.translate(60, 58);
      canvas.rotate(a * math.pi / 180);
      canvas.translate(0, 0.5);
      canvas.scale(sc * 0.92, sc * 1.12);
      canvas.translate(-12, -21.35);
      canvas.drawPath(heart, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.withStem != withStem;
}
