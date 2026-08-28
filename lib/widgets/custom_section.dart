import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'custom_create_sheet.dart';
import 'custom_detail_sheet.dart';
import 'custom_ticket_card.dart';
import 'pressable.dart';

/// 보관함 맨 위의 "내가 만든 행운권" 구역.
///
/// 뽑기 카드 리스트보다 먼저 온다 — 내 손으로 만든 카드가 먼저 눈에 들어와야 한다.
/// 이 카드들은 재조합·강화의 재료 목록에 절대 나타나지 않는다(타입이 다르다).
class CustomSection extends ConsumerWidget {
  const CustomSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cards =
        ref.watch(appControllerProvider.select((s) => s.customTickets));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.customSectionTitle,
                    style: AppText.base(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.title),
                  ),
                ),
                Pressable(
                  onTap: () => runCustomCreateFlow(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.chipFull),
                    ),
                    child: Text(
                      l.customCreateCta,
                      style: AppText.base(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
              child: Text(
                l.customSectionEmpty,
                style: AppText.base(
                    size: 13, weight: FontWeight.w600, color: AppColors.muted),
              ),
            )
          else
            for (final card in cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Pressable(
                  onTap: () => showCustomDetailSheet(context, card.id),
                  child: CustomTicketCard(card: card),
                ),
              ),
        ],
      ),
    );
  }
}
