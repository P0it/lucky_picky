import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 캡슐 머신(가챠폰) 일러스트 — 플랫 스타일 CustomPaint.
///
/// 애니메이션 파라미터(0~1)를 밖에서 넘겨 단계별 연출을 만든다.
/// - [coinT]  : 코인이 투입구로 들어가는 진행도
/// - [leverT] : 레버(다이얼)가 한 바퀴 도는 진행도 — 돔 속 더미가 뒤섞인다
/// - [dropT]  : 뽑힌 캡슐이 더미 → 목 링 → 슈트 → 배출구로 내려가는 진행도
/// - [openT]  : 기계 앞에 멈춘 캡슐이 위아래 두 쪽으로 갈라지는 진행도
/// - [capsuleColor] : 뽑힌 캡슐 윗면 색 (등급색)
class GachaMachine extends StatelessWidget {
  final double coinT;
  final double leverT;
  final double dropT;
  final double openT;
  final Color capsuleColor;

  const GachaMachine({
    super.key,
    this.coinT = 0,
    this.leverT = 0,
    this.dropT = 0,
    this.openT = 0,
    this.capsuleColor = AppColors.accent,
  });

  /// 논리 캔버스 크기. 아래 여백은 기계 앞으로 튀어나온 캡슐이 구르는 자리다.
  static const Size canvas = Size(300, 442);

  /// 배출구를 빠져나와 기계 앞에 멈춘 캡슐의 중심 (논리 좌표).
  /// 앞으로 나온 만큼 크게 그린다 — 가까이 있다는 신호.
  static const Offset droppedCapsuleCenter = Offset(150, 402);
  static const double droppedCapsuleRadius = 30;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: canvas.width / canvas.height,
      child: CustomPaint(
        painter: _MachinePainter(
          coinT: coinT,
          leverT: leverT,
          dropT: dropT,
          openT: openT,
          capsuleColor: capsuleColor,
        ),
      ),
    );
  }
}

/// 돔 안에 쌓인 캡슐 한 알.
class _PileCapsule {
  final Offset pos; // 논리 좌표(캔버스 기준)
  final double radius;
  final double angle; // 분할선 기울기 (rad)
  final Color color;
  final double phase; // 흔들림 위상 — 더미가 한 몸처럼 움직이지 않게
  const _PileCapsule(this.pos, this.radius, this.angle, this.color, this.phase);
}

class _MachinePainter extends CustomPainter {
  final double coinT;
  final double leverT;
  final double dropT;
  final double openT;
  final Color capsuleColor;

  _MachinePainter({
    required this.coinT,
    required this.leverT,
    required this.dropT,
    required this.openT,
    required this.capsuleColor,
  });

  static const _domeCenter = Offset(150, 118);
  static const _domeRadius = 102.0;

  static const _green = Color(0xFF6FC143);

  /// 더미 색 — 클로버 앱이니 그린이 다수를 차지하고 나머지는 악센트로 섞인다.
  static const _pileColors = [
    _green, _green, _green,
    Color(0xFF7B6FDE), // 퍼플
    Color(0xFFE0A32E), // 골드
    Color(0xFFE06FA8), // 핑크
    Color(0xFF57A8E0), // 블루
  ];

  /// 돔 바닥에 쌓인 캡슐 더미. 시드 고정이라 매번 같은 모양 — 정물처럼 안정적이다.
  ///
  /// 아래 행은 빽빽하게, 위 행은 성기게 채워서 "부어놓은 무더기" 실루엣을 만든다.
  static final List<_PileCapsule> _pile = _buildPile();

  /// 더미에서 뽑혀 나가는 캡슐 — 맨 위(가장 y가 작은) 알을 고른다.
  static final int _pulledIndex = () {
    var best = 0;
    for (var i = 1; i < _pile.length; i++) {
      if (_pile[i].pos.dy < _pile[best].pos.dy) best = i;
    }
    return best;
  }();

  static List<_PileCapsule> _buildPile() {
    // 결정적 LCG — dart:math의 Random(seed)와 달리 플랫폼 간에도 동일하다.
    var seed = 20260713;
    double rnd() {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      return seed / 0x7FFFFFFF;
    }

    const r = 14.5; // 볼 기본 반지름
    const wall = _domeRadius - 5; // 유리 안쪽 면
    const bottom = 202.0; // 목 링 위 = 더미가 얹히는 바닥
    const stepX = r * 1.78; // 살짝 겹치는 육각 격자
    const stepY = r * 1.58;

    /// 무더기 표면 — 가운데가 봉긋하고 가장자리로 흘러내리는 곡선.
    /// 이 아래의 격자점만 볼로 채우므로 바닥은 반드시 꽉 찬다.
    double surfaceY(double x) {
      final k = (x - _domeCenter.dx) / wall; // -1..1
      return 96 + 52 * k * k;
    }

    final out = <_PileCapsule>[];
    var rowIndex = 0;
    for (var y = bottom; y > 60; y -= stepY, rowIndex++) {
      final offset = rowIndex.isEven ? 0.0 : stepX / 2; // 육각 엇갈림
      for (var x = _domeCenter.dx - wall + offset;
          x <= _domeCenter.dx + wall;
          x += stepX) {
        final jx = x + (rnd() - 0.5) * 4;
        final jy = y + (rnd() - 0.5) * 4;
        final p = Offset(jx, jy);

        // 유리 밖으로 나가는 볼은 버린다.
        if ((p - _domeCenter).distance + r * 0.92 > wall) continue;

        // 표면 위쪽은 빈 공간. 표면 근처는 듬성듬성 남겨 능선을 울퉁불퉁하게.
        final surface = surfaceY(jx);
        if (jy < surface) continue;
        if (jy < surface + r && rnd() < 0.45) continue;

        out.add(_PileCapsule(
          p,
          r + (rnd() - 0.5) * 2.2,
          (rnd() - 0.5) * 0.9, // 하이라이트 각이 제각각 — 정렬감이 사라진다
          _pileColors[(rnd() * _pileColors.length).floor() % _pileColors.length],
          rnd() * math.pi * 2,
        ));
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / GachaMachine.canvas.width;
    canvas.scale(sx, sx);

    _drawBody(canvas);
    _drawDome(canvas); // 유리 안에서 빠져나가는 캡슐도 여기서(돔 클립 안에서) 그린다
    _drawFace(canvas);
    if (coinT > 0 && coinT < 1) _drawCoin(canvas);
    // 몸통 속(_suckEnd~_exitStart)에서는 캡슐이 보이면 안 된다 — 기계를 관통해 보인다.
    if (dropT >= _exitStart) _drawEjectedCapsule(canvas);
  }

  // 낙하 구간: 더미→목(빨려 들어감) / 목→배출구(몸통 속, 안 보임) / 배출구→기계 앞(튀어나옴).
  static const _suckEnd = 0.26;
  static const _exitStart = 0.6;

  void _drawBody(Canvas canvas) {
    // 본체 — 포인트 그린, 아래로 갈수록 진한 발판.
    final body = RRect.fromRectAndCorners(
      const Rect.fromLTRB(48, 208, 252, 372),
      topLeft: const Radius.circular(26),
      topRight: const Radius.circular(26),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.accent);
    // 본체 하이라이트 면 분할.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTRB(48, 208, 96, 372),
        topLeft: const Radius.circular(26),
        bottomLeft: const Radius.circular(20),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    // 받침.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(38, 366, 262, 386), const Radius.circular(10)),
      Paint()..color = const Color(0xFF57993A),
    );
  }


  void _drawDome(Canvas canvas) {
    // 유리 돔.
    canvas.drawCircle(_domeCenter, _domeRadius, Paint()..color = Colors.white);
    canvas.drawCircle(_domeCenter, _domeRadius,
        Paint()..color = const Color(0xFFF2F4F6).withValues(alpha: 0.6));

    // 더미는 유리 안쪽으로 클립 — 가장자리 알이 유리에 눌린 것처럼 보인다.
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: _domeCenter, radius: _domeRadius - 3)));
    _drawPile(canvas);
    if (dropT > 0 && dropT < _suckEnd) _drawSuckedCapsule(canvas);
    canvas.restore();

    // 유리 반사광.
    canvas.drawCircle(
        _domeCenter, _domeRadius, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final gloss = Path()
      ..addArc(
          Rect.fromCircle(center: _domeCenter, radius: _domeRadius - 14), -2.4, 0.9);
    canvas.drawPath(
      gloss,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    // 돔 테두리 + 목 링.
    canvas.drawCircle(
      _domeCenter,
      _domeRadius,
      Paint()
        ..color = const Color(0xFFDDE3E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(72, 196, 228, 216), const Radius.circular(10)),
      Paint()..color = const Color(0xFF57993A),
    );
  }

  void _drawPile(Canvas canvas) {
    // 레버를 돌리는 동안만 더미가 뒤섞인다. 알마다 위상이 달라 한 몸으로 흔들리지 않는다.
    final churning = leverT > 0 && leverT < 1;
    // 시작/끝에서 부드럽게 붙었다 떨어지도록 강도를 감쌌다.
    final energy = churning ? math.sin(leverT * math.pi) : 0.0;
    // 캡슐 하나가 빠져나가면 더미가 그만큼 내려앉는다.
    final settle = Curves.easeOut.transform(dropT.clamp(0.0, 1.0)) * 3;

    // 뒤(위층) → 앞(아래층) 순서. 앞쪽 볼이 뒤쪽을 덮어야 쌓인 깊이가 보인다.
    for (var i = _pile.length - 1; i >= 0; i--) {
      if (i == _pulledIndex && dropT > 0) continue; // 뽑힌 알은 더미에서 빠진다
      final cap = _pile[i];
      // 위쪽 알일수록 크게 요동친다 (아래는 눌려 있다).
      final depth = ((200 - cap.pos.dy) / 105).clamp(0.0, 1.0);
      final amp = energy * (2 + depth * 7);
      final wobble = Offset(
        math.sin(leverT * math.pi * 6 + cap.phase) * amp,
        math.cos(leverT * math.pi * 5 + cap.phase * 1.7) * amp * 0.7,
      );
      final angle =
          cap.angle + math.sin(leverT * math.pi * 4 + cap.phase) * energy * 0.5;

      _drawCapsule(
        canvas,
        cap.pos + wobble + Offset(0, settle * depth),
        cap.radius,
        cap.color,
        angle: angle,
        contactShadow: true,
      );
    }
  }

  void _drawFace(Canvas canvas) {
    // 레버(다이얼) — leverT 로 회전.
    const knobC = Offset(112, 262);
    canvas.drawCircle(knobC, 30, Paint()..color = Colors.white);
    canvas.drawCircle(
      knobC,
      30,
      Paint()
        ..color = const Color(0xFF57993A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.save();
    canvas.translate(knobC.dx, knobC.dy);
    canvas.rotate(leverT * math.pi * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-24, -6, 24, 6), const Radius.circular(6)),
      Paint()..color = AppColors.accent,
    );
    canvas.restore();
    canvas.drawCircle(knobC, 6, Paint()..color = const Color(0xFF57993A));

    // 코인 투입구.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(166, 236, 214, 252), const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(182, 240, 198, 248), const Radius.circular(4)),
      Paint()..color = const Color(0xFF57993A),
    );

    // 배출구.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(164, 296, 230, 356), const Radius.circular(16)),
      Paint()..color = const Color(0xFF4A8230),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(170, 302, 224, 350), const Radius.circular(12)),
      Paint()..color = const Color(0xFF3C6B27),
    );
  }

  void _drawCoin(Canvas canvas) {
    // 코인이 위에서 투입구로 떨어지며 사라진다. 무늬는 넣지 않는다 —
    // 클로버를 각인하면 선행의 클로버와 광고의 코인이 다시 헷갈린다.
    final t = Curves.easeIn.transform(coinT);
    final pos = Offset.lerp(const Offset(190, 190), const Offset(190, 244), t)!;
    final opacity = (1 - t * 0.65).clamp(0.0, 1.0);
    final r = 13 * (1 - t * 0.35);

    // 가장자리 톱니 — 떨어지는 동안 주화의 무게감을 준다.
    final ridge = Paint()
      ..color = AppColors.coinEdge.withValues(alpha: opacity)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(pos + d * (r * 0.86), pos + d * r, ridge);
    }

    canvas.drawCircle(
        pos, r * 0.86, Paint()..color = AppColors.coin.withValues(alpha: opacity));
    canvas.drawCircle(
      pos,
      r * 0.86,
      Paint()
        ..color = AppColors.coinEdge.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 더미에서 빠져나와 목 링으로 빨려 들어가는 구간(0~_suckEnd).
  /// 유리 안에서 벌어지는 일이라 돔 클립 안에서 그린다.
  void _drawSuckedCapsule(Canvas canvas) {
    final from = _pile[_pulledIndex];
    const neck = Offset(150, 214);
    final k = Curves.easeIn.transform((dropT / _suckEnd).clamp(0.0, 1.0));
    _drawCapsule(
      canvas,
      Offset.lerp(from.pos, neck, k)!,
      from.radius * (1 - k * 0.15), // 목으로 갈수록 작아진다 — 관 속으로 들어가는 원근
      capsuleColor,
      angle: from.angle + k * 1.2,
    );
  }

  /// 배출구 밖으로 튀어나와 기계 앞까지 통통 굴러오는 구간(_exitStart~1).
  void _drawEjectedCapsule(Canvas canvas) {
    final from = _pile[_pulledIndex];
    const mouth = Offset(197, 320); // 배출구 입구 — 여기서 튀어나온다
    const rest = GachaMachine.droppedCapsuleCenter;

    final k = ((dropT - _exitStart) / (1 - _exitStart)).clamp(0.0, 1.0);
    final x = mouth.dx + (rest.dx - mouth.dx) * Curves.easeOut.transform(k);
    final ground = mouth.dy + (rest.dy - mouth.dy) * Curves.easeIn.transform(k);
    // 세 번 튀며 진폭이 죽는다 — bounceOut 한 방보다 "통통" 하는 리듬이 산다.
    final hop = math.sin(k * math.pi * 3).abs() * 34 * (1 - k) * (1 - k);
    final r = from.radius * 0.85 +
        (GachaMachine.droppedCapsuleRadius - from.radius * 0.85) *
            Curves.easeOut.transform(k);

    // 바닥 그림자 — 튀어오를수록 옅고 작아진다.
    final lift = (hop / 34).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, rest.dy + r * 0.85),
        width: r * (1.7 - lift * 0.5),
        height: r * (0.5 - lift * 0.15),
      ),
      Paint()
        ..color =
            const Color(0xFF8B95A1).withValues(alpha: 0.22 * (1 - lift * 0.6) * k),
    );

    final center = Offset(x, ground - hop);
    final angle = from.angle + 3.6 + k * 3.4; // 굴러 나온다

    if (openT > 0) {
      _drawSplitCapsule(canvas, center, r);
      return;
    }

    // 바닥에 닿는 순간마다 눌렸다 펴진다 — 고무공 같은 무게.
    final contact = 1 - (hop / 34).clamp(0.0, 1.0);
    final squash = contact * contact * (1 - k) * 0.9;
    canvas.save();
    canvas.translate(center.dx, center.dy + r);
    canvas.scale(1 + squash * 0.24, 1 - squash * 0.24);
    canvas.translate(-center.dx, -(center.dy + r));
    _drawCapsule(canvas, center, r, capsuleColor, angle: angle, outline: true);
    canvas.restore();
  }

  /// 캡슐이 위아래 두 쪽으로 갈라지며 열린다.
  /// 틈에서 빛이 새어 나오고, 위쪽 뚜껑이 튀어 오르는 동안 아래쪽은 살짝 주저앉는다.
  /// 이음매는 굴러온 각도와 무관하게 수평에 가깝다 — 뚜껑이 열린다는 게 먼저 읽혀야 한다.
  void _drawSplitCapsule(Canvas canvas, Offset c, double r) {
    final t = openT.clamp(0.0, 1.0);
    // 앞부분에 몰리지 않는 감속 — 끝까지 계속 벌어지는 게 보여야 한다.
    final ease = Curves.easeOutQuad.transform(t);
    final fade = 1 - ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    if (fade <= 0) return;

    // 틈에서 새어 나오는 빛 — 흰 배경에 묻히지 않게 등급색 후광을 깐다.
    final flare = math.sin(t * math.pi);
    if (flare > 0.01) {
      canvas.drawCircle(
        c,
        r * (0.6 + ease * 1.2),
        Paint()
          ..color = capsuleColor.withValues(alpha: 0.4 * flare)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        c,
        r * (0.35 + ease * 0.55),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9 * flare)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    const seam = -0.07; // 살짝 기운 이음매 — 정면 대칭은 도장 같아 보인다
    final gap = r * (0.02 + 0.9 * ease);
    // 뚜껑은 옆으로 젖혀지며 살짝 떠오르고, 아래쪽은 조금만 내려앉는다.
    // 뚜껑을 너무 높이 띄우면 기계 몸통에 겹쳐 지저분해진다.
    _drawCapsuleHalf(canvas, c + Offset(-gap * 0.5, -gap * 0.8), r, seam - 0.85 * ease,
        top: true, opacity: fade);
    _drawCapsuleHalf(canvas, c + Offset(gap * 0.2, gap * 0.3), r, seam + 0.2 * ease,
        top: false, opacity: fade);
  }

  /// 갈라진 캡슐 반쪽. 잘린 면에 흰 립을 그려 껍데기 두께가 읽히게 한다.
  void _drawCapsuleHalf(
    Canvas canvas,
    Offset c,
    double r,
    double angle, {
    required bool top,
    required double opacity,
  }) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final half = Path()
      ..addArc(rect, top ? math.pi : 0, math.pi)
      ..close();

    canvas.drawPath(half, Paint()..color = capsuleColor.withValues(alpha: opacity));
    canvas.save();
    canvas.clipPath(half);
    canvas.drawCircle(
      Offset(r * 0.3, r * 0.55),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.09 * opacity),
    );
    if (top) {
      canvas.drawCircle(
        Offset(-r * 0.34, -r * 0.36),
        r * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.7 * opacity),
      );
    }
    canvas.restore();
    // 잘린 면 — 안쪽이 비어 있는 껍데기라는 신호.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-r * 0.97, top ? -3 : 0, r * 0.97, top ? 0 : 3),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92 * opacity),
    );
    canvas.drawPath(
      half,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }


  /// 캡슐은 통색 볼 — 반쪽이 흰색이면 겹쳤을 때 서로 녹아붙어 형태가 안 읽힌다.
  /// [angle]은 하이라이트 위치를 돌려서 굴러가는 느낌을 준다.
  void _drawCapsule(
    Canvas canvas,
    Offset c,
    double r,
    Color color, {
    double angle = 0,
    bool outline = false,
    bool contactShadow = false,
  }) {
    // 겹쳐 쌓인 알들 사이에 무게를 주는 접점 그림자.
    if (contactShadow) {
      canvas.drawCircle(
        c + const Offset(1.5, 2.5),
        r,
        Paint()..color = const Color(0xFF8B95A1).withValues(alpha: 0.13),
      );
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    const zero = Offset.zero;
    canvas.drawCircle(zero, r, Paint()..color = color);
    // 아래쪽에 같은 색 그림자 — 플랫하되 구(球)로 읽히게.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: zero, radius: r)));
    canvas.drawCircle(
      Offset(r * 0.3, r * 0.55),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.09),
    );
    canvas.restore();
    // 하이라이트.
    canvas.drawCircle(Offset(-r * 0.34, -r * 0.36), r * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.7));
    // 이웃한 알과 경계를 세워주는 옅은 테두리.
    canvas.drawCircle(
      zero,
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: outline ? 0.1 : 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline ? 2 : 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MachinePainter old) =>
      old.coinT != coinT ||
      old.leverT != leverT ||
      old.dropT != dropT ||
      old.openT != openT ||
      old.capsuleColor != capsuleColor;
}
