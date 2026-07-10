import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 캡슐 머신(가챠폰) 일러스트 — 플랫 스타일 CustomPaint.
///
/// 애니메이션 파라미터(0~1)를 밖에서 넘겨 단계별 연출을 만든다.
/// - [coinT]  : 클로버 코인이 투입구로 들어가는 진행도
/// - [leverT] : 레버(다이얼)가 한 바퀴 도는 진행도 — 돔 속 캡슐도 들썩인다
/// - [dropT]  : 결과 캡슐이 배출구로 떨어지는 진행도 (바운스 포함)
/// - [capsuleColor] : 결과 캡슐 윗면 색 (등급색)
class GachaMachine extends StatelessWidget {
  final double coinT;
  final double leverT;
  final double dropT;
  final Color capsuleColor;

  const GachaMachine({
    super.key,
    this.coinT = 0,
    this.leverT = 0,
    this.dropT = 0,
    this.capsuleColor = AppColors.accent,
  });

  /// 논리 캔버스 크기. 배출구 캡슐의 탭 판정에도 쓴다.
  static const Size canvas = Size(300, 400);

  /// 배출구에 떨어진 캡슐의 중심 (논리 좌표).
  static const Offset droppedCapsuleCenter = Offset(197, 342);
  static const double droppedCapsuleRadius = 26;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: canvas.width / canvas.height,
      child: CustomPaint(
        painter: _MachinePainter(
          coinT: coinT,
          leverT: leverT,
          dropT: dropT,
          capsuleColor: capsuleColor,
        ),
      ),
    );
  }
}

class _MachinePainter extends CustomPainter {
  final double coinT;
  final double leverT;
  final double dropT;
  final Color capsuleColor;

  _MachinePainter({
    required this.coinT,
    required this.leverT,
    required this.dropT,
    required this.capsuleColor,
  });

  // 돔 속 장식 캡슐 배치 (중심 상대 좌표, 반지름, 색 인덱스).
  static const _domeCapsules = [
    (-52.0, 28.0, 17.0, 0),
    (-18.0, 42.0, 18.0, 1),
    (20.0, 34.0, 17.0, 2),
    (52.0, 24.0, 15.0, 3),
    (-38.0, -4.0, 16.0, 4),
    (2.0, 6.0, 18.0, 0),
    (40.0, -2.0, 15.0, 1),
    (-12.0, -28.0, 15.0, 2),
    (24.0, -32.0, 14.0, 3),
  ];

  static const _capsuleColors = [
    Color(0xFF6FC143), // 그린
    Color(0xFF7B6FDE), // 퍼플
    Color(0xFFE0A32E), // 골드
    Color(0xFFE06FA8), // 핑크
    Color(0xFF57A8E0), // 블루
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / GachaMachine.canvas.width;
    canvas.scale(sx, sx);

    _drawBody(canvas);
    _drawDome(canvas);
    _drawFace(canvas);
    if (coinT > 0 && coinT < 1) _drawCoin(canvas);
    if (dropT > 0) _drawDroppedCapsule(canvas);
  }

  void _drawBody(Canvas canvas) {
    // 본체 — 포인트 그린, 아래로 갈수록 진한 발판.
    final body = RRect.fromRectAndCorners(
      const Rect.fromLTRB(48, 208, 252, 372),
      topLeft: const Radius.circular(26),
      topRight: const Radius.circular(26),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.accent);
    // 본체 하이라이트 면 분할.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTRB(48, 208, 96, 372),
        topLeft: const Radius.circular(26),
        bottomLeft: const Radius.circular(20),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    // 받침.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(38, 366, 262, 386), const Radius.circular(10)),
      Paint()..color = const Color(0xFF57993A),
    );
  }

  void _drawDome(Canvas canvas) {
    const center = Offset(150, 118);
    const r = 102.0;

    // 유리 돔.
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
    canvas.drawCircle(
        center, r, Paint()..color = const Color(0xFFF2F4F6).withValues(alpha: 0.6));

    // 돔 속 캡슐 — 레버 진행도에 맞춰 들썩인다.
    final jiggle = math.sin(leverT * math.pi * 4) * 5 * (leverT > 0 && leverT < 1 ? 1 : 0);
    for (final (dx, dy, cr, ci) in _domeCapsules) {
      final wob = math.sin((leverT * math.pi * 4) + dx) * 4 *
          (leverT > 0 && leverT < 1 ? 1 : 0);
      final c = center + Offset(dx, dy + jiggle * 0.4 + wob * 0.5);
      _drawCapsule(canvas, c, cr, _capsuleColors[ci]);
    }

    // 유리 반사광.
    canvas.drawCircle(center, r,
        Paint()..color = Colors.white.withValues(alpha: 0.08));
    final gloss = Path()
      ..addArc(Rect.fromCircle(center: center, radius: r - 14),
          -2.4, 0.9);
    canvas.drawPath(
      gloss,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    // 돔 테두리 + 목 링.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFDDE3E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(72, 196, 228, 216), const Radius.circular(10)),
      Paint()..color = const Color(0xFF57993A),
    );
  }

  void _drawFace(Canvas canvas) {
    // 레버(다이얼) — leverT 로 회전.
    const knobC = Offset(112, 262);
    canvas.drawCircle(knobC, 30, Paint()..color = Colors.white);
    canvas.drawCircle(
      knobC,
      30,
      Paint()
        ..color = const Color(0xFF57993A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.save();
    canvas.translate(knobC.dx, knobC.dy);
    canvas.rotate(leverT * math.pi * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-24, -6, 24, 6), const Radius.circular(6)),
      Paint()..color = AppColors.accent,
    );
    canvas.restore();
    canvas.drawCircle(knobC, 6, Paint()..color = const Color(0xFF57993A));

    // 코인 투입구.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(166, 236, 214, 252), const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(182, 240, 198, 248), const Radius.circular(4)),
      Paint()..color = const Color(0xFF57993A),
    );

    // 배출구.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(164, 296, 230, 356), const Radius.circular(16)),
      Paint()..color = const Color(0xFF4A8230),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(170, 302, 224, 350), const Radius.circular(12)),
      Paint()..color = const Color(0xFF3C6B27),
    );
  }

  void _drawCoin(Canvas canvas) {
    // 클로버 코인이 위에서 투입구로 떨어지며 사라진다.
    final t = Curves.easeIn.transform(coinT);
    final pos = Offset.lerp(const Offset(190, 190), const Offset(190, 244), t)!;
    final opacity = (1 - t * 0.65).clamp(0.0, 1.0);
    final paint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: opacity);
    canvas.drawCircle(pos, 13 * (1 - t * 0.35), paint);
    canvas.drawCircle(
      pos,
      13 * (1 - t * 0.35),
      Paint()
        ..color = const Color(0xFFE0A32E).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawDroppedCapsule(Canvas canvas) {
    // 배출구 안에서 아래로 떨어지며 바운스.
    final t = Curves.bounceOut.transform(dropT.clamp(0.0, 1.0));
    final start = const Offset(197, 300);
    final end = GachaMachine.droppedCapsuleCenter;
    final c = Offset.lerp(start, end, t)!;
    _drawCapsule(canvas, c, GachaMachine.droppedCapsuleRadius, capsuleColor,
        outline: true);
  }

  void _drawCapsule(Canvas canvas, Offset c, double r, Color top,
      {bool outline = false}) {
    // 아랫면(흰색 반구).
    final lower = Path()
      ..addArc(Rect.fromCircle(center: c, radius: r), 0, math.pi)
      ..close();
    canvas.drawPath(lower, Paint()..color = Colors.white);
    // 윗면(컬러 반구).
    final upper = Path()
      ..addArc(Rect.fromCircle(center: c, radius: r), math.pi, math.pi)
      ..close();
    canvas.drawPath(upper, Paint()..color = top);
    // 분할선 + 하이라이트.
    canvas.drawLine(
      Offset(c.dx - r, c.dy),
      Offset(c.dx + r, c.dy),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
        Offset(c.dx - r * 0.35, c.dy - r * 0.45), r * 0.16,
        Paint()..color = Colors.white.withValues(alpha: 0.75));
    if (outline) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_MachinePainter old) =>
      old.coinT != coinT ||
      old.leverT != leverT ||
      old.dropT != dropT ||
      old.capsuleColor != capsuleColor;
}
