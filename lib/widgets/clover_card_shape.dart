import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'clover_paths.dart';

/// 행운권 카드 = 네잎클로버 그 자체. 축구 게임의 유니폼형 선수 카드처럼,
/// 카드 컴포넌트의 실루엣이 클로버 모양이다.
///
/// 지오메트리는 브랜드 마크(CloverMark)와 동일한 하트 4장 + 줄기이며,
/// viewBox 120 기준으로 그린 뒤 카드 폭에 맞춰 확대한다.
class CloverShape {
  final List<Path> leaves;
  final Path stem;
  final Path outline; // 잎 4장 union (테두리용)

  const CloverShape(this.leaves, this.stem, this.outline);
}

/// [size] 를 꽉 채우는 클로버(잎 4장 + 줄기). 비율은 유지한 채 가운데 정렬.
CloverShape cloverShape(Size size) {
  // 1) viewBox(120) 좌표계에서 잎과 줄기를 만든다.
  var leaves = <Path>[];
  for (final a in kLeafAngles) {
    final m = Matrix4.identity()
      ..translateByDouble(60, 58, 0, 1)
      ..rotateZ(a * math.pi / 180)
      ..translateByDouble(0, 0.5, 0, 1)
      ..scaleByDouble(1.8 * 0.92, 1.8 * 1.12, 1, 1)
      ..translateByDouble(-12, -21.35, 0, 1);
    leaves.add(heartPath().transform(m.storage));
  }
  var outline = leaves.first;
  for (final leaf in leaves.skip(1)) {
    outline = Path.combine(PathOperation.union, outline, leaf);
  }
  var stem = stemPath();

  // 2) 잎+줄기 전체를 size 안에 꽉 채우도록(비율 유지) 맞춘다.
  final b = outline.getBounds().expandToInclude(stem.getBounds());
  final k = math.min(size.width / b.width, size.height / b.height);
  final fit = Matrix4.identity()
    ..translateByDouble(
        (size.width - b.width * k) / 2, (size.height - b.height * k) / 2, 0, 1)
    ..scaleByDouble(k, k, 1, 1)
    ..translateByDouble(-b.left, -b.top, 0, 1);

  leaves = [for (final p in leaves) p.transform(fit.storage)];
  outline = outline.transform(fit.storage);
  stem = stem.transform(fit.storage);

  return CloverShape(leaves, stem, outline);
}

/// 클로버 카드의 면 — 잎을 등급색 그라데이션으로 채우고 줄기를 그린다.
///
/// 잎은 조각별로 칠한다(union path 한 장으로 채우면 Impeller 에서 비어 나온다).
class CloverCardFace extends StatelessWidget {
  final List<Color> panel;
  final Color borderColor;
  final Color stemColor;

  const CloverCardFace({
    super.key,
    required this.panel,
    required this.borderColor,
    required this.stemColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FacePainter(panel, borderColor, stemColor),
      size: Size.infinite,
    );
  }
}

class _FacePainter extends CustomPainter {
  final List<Color> panel;
  final Color borderColor;
  final Color stemColor;

  _FacePainter(this.panel, this.borderColor, this.stemColor);

  @override
  void paint(Canvas canvas, Size size) {
    final c = cloverShape(size);
    final rect = Offset.zero & size;

    canvas.drawPath(
      c.stem,
      Paint()
        ..color = stemColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.032
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    final fill = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: panel,
      ).createShader(rect);

    for (final leaf in c.leaves) {
      canvas.save();
      canvas.clipPath(leaf, doAntiAlias: true);
      canvas.drawRect(rect, fill);
      canvas.restore();
    }

    canvas.drawPath(
      c.outline,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.borderColor != borderColor ||
      old.stemColor != stemColor ||
      !listEquals(old.panel, panel);
}
