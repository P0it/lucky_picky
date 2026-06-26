import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/wish.dart';
import '../theme/app_theme.dart';
import '../widgets/ooloo_toast.dart';
import '../widgets/pressable.dart';
import '../widgets/talisman_export.dart';
import '../widgets/wish_talisman.dart';

/// 도감 카드 → 부적 상세. 페이드로 진입.
Route<void> wishTalismanRoute(Wish wish) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => WishTalismanScreen(wish: wish),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

/// 완성된 소원을 부적 이미지로 미리보고, 앨범 저장 / 공유한다.
class WishTalismanScreen extends StatefulWidget {
  final Wish wish;
  const WishTalismanScreen({super.key, required this.wish});

  @override
  State<WishTalismanScreen> createState() => _WishTalismanScreenState();
}

class _WishTalismanScreenState extends State<WishTalismanScreen> {
  final _boundaryKey = GlobalKey();
  TalismanFormat _format = TalismanFormat.portrait;
  bool _busy = false;

  String get _fileName => 'ooloo_talisman_${widget.wish.id}_${_format.name}';

  Future<void> _withBusy(Future<void> Function() action, {String? failMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showOolooToast(context, failMsg ?? AppLocalizations.of(context).talismanRetry);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _withBusy(() async {
        final bytes = await captureBoundaryPng(_boundaryKey);
        await saveTalismanToGallery(bytes, _fileName);
        if (mounted) showOolooToast(context, AppLocalizations.of(context).toastSavedToAlbum);
      }, failMsg: AppLocalizations.of(context).talismanSaveFail);

  Future<void> _share() {
    final shareText = AppLocalizations.of(context).talismanShareText;
    return _withBusy(() async {
      final bytes = await captureBoundaryPng(_boundaryKey);
      await shareTalisman(bytes, _fileName, text: shareText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _deliveredChip(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22191F28), blurRadius: 44, offset: Offset(0, 20)),
                        ],
                      ),
                      // ClipRRect/그림자는 미리보기 전용 — 캡처되는 RepaintBoundary는
                      // 모서리까지 꽉 찬 원본 사각형이라 배경화면 시 빈틈이 없다.
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: WishTalisman(wish: widget.wish, format: _format),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _formatToggle(),
            const SizedBox(height: 16),
            _actions(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// 도감 카드에서 옮겨온 "전달 완료" 정보 — 부적을 열었을 때 보여준다.
  Widget _deliveredChip() {
    final l = AppLocalizations.of(context);
    final date = widget.wish.completedAt;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.chipFull),
        ),
        child: Text(
          date == null ? l.dexDelivered : '${l.dexDelivered}  ·  $date',
          style: AppText.base(
              size: 12, weight: FontWeight.w700, color: AppColors.accent),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          Pressable(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.close_rounded, size: 26, color: AppColors.sub),
            ),
          ),
          const Spacer(),
          Text(AppLocalizations.of(context).talismanTitle,
              style: AppText.base(size: 17, weight: FontWeight.w800, letterSpacingEm: -0.03)),
          const Spacer(),
          const SizedBox(width: 50), // 닫기 버튼과 대칭
        ],
      ),
    );
  }

  Widget _formatToggle() {
    Widget seg(String label, TalismanFormat f) {
      final active = _format == f;
      return Expanded(
        child: Pressable(
          onTap: active ? null : () => setState(() => _format = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.chipFull),
              boxShadow: active
                  ? const [BoxShadow(color: Color(0x14191F28), blurRadius: 8, offset: Offset(0, 2))]
                  : null,
            ),
            child: Text(label,
                style: AppText.base(
                    size: 14,
                    weight: FontWeight.w700,
                    color: active ? AppColors.title : AppColors.muted)),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.chipFull),
        ),
        child: SizedBox(
          width: 240,
          child: Row(
            children: [
              seg(AppLocalizations.of(context).talismanPortrait, TalismanFormat.portrait),
              seg(AppLocalizations.of(context).talismanSquare, TalismanFormat.square),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: _busy ? null : _save,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, size: 19, color: AppColors.sub),
                    const SizedBox(width: 7),
                    Text(AppLocalizations.of(context).talismanSave,
                        style: AppText.base(size: 16, weight: FontWeight.w700, color: AppColors.sub)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: _busy ? null : _share,
              child: Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ios_share_rounded, size: 19, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(AppLocalizations.of(context).talismanShare,
                        style: AppText.base(size: 16, weight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
