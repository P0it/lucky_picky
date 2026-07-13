import 'package:flutter/material.dart';

/// 하단 탭 아이콘 — Clover.dc.html 의 인라인 SVG(24x24, stroke 1.8, round)를
/// Flutter Path 로 그대로 옮겨 그린다.
enum TabIconKind { home, store, fortune, dex, archive }

class TabIcon extends StatelessWidget {
  final TabIconKind kind;
  final Color color;
  final double size;
  const TabIcon({super.key, required this.kind, required this.color, this.size = 25});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TabIconPainter(kind, color)),
    );
  }
}

class _TabIconPainter extends CustomPainter {
  final TabIconKind kind;
  final Color color;
  _TabIconPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (final p in _paths()) {
      canvas.drawPath(p, paint);
    }
  }

  List<Path> _paths() {
    switch (kind) {
      case TabIconKind.home:
        return [
          Path()
            ..moveTo(3, 10.7)
            ..lineTo(12, 3.5)
            ..lineTo(21, 10.7),
          Path()
            ..moveTo(5.6, 9.5)
            ..lineTo(5.6, 19.5)
            ..arcToPoint(const Offset(6.6, 20.5), radius: const Radius.circular(1))
            ..lineTo(17.4, 20.5)
            ..arcToPoint(const Offset(18.4, 19.5), radius: const Radius.circular(1))
            ..lineTo(18.4, 9.5),
          Path()
            ..moveTo(9.7, 20.5)
            ..lineTo(9.7, 15.1)
            ..arcToPoint(const Offset(10.7, 14.1),
                radius: const Radius.circular(1), clockwise: true)
            ..lineTo(13.3, 14.1)
            ..arcToPoint(const Offset(14.3, 15.1),
                radius: const Radius.circular(1), clockwise: true)
            ..lineTo(14.3, 20.5),
        ];
      case TabIconKind.store:
        return [
          Path()
            ..moveTo(4, 9.5)
            ..lineTo(20, 9.5)
            ..lineTo(20, 19)
            ..arcToPoint(const Offset(19, 20), radius: const Radius.circular(1), clockwise: true)
            ..lineTo(5, 20)
            ..arcToPoint(const Offset(4, 19), radius: const Radius.circular(1), clockwise: true)
            ..close(),
          Path()
            ..moveTo(2.8, 9.5)
            ..lineTo(21.2, 9.5),
          Path()
            ..moveTo(12, 9.5)
            ..lineTo(12, 20.5),
          Path()
            ..moveTo(12, 9.5)
            ..cubicTo(12, 9.5, 10.6, 5, 8, 5.6)
            ..cubicTo(6, 6, 6.4, 9.5, 9.2, 9.5)
            ..close(),
          Path()
            ..moveTo(12, 9.5)
            ..cubicTo(12, 9.5, 13.4, 5, 16, 5.6)
            ..cubicTo(18, 6, 17.6, 9.5, 14.8, 9.5)
            ..close(),
        ];
      case TabIconKind.fortune:
        // 반짝이 별(행운지수) — 중앙 4포인트 스파클 + 작은 트윙클.
        return [
          Path()
            ..moveTo(11, 4.6)
            ..quadraticBezierTo(12.5, 10.5, 18.4, 12)
            ..quadraticBezierTo(12.5, 13.5, 11, 19.4)
            ..quadraticBezierTo(9.5, 13.5, 3.6, 12)
            ..quadraticBezierTo(9.5, 10.5, 11, 4.6)
            ..close(),
          Path()
            ..moveTo(18.7, 3.8)
            ..lineTo(18.7, 7.4),
          Path()
            ..moveTo(16.9, 5.6)
            ..lineTo(20.5, 5.6),
          Path()
            ..moveTo(19.6, 16.6)
            ..lineTo(19.6, 19.4),
          Path()
            ..moveTo(18.2, 18)
            ..lineTo(21, 18),
        ];
      case TabIconKind.dex:
        return [
          Path()..addRRect(RRect.fromLTRBR(4, 4, 10.5, 10.5, const Radius.circular(2))),
          Path()..addRRect(RRect.fromLTRBR(13.5, 4, 20, 10.5, const Radius.circular(2))),
          Path()..addRRect(RRect.fromLTRBR(4, 13.5, 10.5, 20, const Radius.circular(2))),
          Path()..addRRect(RRect.fromLTRBR(13.5, 13.5, 20, 20, const Radius.circular(2))),
        ];
      case TabIconKind.archive:
        return [
          Path()
            ..moveTo(11, 10.5)
            ..cubicTo(11, 7.2, 6.6, 6.8, 6.6, 9.9)
            ..cubicTo(6.6, 12.1, 9.2, 11.8, 11, 10.5)
            ..close(),
          Path()
            ..moveTo(13, 10.5)
            ..cubicTo(13, 7.2, 17.4, 6.8, 17.4, 9.9)
            ..cubicTo(17.4, 12.1, 14.8, 11.8, 13, 10.5)
            ..close(),
          Path()
            ..moveTo(11, 12.5)
            ..cubicTo(7.7, 12.5, 7.3, 16.9, 10.4, 16.9)
            ..cubicTo(12.6, 16.9, 12.3, 14.3, 11, 12.5)
            ..close(),
          Path()
            ..moveTo(13, 12.5)
            ..cubicTo(16.3, 12.5, 16.7, 16.9, 13.6, 16.9)
            ..cubicTo(11.4, 16.9, 11.7, 14.3, 13, 12.5)
            ..close(),
          Path()
            ..moveTo(13, 16.5)
            ..cubicTo(13.8, 18.1, 13.6, 19.9, 14.6, 21.1),
        ];
    }
  }

  @override
  bool shouldRepaint(_TabIconPainter old) => old.color != color || old.kind != kind;
}
