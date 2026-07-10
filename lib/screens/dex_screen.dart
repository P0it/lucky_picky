import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../models/owned_ticket.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_mark.dart';
import '../widgets/pressable.dart';
import '../widgets/rarity_style.dart';
import 'ticket_screen.dart';

/// 행운 도감 — 카탈로그 전체(70종)를 등급별 섹션으로 보여준다.
/// 미획득은 ??? 실루엣, 획득은 컬러 + 중복 카운트 + 강화 레벨.
class DexScreen extends ConsumerWidget {
  const DexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final owned = ref.watch(appControllerProvider.select((s) => s.tickets));
    final ownedById = {for (final t in owned) t.ticketId: t};

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 4),
          child: Text(l.dexTitle,
              style: AppText.base(size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(l.dexSubtitle,
                    style: AppText.base(
                        size: 14, weight: FontWeight.w500, color: AppColors.muted)),
              ),
              // 수집률 칩.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
                child: Text(
                  l.dexProgress(owned.length, LuckCatalog.tickets.length),
                  style: AppText.base(
                      size: 12.5, weight: FontWeight.w800, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        for (final rarity in Rarity.values)
          _raritySection(context, lang, rarity, ownedById),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _raritySection(BuildContext context, String lang, Rarity rarity,
      Map<String, OwnedTicket> ownedById) {
    final style = RarityStyle.of(rarity);
    final pool = LuckCatalog.byRarity(rarity);
    final ownedCount = pool.where((t) => ownedById.containsKey(t.id)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color,
                  gradient: style.aura,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                LuckCatalog.rarityName(rarity, lang),
                style: AppText.base(
                    size: 16, weight: FontWeight.w800, color: style.color),
              ),
              const SizedBox(width: 8),
              Text('$ownedCount/${pool.length}',
                  style: AppText.base(
                      size: 12.5, weight: FontWeight.w700, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: [
              for (final t in pool)
                _DexCard(ticket: t, owned: ownedById[t.id], lang: lang),
            ],
          ),
        ],
      ),
    );
  }
}

class _DexCard extends StatelessWidget {
  final LuckTicket ticket;
  final OwnedTicket? owned; // null = 미획득
  final String lang;

  const _DexCard({required this.ticket, required this.owned, required this.lang});

  @override
  Widget build(BuildContext context) {
    final style = RarityStyle.of(ticket.rarity);
    final unlocked = owned != null;

    return Pressable(
      onTap: unlocked
          ? () => Navigator.of(context).push(ticketRoute(ticket.id))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? style.color.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                      color: style.color.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5)),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- 상단 패널 ----
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: unlocked
                              ? style.panel
                              : const [Color(0xFFF2F4F6), Color(0xFFE9EDF1)],
                        ),
                      ),
                    ),
                    Center(
                      child: CloverMark(
                        size: 44,
                        withStem: true,
                        color: unlocked ? null : AppColors.dashed,
                      ),
                    ),
                    // 중복 카운트 / 강화 레벨 배지.
                    if (unlocked && owned!.copies > 1)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _badge('×${owned!.copies}', style.color),
                      ),
                    if (unlocked && owned!.level > 1)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _badge('Lv.${owned!.level}', style.color, filled: true),
                      ),
                  ],
                ),
              ),
            ),
            // ---- 본문 ----
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                child: Center(
                  child: Text(
                    unlocked ? ticket.text(lang) : '???',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.base(
                      size: 11,
                      weight: FontWeight.w700,
                      height: 1.32,
                      letterSpacingEm: -0.03,
                      color: unlocked ? AppColors.title : AppColors.disabled,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.chipFull),
      ),
      child: Text(
        text,
        style: AppText.base(
          size: 9.5,
          weight: FontWeight.w800,
          color: filled ? Colors.white : color,
          letterSpacingEm: 0,
        ),
      ),
    );
  }
}
