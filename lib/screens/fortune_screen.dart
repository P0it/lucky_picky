import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/daily_fortune.dart';
import '../state/ads_controller.dart';
import '../state/app_controller.dart';
import '../state/copy_controller.dart';
import '../state/fortune_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/fortune_card.dart';
import '../widgets/luck_gauge.dart';
import '../widgets/pressable.dart';
import '../widgets/talisman_export.dart';

/// 오늘의 행운지수 — 타이밍 게이지 미니게임.
/// 게이지가 0~100을 왕복하고, 탭한 순간의 값이 오늘의 행운지수가 된다.
/// 행운은 "받는" 게 아니라 "잡는" 것 — 서비스 정체성(능동적 행운 쟁취)의 축.
class FortuneScreen extends ConsumerStatefulWidget {
  const FortuneScreen({super.key});

  @override
  ConsumerState<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends ConsumerState<FortuneScreen>
    with SingleTickerProviderStateMixin {
  // 한 방향 스윕에 1.1초. 표시값에 pow 커브를 걸어 고득점 구간(90+)을
  // 순식간에 스치게 한다 — "100점 잡는 맛".
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  final _boundaryKey = GlobalKey();
  bool _replaying = false; // 광고 재도전으로 게이지를 다시 돌리는 중
  bool _running = false; // 게이지 가동 중 — 탭 진입만으로는 시작하지 않는다
  bool _justCaught = false; // 방금 잡음 → 카드 숫자 카운트업
  bool _showConfetti = false; // 고득점 축하 연출
  bool _busy = false;

  /// 이 점수 이상이면 컨페티 축하.
  static const _celebrateScore = 95;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? get _uid {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null; // Supabase 미초기화(테스트 등) / 오프라인 첫 실행
    }
  }

  /// 컨트롤러 t(0~1) → 게이지 표시값(0~1). 위로 갈수록 빨라지는 비선형 커브.
  /// 지수 2.4 기준 95점 이상 체류 시간은 스윕당 약 2% — 정점에 머물지 않는다.
  double _gaugeValue(double t) => math.pow(t, 2.4).toDouble();

  /// 시작 전이면 게이지 가동, 가동 중이면 그 순간의 값을 잡는다.
  void _onGaugeAction() {
    if (_running) {
      _catchLuck();
    } else {
      _startGauge();
    }
  }

  void _startGauge() {
    HapticFeedback.selectionClick();
    setState(() => _running = true);
    _ctrl.value = 0;
    _ctrl.repeat(reverse: true);
  }

  void _catchLuck() {
    if (!_ctrl.isAnimating) return;
    _ctrl.stop();
    HapticFeedback.mediumImpact();
    final score = (_gaugeValue(_ctrl.value) * 100).round().clamp(0, 100);
    _justCaught = true;
    _replaying = false;
    _running = false;
    _showConfetti = score >= _celebrateScore;
    ref.read(fortuneControllerProvider.notifier).commitScore(score);
  }

  /// 개발 전용 — 오늘 점수/재도전 소진을 지우고 게이지 화면으로 되돌린다.
  void _devReset() {
    ref.read(fortuneControllerProvider.notifier).devResetToday();
    setState(() {
      _replaying = false;
      _running = false;
      _justCaught = false;
      _showConfetti = false;
    });
  }

  void _retryWithAd() {
    AdsController.instance.showRewarded(onReward: () {
      if (!mounted) return;
      ref.read(fortuneControllerProvider.notifier).markRetryUsed();
      setState(() {
        _replaying = true;
        _running = false; // 재도전도 시작 버튼을 눌러야 가동
        _justCaught = false;
        _showConfetti = false;
      });
    });
  }

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

  String get _fileName =>
      'luckypicky_fortune_${DailyFortune.dateKeyOf(DateTime.now()).replaceAll('-', '')}';

  Future<void> _save() => _withBusy(() async {
        final bytes = await captureBoundaryPng(_boundaryKey);
        await saveTalismanToGallery(bytes, _fileName);
        if (mounted) showAppToast(context, AppLocalizations.of(context).toastSavedToAlbum);
      }, failMsg: AppLocalizations.of(context).talismanSaveFail);

  Future<void> _share(int score) {
    final shareText = AppLocalizations.of(context).fortuneShareText(score);
    return _withBusy(() async {
      final bytes = await captureBoundaryPng(_boundaryKey);
      await shareTalisman(bytes, _fileName, text: shareText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fortune = ref.watch(fortuneControllerProvider);

    if (!fortune.loaded) return const SizedBox.shrink();

    final playing = fortune.todayScore == null || _replaying;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.fortuneTitle,
                      style: AppText.base(
                          size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
                  const SizedBox(height: 6),
                  Text(l.fortuneSubtitle,
                      style: AppText.base(
                          size: 14.5, weight: FontWeight.w500, color: AppColors.sub)),
                ],
              ),
            ),
            if (playing) _playView(l) else _resultView(l, fortune),
          ],
        ),
        // 고득점 축하 — 잡은 직후 한 번만 흩날린다.
        if (!playing && _showConfetti) const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }

  // ── 플레이: 왕복 게이지 + 잡기 버튼 ──────────────────────────────
  Widget _playView(AppLocalizations l) {
    final statLeaves =
        ref.watch(appControllerProvider.select((s) => s.statLeaves));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
      child: Column(
        children: [
          // 선행 응원 카피 — 보상 아님, 정체성 연출.
          if (statLeaves > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.chipFull),
              ),
              child: Text(
                l.fortuneDeedCheer(statLeaves),
                style: AppText.base(
                    size: 12.5, weight: FontWeight.w700, color: AppColors.accent),
              ),
            ),
          const SizedBox(height: 18),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onGaugeAction,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) =>
                  LuckGauge(value: _running ? _gaugeValue(_ctrl.value) : 0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.fortuneGaugeHint,
            textAlign: TextAlign.center,
            style: AppText.base(
                size: 13.5, weight: FontWeight.w500, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: _onGaugeAction,
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
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                _running ? l.fortuneCta : l.fortuneStartCta,
                style: AppText.base(
                    size: 17, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 결과: 운세 카드 + 재도전/공유 ────────────────────────────────
  Widget _resultView(AppLocalizations l, FortuneState state) {
    final score = state.todayScore!;
    final now = DateTime.now();
    final fortune = DailyFortune.compose(_uid, now, score);
    final animate = _justCaught;
    _justCaught = false; // 카운트업은 잡은 직후 1회만

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x14191F28), blurRadius: 30, offset: Offset(0, 12)),
              ],
            ),
            // ClipRRect/그림자는 미리보기 전용 — 캡처 원본은 꽉 찬 사각형.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: FortuneCard(fortune: fortune, animateScore: animate),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 오늘의 선행 추천 — 카드 밖에서 가볍게 (카드는 최소 구성 유지).
          // 운세 멘트로 오독되지 않게 라벨을 명시한다.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  '🍀 ${l.fortuneAdviceLabel}',
                  style: AppText.base(
                      size: 12, weight: FontWeight.w700, color: AppColors.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.watch(copyBookProvider).fortuneAdvice(
                      Localizations.localeOf(context).languageCode, fortune),
                  textAlign: TextAlign.center,
                  style: AppText.base(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppColors.muted,
                      height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!state.retryUsed) ...[
            Pressable(
              onTap: _retryWithAd,
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline_rounded,
                        size: 19, color: AppColors.sub),
                    const SizedBox(width: 7),
                    Text(l.fortuneRetryAd,
                        style: AppText.base(
                            size: 14.5, weight: FontWeight.w700, color: AppColors.sub)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: _busy ? null : _save,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_rounded,
                            size: 19, color: AppColors.sub),
                        const SizedBox(width: 7),
                        Text(l.talismanSave,
                            style: AppText.base(
                                size: 15, weight: FontWeight.w700, color: AppColors.sub)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Pressable(
                  onTap: _busy ? null : () => _share(score),
                  child: Container(
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
                        const Icon(Icons.ios_share_rounded,
                            size: 19, color: Colors.white),
                        const SizedBox(width: 7),
                        Text(l.talismanShare,
                            style: AppText.base(
                                size: 15, weight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l.fortuneTomorrow,
            style: AppText.base(
                size: 13, weight: FontWeight.w500, color: AppColors.muted),
          ),
          // 개발 전용 — 하루 1회 제한을 무시하고 계속 테스트하기 위한 리셋.
          // 릴리즈 빌드에서는 트리에서 통째로 빠진다.
          if (kDebugMode) ...[
            const SizedBox(height: 20),
            Pressable(
              onTap: _devReset,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
                child: Text('DEV · 오늘 기록 리셋',
                    style: AppText.base(
                        size: 12, weight: FontWeight.w700, color: AppColors.muted)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
