import 'package:flutter/material.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'rarity_style.dart';

/// 획득 확률 시트 — 등급별 확률 % + 해학적 비유 문구를 공개한다.
Future<void> showGachaRatesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.backdrop,
    builder: (_) => const _RatesSheet(),
  );
}

class _RatesSheet extends StatelessWidget {
  const _RatesSheet();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + safeBottom),
      // 작은 화면에서도 넘치지 않게 시트 내부를 스크롤 가능하게 한다.
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
            Text(
              l.ratesTitle,
              style: AppText.base(
                size: 22,
                weight: FontWeight.w700,
                letterSpacingEm: -0.03,
              ),
            ),
            const SizedBox(height: 18),
            for (final rarity in Rarity.values) ...[
              _row(lang, rarity),
              if (rarity != Rarity.values.last) const SizedBox(height: 12),
            ],
            const SizedBox(height: 18),
            Text(
              l.ratesDisclaimer,
              style: AppText.base(
                size: 12,
                weight: FontWeight.w500,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String lang, Rarity rarity) {
    final style = RarityStyle.of(rarity);
    final percent = LuckCatalog.weights[rarity]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: style.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.color,
              gradient: style.aura,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      LuckCatalog.rarityName(rarity, lang),
                      style: AppText.base(
                        size: 15,
                        weight: FontWeight.w800,
                        color: style.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percent%',
                      style: AppText.base(
                        size: 15,
                        weight: FontWeight.w800,
                        letterSpacingEm: -0.01,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  LuckCatalog.rarityAnalogy(rarity, lang),
                  style: AppText.base(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.sub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
