import 'package:flutter/material.dart';

/// Design tokens lifted directly from the Clover.dc.html mockup.
/// All visuals are custom — Material's default look is suppressed.
class AppColors {
  static const accent = Color(0xFF6FC143); // 포인트 그린
  static const accentSoft = Color(0x1A6FC143); // rgba(111,193,67,.10)

  static const bg = Color(0xFFEAEDF1); // 회색 캔버스
  static const card = Color(0xFFF2F4F6); // 면 분할 카드
  static const white = Color(0xFFFFFFFF);

  static const title = Color(0xFF191F28); // 메인 타이틀
  static const sub = Color(0xFF4E5968); // 서브 가이드
  static const muted = Color(0xFF8B95A1); // 비활성/설명
  static const disabled = Color(0xFFB0B8C1);

  static const border = Color(0xFFEDEFF2);
  static const borderSoft = Color(0xFFEEF0F2);
  static const divider = Color(0xFFE5E8EB);

  static const emptyLeaf = Color(0xFFE6E9ED);
  static const emptyStem = Color(0xFFE1E5EA);
  static const dashed = Color(0xFFCDD2D9);

  // 뽑기 코인 — 클로버 그린과 확실히 구분되는 금색. 클로버 각인은 넣지 않는다.
  static const coin = Color(0xFFFFD54F);
  static const coinEdge = Color(0xFFE0A32E);

  static const crack = Color(0xFF3A3A3A); // 강화 실패 균열선
  static const shard = Color(0xFF9AA0A6); // 강화 실패 파편

  static const toast = Color(0xEC191F28); // rgba(25,31,40,.93)
  static const backdrop = Color(0x73191F28); // rgba(25,31,40,.45)

  // 카드 그림자 — 테두리 대신 "떠 있는 종이"로 면을 분리한다.
  static const cardShadow = Color(0x14191F28); // rgba(25,31,40,.08)
  static const cardShadowSoft = Color(0x0D191F28); // rgba(25,31,40,.05)
}

class AppRadius {
  static const sheet = 28.0;
  static const button = 18.0;
  static const card = 20.0;
  static const chipFull = 9999.0;
}

/// Text styles matching the mockup's font-size / weight / letter-spacing.
class AppText {
  static const _f = 'Pretendard';

  static TextStyle base({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.title,
    double letterSpacingEm = -0.02,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _f,
      fontSize: size,
      fontWeight: weight,
      color: color,
      // letter-spacing in em → px ≈ em * fontSize
      letterSpacing: letterSpacingEm * size,
      height: height,
    );
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.white,
    ),
    // Kill the "Google" look: no ripple, no highlight.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Pretendard',
      bodyColor: AppColors.title,
      displayColor: AppColors.title,
    ),
  );
}
