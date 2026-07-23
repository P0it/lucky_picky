import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_ticket.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// 나만의 행운권 문구를 적는 하프 모달 — 선행 기록 시트와 같은 결로 올라온다.
///
/// 시트는 문구만 받아 그대로 돌려준다. 광고 재생과 서버 제작은 호출부가 맡는다 —
/// 시트가 닫힌 뒤에 광고가 떠야 모달 위에 모달이 겹치지 않고, 닫힌 위젯의
/// 상태를 건드릴 일도 없다.
Future<String?> showCustomCreateSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.backdrop,
    builder: (_) => const _CustomCreateSheet(),
  );
}

class _CustomCreateSheet extends StatefulWidget {
  const _CustomCreateSheet();

  @override
  State<_CustomCreateSheet> createState() => _CustomCreateSheetState();
}

class _CustomCreateSheetState extends State<_CustomCreateSheet> {
  final _controller = TextEditingController();

  String get _text => _controller.text.trim();
  bool get _canMake => _text.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          boxShadow: [
            BoxShadow(
                color: Color(0x24191F28),
                blurRadius: 30,
                offset: Offset(0, -8))
          ],
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(l.customCreateTitle,
                style: AppText.base(
                    size: 22, weight: FontWeight.w700, letterSpacingEm: -0.03)),
            const SizedBox(height: 6),
            Text(l.customCreateAdNote,
                style: AppText.base(
                    size: 14, weight: FontWeight.w500, color: AppColors.muted)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    maxLines: 2,
                    minLines: 2,
                    maxLength: CustomTicket.maxTextLength,
                    // 기본 카운터는 서체와 위치가 앱과 어긋난다 — 아래에 직접 그린다.
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                          CustomTicket.maxTextLength),
                    ],
                    style: AppText.base(
                        size: 16, weight: FontWeight.w500, height: 1.5),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration.collapsed(
                      hintText: l.customCreateHint,
                      hintStyle: AppText.base(
                          size: 16,
                          weight: FontWeight.w500,
                          color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.customCreateCounter(_controller.text.characters.length,
                        CustomTicket.maxTextLength),
                    style: AppText.base(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Pressable(
              onTap: _canMake
                  ? () => Navigator.of(context).pop(_text)
                  : null,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canMake ? AppColors.accent : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  l.customCreateConfirm(CustomTicket.createCost),
                  style: AppText.base(
                    size: 17,
                    weight: FontWeight.w700,
                    color: _canMake ? Colors.white : AppColors.disabled,
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
