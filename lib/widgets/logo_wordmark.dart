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

  /// 700(상한)은 o·u·c·y 의 속공간이 메워져 글자가 뭉쳐 보인다.
  /// 한 단계 낮춰 속공간을 열어 두는 쪽이 로고로 더 또렷하다.
  static const weight = 600.0;

  /// 둥근 서체라 자간이 좁으면 글자끼리 붙어 보인다. 살짝 벌려 숨을 준다.
  static const trackingRatio = 0.080;

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
    return Transform.translate(
      // 자간은 마지막 글자 뒤에도 붙어 글자 덩어리가 왼쪽으로 치우친다. 절반만큼 되민다.
      offset: Offset(size * trackingRatio / 2, 0),
      child: Text(text, style: style(size).copyWith(color: color)),
    );
  }
}
