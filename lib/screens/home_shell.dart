import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';
import '../widgets/tab_icons.dart';
import 'archive_screen.dart';
import 'dex_screen.dart';
import 'fortune_screen.dart';
import 'gacha_screen.dart';
import 'home_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(appControllerProvider.select((s) => s.tab));
    final offline = ref.watch(appControllerProvider.select((s) => s.offline));
    final notifier = ref.read(appControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // 서버에 못 붙은 동안 — 화면은 마지막 사본이라 최신이 아닐 수 있고,
          // 선행 기록·뽑기 같은 쓰기는 실패한다. 숨기면 "왜 저장이 안 되지"가 된다.
          if (offline) _OfflineBanner(onRetry: notifier.retrySync),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(tab),
                  child: switch (tab) {
                    AppTab.home => const HomeScreen(),
                    AppTab.gacha => const GachaScreen(),
                    AppTab.fortune => const FortuneScreen(),
                    AppTab.dex => const DexScreen(),
                    AppTab.archive => const ArchiveScreen(),
                  },
                ),
              ),
            ),
          ),
          _TabBar(tab: tab, onSelect: notifier.setTab),
        ],
      ),
    );
  }
}

/// 오프라인 안내 띠. 탭하면 다시 붙어 본다.
class _OfflineBanner extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final topPad = MediaQuery.of(context).padding.top;
    return Pressable(
      onTap: onRetry,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, 8 + topPad, 20, 8),
        color: const Color(0xFFFFF4E0),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFF9A6B18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.offlineBanner,
                  style: AppText.base(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF9A6B18))),
            ),
            Text(l.offlineRetry,
                style: AppText.base(
                    size: 12,
                    weight: FontWeight.w800,
                    color: const Color(0xFF9A6B18))),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final AppTab tab;
  final ValueChanged<AppTab> onSelect;
  const _TabBar({required this.tab, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70 + bottomPad,
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: const BoxDecoration(
            color: Color(0xEBFFFFFF), // rgba(255,255,255,.92)
            border: Border(top: BorderSide(color: AppColors.card)),
          ),
          child: Row(
            children: [
              _item(TabIconKind.home, l.tabHome, AppTab.home),
              _item(TabIconKind.store, l.tabGacha, AppTab.gacha),
              _item(TabIconKind.fortune, l.tabFortune, AppTab.fortune),
              _item(TabIconKind.dex, l.tabDex, AppTab.dex),
              _item(TabIconKind.archive, l.tabArchive, AppTab.archive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(TabIconKind icon, String label, AppTab value) {
    final active = tab == value;
    final color = active ? AppColors.accent : AppColors.muted;
    return Expanded(
      child: Pressable(
        onTap: () => onSelect(value),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TabIcon(kind: icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(label,
                style: AppText.base(size: 11, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
