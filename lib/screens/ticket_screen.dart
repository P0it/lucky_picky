import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../models/ticket_instance.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/clover_mark.dart';
import '../widgets/pressable.dart';
import '../widgets/rarity_style.dart';
import '../widgets/collection_card.dart';
import '../widgets/talisman_export.dart';
import 'forge_screen.dart';

/// 지갑 카드 → 행운권 상세. 페이드로 진입. (카드 한 장 = 인스턴스 id)
Route<void> ticketRoute(String instanceId) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => TicketScreen(instanceId: instanceId),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

/// 보유 카드 한 장의 상세 — 지갑과 같은 티켓 실루엣의 대형 버전으로
/// 전체 문구를 보여주고 강화/공유한다.
class TicketScreen extends ConsumerStatefulWidget {
  final String instanceId;
  const TicketScreen({super.key, required this.instanceId});

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  String get _fileName => 'luckypicky_ticket_${widget.instanceId}';

  Future<void> _share(LuckTicket ticket) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final shareText =
          AppLocalizations.of(context).ticketShareText(ticket.text(lang));
      final bytes = await captureBoundaryPng(_boundaryKey);
      await shareTalisman(bytes, _fileName, text: shareText);
    } catch (_) {
      if (mounted) {
        showAppToast(context, AppLocalizations.of(context).talismanRetry);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final owned = ref.watch(appControllerProvider.select(
        (s) => s.tickets.where((t) => t.id == widget.instanceId).firstOrNull));
    final ticket = owned == null ? null : LuckCatalog.byId(owned.ticketId);

    if (ticket == null || owned == null) {
      // 방어 — 강화 재료로 사라졌거나 알 수 없는 카드면 그냥 닫는다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(backgroundColor: AppColors.bg, body: SizedBox());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(l),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: _TicketFace(ticket: ticket, owned: owned, lang: lang),
              ),
            ),
            const Spacer(),
            _enhanceButton(l, ticket, owned),
            const SizedBox(height: 10),
            _shareButton(l, ticket),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _topBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          Pressable(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.close_rounded, size: 26, color: AppColors.sub),
            ),
          ),
          const Spacer(),
          Text(l.ticketTitle,
              style: AppText.base(size: 17, weight: FontWeight.w800, letterSpacingEm: -0.03)),
          const Spacer(),
          const SizedBox(width: 50), // 닫기 버튼과 대칭
        ],
      ),
    );
  }

  /// 강화 버튼 — 누르면 이 카드를 대상으로 한 포지 화면(재료 고르기)이 열린다.
  Widget _enhanceButton(
      AppLocalizations l, LuckTicket ticket, TicketInstance owned) {
    final style = RarityStyle.of(ticket.rarity);
    if (owned.isMaxLevel) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.soft,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: style.color),
            const SizedBox(width: 7),
            Text(l.ticketEnhanceMax,
                style: AppText.base(
                    size: 15, weight: FontWeight.w700, color: style.color)),
          ],
        ),
      );
    }
    return Pressable(
      onTap: () => Navigator.of(context)
          .push(forgeRoute(ForgeMode.enhance, targetId: owned.id)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: [
            BoxShadow(
                color: style.color.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upgrade_rounded, size: 19, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              l.forgeEnhanceCta,
              style: AppText.base(
                size: 15,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareButton(AppLocalizations l, LuckTicket ticket) {
    return Pressable(
      onTap: _busy ? null : () => _share(ticket),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ios_share_rounded, size: 19, color: Colors.white),
            const SizedBox(width: 7),
            Text(l.talismanShare,
                style: AppText.base(
                    size: 16, weight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// 지갑 카드와 같은 플랫 컬렉션 카드의 대형 버전 — 문구 전체와 획득 정보를 담는다.
/// 이 위젯이 그대로 공유 이미지가 된다.
class _TicketFace extends StatelessWidget {
  final LuckTicket ticket;
  final TicketInstance owned;
  final String lang;

  const _TicketFace({required this.ticket, required this.owned, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = RarityStyle.of(ticket.rarity);

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: CollectionCard(
        style: style,
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CloverMark(size: 15, color: style.color),
                  const SizedBox(width: 6),
                  Text(
                    LuckCatalog.rarityName(ticket.rarity, lang),
                    style: AppText.base(
                        size: 12, weight: FontWeight.w800, color: style.color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No.${ticket.id.substring(1)}',
                    style: AppText.base(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.sub,
                        letterSpacingEm: 0),
                  ),
                  const Spacer(),
                  if (owned.plus > 0)
                    Text(
                      l.dexPlus(owned.plus),
                      style: AppText.base(
                        size: 22,
                        weight: FontWeight.w800,
                        color: style.color,
                        letterSpacingEm: 0,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                ticket.text(lang),
                style: AppText.base(
                  size: 19,
                  weight: FontWeight.w800,
                  height: 1.4,
                  letterSpacingEm: -0.03,
                ),
              ),
              const Spacer(),
              Text(
                l.ticketFirstPulled(owned.pulledAt),
                style: AppText.base(
                    size: 11.5, weight: FontWeight.w600, color: AppColors.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
