import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'clover_paths.dart';

/// 메인 클로버 — 잎 채움 상태 + 스프링 팝 + 완성 축하 + 숨쉬기 모션.
class CloverWidget extends StatefulWidget {
  final int leaves; // 0~4
  final int bounceKey; // 증가 시 마지막 잎 팝
  final bool celebrate; // 4잎 완성 축하
  final double size;
  final Color accent;

  const CloverWidget({
    super.key,
    required this.leaves,
    required this.bounceKey,
    required this.celebrate,
    this.size = 252,
    this.accent = AppColors.accent,
  });

  @override
  State<CloverWidget> createState() => _CloverWidgetState();
}

class _CloverWidgetState extends State<CloverWidget> with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _pop;
  late final AnimationController _celebrate;
  late final Animation<double> _popScale;

  int _popLeafOi = -1;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500))
      ..repeat();
    _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _celebrate = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    // leafPop 키프레임: 0 → 1.26 → .86 → 1.09 → .97 → 1
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.26), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.26, end: 0.86), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.09), weight: 16),
      TweenSequenceItem(tween: Tween(begin: 1.09, end: 0.97), weight: 13),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 13),
    ]).animate(_pop);

    if (widget.celebrate) _celebrate.forward(from: 0);
  }

  @override
  void didUpdateWidget(CloverWidget old) {
    super.didUpdateWidget(old);
    if (widget.bounceKey != old.bounceKey) {
      _popLeafOi = widget.leaves - 1;
      _pop.forward(from: 0);
    }
    if (widget.celebrate && !old.celebrate) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    _pop.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathe, _pop, _celebrate]),
        builder: (_, _) {
          final celebrating = _celebrate.isAnimating || (widget.celebrate && _celebrate.value > 0);
          final popping = _pop.isAnimating;
          return CustomPaint(
            painter: _CloverPainter(
              leaves: widget.leaves,
              accent: widget.accent,
              breatheV: _breathe.value,
              celebrateV: celebrating ? _celebrate.value : -1,
              popScale: popping ? _popScale.value : -1,
              popLeafOi: popping ? _popLeafOi : -1,
            ),
          );
        },
      ),
    );
  }
}

class _CloverPainter extends CustomPainter {
  final int leaves;
  final Color accent;
  final double breatheV; // 0..1
  final double celebrateV; // 0..1, -1 = off
  final double popScale; // -1 = off
  final int popLeafOi;

  _CloverPainter({
    required this.leaves,
    required this.accent,
    required this.breatheV,
    required this.celebrateV,
    required this.popScale,
    required this.popLeafOi,
  });

  // cloverCelebrate 키프레임 보간.
  static double _keyed(double t, List<double> stops, List<double> vals) {
    for (var i = 0; i < stops.length - 1; i++) {
      if (t <= stops[i + 1]) {
        final f = (t - stops[i]) / (stops[i + 1] - stops[i]);
        return vals[i] + (vals[i + 1] - vals[i]) * f;
      }
    }
    return vals.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    canvas.scale(s, s);

    // ---- 원근 틸트 ----
    canvas.save();
    canvas.translate(60, 61);
    canvas.scale(1.07, 0.9);
    canvas.translate(-60, -61);

    // ---- 클로버 그룹 변형 (숨쉬기 / 축하) ----
    double groupScale;
    double groupRotDeg;
    if (celebrateV >= 0) {
      groupScale = _keyed(celebrateV, [0, .22, .46, .70, 1], [1, 1.14, .95, 1.06, 1]);
      groupRotDeg = _keyed(celebrateV, [0, .22, .46, .70, 1], [0, -4, 3, -1.5, 0]);
    } else {
      final w = 0.5 - 0.5 * math.cos(2 * math.pi * breatheV); // 0→1→0
      groupScale = 1 + 0.03 * w;
      groupRotDeg = 0.8 * w;
    }
    canvas.translate(60, 60);
    canvas.rotate(groupRotDeg * math.pi / 180);
    canvas.scale(groupScale);
    canvas.translate(-60, -60);

    // ---- 줄기 (4잎 완성 시에만 그린) ----
    canvas.drawPath(
      stemPath(),
      Paint()
        ..color = leaves >= 4 ? accent : AppColors.emptyStem
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // ---- 잎 4장 ----
    final heart = heartPath();
    const sc = 1.8;
    for (final a in kLeafAngles) {
      final oi = kLeafFillOrder[a.toInt()]!;
      final filled = oi < leaves;
      final paint = Paint()
        ..color = filled ? accent : AppColors.emptyLeaf
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.save();
      canvas.translate(60, 58);
      canvas.rotate(a * math.pi / 180);
      canvas.translate(0, 0.5);
      canvas.scale(sc * 0.92, sc * 1.12);
      canvas.translate(-12, -21.35);
      if (oi == popLeafOi && popScale >= 0) {
        // 잎 꼭지점(12,21.35) 기준 스프링 팝
        canvas.translate(12, 21.35);
        canvas.scale(popScale);
        canvas.translate(-12, -21.35);
      }
      canvas.drawPath(heart, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CloverPainter old) =>
      old.leaves != leaves ||
      old.accent != accent ||
      old.breatheV != breatheV ||
      old.celebrateV != celebrateV ||
      old.popScale != popScale ||
      old.popLeafOi != popLeafOi;
}
