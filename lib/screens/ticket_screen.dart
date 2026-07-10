import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../models/owned_ticket.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/pressable.dart';
import '../widgets/rarity_style.dart';
import '../widgets/talisman_export.dart';
import '../widgets/ticket_card.dart';

/// 도감 카드 → 행운권 상세. 페이드로 진입.
Route<void> ticketRoute(String ticketId) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => TicketScreen(ticketId: ticketId),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

/// 획득한 행운권을 카드 이미지로 미리보고 강화 / 앨범 저장 / 공유한다.
class TicketScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  final _boundaryKey = GlobalKey();
  TicketFormat _format = TicketFormat.portrait;
  bool _busy = false;

  String get _fileName => 'luckypicky_ticket_${widget.ticketId}_${_format.name}';

  Future<void> _withBusy(Future<void> Function() action, {String? failMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showAppToast(context, failMsg ?? AppLocalizations.of(context).talismanRetry);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _withBusy(() async {
        final bytes = await captureBoundaryPng(_boundaryKey);
        await saveTalismanToGallery(bytes, _fileName);
        if (mounted) showAppToast(context, AppLocalizations.of(context).toastSavedToAlbum);
      }, failMsg: AppLocalizations.of(context).talismanSaveFail);

  Future<void> _share(LuckTicket ticket) {
    final lang = Localizations.localeOf(context).languageCode;
    final shareText = AppLocalizations.of(context).ticketShareText(ticket.text(lang));
    return _withBusy(() async {
      final bytes = await captureBoundaryPng(_boundaryKey);
      await shareTalisman(bytes, _fileName, text: shareText);
    });
  }

  Future<void> _enhance() async {
    final l = AppLocalizations.of(context);
    try {
      final up = await ref
          .read(appControllerProvider.notifier)
          .enhanceTicket(widget.ticketId);
      if (up != null && mounted) showAppToast(context, l.toastEnhanced(up.level));
    } on GameConnectionException {
      if (mounted) showAppToast(context, l.errorNeedConnection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ticket = LuckCatalog.byId(widget.ticketId);
    final owned = ref.watch(appControllerProvider.select(
        (s) => s.tickets.where((t) => t.ticketId == widget.ticketId).firstOrNull));

    if (ticket == null || owned == null) {
      // 방어 — 미획득/알 수 없는 ID 로 진입 시 그냥 닫는다.
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
            _infoChips(l, ticket, owned),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22191F28), blurRadius: 44, offset: Offset(0, 20)),
                        ],
                      ),
                      // ClipRRect/그림자는 미리보기 전용 — 캡처되는 RepaintBoundary는
                      // 모서리까지 꽉 찬 원본 사각형이라 배경화면 시 빈틈이 없다.
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: TicketCard(ticket: ticket, owned: owned, format: _format),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _enhanceButton(l, ticket, owned),
            const SizedBox(height: 12),
            _formatToggle(),
            const SizedBox(height: 14),
            _actions(ticket),
            const SizedBox(height: 12),
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

  /// 획득일 · 보유 장수 · 강화 레벨 정보 칩.
  Widget _infoChips(AppLocalizations l, LuckTicket ticket, OwnedTicket owned) {
    final style = RarityStyle.of(ticket.rarity);
    Widget chip(String text, {bool filled = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: filled ? style.color : style.soft,
            borderRadius: BorderRadius.circular(AppRadius.chipFull),
          ),
          child: Text(
            text,
            style: AppText.base(
                size: 12,
                weight: FontWeight.w700,
                color: filled ? Colors.white : style.color),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Wrap(
        spacing: 6,
        alignment: WrapAlignment.center,
        children: [
          chip(l.ticketLevel(owned.level), filled: owned.level > 1),
          chip(l.ticketOwnedCopies(owned.copies)),
          chip(l.ticketFirstPulled(owned.firstPulledAt)),
        ],
      ),
    );
  }

  /// 강화 버튼 — 재료(중복) 현황과 함께.
  Widget _enhanceButton(AppLocalizations l, LuckTicket ticket, OwnedTicket owned) {
    final style = RarityStyle.of(ticket.rarity);
    if (owned.isMaxLevel) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 48,
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
    final need = OwnedTicket.costForNextLevel(owned.level);
    final have = owned.spareCopies;
    final can = owned.canEnhance;
    return Pressable(
      onTap: can ? _enhance : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: can ? style.color : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: can
              ? [
                  BoxShadow(
                      color: style.color.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upgrade_rounded,
                size: 19, color: can ? Colors.white : AppColors.disabled),
            const SizedBox(width: 6),
            Text(
              l.ticketEnhance(have, need),
              style: AppText.base(
                size: 15,
                weight: FontWeight.w700,
                color: can ? Colors.white : AppColors.disabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatToggle() {
    Widget seg(String label, TicketFormat f) {
      final active = _format == f;
      return Expanded(
        child: Pressable(
          onTap: active ? null : () => setState(() => _format = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.chipFull),
              boxShadow: active
                  ? const [BoxShadow(color: Color(0x14191F28), blurRadius: 8, offset: Offset(0, 2))]
                  : null,
            ),
            child: Text(label,
                style: AppText.base(
                    size: 14,
                    weight: FontWeight.w700,
                    color: active ? AppColors.title : AppColors.muted)),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.chipFull),
        ),
        child: SizedBox(
          width: 240,
          child: Row(
            children: [
              seg(AppLocalizations.of(context).talismanPortrait, TicketFormat.portrait),
              seg(AppLocalizations.of(context).talismanSquare, TicketFormat.square),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(LuckTicket ticket) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: _busy ? null : _save,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, size: 19, color: AppColors.sub),
                    const SizedBox(width: 7),
                    Text(AppLocalizations.of(context).talismanSave,
                        style: AppText.base(size: 16, weight: FontWeight.w700, color: AppColors.sub)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: _busy ? null : () => _share(ticket),
              child: Container(
                height: 56,
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
                    Text(AppLocalizations.of(context).talismanShare,
                        style: AppText.base(size: 16, weight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
