import 'package:flutter/material.dart';

import '../config/luck_tickets.dart';

/// 등급별 시각 아이덴티티 — 그린 클로버 톤을 해치지 않는 절제된 포인트 컬러.
/// 신화 등급만 무지개 그라데이션으로 특별 취급한다.
class RarityStyle {
  final Color color; // 포인트(칩/테두리/글자)
  final Color soft; // 연한 배경
  final List<Color> panel; // 카드 상단 패널 그라데이션
  final Gradient? aura; // 신화 전용 무지개 광 (null 이면 단색)

  const RarityStyle({
    required this.color,
    required this.soft,
    required this.panel,
    this.aura,
  });

  static RarityStyle of(Rarity r) => _styles[r]!;

  static const _styles = <Rarity, RarityStyle>{
    Rarity.common: RarityStyle(
      color: Color(0xFF8B95A1),
      soft: Color(0x148B95A1),
      panel: [Color(0xFFF4F6F8), Color(0xFFE9EDF1)],
    ),
    Rarity.rare: RarityStyle(
      color: Color(0xFF6FC143),
      soft: Color(0x1A6FC143),
      panel: [Color(0xFFF4FBEC), Color(0xFFE7F4D8)],
    ),
    Rarity.epic: RarityStyle(
      color: Color(0xFF7B6FDE),
      soft: Color(0x1A7B6FDE),
      panel: [Color(0xFFF3F1FD), Color(0xFFE6E1FA)],
    ),
    Rarity.legendary: RarityStyle(
      color: Color(0xFFE0A32E),
      soft: Color(0x1AE0A32E),
      panel: [Color(0xFFFdF7E9), Color(0xFFFAEDCB)],
    ),
    Rarity.mythic: RarityStyle(
      color: Color(0xFFE06FA8),
      soft: Color(0x1AE06FA8),
      panel: [Color(0xFFFDF1F7), Color(0xFFF3E6FB)],
      aura: LinearGradient(
        colors: [
          Color(0xFFFF8A80),
          Color(0xFFFFD180),
          Color(0xFFA5D6A7),
          Color(0xFF81D4FA),
          Color(0xFFCE93D8),
          Color(0xFFFF8A80),
        ],
      ),
    ),
  };
}
