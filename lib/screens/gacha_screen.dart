import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../state/ads_controller.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/clover_mark.dart';
import '../widgets/gacha_machine.dart';
import '../widgets/gacha_pull_overlay.dart';
import '../widgets/gacha_rates_sheet.dart';
import '../widgets/pressable.dart';

/// 행운 뽑기 화면 — 캡슐 머신 + 클로버로 뽑기 / 광고 보고 클로버 받기.
/// 클로버가 곧 뽑기 코인이다. 광고는 뽑기를 대신 돌리지 않고 클로버를 채워준다.
class GachaScreen extends ConsumerWidget {
  const GachaScreen({super.key});

  void _pull(BuildContext context, WidgetRef ref) {
    final s = ref.read(appControllerProvider);
    if (s.clovers <= 0) return;
    runGachaPullFlow(context, ref);
  }

  /// 광고 시청 → 클로버 1개 적립. 뽑기는 사용자가 직접 돌린다.
  /// 적립 성공은 상단 보유 클로버 칩이 올라가는 것으로 보여준다 — 별도 알림 없음.
  void _watchAdForClover(BuildContext context, WidgetRef ref) {
    final n = ref.read(appControllerProvider.notifier);
    if (n.adCloversLeft <= 0) return;
    AdsController.instance.showRewarded(onReward: () async {
      try {
        await n.grantAdClover();
      } on GameConnectionException {
        if (context.mounted) {
          showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(appControllerProvider);
    final n = ref.read(appControllerProvider.notifier);
    final adCloversLeft = n.adCloversLeft;
    final canPull = s.clovers > 0;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        // ---- 헤더 ----
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(l.gachaTitle,
                        style: AppText.base(
                            size: 30, weight: FontWeight.w800, letterSpacingEm: -0.035)),
                  ),
                  // 확률 정보 진입점.
                  Pressable(
                    onTap: () => showGachaRatesSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.chipFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.percent_rounded,
                              size: 15, color: AppColors.sub),
                          const SizedBox(width: 4),
                          Text(l.gachaRatesButton,
                              style: AppText.base(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.sub)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 보유 클로버 칩.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0D191F28), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.gachaOwnedLabel,
                        style: AppText.base(
                            size: 14, weight: FontWeight.w600, color: AppColors.muted)),
                    const SizedBox(width: 8),
                    const CloverMark(size: 21),
                    const SizedBox(width: 5),
                    Text(l.gachaCloverCount(s.clovers),
                        style: AppText.base(size: 18, weight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ---- 캡슐 머신 ----
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 52, vertical: 6),
          child: GachaMachine(),
        ),
        // ---- 버튼 ----
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Column(
            children: [
              Pressable(
                onTap: canPull ? () => _pull(context, ref) : null,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canPull ? AppColors.accent : AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: canPull
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CloverMark(
                          size: 20,
                          color: canPull ? Colors.white : AppColors.disabled),
                      const SizedBox(width: 8),
                      Text(
                        canPull ? l.gachaPull : l.gachaNotEnough,
                        style: AppText.base(
                          size: 17,
                          weight: FontWeight.w700,
                          color: canPull ? Colors.white : AppColors.disabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Pressable(
                onTap: adCloversLeft > 0
                    ? () => _watchAdForClover(context, ref)
                    : null,
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
                      Icon(Icons.play_circle_outline_rounded,
                          size: 19,
                          color: adCloversLeft > 0
                              ? AppColors.sub
                              : AppColors.disabled),
                      const SizedBox(width: 7),
                      Text(
                        adCloversLeft > 0
                            ? l.gachaAdClover(adCloversLeft, kAdCloversPerDay)
                            : l.gachaAdCloverNone,
                        style: AppText.base(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: adCloversLeft > 0
                              ? AppColors.sub
                              : AppColors.disabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
