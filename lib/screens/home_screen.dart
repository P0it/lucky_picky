import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_mark.dart';
import '../widgets/clover_widget.dart';
import '../widgets/pressable.dart';
import '../widgets/record_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _todayLabel() {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    final d = DateTime.now();
    // DateTime.weekday: 월=1..일=7  → days 인덱스(일=0)로 변환
    final dow = d.weekday % 7;
    return '${d.month}월 ${d.day}일 ${days[dow]}요일';
  }

  String _statusText(int leaves) {
    if (leaves <= 0) return '새 네잎클로버를 시작해요. 4번의 선행이면 잎이 가득 차요.';
    if (leaves >= 4) return '네잎클로버가 완성됐어요! 🍀';
    return '잎이 $leaves개 모였어요. ${4 - leaves}번 더 선행을 베풀면 클로버가 완성돼요!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
      child: Column(
        children: [
          // ---- 헤더 ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_todayLabel(),
                        style: AppText.base(
                            size: 13, weight: FontWeight.w500, color: AppColors.muted)),
                    const SizedBox(height: 5),
                    Text('오늘도 따뜻한 하루',
                        style: AppText.base(
                            size: 21, weight: FontWeight.w700, letterSpacingEm: -0.035)),
                  ],
                ),
              ),
              // 보유 클로버 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.chipFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CloverMark(size: 17),
                    const SizedBox(width: 6),
                    Text('× ${s.clovers}',
                        style: AppText.base(
                            size: 15, weight: FontWeight.w800, letterSpacingEm: -0.01)),
                  ],
                ),
              ),
            ],
          ),
          // ---- 중앙 클로버 + 상태 ----
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CloverWidget(
                  leaves: s.leaves,
                  bounceKey: s.bounceKey,
                  celebrate: s.celebrate,
                  size: 252,
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 288),
                  child: Text(
                    _statusText(s.leaves),
                    textAlign: TextAlign.center,
                    style: AppText.base(
                        size: 16, weight: FontWeight.w500, color: AppColors.sub, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          // ---- 기록 버튼 ----
          Pressable(
            onTap: () => showRecordSheet(context, ref),
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
              child: Text('오늘의 선행 기록하기',
                  style: AppText.base(size: 17, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
