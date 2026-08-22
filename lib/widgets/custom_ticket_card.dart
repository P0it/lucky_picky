import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_ticket.dart';
import '../theme/app_theme.dart';
import '../theme/toss_face.dart';
import 'clover_mark.dart';
import 'collection_card.dart';
import 'rarity_style.dart';

/// 내가 만든 행운권 한 장.
///
/// 뽑기 카드와 같은 [CollectionCard] 면을 쓰되 등급 자리에는 등급명 대신
/// "직접 만듦" 배지가 온다 — 커스텀 카드에는 희귀도가 없다.
class CustomTicketCard extends StatelessWidget {
  final CustomTicket card;

  const CustomTicketCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const style = RarityStyle.custom;

    return CollectionCard(
      style: style,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CloverMark(size: 13, color: style.color),
                const SizedBox(width: 5),
                Text(
                  l.customBadge,
                  style: AppText.base(
                    size: 10,
                    weight: FontWeight.w800,
                    color: style.color,
                  ),
                ),
                const Spacer(),
                // 등급이 없으므로 이 자리는 오로지 강화 상태만 말한다.
                if (card.plus > 0)
                  Text(
                    l.dexPlus(card.plus),
                    style: AppText.base(
                      size: 15,
                      weight: FontWeight.w800,
                      color: style.color,
                      letterSpacingEm: 0,
                    ),
                  ),
                if (card.isMaxLevel) ...[
                  const SizedBox(width: 4),
                  const TossEmoji(TossFace.crown, size: 18),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Text(
              card.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                size: 14,
                weight: FontWeight.w700,
                height: 1.32,
                letterSpacingEm: -0.03,
                color: AppColors.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
