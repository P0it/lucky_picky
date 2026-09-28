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
  // 조합 중이던 글자로 한도를 넘긴 채 끝났을 수 있다 — 서버와 같은 기준으로 한 번 더 본다.
  bool get _canMake =>
      _text.isNotEmpty && _text.runes.length <= CustomTicket.maxTextLength;

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
                    // 서버(char_length)와 같은 단위 — 코드포인트로 센다. 기본 포매터는
                    // 글자(grapheme) 단위라 이모지가 섞이면 앱은 통과시키고 서버는
                    // 광고를 다 본 뒤에 거절한다.
                    inputFormatters: const [
                      _CodePointLimitFormatter(CustomTicket.maxTextLength),
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
                    l.customCreateCounter(_controller.text.runes.length,
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

/// 코드포인트 수로 길이를 제한한다 — 넘치는 입력은 받아들이지 않는다.
class _CodePointLimitFormatter extends TextInputFormatter {
  final int max;
  const _CodePointLimitFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 한글 조합 중에는 자르지 않는다 — 조합이 끝난 뒤에 판정한다.
    if (newValue.composing.isValid) return newValue;
    return newValue.text.runes.length <= max ? newValue : oldValue;
  }
}
