import 'package:flutter/material.dart';

import '../config/luck_tickets.dart';

/// 등급별 시각 아이덴티티 — 노멀부터 그린 클로버 톤으로 시작해,
/// 등급이 오를수록 유리·홀로그램처럼 화려해지는 램프.
///   노멀   = 클로버 그린 (브랜드 기본색)
///   레어   = 하늘빛 글래스
///   유니크 = 바이올렛 → 핑크 오로라
///   레전드 = 골드 시머
///   미스틱 = 파스텔 홀로그램 무지개
class RarityStyle {
  final Color color; // 포인트(칩/테두리/글자)
  final Color soft; // 연한 배경
  final List<Color> panel; // 티켓 스텁 그라데이션 (다중 스톱 = 홀로 느낌)
  final Gradient? aura; // 상위 등급 전용 광채 (null 이면 단색)

  const RarityStyle({
    required this.color,
    required this.soft,
    required this.panel,
    this.aura,
  });

  static RarityStyle of(Rarity r) => _styles[r]!;

  static const _styles = <Rarity, RarityStyle>{
    // 노멀 — 클로버 그린. 시작 등급부터 브랜드색이라 투박하지 않다.
    Rarity.common: RarityStyle(
      color: Color(0xFF5CA834),
      soft: Color(0x1A6FC143),
      panel: [Color(0xFFEAF7DB), Color(0xFFCDEAAD)],
    ),
    // 레어 — 하늘빛 글래스.
    Rarity.rare: RarityStyle(
      color: Color(0xFF3E97D8),
      soft: Color(0x1A4FA8E8),
      panel: [Color(0xFFE3F2FD), Color(0xFFB9DCF8)],
    ),
    // 유니크 — 바이올렛에서 핑크로 흐르는 오로라 유리.
    Rarity.epic: RarityStyle(
      color: Color(0xFF7B6FDE),
      soft: Color(0x1A7B6FDE),
      panel: [Color(0xFFE9E3FC), Color(0xFFCFC3F5), Color(0xFFEDD1EE)],
      aura: LinearGradient(
        colors: [Color(0xFF9A8CF0), Color(0xFFE0A5E4), Color(0xFF7B6FDE)],
      ),
    ),
    // 레전드 — 골드 시머.
    Rarity.legendary: RarityStyle(
      color: Color(0xFFD79A22),
      soft: Color(0x1AE0A32E),
      panel: [Color(0xFFFCF0C8), Color(0xFFF2DA8E), Color(0xFFFAEBBB)],
      aura: LinearGradient(
        colors: [Color(0xFFE8C05A), Color(0xFFFAF0B5), Color(0xFFD79A22)],
      ),
    ),
    // 미스틱 — 파스텔 홀로그램 무지개.
    Rarity.mythic: RarityStyle(
      color: Color(0xFFE06FA8),
      soft: Color(0x1AE06FA8),
      panel: [
        Color(0xFFF9D3E5),
        Color(0xFFFBEDBC),
        Color(0xFFC9ECD1),
        Color(0xFFC5DFF9),
        Color(0xFFDECDF5),
      ],
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
