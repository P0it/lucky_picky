import 'package:flutter/material.dart';

import '../config/luck_tickets.dart';

/// 오로라 글래스 표면을 이루는 색 덩어리 하나.
/// CSS `radial-gradient(<radius> at <center>)` 을 그대로 옮긴 것 —
/// 여러 개를 겹쳐 이음새 없는 오로라(홀로그램) 면을 만든다.
class AuroraBlob {
  final Color color; // 덩어리 중심색 (가장자리로 갈수록 투명)
  final Alignment center; // 카드 안 위치 (-1..1)
  final double radius; // 짧은 변 대비 반지름 배율

  const AuroraBlob(this.color, this.center, this.radius);
}

/// 등급별 시각 아이덴티티 — 밝은 파스텔 오로라 글래스.
/// 흰 배경 앱에 맞춰 카드 면은 밝은 파스텔 베이스([panel]) 위에
/// 오로라 색 덩어리([blobs])를 겹쳐 이리데센스를 낸다.
/// 등급이 오를수록 색이 달아오른다:
///   노멀   = 푸른
///   레어   = 보라
///   유니크 = 핑크
///   레전드 = 황금
///   미스틱 = 풀 레인보우
class RarityStyle {
  final Color color; // 포인트(칩/등급명/점) — 흰 배경에서도 읽히는 채도
  final Color soft; // 연한 배경 틴트 (확률표 행·최대강화 버튼 등)
  final List<Color> panel; // 카드면 베이스 그라데이션 (2 스톱 파스텔)
  final List<AuroraBlob> blobs; // 카드면 오로라 덩어리
  final Gradient? aura; // 등급 점 전용 무지개 (미스틱만; 없으면 단색)

  const RarityStyle({
    required this.color,
    required this.soft,
    required this.panel,
    this.blobs = const [],
    this.aura,
  });

  static RarityStyle of(Rarity r) => _styles[r]!;

  /// 커스텀 행운권 전용 — 등급이 없는 카드라 등급 램프 바깥에 둔다.
  /// 다섯 등급이 모두 오로라인 데 반해 이것만 종이(아이보리) 면에
  /// 클로버 그린 포인트다. 한눈에 "뽑은 게 아니라 쓴 것"으로 읽힌다.
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
      blobs: [
        AuroraBlob(Color(0x9978C3FF), Alignment(-0.56, -0.64), 0.95),
        AuroraBlob(Color(0x80A0AFFF), Alignment(0.68, -0.40), 0.90),
        AuroraBlob(Color(0x6B8CF0E1), Alignment(0.20, 0.88), 1.05),
      ],
    ),
    // 레어 — 보라.
    Rarity.rare: RarityStyle(
      color: Color(0xFF7D5FE0),
      soft: Color(0x1A7D5FE0),
      panel: [Color(0xFFF2ECFF), Color(0xFFE0D3FB)],
      blobs: [
        AuroraBlob(Color(0x99BE9BFF), Alignment(-0.56, -0.64), 0.95),
        AuroraBlob(Color(0x80A096FA), Alignment(0.68, -0.40), 0.90),
        AuroraBlob(Color(0x6B96AFFF), Alignment(0.20, 0.88), 1.05),
      ],
    ),
    // 유니크 — 핑크.
    Rarity.epic: RarityStyle(
      color: Color(0xFFE05FA0),
      soft: Color(0x1AE05FA0),
      panel: [Color(0xFFFFEDF6), Color(0xFFFBD8EC)],
      blobs: [
        AuroraBlob(Color(0x9EFFA5D7), Alignment(-0.56, -0.64), 0.95),
        AuroraBlob(Color(0x85FF96B4), Alignment(0.68, -0.40), 0.90),
        AuroraBlob(Color(0x6BF5A0F0), Alignment(0.20, 0.88), 1.05),
      ],
    ),
    // 레전드 — 황금.
    Rarity.legendary: RarityStyle(
      color: Color(0xFFE3A52C),
      soft: Color(0x1AE3A52C),
      panel: [Color(0xFFFFF6DC), Color(0xFFFCE7B6)],
      blobs: [
        AuroraBlob(Color(0xB8FFE896), Alignment(-0.52, -0.64), 0.98),
        AuroraBlob(Color(0x99FFD06E), Alignment(0.68, -0.36), 0.90),
        AuroraBlob(Color(0x6BFFB48C), Alignment(0.24, 0.88), 1.05),
      ],
    ),
    // 미스틱 — 풀 레인보우.
    Rarity.mythic: RarityStyle(
      color: Color(0xFFB06FD8),
      soft: Color(0x1AB06FD8),
      panel: [Color(0xFFF6F0FF), Color(0xFFEAE2FB)],
      blobs: [
        AuroraBlob(Color(0x94FFAABE), Alignment(-0.64, -0.68), 0.85),
        AuroraBlob(Color(0x8AFFE496), Alignment(0.60, -0.60), 0.82),
        AuroraBlob(Color(0x8AAFFAC3), Alignment(0.76, 0.24), 0.85),
        AuroraBlob(Color(0x8FA0D7FF), Alignment(-0.44, 0.56), 0.85),
        AuroraBlob(Color(0x8AD2AAFF), Alignment(0.20, 0.92), 0.82),
      ],
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
