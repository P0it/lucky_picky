import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../models/ticket_instance.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/toss_face.dart';
import '../widgets/app_toast.dart';
import '../widgets/clover_mark.dart';
import '../widgets/collection_card.dart';
import '../widgets/pressable.dart';
import '../widgets/rarity_style.dart';
import 'forge_screen.dart';
import 'ticket_screen.dart';

/// 행운 지갑 — 보유한 카드를 한 장씩 보여준다.
/// 같은 행운권이라도 뽑은 장수만큼 따로 존재하고, 그 카드들이 서로의 강화 재료가 된다.
class DexScreen extends ConsumerWidget {
  const DexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final tickets = ref.watch(appControllerProvider.select((s) => s.tickets));

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(l.dexTitle,
              style: AppText.base(
                  size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(l.dexSubtitle,
                    style: AppText.base(
                        size: 14,
                        weight: FontWeight.w500,
                        color: AppColors.muted)),
              ),
              // 도감 전체 수는 알 필요 없다 — 내가 가진 장수만.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
                child: Text(
                  l.dexOwnedCount(tickets.length),
                  style: AppText.base(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        // 지갑의 두 기능 — 카드 고르기는 포지 화면이 맡는다.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  label: l.forgeReforgeCta,
                  enabled: tickets.length >= TicketInstance.reforgeMaterials,
                  primary: false,
                  mode: ForgeMode.reforge,
                  blockedMessage:
                      l.forgeNotEnoughCards(TicketInstance.reforgeMaterials),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  context,
                  label: l.forgeEnhanceCta,
                  // 올릴 수 있는 카드가 있는 것만으로는 부족하다 — 그 카드를 먹일
                  // **다른 카드**가 필요한 만큼 있어야 STEP 2 에서 막히지 않는다.
                  enabled: tickets.any((t) =>
                      !t.isMaxLevel &&
                      t.materialsNeeded <= tickets.length - 1),
                  primary: true,
                  mode: ForgeMode.enhance,
                  blockedMessage: l.forgeNoEnhanceable,
                ),
              ),
            ],
          ),
        ),
        if (tickets.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Center(
              child: Text(
                l.dexEmpty,
                textAlign: TextAlign.center,
                style: AppText.base(
                    size: 14, weight: FontWeight.w600, color: AppColors.muted),
              ),
            ),
          )
        else
          for (final rarity in Rarity.values)
            _raritySection(context, lang, rarity, tickets),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 지갑 상단 기능 버튼. 조건을 못 채우면 회색으로 두되 이유는 토스트로 알려준다
  /// — 눌러도 아무 반응이 없으면 고장으로 보인다.
  Widget _actionButton(
    BuildContext context, {
    required String label,
    required bool enabled,
    required bool primary,
    required ForgeMode mode,
    required String blockedMessage,
  }) {
    final bg = enabled && primary ? AppColors.accent : AppColors.card;
    final fg = !enabled
        ? AppColors.disabled
        : (primary ? AppColors.white : AppColors.sub);

    return Pressable(
      onTap: () {
        if (!enabled) {
          showAppToast(context, blockedMessage);
          return;
        }
        Navigator.of(context).push(forgeRoute(mode));
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        // 글자만 — 아이콘도 그 자리도 없다. 가운데 정렬이 곧 라벨 정렬.
        child: Text(
          label,
          style: AppText.base(size: 15, weight: FontWeight.w800, color: fg),
        ),
      ),
    );
  }

  Widget _raritySection(BuildContext context, String lang, Rarity rarity,
      List<TicketInstance> tickets) {
    final l = AppLocalizations.of(context);
    final style = RarityStyle.of(rarity);
    final poolIds = {for (final t in LuckCatalog.byRarity(rarity)) t.id};

    // 같은 행운권끼리 묶어 보여주되, 카드는 한 장씩 따로 — 강화가 잘 된 순.
    final cards = tickets.where((t) => poolIds.contains(t.ticketId)).toList()
      ..sort((a, b) {
        final byKind = a.ticketId.compareTo(b.ticketId);
        return byKind != 0 ? byKind : b.level.compareTo(a.level);
      });
    if (cards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
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
                Text(l.dexRarityCount(cards.length),
                    style: AppText.base(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 가로형 티켓이라 한 줄에 하나 — 문구가 어색하게 꺾이지 않는다.
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TicketRow(card: card, lang: lang),
            ),
        ],
      ),
    );
  }
}

class _TicketRow extends ConsumerWidget {
  final TicketInstance card;
  final String lang;

  const _TicketRow({required this.card, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ticket = LuckCatalog.byId(card.ticketId);
    if (ticket == null) return const SizedBox.shrink();
    final style = RarityStyle.of(ticket.rarity);

    // 플랫 컬렉션 카드 — 등급색이 카드 전체를 칠한다. 강화는 상세에서.
    return Pressable(
      onTap: () => Navigator.of(context).push(ticketRoute(card.id)),
      // 높이를 고정하지 않는다 — 한 줄짜리 문구면 카드가 그만큼 얇아져 지갑에
      // 더 많은 장수가 한 화면에 들어온다. 두 줄짜리는 알아서 늘어난다.
      child: CollectionCard(
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
                    LuckCatalog.rarityName(ticket.rarity, lang),
                    style: AppText.base(
                      size: 10,
                      weight: FontWeight.w800,
                      color: style.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'No.${card.ticketId.substring(1)}',
                    style: AppText.base(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.sub,
                      letterSpacingEm: 0,
                    ),
                  ),
                  const Spacer(),
                  // 스텁은 강화 상태만 말한다 — 기능 버튼은 지갑 상단에 있다.
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
                  ] else if (card.plus == 0)
                    // 빈칸 방지 — 무강화 카드는 등급색 클로버 한 장.
                    CloverMark(size: 18, color: style.color),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                ticket.text(lang),
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
      ),
    );
  }
}
