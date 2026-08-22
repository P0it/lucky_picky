import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'clover_mark.dart';

/// 보유 클로버 수 배지. [count] 가 바뀌면 클로버 마크가 통 튀어오른다.
///
/// 언제 새 값을 받을지는 이 위젯이 정하지 않는다 — 비행 연출이 착지할 때까지
/// 이전 값을 붙들고 있는 판단은 호출부(HomeScreen)의 몫이다.
class CloverCountBadge extends StatefulWidget {
  final int count;

  /// 비행 연출의 도착 지점을 재기 위해 클로버 마크에 붙는 키.
  final GlobalKey? markKey;

  const CloverCountBadge({super.key, required this.count, this.markKey});

  @override
  State<CloverCountBadge> createState() => _CloverCountBadgeState();
}

class _CloverCountBadgeState extends State<CloverCountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    // 통~ : 살짝 눌렸다가 크게 튀고 잦아든다.
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 14),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.34), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.34, end: 0.95), weight: 26),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.06), weight: 16),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 14),
    ]).animate(_bounce);
  }

  @override
  void didUpdateWidget(CloverCountBadge old) {
    super.didUpdateWidget(old);
    if (widget.count != old.count) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.chipFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: CloverMark(key: widget.markKey, size: 17),
          ),
          const SizedBox(width: 6),
          Text('× ${widget.count}',
              style: AppText.base(
                  size: 15, weight: FontWeight.w800, letterSpacingEm: -0.01)),
        ],
      ),
    );
  }
}
