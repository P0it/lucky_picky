import 'package:flutter/material.dart';

import '../config/luck_tickets.dart';

/// 등급별 시각 아이덴티티.
/// 카드는 흰 면에 [color] 테두리로만 등급을 말한다([CollectionCard]).
/// [panel] 파스텔 그라데이션은 강화 화면의 선택 행처럼 면을 칠해야 하는
/// 자리에만 남아 있다. 등급이 오를수록 색이 달아오른다:
///   노멀   = 푸른
///   레어   = 보라
///   유니크 = 핑크
///   레전드 = 황금
///   미스틱 = 풀 레인보우
class RarityStyle {
  final Color color; // 포인트(칩/등급명/점) — 흰 배경에서도 읽히는 채도
  final Color soft; // 연한 배경 틴트 (확률표 행·최대강화 버튼 등)
  final List<Color> panel; // 파스텔 면 그라데이션 (강화 화면 선택 행 등)
  final Gradient? aura; // 등급 점 전용 무지개 (미스틱만; 없으면 단색)

  const RarityStyle({
    required this.color,
    required this.soft,
    required this.panel,
    this.aura,
  });

  static RarityStyle of(Rarity r) => _styles[r]!;

  /// 커스텀 행운권 전용 — 등급이 없는 카드라 등급 램프 바깥에 둔다.
  /// 등급 대신 클로버 그린 포인트다 — 한눈에 "뽑은 게 아니라 쓴 것"으로 읽힌다.
  static const custom = RarityStyle(
    color: Color(0xFF4A8230),
    soft: Color(0x1A6FC143),
    panel: [Color(0xFFFFFDF6), Color(0xFFF3F1E6)],
  );

  static const _styles = <Rarity, RarityStyle>{
    // 노멀 — 푸른.
    Rarity.common: RarityStyle(
      color: Color(0xFF2F8FD6),
      soft: Color(0x1A2F8FD6),
      panel: [Color(0xFFEAF5FF), Color(0xFFD2E7FB)],
    ),
    // 레어 — 보라.
    Rarity.rare: RarityStyle(
      color: Color(0xFF7D5FE0),
      soft: Color(0x1A7D5FE0),
      panel: [Color(0xFFF2ECFF), Color(0xFFE0D3FB)],
    ),
    // 유니크 — 핑크.
    Rarity.epic: RarityStyle(
      color: Color(0xFFE05FA0),
      soft: Color(0x1AE05FA0),
      panel: [Color(0xFFFFEDF6), Color(0xFFFBD8EC)],
    ),
    // 레전드 — 황금.
    Rarity.legendary: RarityStyle(
      color: Color(0xFFE3A52C),
      soft: Color(0x1AE3A52C),
      panel: [Color(0xFFFFF6DC), Color(0xFFFCE7B6)],
    ),
    // 미스틱 — 풀 레인보우.
    Rarity.mythic: RarityStyle(
      color: Color(0xFFB06FD8),
      soft: Color(0x1AB06FD8),
      panel: [Color(0xFFF6F0FF), Color(0xFFEAE2FB)],
      aura: LinearGradient(
        colors: [
          Color(0xFFFF8AA0),
          Color(0xFFFFD180),
          Color(0xFFA5D6A7),
          Color(0xFF81D4FA),
          Color(0xFFCE93D8),
          Color(0xFFFF8AA0),
        ],
      ),
    ),
  };
}
