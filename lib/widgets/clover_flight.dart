import 'package:flutter/material.dart';

import 'clover_mark.dart';

/// 완성된 클로버가 보유 배지로 빨려 올라가는 연출.
///
/// 경로와 렌더링만 담당한다 — 언제 재생할지, 끝난 뒤 무엇을 할지는 모른다.
/// 부모가 [Positioned.fill] 로 감싸 쓰며, 좌표는 그 부모 기준이다.
class CloverFlight extends StatefulWidget {
  /// 출발/도착 지점 (부모 기준 좌표, 클로버의 중심).
  final Offset from;
  final Offset to;

  /// 출발/도착 시 클로버의 한 변 길이.
  final double fromSize;
  final double toSize;

  /// 착지 시점 — 호출부는 여기서 배지 숫자를 갱신한다.
  final VoidCallback onLanded;

  final Duration duration;

  const CloverFlight({
    super.key,
    required this.from,
    required this.to,
    required this.onLanded,
    this.fromSize = 150,
    this.toSize = 17,
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<CloverFlight> createState() => _CloverFlightState();
}

class _CloverFlightState extends State<CloverFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_landed) {
          _landed = true;
          widget.onLanded();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 솟구쳤다가 배지로 휘어드는 2차 베지어.
  ///
  /// 제어점을 (출발 x, 도착 y) 로 두면 수직으로 올라갔다 옆으로 꺾여, 클로버가
  /// 잠깐 화면 상단 한가운데를 향하는 것처럼 보인다. 목표 쪽으로 3할쯤 당기고
  /// 도착점보다 조금 더 위에 두어, 오르는 내내 배지를 향하면서도 위로 빨려드는
  /// 결을 남긴다.
  Offset _pointAt(double t) {
    final c = Offset(
      widget.from.dx + (widget.to.dx - widget.from.dx) * 0.32,
      widget.to.dy - 48,
    );
    final u = 1 - t;
    return widget.from * (u * u) + c * (2 * u * t) + widget.to * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final p = _pointAt(t);
          final scale = 1 + (widget.toSize / widget.fromSize - 1) * t;
          // 마지막 구간에서만 살짝 지워 배지에 스미도록 한다.
          final opacity = t < 0.82 ? 1.0 : (1 - (t - 0.82) / 0.18).clamp(0.0, 1.0);

          return Stack(
            children: [
              Positioned(
                left: p.dx - widget.fromSize / 2,
                top: p.dy - widget.fromSize / 2,
                width: widget.fromSize,
                height: widget.fromSize,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: 3.4 * t, // 휘리릭 — 클로버가 4겹 대칭이라 넉넉히 돌린다
                    child: Transform.scale(
                      scale: scale,
                      child: CloverMark(size: widget.fromSize, withStem: true),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
