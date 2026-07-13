import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/luck_tickets.dart';
import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../models/ticket_instance.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/toss_face.dart';
import 'app_toast.dart';
import 'clover_mark.dart';
import 'collection_card.dart';
import 'forge_painters.dart';
import 'pressable.dart';
import 'rarity_style.dart';

/// 포지(강화·재조합) 연출에 주입되는 확정된 결과.
sealed class ForgeResult {
  const ForgeResult();
}

/// 강화 결과 — 서버가 실제로 굴린 확률([EnhanceOutcome.rate])까지 들어 있다.
/// 게이지는 이 값으로 차오른다(클라이언트 예측값이 아니라).
class ForgeEnhanceResult extends ForgeResult {
  final EnhanceOutcome outcome;
  final String ticketId;

  const ForgeEnhanceResult({required this.outcome, required this.ticketId});
}

/// 재조합 결과 — 새로 만들어진 카드.
class ForgeReforgeResult extends ForgeResult {
  final ReforgeOutcome outcome;

  const ForgeReforgeResult({required this.outcome});
}

/// 강화 플로우: 서버에서 결과를 **먼저** 확정하고, 확정된 결과로 연출을 재생한다.
/// (가챠 `runGachaPullFlow` 와 같은 패턴 — 빌드 중 상태 변경 방지)
///
/// 서버 판정이 나고 연출까지 띄웠으면 true. 오프라인(연결 실패)이거나 규칙에 걸려
/// 아무 일도 일어나지 않았으면 false — 호출자는 고른 카드를 지우면 안 된다.
Future<bool> runEnhanceFlow(
  BuildContext context,
  WidgetRef ref, {
  required String targetId,
  required List<String> materialIds,
}) async {
  // 연출이 그릴 카드는 **서버가 태우기 전에** 지갑에서 읽어 둔다.
  final target = _lookup(ref, targetId);
  final materials = _lookupAll(ref, materialIds);

  final EnhanceOutcome? r;
  try {
    r = await ref
        .read(appControllerProvider.notifier)
        .enhanceTicket(targetId, materialIds);
  } on GameConnectionException {
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
    }
    return false;
  }
  if (r == null) {
    // 서버가 규칙으로 거절함 — 조용히 끝내지 않는다. 알려주고 지갑을 다시 맞춘다.
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).forgeRejected);
    }
    _resync(ref);
    return false;
  }
  if (!context.mounted) return false;

  final rarity = LuckCatalog.byId(r.ticketId)?.rarity ?? Rarity.common;
  await _pushOverlay(
    context,
    result: ForgeEnhanceResult(outcome: r, ticketId: r.ticketId),
    target: target,
    materials: materials,
    accent: RarityStyle.of(rarity).color,
  );
  return true;
}

/// 재조합 플로우 — 재료를 갈아 새 카드를 만든다. 액센트는 결과 카드 등급색이지만,
/// 결과가 뒤집히기 전까지는 중립색으로 가려진다([ForgeOverlay._accent]).
/// 반환값의 의미는 [runEnhanceFlow] 와 같다.
Future<bool> runReforgeFlow(
  BuildContext context,
  WidgetRef ref, {
  required List<String> materialIds,
}) async {
  final materials = _lookupAll(ref, materialIds);

  final ReforgeOutcome? r;
  try {
    r = await ref
        .read(appControllerProvider.notifier)
        .reforgeTickets(materialIds);
  } on GameConnectionException {
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
    }
    return false;
  }
  if (r == null) {
    // 서버가 규칙으로 거절함 — 조용히 끝내지 않는다. 알려주고 지갑을 다시 맞춘다.
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).forgeRejected);
    }
    _resync(ref);
    return false;
  }
  if (!context.mounted) return false;

  final rarity =
      LuckCatalog.byId(r.instance.ticketId)?.rarity ?? Rarity.common;
  await _pushOverlay(
    context,
    result: ForgeReforgeResult(outcome: r),
    target: null,
    materials: materials,
    accent: RarityStyle.of(rarity).color,
  );
  return true;
}

/// 클라이언트 지갑이 서버와 어긋나 거절당한 것이므로(다른 세션에서 이미 태운 카드,
/// 낡은 인스턴스 id 등) 서버 기준으로 다시 맞춘다. 재동기화가 실패(오프라인)해도
/// 여기서 더 할 말은 없다 — 안내 토스트는 이미 떴다.
void _resync(WidgetRef ref) {
  unawaited(
    ref.read(appControllerProvider.notifier).refresh().catchError((_) {}),
  );
}

TicketInstance? _lookup(WidgetRef ref, String id) => ref
    .read(appControllerProvider)
    .tickets
    .where((t) => t.id == id)
    .firstOrNull;

List<TicketInstance> _lookupAll(WidgetRef ref, List<String> ids) {
  final wallet = ref.read(appControllerProvider).tickets;
  return [
    for (final id in ids)
      ...wallet.where((t) => t.id == id).take(1),
  ];
}

Future<void> _pushOverlay(
  BuildContext context, {
  required ForgeResult result,
  required TicketInstance? target,
  required List<TicketInstance> materials,
  required Color accent,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => ForgeOverlay(
        result: result,
        target: target,
        materials: materials,
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

/// 날아드는 재료 카드 — 중앙 카드의 축소판.
const double _matW = 54;
const double _matH = 74;

/// 확정된 [ForgeResult] 를 그리는 순수 연출 위젯 — 서버도 Riverpod 도 모른다.
///
/// [materials] 는 태워지는 **실제 카드들**, [target] 은 강화 대상 카드(재조합이면 null).
/// 개수가 아니라 카드를 받는 이유: 날아드는 재료도 중앙 카드도 사용자가 방금 고른
/// 그 카드로 보여야 "이 세 장을 태워 이 한 장을 올린다"가 전달된다.
class ForgeOverlay extends StatefulWidget {
  final ForgeResult result;
  final TicketInstance? target;
  final List<TicketInstance> materials;

  /// 결과 카드의 등급색. 재조합은 결과가 뒤집히기 전까지 쓰이지 않는다.
  final Color accent;

  const ForgeOverlay({
    super.key,
    required this.result,
    required this.materials,
    this.target,
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

  /// 재료 카드의 출발 각도(살짝 기울어져 날아온다) — 역시 고정.
  late final List<double> _tilts;

  bool get _isReforge => widget.result is ForgeReforgeResult;

  int get _materialCount => widget.materials.length;

  @override
  void initState() {
    super.initState();

    final rng = math.Random(4713);
    _origins = List.generate(_materialCount, (i) {
      // 화면 바깥 링 위의 점 — 균등 분포에 약간의 흔들림.
      final ang = (i / math.max(1, _materialCount)) * 2 * math.pi +
          (rng.nextDouble() - 0.5) * 0.7;
      final dist = 220 + rng.nextDouble() * 80;
      return Offset(math.cos(ang) * dist, math.sin(ang) * dist);
    });
    _tilts =
        List.generate(_materialCount, (_) => (rng.nextDouble() - 0.5) * 0.5);

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
    for (var i = 0; i < _materialCount; i++) {
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

  /// 재조합 카드 플립 진행 (0 = 뒷면, 1 = 앞면).
  double get _flipT => _phase != _Phase.result
      ? 0
      : Curves.easeOutCubic.transform((_resultMs / _flipMs).clamp(0.0, 1.0));

  /// 재조합 카드 플립(Y축).
  ///
  /// 결과 이전 페이즈에서는 계속 π(=뒷면)에 머무르고, 결과 페이즈에서 π → 0 으로
  /// **한 번만** 앞으로 돌아간다. 결과 시작 시점의 값이 정확히 π 라서 스냅이 없다.
  /// 강화는 항상 앞면이므로 0.
  double get _flipY => _isReforge ? (1 - _flipT) * math.pi : 0;

  /// 화면을 칠하는 색.
  ///
  /// 재조합은 결과 카드의 등급색이 **연출 내내** 새면 뒤집기 전에 답을 알려주는 셈이다
  /// (미스틱 보라빛이 2.3초 먼저 빛난다). 그래서 뒤집히는 동안 중립 → 등급색으로 옮겨간다.
  /// 강화는 대상 카드의 등급색 = 이미 아는 정보라 그대로 쓴다.
  Color get _accent => _isReforge
      ? Color.lerp(AppColors.accent, widget.accent, _flipT)!
      : widget.accent;

  bool get _showResultUi => _phase == _Phase.result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = _accent;

    // 충전 중 카드가 살짝 떠오른다.
    final chargeT = _phase.index >= _Phase.charge.index ? _charge.value : 0.0;
    final lift = -10 * Curves.easeOut.transform(chargeT);
    final scale = 1 + 0.06 * Curves.easeOut.transform(chargeT);
    final spin = _isReforge ? chargeT * chargeT * 6 * math.pi : 0.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      // 실패 쉐이크는 카드 무대가 아니라 **화면 전체**(뱃지·CTA·연출 레이어)를 흔든다.
      body: Transform.translate(
        offset: Offset(_shakeDx, 0),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 강화 게이지 링 — 서버가 실제로 굴린 확률만큼 차오른다.
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
      ),
    );
  }

  /// 게이지가 차오르는 확률 — **서버가 적용한** 값([EnhanceOutcome.rate]).
  int get _enhanceRate => switch (widget.result) {
        ForgeEnhanceResult(:final outcome) => outcome.rate,
        ForgeReforgeResult() => 0,
      };

  /// 중앙에 놓이는 카드 — 강화면 지갑에서 읽어 둔 대상 카드, 재조합이면 새로 나온 카드.
  /// 대상을 못 찾았으면(지갑에 없던 id) 서버가 알려준 최소 정보로 세운다.
  TicketInstance get _centerCard => switch (widget.result) {
        ForgeEnhanceResult(:final outcome) =>
          widget.target ??
              TicketInstance(
                id: outcome.instanceId,
                ticketId: outcome.ticketId,
                level: outcome.success ? outcome.level - 1 : outcome.level,
                pulledAt: '',
              ),
        ForgeReforgeResult(:final outcome) => outcome.instance,
      };

  Widget _targetCard(AppLocalizations l) {
    // 재조합은 결과 페이즈에서 절반쯤 뒤집힐 때까지 계속 뒷면 — 그 전 페이즈(흡수·충전·정지)
    // 에서는 문구도 등급색도 절대 새지 않는다. 강화는 언제나 앞면.
    final faceDown =
        _isReforge && (_phase != _Phase.result || _flipY > math.pi / 2);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: _cardW,
          height: _cardH,
          child: faceDown
              // 카드 자체가 Y축으로 뒤집혀 있으니, 뒷면 문양은 되돌려서 거울상이 되지 않게.
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: const _CardBack(),
                )
              : _CardFace(instance: _centerCard),
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
                color: _accent,
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

  /// 날아드는 재료 — 각자 자기 등급색과 강화 단계를 그대로 달고 온다.
  List<Widget> _materialCards() {
    final elapsed = _absorb.value * _absorbDur.inMilliseconds;
    return [
      for (var i = 0; i < _materialCount; i++)
        Builder(builder: (_) {
          final raw =
              ((elapsed - i * _staggerMs) / _flightMs).clamp(0.0, 1.0);
          final t = Curves.easeInCubic.transform(raw);
          final o = _origins[i];
          return Transform.translate(
            offset: Offset(o.dx * (1 - t), o.dy * (1 - t)),
            child: Opacity(
              opacity: (1 - t * t).clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: _tilts[i] * (1 - t),
                child: Transform.scale(
                  scale: 1 - 0.7 * t,
                  child: SizedBox(
                    width: _matW,
                    height: _matH,
                    child: _CardFace(
                        instance: widget.materials[i], compact: true),
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

/// 지갑/포지와 같은 시각 어휘로 그린 카드 한 장 — 등급 그라데이션 · 등급색 테두리 ·
/// 클로버 마크 · 강화 단계 · 문구. [compact] 는 날아드는 재료용 축소판(문구 없음).
class _CardFace extends StatelessWidget {
  final TicketInstance instance;
  final bool compact;

  const _CardFace({required this.instance, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ticket = LuckCatalog.byId(instance.ticketId);
    final rarity = ticket?.rarity ?? Rarity.common;
    final style = RarityStyle.of(rarity);

    if (compact) {
      return CollectionCard(
        style: style,
        borderRadius: 10,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CloverMark(size: 20, color: style.color),
              if (instance.plus > 0) ...[
                const SizedBox(height: 3),
                Text(
                  l.dexPlus(instance.plus),
                  style: AppText.base(
                    size: 11,
                    weight: FontWeight.w800,
                    color: style.color,
                    letterSpacingEm: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return CollectionCard(
      style: style,
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CloverMark(size: 13, color: style.color),
                const SizedBox(width: 5),
                Text(
                  LuckCatalog.rarityName(rarity, lang),
                  style: AppText.base(
                      size: 10, weight: FontWeight.w800, color: style.color),
                ),
                const Spacer(),
                if (instance.plus > 0)
                  Text(
                    l.dexPlus(instance.plus),
                    style: AppText.base(
                      size: 14,
                      weight: FontWeight.w800,
                      color: style.color,
                      letterSpacingEm: 0,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              ticket?.text(lang) ?? '',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                size: 14,
                weight: FontWeight.w800,
                height: 1.4,
                letterSpacingEm: -0.03,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// 재조합 카드의 뒷면 — 등급을 한 톨도 흘리지 않는 중립 면.
class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const TossEmoji(TossFace.recycle, size: 40),
    );
  }
}
