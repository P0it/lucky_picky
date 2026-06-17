import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'ooloo_toast.dart';
import 'pressable.dart';

/// 선행 기록 하프 모달. 홈의 버튼에서 슥 올라온다.
Future<void> showRecordSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.backdrop,
    builder: (_) => const _RecordSheet(),
  );
}

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet();

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  final _controller = TextEditingController();
  bool get _canRecord => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _record() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final completed = ref.read(appControllerProvider.notifier).recordDeed(text);
    Navigator.of(context).pop();
    showOolooToast(context, completed ? '네잎클로버가 완성됐어요 🍀' : '잎을 채웠어요');
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom; // 홈 인디케이터
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          boxShadow: [BoxShadow(color: Color(0x24191F28), blurRadius: 30, offset: Offset(0, -8))],
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들 인디케이터
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 18),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.chipFull),
                  ),
                ),
              ),
            ),
            Text('어떤 선행을 베푸셨나요?',
                style: AppText.base(size: 22, weight: FontWeight.w700, letterSpacingEm: -0.03)),
            const SizedBox(height: 6),
            Text('작은 선행도 클로버의 잎이 됩니다.',
                style: AppText.base(size: 14, weight: FontWeight.w500, color: AppColors.muted)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                maxLines: 3,
                minLines: 3,
                style: AppText.base(size: 16, weight: FontWeight.w500, height: 1.5),
                cursorColor: AppColors.accent,
                decoration: InputDecoration.collapsed(
                  hintText: '예: 엘리베이터 문을 잡아주었습니다.',
                  hintStyle:
                      AppText.base(size: 16, weight: FontWeight.w500, color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Pressable(
              onTap: _canRecord ? _record : null,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canRecord ? AppColors.accent : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  '기록 완료하고 잎 채우기',
                  style: AppText.base(
                    size: 17,
                    weight: FontWeight.w700,
                    color: _canRecord ? Colors.white : AppColors.disabled,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
