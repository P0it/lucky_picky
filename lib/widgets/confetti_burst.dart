import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 고득점(95+) 축하용 컨페티 — 마운트되면 한 번 재생되고 사라진다.
/// 화면 위쪽에서 종이가루가 흩날리며 떨어지는 가벼운 연출 (탭 불가, 장식 전용).
class ConfettiBurst extends StatefulWidget {
  final Duration duration;
  const ConfettiBurst({super.key, this.duration = const Duration(milliseconds: 2200)});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => _ctrl.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_ctrl.value),
              ),
      ),
    );
  }
}

class _Piece {
  final double x; // 시작 x (0~1)
  final double drift; // 좌우 흔들림 폭
  final double speed; // 낙하 속도 배율
  final double size;
  final double spin; // 회전 속도
  final double phase;
  final Color color;
  const _Piece(this.x, this.drift, this.speed, this.size, this.spin, this.phase,
      this.color);
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    Color(0xFF6FC143), // accent green
    Color(0xFFF2B705),
    Color(0xFF4FA8E8),
    Color(0xFFFF8A70),
    Color(0xFF9C8BDB),
    Color(0xFFF07EA8),
  ];

  // 조각 파라미터는 고정 시드로 한 번만 생성 — 매 프레임 동일 배치.
  static final List<_Piece> _pieces = () {
    final rng = math.Random(20260713);
    return List.generate(70, (i) {
      return _Piece(
        rng.nextDouble(),
        (rng.nextDouble() - 0.5) * 0.22,
        0.65 + rng.nextDouble() * 0.7,
        5.5 + rng.nextDouble() * 5,
        (rng.nextDouble() - 0.5) * 14,
        rng.nextDouble() * math.pi * 2,
        _colors[i % _colors.length],
      );
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final fade = t < 0.75 ? 1.0 : 1.0 - (t - 0.75) / 0.25; // 끝에서 페이드아웃
    for (final p in _pieces) {
      final fall = t * p.speed;
      if (fall <= 0) continue;
      final y = -0.08 + fall * 1.25; // 화면 위 밖에서 아래로
      if (y > 1.1) continue;
      final x = p.x + math.sin(t * 6 + p.phase) * p.drift;
      final center = Offset(x * size.width, y * size.height);
      paint.color = p.color.withValues(alpha: 0.9 * fade);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(t * p.spin + p.phase);
      // 살짝 눕는 종이 느낌 — 회전에 따라 세로폭이 접힘.
      final fold = 0.35 + 0.65 * math.sin(t * 9 + p.phase).abs();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * fold),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
