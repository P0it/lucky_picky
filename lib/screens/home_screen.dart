import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import '../state/copy_controller.dart';
import '../util/text_wrap.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_mark.dart';
import '../widgets/clover_widget.dart';
import '../widgets/pressable.dart';
import '../widgets/record_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _statusText(AppLocalizations l, int leaves) {
    if (leaves <= 0) return l.homeStatusEmpty;
    if (leaves >= 4) return l.homeStatusComplete;
    return l.homeStatusProgress(leaves, 4 - leaves);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final copy = ref.watch(copyBookProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
      child: Column(
        children: [
          // ---- 헤더 ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
                        style: AppText.base(
                            size: 13, weight: FontWeight.w500, color: AppColors.muted)),
                    const SizedBox(height: 5),
                    Text(copy.dailyQuote(lang).keepAll,
                        style: AppText.base(
                            size: 21, weight: FontWeight.w700, letterSpacingEm: -0.035)),
                  ],
                ),
              ),
              // 보유 클로버 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CloverMark(size: 17),
                    const SizedBox(width: 6),
                    Text('× ${s.clovers}',
                        style: AppText.base(
                            size: 15, weight: FontWeight.w800, letterSpacingEm: -0.01)),
                  ],
                ),
              ),
            ],
          ),
          // ---- 중앙 클로버 + 상태 ----
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CloverWidget(
                  leaves: s.leaves,
                  bounceKey: s.bounceKey,
                  celebrate: s.celebrate,
                  size: 252,
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 288),
                  child: Text(
                    _statusText(l, s.leaves).keepAll,
                    textAlign: TextAlign.center,
                    style: AppText.base(
                        size: 16, weight: FontWeight.w500, color: AppColors.sub, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          // ---- 기록 버튼 ----
          Pressable(
            onTap: () => showRecordSheet(context, ref),
            child: Container(
              width: double.infinity,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.button),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(l.homeRecordButton,
                  style: AppText.base(size: 17, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
