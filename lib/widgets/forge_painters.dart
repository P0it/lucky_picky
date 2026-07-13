import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 강화 게이지 — 등급색 링이 성공 확률만큼 차오른다.
/// 채워지는 동안 바깥으로 얇은 광채 링이 한 겹 번진다.
class ForgeGaugePainter extends CustomPainter {
  final double t; // 0..1 애니메이션 진행
  final double rate; // 0..1 목표 확률
  final Color color;

  const ForgeGaugePainter({
    required this.t,
    required this.rate,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    if (radius <= 0) return;

    // 트랙.
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    // 채워지는 호 — 12시에서 시계방향.
    final sweep = 2 * math.pi * rate * t.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );

    // 링이 차오를수록 밖으로 번지는 광채.
    final glow = (t * rate).clamp(0.0, 1.0);
    if (glow > 0) {
      canvas.drawCircle(
        c,
        radius + 6 * glow,
        Paint()
          ..color = color.withValues(alpha: 0.18 * glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(ForgeGaugePainter old) =>
      old.t != t || old.rate != rate || old.color != color;
}

/// 성공 폭발 — 등급색 링 두 겹 + 클로버 잎 파티클이 사방으로 흩어진다.
class ForgeBurstPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;

  const ForgeBurstPainter({required this.t, required this.color});

  static const _petals = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final reach = math.min(size.width, size.height) / 2;

    // 충격파 링 두 겹 (시간차).
    for (var r = 0; r < 2; r++) {
      final lt = (t - r * 0.12).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      canvas.drawCircle(
        c,
        20 + reach * lt,
        Paint()
          ..color = color.withValues(alpha: 0.5 * (1 - lt))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // 잎 파티클 — 뻗어나가며 회전하고, 뒤로 갈수록 사라진다.
    final fade = t < 0.35 ? t / 0.35 : 1 - (t - 0.35) / 0.65;
    final opacity = fade.clamp(0.0, 1.0);
    final dist = reach * (0.35 + 0.55 * t);
    final leaf = 3.4 * (t < 0.35 ? t / 0.35 : 1.0);

    for (var k = 0; k < _petals; k++) {
      final ang = (k * (2 * math.pi / _petals)) + t * 0.6;
      final p = c + Offset(dist * math.cos(ang), dist * math.sin(ang));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(ang + t * 3);
      // 잎사귀 = 살짝 눌린 타원.
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: leaf * 2.2, height: leaf * 1.4),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ForgeBurstPainter old) =>
      old.t != t || old.color != color;
}

/// 실패 균열 — 카드 위에 금이 번지고, 조각이 아래로 떨어진다.
class ForgeCrackPainter extends CustomPainter {
  final double t; // 0..1

  const ForgeCrackPainter({required this.t});

  // 균열 갈래는 고정 시드 — 매 프레임 같은 모양.
  static final List<List<Offset>> _cracks = () {
    final rng = math.Random(7130);
    return List.generate(4, (i) {
      var p = const Offset(0.5, 0.5);
      final pts = <Offset>[p];
      final dir = (i * math.pi / 2) + rng.nextDouble() * 0.6 - 0.3;
      for (var s = 0; s < 4; s++) {
        p = Offset(
          p.dx + math.cos(dir + (rng.nextDouble() - 0.5) * 1.1) * 0.16,
          p.dy + math.sin(dir + (rng.nextDouble() - 0.5) * 1.1) * 0.16,
        );
        pts.add(p);
      }
      return pts;
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final grow = (t / 0.45).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = AppColors.crack.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (final pts in _cracks) {
      final path = Path()
        ..moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
      final shown = 1 + ((pts.length - 1) * grow).floor();
      for (var i = 1; i < shown; i++) {
        path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
    }

    // 조각 낙하 — 균열이 다 번진 뒤부터.
    final fall = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    if (fall <= 0) return;
    for (var k = 0; k < 6; k++) {
      final x = (0.18 + k * 0.13) * size.width;
      final y = size.height * (0.45 + fall * 0.9) + k * 4;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(fall * (k.isEven ? 2.4 : -2.0));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 5),
        Paint()
          ..color = AppColors.shard.withValues(alpha: 0.8 * (1 - fall)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ForgeCrackPainter old) => old.t != t;
}
