import 'dart:ui';

/// 클로버 지오메트리 — Clover.dc.html 의 SVG 하트 path / 배치를 그대로 옮긴다.
/// viewBox 는 0 0 120 120 기준.

/// 하트 한 장 (로컬 좌표, 꼭지점이 (12, 21.35)).
Path heartPath() {
  return Path()
    ..moveTo(12, 21.35)
    ..relativeLineTo(-1.45, -1.32)
    ..cubicTo(5.4, 15.36, 2, 12.28, 2, 8.5)
    ..cubicTo(2, 5.42, 4.42, 3, 7.5, 3)
    ..cubicTo(9.24, 3, 10.91, 3.81, 12, 5.09)
    ..cubicTo(13.09, 3.81, 14.76, 3, 16.5, 3)
    ..cubicTo(19.58, 3, 22, 5.42, 22, 8.5)
    ..cubicTo(22, 12.28, 18.6, 15.36, 13.45, 20.04)
    ..lineTo(12, 21.35)
    ..close();
}

/// 잎이 배치되는 각도(도)와 채워지는 순서.
const List<double> kLeafAngles = [135, 225, -45, 45];

/// angle(deg) -> fill order index.
const Map<int, int> kLeafFillOrder = {-45: 0, 45: 1, 135: 2, 225: 3};

/// 줄기 path (4잎 완성 시 채색).
Path stemPath() {
  return Path()
    ..moveTo(60, 58)
    ..cubicTo(63.5, 76, 58.5, 90, 64, 105);
}
