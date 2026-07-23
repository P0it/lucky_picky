import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../state/ads_controller.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/coin_mark.dart';
import '../widgets/gacha_machine.dart';
import '../widgets/gacha_pull_overlay.dart';
import '../widgets/gacha_rates_sheet.dart';
import '../widgets/pressable.dart';

/// 행운 뽑기 화면 — 캡슐 머신 + 코인으로 뽑기 / 광고 보고 코인 받기.
/// 뽑기 재화는 코인이고, 코인은 광고로만 생긴다. 선행으로 만든 클로버는
/// 여기에 쓰이지 않는다 — 클로버는 커스텀 행운권 제작·강화 전용이다.
class GachaScreen extends ConsumerWidget {
  const GachaScreen({super.key});

  void _pull(BuildContext context, WidgetRef ref) {
    final s = ref.read(appControllerProvider);
    if (s.coins <= 0) return;
    runGachaPullFlow(context, ref);
  }

  /// 광고 시청 → 코인 1개 적립. 뽑기는 사용자가 직접 돌린다.
  /// 적립 성공은 버튼 안 코인 수가 올라가는 것으로 보여준다 — 별도 알림 없음.
  void _watchAdForCoin(BuildContext context, WidgetRef ref) {
    final n = ref.read(appControllerProvider.notifier);
    if (n.adCoinsLeft <= 0) return;
    ref.read(rewardedAdProvider)(onReward: () async {
      try {
        await n.grantAdCoin();
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
    final adCoinsLeft = n.adCoinsLeft;
    final canPull = s.coins > 0;

    // 머신은 남는 공간만 차지한다 — 버튼까지 한 화면에 들어오는 게 우선.
    return Column(
      children: [
        // ---- 헤더 ----
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(l.gachaTitle,
                    style: AppText.base(
                        size: 28, weight: FontWeight.w800, letterSpacingEm: -0.035)),
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
        ),
        // ---- 캡슐 머신 ---- 남는 높이에 맞춰 줄어든다.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 214),
                child: const GachaMachine(),
              ),
            ),
          ),
        ),
        // ---- 버튼 ----
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
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
                      CoinMark(
                          size: 20, color: canPull ? null : AppColors.disabled),
                      const SizedBox(width: 8),
                      Text(
                        canPull ? l.gachaPull : l.gachaNotEnough,
                        style: AppText.base(
                          size: 17,
                          weight: FontWeight.w700,
                          color: canPull ? Colors.white : AppColors.disabled,
                        ),
                      ),
                      // 보유 코인은 별도 칩 대신 버튼 안에서 보여준다.
                      if (canPull) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius:
                                BorderRadius.circular(AppRadius.chipFull),
                          ),
                          child: Text(
                            l.gachaCoinCount(s.coins),
                            style: AppText.base(
                                size: 13.5,
                                weight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Pressable(
                onTap:
                    adCoinsLeft > 0 ? () => _watchAdForCoin(context, ref) : null,
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
                          color: adCoinsLeft > 0
                              ? AppColors.sub
                              : AppColors.disabled),
                      const SizedBox(width: 7),
                      Text(
                        adCoinsLeft > 0
                            ? l.gachaAdCoin(adCoinsLeft, kAdCoinsPerDay)
                            : l.gachaAdCoinNone,
                        style: AppText.base(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: adCoinsLeft > 0
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
