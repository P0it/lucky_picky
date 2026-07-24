import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_backend.dart';
import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'pressable.dart';

/// 복구 코드 하프 모달 — 내 코드 보기(백업)와 코드로 복구(이관).
/// 기기가 바뀌어도 자산을 이어가는 최소 장치.
Future<void> showRecoverySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.backdrop,
    builder: (_) => const _RecoverySheet(),
  );
}

class _RecoverySheet extends ConsumerStatefulWidget {
  const _RecoverySheet();

  @override
  ConsumerState<_RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends ConsumerState<_RecoverySheet> {
  final _restoreController = TextEditingController();

  String? _myCode; // 발급받은 내 코드 (표시용). null 이면 아직 안 봄.
  bool _issuing = false;
  bool _restoring = false;

  bool get _canRestore =>
      _restoreController.text.trim().isNotEmpty && !_restoring;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _showMyCode() async {
    if (_issuing) return;
    setState(() => _issuing = true);
    final l = AppLocalizations.of(context);
    try {
      final code = await ref.read(appControllerProvider.notifier).issueRecoveryCode();
      if (!mounted) return;
      setState(() => _myCode = code);
    } on GameConnectionException {
      if (mounted) showAppToast(context, l.errorNeedConnection);
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  Future<void> _copyMyCode() async {
    final code = _myCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showAppToast(context, AppLocalizations.of(context).recoveryCopied);
  }

  Future<void> _restore() async {
    final code = _restoreController.text.trim();
    if (code.isEmpty || _restoring) return;
    setState(() => _restoring = true);
    final l = AppLocalizations.of(context);
    try {
      final ok =
          await ref.read(appControllerProvider.notifier).redeemRecoveryCode(code);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        showAppToast(context, l.recoveryRestored);
      } else {
        showAppToast(context, l.recoveryNotFound);
      }
    } on GameConnectionException {
      if (mounted) showAppToast(context, l.errorNeedConnection);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          boxShadow: [BoxShadow(color: Color(0x24191F28), blurRadius: 30, offset: Offset(0, -8))],
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 18),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.chipFull),
                  ),
                ),
              ),
            ),
            Text(l.recoveryTitle,
                style: AppText.base(size: 22, weight: FontWeight.w700, letterSpacingEm: -0.03)),
            const SizedBox(height: 6),
            Text(l.recoverySubtitle,
                style: AppText.base(size: 14, weight: FontWeight.w500, color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 22),

            // ---- 내 복구 코드 (백업) ----
            Text(l.recoveryMyCodeLabel,
                style: AppText.base(size: 13, weight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            if (_myCode == null)
              _outlinedButton(
                label: l.recoveryShowCode,
                busy: _issuing,
                onTap: _showMyCode,
              )
            else
              _codeBox(l),
            const SizedBox(height: 24),

            // ---- 코드로 복구 (이관) ----
            Text(l.recoveryRestoreLabel,
                style: AppText.base(size: 13, weight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _restoreController,
                onChanged: (_) => setState(() {}),
                style: AppText.base(size: 16, weight: FontWeight.w600),
                cursorColor: AppColors.accent,
                decoration: InputDecoration.collapsed(
                  hintText: l.recoveryRestoreHint,
                  hintStyle:
                      AppText.base(size: 15, weight: FontWeight.w500, color: AppColors.disabled),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Pressable(
              onTap: _canRestore ? _restore : null,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canRestore ? AppColors.accent : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  l.recoveryRestoreCta,
                  style: AppText.base(
                    size: 17,
                    weight: FontWeight.w700,
                    color: _canRestore ? Colors.white : AppColors.disabled,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlinedButton(
      {required String label, required bool busy, required VoidCallback onTap}) {
    return Pressable(
      onTap: busy ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              )
            : Text(label,
                style: AppText.base(size: 16, weight: FontWeight.w700, color: AppColors.accent)),
      ),
    );
  }

  Widget _codeBox(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _myCode!,
                  style: AppText.base(
                      size: 18, weight: FontWeight.w800, color: AppColors.title, height: 1.35),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: _copyMyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.chipFull),
                  ),
                  child: Text(l.recoveryCopy,
                      style: AppText.base(size: 14, weight: FontWeight.w700, color: AppColors.accent)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(l.recoveryCodeSaveHint,
            style: AppText.base(size: 12, weight: FontWeight.w500, color: AppColors.muted)),
      ],
    );
  }
}
