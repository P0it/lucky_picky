import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'clover_paths.dart';

/// 오늘의 행운지수 타이밍 게이지 — 큰 클로버가 0~100으로 차올랐다 내려갔다
/// 반복하고, 유저가 탭한 순간의 값이 점수가 된다 (골프 힘게이지 느낌).
///
/// 애니메이션의 소유자는 화면 쪽이고, 이 위젯은 [value](0.0~1.0)만 받아
/// 클로버 채움 + 실시간 숫자를 그린다.
class LuckGauge extends StatelessWidget {
  final double value; // 0.0 ~ 1.0 (표시값 = 0~100)
  final double size;

  const LuckGauge({super.key, required this.value, this.size = 240});

  int get score => (value * 100).round().clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    // 숫자·채움이 모두 같은 v에서 나온다 — 표시 싱크의 단일 소스.
    final v = value.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 실시간 숫자 — 100에 가까워질수록 검정에서 클로버 그린으로 물든다.
        Text(
          '$score',
          style: AppText.base(
            size: 64,
            weight: FontWeight.w800,
            letterSpacingEm: -0.04,
            color: luckColor(v),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _GaugeCloverPainter(v)),
        ),
      ],
    );
  }
}

/// 행운지수 숫자 색 — 0이면 검정, 100에 가까울수록 클로버 그린.
/// (클로버 채움색은 항상 accent 고정 — 색이 아니라 "얼마나 찼는가"로 읽힌다)
Color luckColor(double v) =>
    Color.lerp(AppColors.title, AppColors.accent, v.clamp(0.0, 1.0))!;

/// 4잎을 하나로 합친 클로버 path (viewBox 120 기준) — 채움 클립의 기준 도형.
final Path _cloverPath = _buildCloverPath();
final Rect _cloverBounds = _cloverPath.getBounds();

Path _buildCloverPath() {
  final heart = heartPath();
  final path = Path();
  const sc = 1.8;
  for (final a in kLeafAngles) {
    final m = Matrix4.identity()
      ..translateByDouble(60.0, 58.0, 0.0, 1.0)
      ..rotateZ(a * math.pi / 180)
      ..translateByDouble(0.0, 0.5, 0.0, 1.0)
      ..scaleByDouble(sc * 0.92, sc * 1.12, 1.0, 1.0)
      ..translateByDouble(-12.0, -21.35, 0.0, 1.0);
    path.addPath(heart.transform(m.storage), Offset.zero);
  }
  return path;
}

/// 회색 클로버 위에 색 클로버가 아래→위로 차오른다.
/// 채움 높이는 위젯 박스가 아니라 **클로버 실제 경계**를 기준으로 계산한다.
/// (박스 기준으로 자르면 여백 때문에 숫자와 눈에 보이는 채움량이 어긋난다.)
class _GaugeCloverPainter extends CustomPainter {
  final double value;
  _GaugeCloverPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    canvas.save();
    canvas.scale(s, s);

    final paint = Paint()..isAntiAlias = true;

    // 바탕: 빈 클로버.
    canvas.drawPath(_cloverPath, paint..color = AppColors.emptyLeaf);

    // 채움: 클로버 bounds 안에서 value 비율만큼.
    final b = _cloverBounds;
    final fillTop = b.bottom - b.height * value;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(b.left - 1, fillTop, b.right + 1, b.bottom + 1));
    canvas.drawPath(_cloverPath, paint..color = AppColors.accent);
    canvas.restore();

    // 수면선 — 채움 경계에 옅은 하이라이트로 "차오르는" 느낌. 클로버 안쪽만.
    if (value > 0.02 && value < 0.98) {
      canvas.save();
      canvas.clipPath(_cloverPath);
      canvas.drawLine(
        Offset(b.left, fillTop),
        Offset(b.right, fillTop),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 2 / s
          ..isAntiAlias = true,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugeCloverPainter old) => old.value != value;
}
