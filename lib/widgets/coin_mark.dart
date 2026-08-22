import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 뽑기 코인 마크 — 금색 원반에 가장자리 톱니.
///
/// 무늬를 넣지 않는다. 클로버를 각인하면 방금 갈라놓은 두 재화(선행의 클로버 /
/// 광고의 코인)가 다시 헷갈린다. 머신 투입구로 떨어지는 코인
/// (`gacha_machine.dart`)과 같은 색을 쓴다.
class CoinMark extends StatelessWidget {
  final double size;

  /// 단색으로 그릴 색 — 비활성 버튼처럼 금색이 어울리지 않는 자리에서 쓴다.
  final Color? color;

  const CoinMark({super.key, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CoinPainter(color)),
    );
  }
}

class _CoinPainter extends CustomPainter {
  final Color? flat;
  _CoinPainter(this.flat);

  /// 가장자리 톱니 개수 — 실제 주화처럼 촘촘하되 작은 크기에서 뭉개지지 않는 선.
  static const _ridges = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final face = flat ?? AppColors.coin;
    final edge = flat ?? AppColors.coinEdge;

    // 톱니 — 원 바깥으로 삐져나오지 않도록 테두리 안쪽에 짧게 긋는다.
    final ridge = Paint()
      ..color = edge
      ..strokeWidth = math.max(1, r * 0.1)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (var i = 0; i < _ridges; i++) {
      final a = i * 2 * math.pi / _ridges;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r * 0.86), c + d * (r * 0.99), ridge);
    }

    canvas.drawCircle(
        c, r * 0.86, Paint()..color = face..isAntiAlias = true);
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.13)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.flat != flat;
}
