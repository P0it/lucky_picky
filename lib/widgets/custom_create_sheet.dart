import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_ticket.dart';
import '../state/ads_controller.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'pressable.dart';

/// 소원 만들기 한 판: 클로버 확인 → 문구 시트 → 광고 → 서버 제작.
///
/// 입구가 둘이다 — 홈의 클로버 배지, 보관함의 '만들기' 버튼. 두 곳이 같은
/// 함수를 불러야 한다. 복사해두면 언젠가 한쪽만 고쳐지고, 그 입구에서만
/// 클로버가 새기 시작한다.
///
/// **광고를 끝까지 본 경우에만 서버를 부른다.** 차감 후 환불이 아니라 아예
/// 차감하지 않는 방식이다 — 환불식은 "차감됨 → 환불됨" 사이에 클로버가
/// 사라져 보이는 구간이 생기고, 그 순간 앱이 죽으면 진짜로 날아간다.
/// (가챠 `runGachaPullFlow` 와 같은 패턴)
Future<void> runCustomCreateFlow(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);

  if (ref.read(appControllerProvider).clovers < CustomTicket.createCost) {
    showAppToast(context, l.customCreateNoClovers(CustomTicket.createCost));
    return;
  }

  final text = await showCustomCreateSheet(context);
  if (text == null || !context.mounted) return;

  var rewarded = false;
  ref.read(rewardedAdProvider)(
    onReward: () async {
      rewarded = true;
      try {
        final made =
            await ref.read(appControllerProvider.notifier).createCustomTicket(text);
        if (!context.mounted) return;
        showAppToast(
            context, made == null ? l.customCreateFailed : l.customCreated);
      } on GameConnectionException {
        if (context.mounted) showAppToast(context, l.errorNeedConnection);
      }
    },
    onDone: () {
      if (rewarded || !context.mounted) return;
      showAppToast(context, l.customCreateFailed);
    },
  );
}

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
