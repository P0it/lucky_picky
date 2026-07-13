import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../models/ticket_instance.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/toss_face.dart';
import '../widgets/forge_overlay.dart';
import '../widgets/pressable.dart';
import '../widgets/rarity_style.dart';

/// 포지의 두 갈래 — 강화(대상 1장 + 재료 N장)와 재조합(재료 3장).
enum ForgeMode { enhance, reforge }

/// 지갑 상단 액션 → 포지 선택 화면. 페이드로 진입 ([ticketRoute] 와 같은 톤).
///
/// [targetId] 를 주면 강화 대상이 이미 정해진 것으로 보고 재료 고르기(STEP 2)로
/// 바로 들어간다 (행운권 상세의 강화 버튼 경로).
Route<void> forgeRoute(ForgeMode mode, {String? targetId}) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) =>
          ForgeScreen(mode: mode, initialTargetId: targetId),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

/// 지갑에서 카드를 골라 강화하거나 재조합하는 풀스크린 화면.
///
/// 강화는 STEP 1(대상) → STEP 2(재료) 두 단계, 재조합은 재료 선택 한 단계뿐이다.
/// 실행 자체는 [runEnhanceFlow] / [runReforgeFlow] 가 맡고(서버 판정 + 연출),
/// 이 화면은 무엇을 태울지 고르는 일만 한다.
class ForgeScreen extends ConsumerStatefulWidget {
  final ForgeMode mode;

  /// 강화 대상이 이미 정해져 있으면 STEP 1 을 건너뛴다.
  final String? initialTargetId;

  const ForgeScreen({super.key, required this.mode, this.initialTargetId});

  @override
  ConsumerState<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends ConsumerState<ForgeScreen> {
  /// 강화 대상 카드 (STEP 1 에서 고른다).
  String? _targetId;

  /// 재료 고르기(STEP 2)로 넘어왔는가. 강화 전용 — 재조합은 언제나 재료 단계다.
  bool _onMaterialStep = false;

  /// 재료로 고른 카드들.
  final _picked = <String>{};

  bool _busy = false;

  /// 대상이 사라져 화면을 닫는 중 — maybePop 이 두 번 예약되지 않게 한 번만 잠근다.
  bool _popping = false;

  bool get _isEnhance => widget.mode == ForgeMode.enhance;

  /// 대상이 처음부터 주어진 경우 — STEP 2 에서 뒤로 가면 STEP 1 이 아니라 화면을 닫는다.
  bool get _targetLocked => widget.initialTargetId != null;

  @override
  void initState() {
    super.initState();
    if (_isEnhance && widget.initialTargetId != null) {
      // 행운권 상세에서 온 경로 — 대상은 이미 정해졌으니 재료부터 고른다.
      _targetId = widget.initialTargetId;
      _onMaterialStep = true;
    }
  }

  // ---- 실행 ----

  Future<void> _runEnhance(TicketInstance target, int rate) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ran = await runEnhanceFlow(
      context,
      ref,
      targetId: target.id,
      materialIds: _picked.toList(),
      rate: rate,
    );
    if (!mounted) return;
    if (ran) {
      // 연출까지 끝났으면 지갑으로 돌아간다.
      Navigator.of(context).maybePop();
    } else {
      // 오프라인이거나 규칙에 걸려 아무 일도 없었다 — 고른 카드를 그대로 두고 다시 누를 수 있게.
      setState(() => _busy = false);
    }
  }

  Future<void> _runReforge() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ran = await runReforgeFlow(context, ref, materialIds: _picked.toList());
    if (!mounted) return;
    if (ran) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _busy = false);
    }
  }

  /// STEP 2 → STEP 1. 대상이 고정된 진입(상세 화면 경로)에서는 되돌릴 STEP 1 이 없다.
  void _backToTargetStep() {
    setState(() {
      _targetId = null;
      _onMaterialStep = false;
      _picked.clear();
    });
  }

  bool get _canGoBackAStep =>
      _isEnhance && _onMaterialStep && !_targetLocked;

  void _onBack() {
    if (_canGoBackAStep) {
      _backToTargetStep();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  // ---- 선택 ----

  void _pickTarget(String id) => setState(() {
        _targetId = _targetId == id ? null : id; // 라디오처럼 한 장만
      });

  void _toggleMaterial(String id, int need) => setState(() {
        if (_picked.contains(id)) {
          _picked.remove(id);
        } else if (_picked.length < need) {
          _picked.add(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tickets = ref.watch(appControllerProvider.select((s) => s.tickets));

    // 지갑에서 사라진 카드의 id 는 붙들고 있지 않는다 — CTA 가 유령 선택으로 열리면 안 된다.
    _picked.retainWhere((id) => tickets.any((t) => t.id == id));

    final target =
        tickets.where((t) => t.id == _targetId).firstOrNull; // 사라졌으면 null

    // 강화 대상이 재료로 소모되었거나 알 수 없는 카드면 대상 단계로 되돌린다.
    if (_isEnhance && _onMaterialStep && target == null && !_busy && !_popping) {
      if (_targetLocked) _popping = true; // 닫는 중 재빌드가 pop 을 또 예약하지 않게.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_targetLocked) {
          Navigator.of(context).maybePop();
        } else {
          _backToTargetStep();
        }
      });
    }

    return PopScope(
      // STEP 2 에서 뒤로가기 = STEP 1 로 복귀. 화면은 닫지 않는다.
      canPop: !_canGoBackAStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canGoBackAStep) _backToTargetStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(l),
              Expanded(
                child: _isEnhance
                    ? (_onMaterialStep && target != null
                        ? _enhanceMaterialStep(l, tickets, target)
                        : _enhanceTargetStep(l, tickets))
                    : _reforgeStep(l, tickets),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 상단 ----

  Widget _topBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 4),
      child: Row(
        children: [
          Pressable(
            onTap: _onBack,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.sub),
            ),
          ),
          const Spacer(),
          TossEmoji(_isEnhance ? TossFace.star : TossFace.recycle, size: 18),
          const SizedBox(width: 6),
          Text(
            _isEnhance ? l.forgeEnhanceCta : l.forgeReforgeCta,
            style: AppText.base(
                size: 17, weight: FontWeight.w800, letterSpacingEm: -0.03),
          ),
          const Spacer(),
          const SizedBox(width: 44), // 뒤로가기와 대칭
        ],
      ),
    );
  }

  Widget _stepTitle(String title, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppText.base(
                  size: 20, weight: FontWeight.w800, letterSpacingEm: -0.03)),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint,
                style: AppText.base(
                    size: 12, weight: FontWeight.w600, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.base(
                size: 13.5, weight: FontWeight.w600, color: AppColors.muted),
          ),
        ),
      );

  Widget _list(List<Widget> children) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => children[i],
      );

  /// 하단 고정 CTA — 비활성이면 회색.
  Widget _cta(String label, Color accent, {required bool ready, VoidCallback? onTap}) {
    final on = ready && !_busy;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Pressable(
          onTap: on ? onTap : null,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? accent : AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Text(
              label,
              style: AppText.base(
                size: 16,
                weight: FontWeight.w800,
                color: on ? AppColors.white : AppColors.disabled,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- 강화 STEP 1: 대상 고르기 ----

  Widget _enhanceTargetStep(
      AppLocalizations l, List<TicketInstance> tickets) {
    // 만렙 카드는 더 올릴 수 없으니 후보에서 뺀다.
    final candidates = tickets.where((t) => !t.isMaxLevel).toList()
      ..sort((a, b) {
        final rankA = LuckCatalog.byId(a.ticketId)?.rarity.index ?? 0;
        final rankB = LuckCatalog.byId(b.ticketId)?.rarity.index ?? 0;
        if (rankA != rankB) return rankB - rankA; // 상위 등급 먼저
        return b.level.compareTo(a.level); // 이미 강화된 카드 먼저
      });

    return Column(
      children: [
        _stepTitle(l.forgeStepTarget),
        Expanded(
          child: candidates.isEmpty
              ? _empty(l.forgeNoEnhanceable)
              : _list([
                  for (final t in candidates)
                    ForgePickCard(
                      instance: t,
                      picked: _targetId == t.id,
                      onTap: () => _pickTarget(t.id),
                    ),
                ]),
        ),
        _cta(
          l.forgeNext,
          AppColors.accent,
          ready: _targetId != null,
          onTap: () => setState(() => _onMaterialStep = true),
        ),
      ],
    );
  }

  // ---- 강화 STEP 2: 재료 고르기 ----

  Widget _enhanceMaterialStep(
      AppLocalizations l, List<TicketInstance> tickets, TicketInstance target) {
    final style = RarityStyle.of(
        LuckCatalog.byId(target.ticketId)?.rarity ?? Rarity.common);
    final need = target.materialsNeeded;

    // 재료 후보 = 대상 말고 내가 가진 모든 카드. 종류/등급 제한은 없고, 등급이 확률을
    // 좌우한다. 같은 행운권 → 상위 등급 → 저레벨 순으로 위에 둔다. (기존 강화 시트 규칙)
    final candidates = tickets.where((t) => t.id != target.id).toList()
      ..sort((a, b) {
        final sameA = a.ticketId == target.ticketId ? 0 : 1;
        final sameB = b.ticketId == target.ticketId ? 0 : 1;
        if (sameA != sameB) return sameA - sameB;
        final rankA = LuckCatalog.byId(a.ticketId)?.rarity.index ?? 0;
        final rankB = LuckCatalog.byId(b.ticketId)?.rarity.index ?? 0;
        if (rankA != rankB) return rankB - rankA;
        return a.level.compareTo(b.level);
      });

    final pickedCards =
        tickets.where((t) => _picked.contains(t.id)).toList(growable: false);
    // 화면에 보여주는 확률과 연출 게이지가 어긋나면 안 된다 — 같은 값을 그대로 넘긴다.
    final rate = target.successRateWith(pickedCards);
    // 보여준 확률과 넘기는 재료가 같은 목록에서 나와야 한다 — 개수도 그 목록으로 센다.
    final ready = pickedCards.length == need;

    return Column(
      children: [
        _stepTitle(l.forgeStepMaterial),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 무엇을 강화하는지 항상 보이게 대상 카드를 고정한다.
              ForgePickCard(instance: target, picked: true, highlight: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(l.forgeRate(rate),
                      style: AppText.base(
                          size: 16,
                          weight: FontWeight.w800,
                          color: style.color)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.forgeWarn,
                        style: AppText.base(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: AppColors.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(l.forgeRateHint,
                  style: AppText.base(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.muted)),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: candidates.isEmpty
              ? _empty(l.forgeNoMaterial)
              : _list([
                  for (final t in candidates)
                    ForgePickCard(
                      instance: t,
                      picked: _picked.contains(t.id),
                      onTap: () => _toggleMaterial(t.id, need),
                    ),
                ]),
        ),
        _cta(
          l.forgeRunEnhance(pickedCards.length, need),
          style.color,
          ready: ready,
          onTap: () => _runEnhance(target, rate),
        ),
      ],
    );
  }

  // ---- 재조합: 재료 고르기 한 단계 ----

  Widget _reforgeStep(AppLocalizations l, List<TicketInstance> tickets) {
    const need = TicketInstance.reforgeMaterials;

    // 강화가 덜 된 하위 등급부터 갈아 넣게 정렬. (기존 재조합 시트 규칙)
    final cards = [...tickets]..sort((a, b) {
        final rankA = LuckCatalog.byId(a.ticketId)?.rarity.index ?? 0;
        final rankB = LuckCatalog.byId(b.ticketId)?.rarity.index ?? 0;
        if (rankA != rankB) return rankA - rankB;
        return a.level.compareTo(b.level);
      });

    // 지갑에 실제로 남아 있는 카드만 재료로 센다 (id 만 보고 세면 유령 선택이 생긴다).
    final pickedCards =
        tickets.where((t) => _picked.contains(t.id)).toList(growable: false);
    // 결과 등급 미리보기 — 재료 중 최고 등급.
    final topRarity = pickedCards.isEmpty
        ? null
        : Rarity.values[pickedCards
            .map((t) => LuckCatalog.byId(t.ticketId)?.rarity.index ?? 0)
            .reduce((a, b) => a > b ? a : b)];
    final accent =
        topRarity == null ? AppColors.accent : RarityStyle.of(topRarity).color;

    return Column(
      children: [
        _stepTitle(
          l.forgeStepReforge(need),
          hint: l.forgeReforgeHint(TicketInstance.reforgeUpgradeRate),
        ),
        Expanded(
          child: cards.length < need
              ? _empty(l.forgeNotEnoughCards(need))
              : _list([
                  for (final t in cards)
                    ForgePickCard(
                      instance: t,
                      picked: _picked.contains(t.id),
                      onTap: () => _toggleMaterial(t.id, need),
                    ),
                ]),
        ),
        _cta(
          l.forgeRunReforge(pickedCards.length, need),
          accent,
          ready: pickedCards.length == need,
          onTap: _runReforge,
        ),
      ],
    );
  }
}

/// 포지에서 고르는 카드 한 장 — 등급명 · +N · 문구 한 줄.
/// 등급색 테두리 + 선택 시 체크. ([highlight] 는 선택 대상 고정 표시용)
class ForgePickCard extends StatelessWidget {
  final TicketInstance instance;
  final bool picked;
  final VoidCallback? onTap;

  /// 강화 STEP 2 상단의 대상 카드처럼, 고를 수 없고 그냥 강조만 하는 경우.
  final bool highlight;

  const ForgePickCard({
    super.key,
    required this.instance,
    required this.picked,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ticket = LuckCatalog.byId(instance.ticketId);
    if (ticket == null) return const SizedBox.shrink();
    final style = RarityStyle.of(ticket.rarity);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: picked ? style.soft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: picked ? style.color : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            if (highlight)
              TossEmoji(TossFace.star, size: 18)
            else
              Icon(
                picked
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: picked ? style.color : AppColors.disabled,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        LuckCatalog.rarityName(ticket.rarity, lang),
                        style: AppText.base(
                            size: 10.5,
                            weight: FontWeight.w800,
                            color: style.color),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        instance.plus > 0
                            ? l.dexPlus(instance.plus)
                            : l.forgeCardBase,
                        style: AppText.base(
                            size: 10.5,
                            weight: FontWeight.w800,
                            color: AppColors.sub,
                            letterSpacingEm: 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.text(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.base(
                        size: 12.5,
                        weight: FontWeight.w700,
                        letterSpacingEm: -0.03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
