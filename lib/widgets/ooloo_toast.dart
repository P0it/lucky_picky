import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 폰 하단(탭바 위)에 뜨는 토스 스타일 알약 토스트. toastIn 모션 재현.
void showOolooToast(BuildContext context, String text) {
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70 + bottomPad + 20, // 탭바(70) 위
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Opacity(
              opacity: _c.value,
              child: Transform.translate(offset: Offset(0, 12 * (1 - _c.value)), child: child),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.toast,
                borderRadius: BorderRadius.circular(AppRadius.chipFull),
              ),
              child: Text(
                widget.text,
                style: AppText.base(size: 14, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
