import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Lucky Picky" 워드마크 — 둥근 팝 계열(Fredoka)에 단색.
///
/// 클로버 일러스트와 같은 결로 맞춘다: 그림자·윤곽·광택 없이 면 하나.
/// 스플래시 PNG(test/export_brand_assets_test.dart)와 같은 사양을 쓰므로,
/// 값을 바꾸면 PNG 도 함께 재생성해야 두 화면이 어긋나지 않는다.
class LogoWordmark extends StatelessWidget {
  static const text = 'Lucky Picky';
  static const family = 'Fredoka';
  static const weight = 700.0;

  /// Fredoka 의 wght 축 상한이 700 이라 가변 축만으로는 더 굵어지지 않는다.
  /// 같은 색 외곽선을 덧대 글자를 균일하게 부풀린다(페이크 볼드).
  static const boldenRatio = 0.055;

  /// 페이크 볼드가 글자를 양옆으로 [boldenRatio]/2 씩 부풀려 그만큼 자간을 먹는다.
  /// 그 몫을 되돌리고(= boldenRatio) 가독성을 위해 조금 더 벌린다.
  static const trackingRatio = boldenRatio + 0.035;

  static TextStyle style(double size) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontVariations: const [FontVariation('wght', weight)],
        letterSpacing: size * trackingRatio,
      );

  final double size;
  final Color color;
  const LogoWordmark({super.key, this.size = 34, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) {
    final base = style(size);
    return Transform.translate(
      // 자간은 마지막 글자 뒤에도 붙어 글자 덩어리가 왼쪽으로 치우친다. 절반만큼 되민다.
      offset: Offset(size * trackingRatio / 2, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * boldenRatio
                ..strokeJoin = StrokeJoin.round
                ..color = color,
            ),
          ),
          Text(text, style: base.copyWith(color: color)),
        ],
      ),
    );
  }
}
