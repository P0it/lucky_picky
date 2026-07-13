import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/toss_face.dart';
import 'app_toast.dart';
import 'forge_painters.dart';
import 'pressable.dart';
import 'rarity_style.dart';

/// 포지(강화·재조합) 연출에 주입되는 확정된 결과.
sealed class ForgeResult {
  const ForgeResult();
}

/// 강화 결과 — 대상 카드([ticketId])와 적용된 확률([rate], %)을 함께 들고 있다.
class ForgeEnhanceResult extends ForgeResult {
  final EnhanceOutcome outcome;
  final String ticketId;
  final int rate;

  const ForgeEnhanceResult({
    required this.outcome,
    required this.ticketId,
    required this.rate,
  });
}

/// 재조합 결과 — 새로 만들어진 카드.
class ForgeReforgeResult extends ForgeResult {
  final ReforgeOutcome outcome;

  const ForgeReforgeResult({required this.outcome});
}

/// 강화 플로우: 서버에서 결과를 **먼저** 확정하고, 확정된 결과로 연출을 재생한다.
/// (가챠 `runGachaPullFlow` 와 같은 패턴 — 빌드 중 상태 변경 방지)
Future<void> runEnhanceFlow(
  BuildContext context,
  WidgetRef ref, {
  required String targetId,
  required List<String> materialIds,
  required int rate,
}) async {
  final EnhanceOutcome? r;
  try {
    r = await ref
        .read(appControllerProvider.notifier)
        .enhanceTicket(targetId, materialIds);
  } on GameConnectionException {
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
    }
    return;
  }
  if (r == null || !context.mounted) return;
  final result = ForgeEnhanceResult(outcome: r, ticketId: r.ticketId, rate: rate);
  final rarity = LuckCatalog.byId(r.ticketId)?.rarity ?? Rarity.common;
  await _pushOverlay(
    context,
    result: result,
    materialCount: materialIds.length,
    accent: RarityStyle.of(rarity).color,
  );
}

/// 재조합 플로우 — 재료를 갈아 새 카드를 만든다. 액센트는 결과 카드 등급색.
Future<void> runReforgeFlow(
  BuildContext context,
  WidgetRef ref, {
  required List<String> materialIds,
}) async {
  final ReforgeOutcome? r;
  try {
    r = await ref
        .read(appControllerProvider.notifier)
        .reforgeTickets(materialIds);
  } on GameConnectionException {
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
    }
    return;
  }
  if (r == null || !context.mounted) return;
  final rarity =
      LuckCatalog.byId(r.instance.ticketId)?.rarity ?? Rarity.common;
  await _pushOverlay(
    context,
    result: ForgeReforgeResult(outcome: r),
    materialCount: materialIds.length,
    accent: RarityStyle.of(rarity).color,
  );
}

Future<void> _pushOverlay(
  BuildContext context, {
  required ForgeResult result,
  required int materialCount,
  required Color accent,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => ForgeOverlay(
        result: result,
        materialCount: materialCount,
        accent: accent,
      ),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// 흡수 → 충전 → 정지 → 결과.
enum _Phase { absorb, charge, hold, result }

const Duration _absorbDur = Duration(milliseconds: 800);
const Duration _chargeDur = Duration(milliseconds: 1200);
const Duration _holdDur = Duration(milliseconds: 300);
const Duration _resultDur = Duration(milliseconds: 900);

/// 재료 카드 한 장의 비행 시간과 카드 사이 스태거.
const double _flightMs = 440;
const double _staggerMs = 120;

/// 결과 페이즈 세부 타이밍(ms).
const double _flashMs = 180; // 흰 플래시 페이드아웃
const double _burstMs = 650; // 성공 버스트
const double _shakeMs = 420; // 실패 쉐이크 감쇠
const double _flipMs = 620; // 재조합 카드 플립

const double _cardW = 150;
const double _cardH = 200;

/// 확정된 [ForgeResult] 를 그리는 순수 연출 위젯 — 서버도 Riverpod 도 모른다.
class ForgeOverlay extends StatefulWidget {
  final ForgeResult result;
  final int materialCount;
  final Color accent;

  const ForgeOverlay({
    super.key,
    required this.result,
    required this.materialCount,
    required this.accent,
  });

  @override
  State<ForgeOverlay> createState() => _ForgeOverlayState();
}

class _ForgeOverlayState extends State<ForgeOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _absorb;
  late final AnimationController _charge;
  late final AnimationController _hold;
  late final AnimationController _result;

  Timer? _chargeTicks; // 충전 중 240ms 셀렉션 햅틱
  final List<Timer> _pending = []; // 흡수 도착 / 결과 햅틱 타이머

  _Phase _phase = _Phase.absorb;

  /// 재료 카드의 출발 지점 — 고정 시드로 한 번만 뽑는다(프레임마다 랜덤 금지).
  late final List<Offset> _origins;

  bool get _isReforge => widget.result is ForgeReforgeResult;

  @override
  void initState() {
    super.initState();

    final rng = math.Random(4713);
    _origins = List.generate(widget.materialCount, (i) {
      // 화면 바깥 링 위의 점 — 균등 분포에 약간의 흔들림.
      final ang = (i / math.max(1, widget.materialCount)) * 2 * math.pi +
          (rng.nextDouble() - 0.5) * 0.7;
      final dist = 220 + rng.nextDouble() * 80;
      return Offset(math.cos(ang) * dist, math.sin(ang) * dist);
    });

    _absorb = AnimationController(vsync: this, duration: _absorbDur)
      ..addListener(_repaint);
    _charge = AnimationController(vsync: this, duration: _chargeDur)
      ..addListener(_repaint);
    _hold = AnimationController(vsync: this, duration: _holdDur);
    _result = AnimationController(vsync: this, duration: _resultDur)
      ..addListener(_repaint);

    _startAbsorb();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  void _later(int ms, VoidCallback fn) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _pending.remove(t);
      if (mounted) fn();
    });
    _pending.add(t);
  }

  // ---- 시퀀스 ----

  void _startAbsorb() {
    HapticFeedback.selectionClick();
    // 카드가 중앙에 닿는 순간마다 톡.
    for (var i = 0; i < widget.materialCount; i++) {
      _later((i * _staggerMs + _flightMs).round(), HapticFeedback.lightImpact);
    }
    _absorb.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _phase = _Phase.charge);
      _startCharge();
    });
  }

  void _startCharge() {
    _chargeTicks = Timer.periodic(
      const Duration(milliseconds: 240),
      (_) => HapticFeedback.selectionClick(),
    );
    _charge.forward(from: 0).whenComplete(() {
      _chargeTicks?.cancel();
      _chargeTicks = null;
      if (!mounted) return;
      setState(() => _phase = _Phase.hold);
      // 정지 = 긴장. 아무것도 안 하지만 프레임은 계속 흐른다.
      _hold.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() => _phase = _Phase.result);
        _startResult();
      });
    });
  }

  void _startResult() {
    switch (widget.result) {
      case ForgeEnhanceResult(:final outcome):
        if (outcome.success) {
          HapticFeedback.heavyImpact();
          _later(140, HapticFeedback.heavyImpact);
          _later(300, HapticFeedback.heavyImpact);
        } else {
          HapticFeedback.heavyImpact();
        }
      case ForgeReforgeResult(:final outcome):
        HapticFeedback.heavyImpact();
        if (outcome.upgraded) _later(160, HapticFeedback.mediumImpact);
    }
    _result.forward(from: 0);
  }

  @override
  void dispose() {
    _chargeTicks?.cancel();
    for (final t in _pending) {
      t.cancel();
    }
    _pending.clear();
    _absorb.dispose();
    _charge.dispose();
    _hold.dispose();
    _result.dispose();
    super.dispose();
  }

  // ---- 파생 진행값 ----

  double get _resultMs => _result.value * _resultDur.inMilliseconds;

  /// 흰 플래시 — 결과 시작 순간 번쩍이고 180ms 만에 사라진다.
  double get _flash {
    if (_phase != _Phase.result || !_flashes) return 0;
    return (1 - _resultMs / _flashMs).clamp(0.0, 1.0);
  }

  bool get _flashes => switch (widget.result) {
        ForgeEnhanceResult(:final outcome) => outcome.success,
        ForgeReforgeResult(:final outcome) => outcome.upgraded,
      };

  bool get _bursts => _flashes;

  bool get _cracks => switch (widget.result) {
        ForgeEnhanceResult(:final outcome) => !outcome.success,
        ForgeReforgeResult() => false,
      };

  double get _burstT =>
      _phase == _Phase.result ? (_resultMs / _burstMs).clamp(0.0, 1.0) : 0;

  double get _crackT =>
      _phase == _Phase.result ? (_resultMs / _burstMs).clamp(0.0, 1.0) : 0;

  /// 실패 쉐이크 — ±6px, 420ms 감쇠 사인.
  double get _shakeDx {
    if (!_cracks || _phase != _Phase.result) return 0;
    final t = (_resultMs / _shakeMs).clamp(0.0, 1.0);
    if (t >= 1) return 0;
    return math.sin(t * math.pi * 5) * 6 * (1 - t);
  }

  /// 재조합 카드 플립(Y축) — 0.5회전에서 앞면으로 뒤집힌다.
  double get _flipY {
    if (!_isReforge || _phase != _Phase.result) return 0;
    final t = Curves.easeOutCubic
        .transform((_resultMs / _flipMs).clamp(0.0, 1.0));
    return (1 - t) * math.pi;
  }

  bool get _showResultUi => _phase == _Phase.result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = widget.accent;

    // 충전 중 카드가 살짝 떠오른다.
    final chargeT = _phase.index >= _Phase.charge.index ? _charge.value : 0.0;
    final lift = -10 * Curves.easeOut.transform(chargeT);
    final scale = 1 + 0.06 * Curves.easeOut.transform(chargeT);
    final spin = _isReforge ? chargeT * chargeT * 6 * math.pi : 0.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(_shakeDx, 0),
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 강화 게이지 링 — 확률만큼 차오른다.
                            if (!_isReforge &&
                                _phase.index >= _Phase.charge.index)
                              SizedBox(
                                width: 300,
                                height: 300,
                                child: CustomPaint(
                                  painter: ForgeGaugePainter(
                                    t: chargeT,
                                    rate: _enhanceRate / 100,
                                    color: accent,
                                  ),
                                ),
                              ),
                            // 성공/승급 버스트.
                            if (_bursts && _phase == _Phase.result)
                              SizedBox(
                                width: 300,
                                height: 300,
                                child: CustomPaint(
                                  painter: ForgeBurstPainter(
                                      t: _burstT, color: accent),
                                ),
                              ),
                            // 중앙 대상 카드.
                            Transform.translate(
                              offset: Offset(0, lift),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012)
                                  ..rotateY(spin + _flipY)
                                  ..scaleByDouble(scale, scale, 1, 1),
                                child: _targetCard(l),
                              ),
                            ),
                            // 흡수 중인 재료 카드들.
                            if (_phase == _Phase.absorb) ..._materialCards(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showResultUi) _badge(l),
                const SizedBox(height: 20),
                if (_showResultUi) _confirmCta(l),
                const SizedBox(height: 28),
              ],
            ),
          ),
          // 성공 순간의 흰 플래시.
          if (_flash > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: AppColors.white.withValues(alpha: _flash),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int get _enhanceRate => switch (widget.result) {
        ForgeEnhanceResult(:final rate) => rate,
        ForgeReforgeResult() => 0,
      };

  /// 중앙 카드에 적힌 행운권 문구 — 재조합이면 새로 만들어진 카드의 문구.
  String _cardText() {
    final lang = Localizations.localeOf(context).languageCode;
    final id = switch (widget.result) {
      ForgeEnhanceResult(:final ticketId) => ticketId,
      ForgeReforgeResult(:final outcome) => outcome.instance.ticketId,
    };
    return LuckCatalog.byId(id)?.text(lang) ?? '';
  }

  Widget _targetCard(AppLocalizations l) {
    final accent = widget.accent;
    // 재조합은 결과 페이즈에서 뒤집히기 전까지 뒷면(문구를 감춘다).
    final faceDown = _isReforge && _flipY > math.pi / 2;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: _cardW,
          height: _cardH,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.10),
                accent.withValues(alpha: 0.26),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: faceDown
              ? TossEmoji(TossFace.recycle, size: 40)
              : Text(
                  _cardText(),
                  textAlign: TextAlign.center,
                  style: AppText.base(
                    size: 15,
                    weight: FontWeight.w800,
                    height: 1.45,
                    letterSpacingEm: -0.03,
                  ),
                ),
        ),
        // 실패 균열은 카드 위에 그린다.
        if (_cracks && _phase == _Phase.result)
          SizedBox(
            width: _cardW,
            height: _cardH,
            child: CustomPaint(painter: ForgeCrackPainter(t: _crackT)),
          ),
        // 성공 각인 — +N 이 카드 위로 튀어나온다.
        if (_engravePlus != null && _phase == _Phase.result)
          Transform.scale(
            scale: Curves.easeOutBack
                .transform((_resultMs / 520).clamp(0.0, 1.0)),
            child: Text(
              l.forgeSuccessPlus(_engravePlus!),
              style: AppText.base(
                size: 46,
                weight: FontWeight.w800,
                color: widget.accent,
              ),
            ),
          ),
      ],
    );
  }

  /// 성공 시 각인할 강화 단계 (level 3 → +2). 실패·재조합이면 null.
  int? get _engravePlus => switch (widget.result) {
        ForgeEnhanceResult(:final outcome) =>
          outcome.success ? outcome.level - 1 : null,
        ForgeReforgeResult() => null,
      };

  List<Widget> _materialCards() {
    final elapsed = _absorb.value * _absorbDur.inMilliseconds;
    return [
      for (var i = 0; i < widget.materialCount; i++)
        Builder(builder: (_) {
          final raw =
              ((elapsed - i * _staggerMs) / _flightMs).clamp(0.0, 1.0);
          final t = Curves.easeInCubic.transform(raw);
          final o = _origins[i];
          return Transform.translate(
            offset: Offset(o.dx * (1 - t), o.dy * (1 - t)),
            child: Opacity(
              opacity: (1 - t * t).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 - 0.7 * t,
                child: Container(
                  width: 46,
                  height: 62,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.6), width: 1.2),
                  ),
                ),
              ),
            ),
          );
        }),
    ];
  }

  Widget _badge(AppLocalizations l) {
    final (String emoji, String title, String? hint) = switch (widget.result) {
      ForgeEnhanceResult(:final outcome) when outcome.success => (
          TossFace.party,
          l.forgeSuccess,
          null,
        ),
      ForgeEnhanceResult() => (TossFace.boom, l.forgeFail, l.forgeFailHint),
      ForgeReforgeResult(:final outcome) when outcome.upgraded => (
          TossFace.sparkles,
          l.forgeUpgraded,
          null,
        ),
      ForgeReforgeResult() => (TossFace.clover, l.forgeReforged, null),
    };

    return Opacity(
      opacity: Curves.easeOut.transform((_resultMs / 400).clamp(0.0, 1.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TossEmoji(emoji, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.base(size: 22, weight: FontWeight.w800),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppText.base(
                  size: 14, weight: FontWeight.w600, color: AppColors.sub),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confirmCta(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Pressable(
        onTap: () => Navigator.of(context).maybePop(),
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
          child: Text(
            l.forgeConfirm,
            style: AppText.base(
                size: 17, weight: FontWeight.w700, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
