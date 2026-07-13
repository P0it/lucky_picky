import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/fortune_pool.dart';
import '../l10n/app_localizations.dart';
import '../models/daily_fortune.dart';
import '../state/copy_controller.dart';
import '../theme/app_theme.dart';
import 'luck_gauge.dart' show luckColor;

/// 오늘의 행운지수 결과 카드 — 이 위젯이 그대로 공유 이미지가 된다.
/// (RepaintBoundary 캡처 대상이므로 배경까지 불투명하게 채운다.)
/// 구성: 점수 + 총운 한마디 + 행운 요소(색/숫자/아이템) 라벨 행.
class FortuneCard extends ConsumerWidget {
  final DailyFortune fortune;
  final bool animateScore; // 첫 공개 때만 카운트업

  const FortuneCard({
    super.key,
    required this.fortune,
    this.animateScore = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final lucky = FortunePool.luckyColor(fortune);
    // 총운 문구는 서버(copy_lines) 우선, 없으면 번들 폴백.
    final overall = ref.watch(copyBookProvider).fortuneOverall(lang, fortune);

    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.fortuneScoreLabel,
            style: AppText.base(
                size: 13, weight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          // 헤드라인 — 큰 숫자. 게이지와 같은 색 규칙(검정→클로버 그린)을 쓴다.
          // 카운트업 중에도 색이 함께 물들도록 현재 v 로 색을 뽑는다.
          animateScore
              ? TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: fortune.luckIndex),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => _scoreText(v, luckColor(v / 100)),
                )
              : _scoreText(
                  fortune.luckIndex, luckColor(fortune.luckIndex / 100)),
          const SizedBox(height: 16),
          Text(
            overall,
            textAlign: TextAlign.center,
            style: AppText.base(
                size: 19, weight: FontWeight.w800, height: 1.35,
                letterSpacingEm: -0.03),
          ),
          const SizedBox(height: 22),
          // 행운 요소 — 라벨 + 값, 한 항목당 한 행.
          _luckyRow(
            l.fortuneLuckyColor,
            valueLeading: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(color: lucky.color, shape: BoxShape.circle),
            ),
            value: lucky.name(lang),
          ),
          _rowDivider(),
          _luckyRow(l.fortuneLuckyNumber, value: '${fortune.luckyNumber}'),
          _rowDivider(),
          _luckyRow(l.fortuneLuckyItem, value: FortunePool.item(lang, fortune)),
        ],
      ),
    );
  }

  Widget _scoreText(int score, Color color) {
    return Text(
      '$score',
      style: AppText.base(
          size: 76, weight: FontWeight.w800, color: color, letterSpacingEm: -0.04,
          height: 1.0),
    );
  }

  Widget _rowDivider() => const Divider(
        height: 1, thickness: 1, color: AppColors.borderSoft);

  Widget _luckyRow(String label, {Widget? valueLeading, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label,
              style: AppText.base(
                  size: 13.5, weight: FontWeight.w600, color: AppColors.muted)),
          const Spacer(),
          if (valueLeading != null) ...[
            valueLeading,
            const SizedBox(width: 6),
          ],
          Text(value,
              style: AppText.base(size: 15, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
