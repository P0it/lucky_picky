import 'package:flutter/widgets.dart';

/// Toss Face 이모지 — Material 기본 아이콘 대신 쓰는 앱 공용 픽토그램.
/// 폰트는 assets/fonts/TossFace.otf (toss/tossface v1.6.1).
abstract final class TossFace {
  static const family = 'TossFace';

  static const recycle = '♻️'; // ♻️ 재조합
  static const star = '⭐'; // ⭐ 강화
  static const clover = '\u{1F340}'; // 🍀 성공 / 브랜드
  static const boom = '\u{1F4A5}'; // 💥 강화 실패
  static const crown = '\u{1F451}'; // 👑 만렙
  static const party = '\u{1F389}'; // 🎉 축하
  static const sparkles = '✨'; // ✨ 등급 상승
}

/// 이모지 한 글자를 아이콘처럼 그린다. 폰트 폴백을 막기 위해 패밀리를 고정한다.
class TossEmoji extends StatelessWidget {
  final String emoji;
  final double size;

  const TossEmoji(this.emoji, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontFamily: TossFace.family,
        fontSize: size,
        height: 1,
      ),
    );
  }
}
