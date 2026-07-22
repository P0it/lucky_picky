import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 화면 상단(상태바 아래)에 내려오는 흰색 알약 토스트.
void showAppToast(BuildContext context, String text) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastPill(text: text, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _ToastPill extends StatefulWidget {
  final String text;
  final VoidCallback onDone;
  const _ToastPill({required this.text, required this.onDone});

  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..forward();
    Future.delayed(const Duration(milliseconds: 1650), () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      left: 0,
      right: 0,
      top: topPad + 12, // 상태바 아래
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Opacity(
              opacity: _c.value,
              // 위에서 내려오는 모션
              child: Transform.translate(offset: Offset(0, -12 * (1 - _c.value)), child: child),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.chipFull),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.text,
                style: AppText.base(size: 14, weight: FontWeight.w600, color: AppColors.title),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
