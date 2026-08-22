import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_ticket.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'custom_ticket_card.dart';
import 'pressable.dart';

/// 내가 만든 행운권 상세 — 카드 전문과 강화 버튼만 있는 하프 모달.
///
/// 강화는 클로버를 현재 레벨 수만큼 쓰고 **실패하지 않는다.** 그래서
/// `forge_overlay` 의 게이지·균열·폭발 연출을 쓰지 않고 +N 이 오르는 팝으로 끝낸다.
Future<void> showCustomDetailSheet(BuildContext context, String id) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.backdrop,
    builder: (_) => _CustomDetailSheet(id: id),
  );
}

class _CustomDetailSheet extends ConsumerStatefulWidget {
  final String id;
  const _CustomDetailSheet({required this.id});

  @override
  ConsumerState<_CustomDetailSheet> createState() => _CustomDetailSheetState();
}

class _CustomDetailSheetState extends ConsumerState<_CustomDetailSheet> {
  bool _busy = false;

  /// 레벨이 오른 순간 카드를 한 번 튕겨준다.
  int _popKey = 0;

  Future<void> _enhance(CustomTicket card) async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    if (ref.read(appControllerProvider).clovers < card.enhanceCost) {
      showAppToast(context, l.customEnhanceNoClovers);
      return;
    }

    setState(() => _busy = true);
    try {
      final r = await ref
          .read(appControllerProvider.notifier)
          .enhanceCustomTicket(widget.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (r != null) _popKey++;
      });
      if (r == null) showAppToast(context, l.customEnhanceNoClovers);
    } on GameConnectionException {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(context, l.errorNeedConnection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final card = ref
        .watch(appControllerProvider.select((s) => s.customTickets))
        .where((t) => t.id == widget.id)
        .firstOrNull;

    // 카드가 사라졌다면(재동기화 등) 시트를 유지할 이유가 없다.
    if (card == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    final clovers = ref.watch(appControllerProvider.select((s) => s.clovers));
    final canEnhance = !card.isMaxLevel && clovers >= card.enhanceCost && !_busy;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: [
          BoxShadow(
              color: Color(0x24191F28), blurRadius: 30, offset: Offset(0, -8))
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
          Text(l.customSectionTitle,
              style: AppText.base(
                  size: 22, weight: FontWeight.w700, letterSpacingEm: -0.03)),
          const SizedBox(height: 18),
          _LevelPop(popKey: _popKey, child: CustomTicketCard(card: card)),
          const SizedBox(height: 20),
          Pressable(
            onTap: canEnhance ? () => _enhance(card) : null,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canEnhance ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Text(
                card.isMaxLevel
                    ? l.customEnhanceMax
                    : l.customEnhance(card.enhanceCost),
                style: AppText.base(
                  size: 17,
                  weight: FontWeight.w700,
                  color: canEnhance ? AppColors.white : AppColors.disabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [popKey] 가 바뀔 때마다 한 번 튕긴다 — 강화 성공의 유일한 연출.
class _LevelPop extends StatefulWidget {
  final int popKey;
  final Widget child;
  const _LevelPop({required this.popKey, required this.child});

  @override
  State<_LevelPop> createState() => _LevelPopState();
}

class _LevelPopState extends State<_LevelPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(_LevelPop old) {
    super.didUpdateWidget(old);
    if (old.popKey != widget.popKey) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        // 0 → 1 로 갈수록 잦아드는 한 번의 스프링.
        final scale = 1 + 0.08 * Curves.elasticOut.transform(t) * (1 - t);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
