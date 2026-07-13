import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'clover_mark.dart';
import 'collection_card.dart';
import 'gacha_machine.dart';
import 'pressable.dart';
import 'rarity_style.dart';

/// 뽑기 전체 플로우: 코인 투입 → 레버 → 캡슐 낙하 → 탭 개봉 → 결과 카드.
/// 뽑기 도중에는 어떤 광고도 끼어들지 않는다 — 광고는 뽑기 화면에서 사용자가
/// 직접 누르는 '광고 보고 클로버 받기' 하나뿐이다.
/// 호출 전에 클로버 보유 여부를 확인해야 한다 (뽑기는 언제나 클로버 1개).
Future<void> runGachaPullFlow(BuildContext context, WidgetRef ref) async {
  // 뽑기는 라우트 진입 전에 서버에서 확정한다 (빌드 중 상태 변경 방지).
  final PullResult? result;
  try {
    result = await ref.read(appControllerProvider.notifier).pullGacha();
  } on GameConnectionException {
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
    }
    return;
  }
  if (result == null || !context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _GachaPullOverlay(firstResult: result!),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

enum _Phase { coin, lever, drop, waitTap, open, reveal }

/// 머신 렌더 폭과, 논리 캔버스 → 화면 좌표 배율.
const double _machineWidth = 280;
const double _machineScale = _machineWidth / 300; // GachaMachine.canvas.width

class _GachaPullOverlay extends ConsumerStatefulWidget {
  final PullResult firstResult;
  const _GachaPullOverlay({required this.firstResult});

  @override
  ConsumerState<_GachaPullOverlay> createState() => _GachaPullOverlayState();
}

class _GachaPullOverlayState extends ConsumerState<_GachaPullOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _machine; // coin/lever/drop 공용
  late final AnimationController _burst; // 개봉 버스트
  late final AnimationController _card; // 결과 카드 등장

  _Phase _phase = _Phase.coin;
  PullResult? _result;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _machine = AnimationController(vsync: this)
      ..addStatusListener(_onMachinePhaseDone)
      ..addListener(() => setState(() {}));
    _burst = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..addListener(() => setState(() {}));
    _card = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _startSequence(widget.firstResult);
  }

  /// 확정된 뽑기 결과로 연출 시퀀스를 (재)시작한다.
  void _startSequence(PullResult r) {
    _result = r;
    _card.value = 0;
    _burst.value = 0;
    _phase = _Phase.coin;
    HapticFeedback.selectionClick();
    _machine
      ..duration = const Duration(milliseconds: 520)
      ..forward(from: 0);
  }

  void _onMachinePhaseDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    switch (_phase) {
      case _Phase.coin:
        _phase = _Phase.lever;
        HapticFeedback.mediumImpact();
        _machine
          ..duration = const Duration(milliseconds: 850)
          ..forward(from: 0);
      case _Phase.lever:
        _phase = _Phase.drop;
        HapticFeedback.lightImpact();
        // 캡슐이 슈트를 빠져나와 배출구에 닿는 순간(≈72%)에 한 번 더.
        Future.delayed(const Duration(milliseconds: 720), () {
          if (mounted && _phase == _Phase.drop) HapticFeedback.lightImpact();
        });
        _machine
          ..duration = const Duration(milliseconds: 1000)
          ..forward(from: 0);
      case _Phase.drop:
        setState(() => _phase = _Phase.waitTap);
        HapticFeedback.mediumImpact();
      case _Phase.waitTap:
      case _Phase.open:
      case _Phase.reveal:
        break;
    }
  }

  void _openCapsule() {
    if (_phase != _Phase.waitTap) return;
    setState(() => _phase = _Phase.open);
    final rarity = _result!.ticket.rarity;
    // 등급이 높을수록 존재감 있는 햅틱.
    HapticFeedback.heavyImpact();
    if (rarity.index >= Rarity.legendary.index) {
      Future.delayed(const Duration(milliseconds: 140), HapticFeedback.heavyImpact);
      Future.delayed(const Duration(milliseconds: 300), HapticFeedback.mediumImpact);
    }
    _burst.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _phase = _Phase.reveal);
      _card.forward(from: 0);
    });
  }

  void _confirm() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _machine.dispose();
    _burst.dispose();
    _card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = _result;
    if (result == null) {
      return const Scaffold(backgroundColor: AppColors.white, body: SizedBox());
    }
    final style = RarityStyle.of(result.ticket.rarity);
    final revealing = _phase == _Phase.reveal;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: revealing
                    ? _resultCard(l, result, style)
                    : _machineStage(l, result, style),
              ),
            ),
            if (revealing) _resultButtons(l),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- 머신 연출 스테이지 ----
  Widget _machineStage(AppLocalizations l, PullResult result, RarityStyle style) {
    final t = _machine.value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCapsule,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: _machineWidth,
                child: GachaMachine(
                  coinT: _phase == _Phase.coin ? t : (_phase.index > 0 ? 1 : 0),
                  leverT: _phase == _Phase.lever
                      ? t
                      : (_phase.index > _Phase.lever.index ? 1 : 0),
                  dropT: switch (_phase) {
                    _Phase.coin || _Phase.lever => 0,
                    _Phase.drop => t,
                    _ => 1,
                  },
                  capsuleColor: style.color,
                ),
              ),
              // 개봉 버스트 — 기계 앞에 멈춘 캡슐 위치에서 퍼진다.
              if (_phase == _Phase.open)
                Positioned(
                  left: GachaMachine.droppedCapsuleCenter.dx * _machineScale - 90,
                  top: GachaMachine.droppedCapsuleCenter.dy * _machineScale - 90,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                        painter: _BurstPainter(_burst.value, style.color)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _phase == _Phase.waitTap ? 1 : 0,
            child: Text(
              l.gachaTapCapsule,
              style: AppText.base(
                  size: 16, weight: FontWeight.w700, color: AppColors.sub),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 결과 카드 ----
  /// 지갑에 들어갈 그 카드를 그대로 보여준다 — 도감/상세와 같은 [CollectionCard].
  /// "방금 이 카드를 얻었다"가 한눈에 읽히도록 배지는 카드 밖 위쪽에 띄운다.
  Widget _resultCard(AppLocalizations l, PullResult result, RarityStyle style) {
    final lang = Localizations.localeOf(context).languageCode;
    final rarityName = LuckCatalog.rarityName(result.ticket.rarity, lang);
    final text = result.ticket.text(lang);
    // 긴 문구는 한 단계 줄여서 카드 안에 자연스럽게 앉힌다.
    final textSize = text.length > 46
        ? 17.0
        : text.length > 30
            ? 19.0
            : 21.0;

    return ScaleTransition(
      scale: CurvedAnimation(parent: _card, curve: Curves.easeOutBack),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NEW / 중복 배지 — 이번 뽑기에서만 의미 있는 정보라 카드 밖에 둔다.
            if (result.isNew)
              _chip(l.resultNew, style.color, filled: true)
            else
              _chip(l.resultDup(result.copies), AppColors.sub, filled: false),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: CollectionCard(
                style: style,
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 등급 + 번호 — 지갑 카드와 같은 머리글.
                      Row(
                        children: [
                          CloverMark(size: 15, color: style.color),
                          const SizedBox(width: 6),
                          Text(
                            rarityName,
                            style: AppText.base(
                                size: 12,
                                weight: FontWeight.w800,
                                color: style.color),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No.${result.ticket.id.substring(1)}',
                            style: AppText.base(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.sub,
                                letterSpacingEm: 0),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        text,
                        style: AppText.base(
                          size: textSize,
                          weight: FontWeight.w800,
                          height: 1.4,
                          letterSpacingEm: -0.03,
                        ),
                      ),
                      const Spacer(),
                      // 중복이면 강화 재료로 쓸 수 있다는 안내를 카드 발치에.
                      if (result.isNew)
                        Text(
                          l.ticketFirstPulled(result.instance.pulledAt),
                          style: AppText.base(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: AppColors.sub),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius:
                                BorderRadius.circular(AppRadius.chipFull),
                          ),
                          child: Text(l.resultMaterial,
                              style: AppText.base(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: style.color)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.chipFull),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: AppText.base(
          size: 11.5,
          weight: FontWeight.w800,
          color: filled ? Colors.white : color,
          letterSpacingEm: 0.06,
        ),
      ),
    );
  }

  Widget _resultButtons(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Pressable(
        onTap: _confirm,
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
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(l.resultConfirm,
              style: AppText.base(
                  size: 17, weight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

/// 광채 링 + 스파클 버스트 (등급색).
class _BurstPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  _BurstPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    for (var r = 0; r < 2; r++) {
      final lt = (t - r * 0.12).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final radius = 24 + (size.width * 0.5) * lt;
      final opacity = (0.5 * (1 - lt)).clamp(0.0, 1.0);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final sp = t < 0.4 ? (t / 0.4) : (1 - (t - 0.4) / 0.6);
    final spScale =
        (t < 0.4 ? 1.4 * (t / 0.4) : 1.4 * (1 - (t - 0.4) / 0.6)).clamp(0.0, 1.4);
    final spOpacity = sp.clamp(0.0, 1.0);
    final dist = 40 + 30 * t;
    for (var k = 0; k < 12; k++) {
      final ang = (k * 30) * math.pi / 180;
      final p = c + Offset(dist * math.cos(ang), dist * math.sin(ang));
      canvas.drawCircle(
        p,
        3.0 * spScale,
        Paint()..color = color.withValues(alpha: spOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}
