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
        // 행운 뽑기 — 캡슐 머신처럼 보이는 구슬 + 받침대, 안쪽에 작은 반짝임.
        return [
          Path()..addOval(Rect.fromCircle(center: const Offset(12, 10), radius: 6)),
          Path()
            ..moveTo(8.7, 15)
            ..lineTo(5.9, 20.3)
            ..lineTo(18.1, 20.3)
            ..lineTo(15.3, 15),
          Path()
            ..moveTo(10.2, 6.4)
            ..quadraticBezierTo(10.9, 8.1, 12.6, 8.8)
            ..quadraticBezierTo(10.9, 9.5, 10.2, 11.2)
            ..quadraticBezierTo(9.5, 9.5, 7.8, 8.8)
            ..quadraticBezierTo(9.5, 8.1, 10.2, 6.4)
            ..close(),
        ];
      case TabIconKind.fortune:
        // 운세 — 포춘쿠키: 가운데가 접힌 과자 + 비스듬히 삐져나온 쪽지.
        return [
          // 쿠키 몸통 — 위 가운데가 깊게 파인 만두 모양(두 잎이 접힌 느낌).
          Path()
            ..moveTo(4.3, 13.2)
            ..cubicTo(4.3, 8.3, 11.2, 8.3, 12, 11.8)
            ..cubicTo(12.8, 8.3, 19.7, 8.3, 19.7, 13.2)
            ..cubicTo(19.7, 18, 4.3, 18, 4.3, 13.2)
            ..close(),
          // 쪽지 — 접힘에서 위로 비스듬히 삐져나온 종이.
          Path()
            ..moveTo(11.2, 11)
            ..lineTo(12.4, 6.4)
            ..lineTo(14.3, 6.9)
            ..lineTo(13.1, 11.5)
            ..close(),
        ];
      case TabIconKind.dex:
        // 보관함 — 뚜껑 달린 상자.
        return [
          Path()..addRRect(RRect.fromLTRBR(3, 4.5, 21, 8.8, const Radius.circular(1.2))),
          Path()
            ..moveTo(4.7, 8.8)
            ..lineTo(4.7, 19)
            ..arcToPoint(const Offset(5.7, 20), radius: const Radius.circular(1))
            ..lineTo(18.3, 20)
            ..arcToPoint(const Offset(19.3, 19), radius: const Radius.circular(1))
            ..lineTo(19.3, 8.8),
          Path()
            ..moveTo(9.9, 12.6)
            ..lineTo(14.1, 12.6),
        ];
      case TabIconKind.archive:
        // 나의 기록 — 날짜에 체크가 찍힌 달력.
        return [
          Path()..addRRect(RRect.fromLTRBR(3.5, 5.5, 20.5, 20.5, const Radius.circular(2))),
          Path()
            ..moveTo(3.5, 10.2)
            ..lineTo(20.5, 10.2),
          Path()
            ..moveTo(8.2, 3.6)
            ..lineTo(8.2, 7.2),
          Path()
            ..moveTo(15.8, 3.6)
            ..lineTo(15.8, 7.2),
          Path()
            ..moveTo(8.6, 15.2)
            ..lineTo(11.1, 17.6)
            ..lineTo(15.5, 13.2),
        ];
    }
  }

  @override
  bool shouldRepaint(_TabIconPainter old) => old.color != color || old.kind != kind;
}
