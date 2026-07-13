import 'dart:ui';

import '../models/daily_fortune.dart';
import 'fortune_copy.dart';

// ════════════════════════════════════════════════════════════════
//  오늘의 행운지수 — 행운의 색/숫자/아이템 풀 + 조회 진입점.
//
//  총운·조언 "문구"는 fortune_copy.dart 에 있다. 문구는 서버로 동기화되는
//  대상이라(tool/sync_copy.dart) Flutter(dart:ui) 없이 읽혀야 하는데,
//  이 파일은 색(Color) 때문에 dart:ui 에 묶여 있어서 분리했다.
//
//  (동아시아권 금기로 숫자 4는 행운의 숫자 후보에서 제외 — daily_fortune.dart)
// ════════════════════════════════════════════════════════════════

/// 행운의 색 — 스와치 색상 + 언어별 이름.
class FortuneLuckyColor {
  final Color color;
  final Map<String, String> names;
  const FortuneLuckyColor(this.color, this.names);

  String name(String lang) => names[lang] ?? names[FortunePool.fallbackLang]!;
}

class FortunePool {
  const FortunePool._();

  static const fallbackLang = 'en';

  // ── 행운의 색 (스와치 + 이름) ──────────────────────────────────
  // "빨주노초" 같은 기본색 나열 대신, 이름만 들어도 그림이 그려지는 색으로.
  // 이름과 실제 스와치가 반드시 일치해야 한다 (노랑인데 주황빛 = 신뢰 깨짐).
  static const List<FortuneLuckyColor> luckyColors = [
    FortuneLuckyColor(
        Color(0xFF2F5FE0), {'ko': '코발트 블루', 'en': 'Cobalt Blue', 'ja': 'コバルトブルー'}),
    FortuneLuckyColor(
        Color(0xFFFF3E9D), {'ko': '핫핑크', 'en': 'Hot Pink', 'ja': 'ホットピンク'}),
    FortuneLuckyColor(
        Color(0xFF15C7C0), {'ko': '터콰이즈', 'en': 'Turquoise', 'ja': 'ターコイズ'}),
    FortuneLuckyColor(
        Color(0xFF8B5CF6), {'ko': '바이올렛', 'en': 'Violet', 'ja': 'バイオレット'}),
    FortuneLuckyColor(
        Color(0xFFFF7A2F), {'ko': '탠저린', 'en': 'Tangerine', 'ja': 'タンジェリン'}),
    FortuneLuckyColor(
        Color(0xFFFFDD33), {'ko': '레몬 옐로', 'en': 'Lemon Yellow', 'ja': 'レモンイエロー'}),
    FortuneLuckyColor(
        Color(0xFF6FC143), {'ko': '클로버 그린', 'en': 'Clover Green', 'ja': 'クローバーグリーン'}),
    FortuneLuckyColor(
        Color(0xFFB8E986), {'ko': '라임', 'en': 'Lime', 'ja': 'ライム'}),
    FortuneLuckyColor(
        Color(0xFF1F3A93), {'ko': '네이비', 'en': 'Navy', 'ja': 'ネイビー'}),
    FortuneLuckyColor(
        Color(0xFFE8467C), {'ko': '라즈베리', 'en': 'Raspberry', 'ja': 'ラズベリー'}),
    FortuneLuckyColor(
        Color(0xFF00B4D8), {'ko': '아쿠아', 'en': 'Aqua', 'ja': 'アクア'}),
    FortuneLuckyColor(
        Color(0xFFC59B2E), {'ko': '머스터드', 'en': 'Mustard', 'ja': 'マスタード'}),
    FortuneLuckyColor(
        Color(0xFFFF6B6B), {'ko': '코랄', 'en': 'Coral', 'ja': 'コーラル'}),
    FortuneLuckyColor(
        Color(0xFF9C8BDB), {'ko': '라벤더', 'en': 'Lavender', 'ja': 'ラベンダー'}),
    FortuneLuckyColor(
        Color(0xFF2E3A45), {'ko': '차콜', 'en': 'Charcoal', 'ja': 'チャコール'}),
  ];

  // ── 행운의 아이템 ──────────────────────────────────────────────
  static const Map<String, List<String>> _itemsByLang = {
    'ko': [
      '초록색 펜', '클로버 스티커', '따뜻한 아메리카노', '이어폰',
      '동전 지갑', '손수건', '초콜릿', '우산',
      '에코백', '포스트잇', '립밤', '텀블러',
    ],
    'en': [
      'a green pen', 'a clover sticker', 'a warm coffee', 'earphones',
      'a coin purse', 'a handkerchief', 'chocolate', 'an umbrella',
      'a tote bag', 'sticky notes', 'lip balm', 'a tumbler',
    ],
    'ja': [
      '緑のペン', 'クローバーのシール', 'あったかいコーヒー', 'イヤホン',
      '小銭入れ', 'ハンカチ', 'チョコレート', '傘',
      'エコバッグ', '付箋', 'リップクリーム', 'タンブラー',
    ],
  };

  // ── 조회 (풀 길이로 modulo — 언어별 개수가 달라도 안전) ────────
  static String overall(String lang, DailyFortune f) {
    final list = FortuneCopy.overallPool(lang, f.grade);
    return list[f.overallRoll % list.length];
  }

  static String advice(String lang, DailyFortune f) {
    final list = FortuneCopy.advicePool(lang);
    return list[f.adviceRoll % list.length];
  }

  static FortuneLuckyColor luckyColor(DailyFortune f) =>
      luckyColors[f.colorRoll % luckyColors.length];

  static String item(String lang, DailyFortune f) {
    final list = _itemsByLang[lang] ?? _itemsByLang[fallbackLang]!;
    return list[f.itemRoll % list.length];
  }
}
