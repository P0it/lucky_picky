import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../state/app_controller.dart';
import '../state/copy_controller.dart';
import '../util/text_wrap.dart';
import '../theme/app_theme.dart';
import '../widgets/clover_count_badge.dart';
import '../widgets/clover_flight.dart';
import '../widgets/clover_widget.dart';
import '../widgets/pressable.dart';
import '../widgets/record_sheet.dart';

/// 진행 중인 비행의 출발·도착 좌표 (홈 [Stack] 기준).
class _FlightSpec {
  final Offset from;
  final Offset to;
  const _FlightSpec(this.from, this.to);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _cloverSize = 252;

  final _stackKey = GlobalKey();
  final _cloverKey = GlobalKey();
  final _badgeMarkKey = GlobalKey();

  /// 배지에 실제로 보여줄 수. 평소엔 상태를 따라가지만
  /// 비행 중에는 얼어붙어 있다가 착지 시점에 [_pendingClovers] 로 갈아탄다.
  late int _shownClovers;
  int? _pendingClovers;
  _FlightSpec? _flight;

  @override
  void initState() {
    super.initState();
    _shownClovers = ref.read(appControllerProvider).clovers;
  }

  String _statusText(AppLocalizations l, int leaves) {
    if (leaves <= 0) return l.homeStatusEmpty;
    if (leaves >= 4) return l.homeStatusComplete;
    return l.homeStatusProgress(leaves, 4 - leaves);
  }

  void _onStateChanged(AppState? prev, AppState next) {
    if (prev == null) return;

    if (next.flightKey > prev.flightKey) {
      // 서버 확정 성공 — 숫자를 붙들어 두고 비행을 띄운다.
      _pendingClovers = next.clovers;
      _launchFlight();
      return;
    }
    if (_flight != null) {
      // 비행 중 다른 경로로 값이 또 바뀌면 착지 때 반영한다.
      _pendingClovers = next.clovers;
      return;
    }
    if (next.clovers != _shownClovers) {
      setState(() => _shownClovers = next.clovers);
    }
  }

  /// 잎이 비워진 프레임이 그려진 뒤에 좌표를 재야 출발점이 정확하다.
  void _launchFlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stack = _stackKey.currentContext?.findRenderObject();
      if (stack is! RenderBox || !stack.hasSize) return _landFlight();

      final from = _centerIn(stack, _cloverKey);
      final to = _centerIn(stack, _badgeMarkKey);
      if (from == null || to == null) return _landFlight();

      setState(() => _flight = _FlightSpec(from, to));
    });
  }

  Offset? _centerIn(RenderBox stack, GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  /// 착지 — 비행을 걷고 숫자를 갱신한다. 좌표를 못 재 비행을 건너뛴 경우에도
  /// 여기로 와서 숫자는 반드시 맞춰진다.
  void _landFlight() {
    if (!mounted) return;
    setState(() {
      _flight = null;
      if (_pendingClovers != null) {
        _shownClovers = _pendingClovers!;
        _pendingClovers = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final copy = ref.watch(copyBookProvider);

    ref.listen(appControllerProvider, _onStateChanged);

    return Stack(
      key: _stackKey,
      children: [
        Padding(
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
                        Text(
                            MaterialLocalizations.of(context)
                                .formatFullDate(DateTime.now()),
                            style: AppText.base(
                                size: 13,
                                weight: FontWeight.w500,
                                color: AppColors.muted)),
                        const SizedBox(height: 5),
                        Text(copy.dailyQuote(lang).keepAll,
                            style: AppText.base(
                                size: 21,
                                weight: FontWeight.w700,
                                letterSpacingEm: -0.035)),
                      ],
                    ),
                  ),
                  CloverCountBadge(
                      count: _shownClovers, markKey: _badgeMarkKey),
                ],
              ),
              // ---- 중앙 클로버 + 상태 ----
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CloverWidget(
                      key: _cloverKey,
                      leaves: s.leaves,
                      bounceKey: s.bounceKey,
                      celebrate: s.celebrate,
                      size: _cloverSize,
                    ),
                    const SizedBox(height: 22),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 288),
                      child: Text(
                        _statusText(l, s.leaves).keepAll,
                        textAlign: TextAlign.center,
                        style: AppText.base(
                            size: 16,
                            weight: FontWeight.w500,
                            color: AppColors.sub,
                            height: 1.55),
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
                  child: Text(l.homeRecordButton,
                      style: AppText.base(
                          size: 17,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        if (_flight case final f?)
          Positioned.fill(
            child: CloverFlight(
              from: f.from,
              to: f.to,
              fromSize: _cloverSize,
              onLanded: _landFlight,
            ),
          ),
      ],
    );
  }
}
