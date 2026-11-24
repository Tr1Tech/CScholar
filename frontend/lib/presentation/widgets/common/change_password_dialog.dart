import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/services/api_service.dart';

/// Opens the change-password dialog for the signed-in account.
///
/// Every role reaches it through the same dialog: the API endpoint only needs
/// the caller's own token, so there is no per-role variant to maintain.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final updated = await showClayDialog<bool>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
  if (updated == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated.')),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _friendly(e);
        });
      }
    }
  }

  /// The API returns `{"detail": "..."}`; show that sentence instead of the
  /// raw exception text.
  String _friendly(Object error) {
    final raw = error is ApiException ? error.message : error.toString();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {
      // Fall through to the raw message.
    }
    return raw;
  }

  Widget _reveal({
    required bool shown,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final ink = color ?? CScholarColors.textMuted;
    return IconButton(
      tooltip: shown ? 'Hide password' : 'Show password',
      icon: MorphIcon(
        icon: Icons.visibility_outlined,
        selectedIcon: Icons.visibility_off_outlined,
        selected: shown,
        color: ink,
        selectedColor: ink,
        size: 18,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mobile has its own surface language: a near-white sheet, flatter
    // geometry and DM Sans / Manrope type. Desktop keeps the clay dialog.
    final isMobile =
        MediaQuery.sizeOf(context).width <= CScholarBreakpoints.mobile;
    final t = CScholarMobileTheme.of(context);
    final errorInk = t.dangerInk;
    final labelStyle = isMobile
        ? t.dmSans(9.5, FontWeight.w800, t.muted, letterSpacing: 0.9)
        : null;
    final cancelButton = NeumorphButton(
      label: 'Cancel',
      gel: false,
      flat: isMobile,
      mobile: isMobile,
      onPressed: _saving ? null : () => Navigator.pop(context),
    );
    final submitButton = NeumorphButton(
      label: 'Update password',
      loading: _saving,
      flat: isMobile,
      mobile: isMobile,
      onPressed: _saving ? null : _submit,
    );
    return GlassDialog(
      radius: isMobile ? CScholarMobileRadius.sheet : CScholarRadius.softSheet,
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      fill: isMobile ? t.surface : null,
      shadows: isMobile ? CScholarMobileShadows.overlay : null,
      borderColor: isMobile ? t.line : null,
      title: Text(
        'Change Password',
        style: isMobile
            ? t.manrope(20, FontWeight.w700, t.ink, height: 1.2)
            : null,
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm your current password, then choose a new one of at '
                  'least 6 characters.',
                  style: isMobile
                      ? t.dmSans(11.5, FontWeight.w400, t.muted, height: 1.55)
                      : CScholarTextStyles.body(
                          12,
                          FontWeight.w400,
                          CScholarColors.textSecondary,
                        ),
                ),
                const SizedBox(height: 14),
                NeumorphField(
                  controller: _currentCtrl,
                  label: 'Current password',
                  labelStyle: labelStyle,
                  mobile: isMobile,
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_showCurrent,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter your current password'
                      : null,
                  suffixIcon: _reveal(
                    shown: _showCurrent,
                    color: isMobile ? t.muted : CScholarColors.textMuted,
                    onPressed: () =>
                        setState(() => _showCurrent = !_showCurrent),
                  ),
                ),
                const SizedBox(height: 12),
                NeumorphField(
                  controller: _newCtrl,
                  label: 'New password',
                  labelStyle: labelStyle,
                  mobile: isMobile,
                  prefixIcon: Icons.lock_reset_outlined,
                  obscureText: !_showNew,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                  suffixIcon: _reveal(
                    shown: _showNew,
                    color: isMobile ? t.muted : CScholarColors.textMuted,
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                const SizedBox(height: 12),
                NeumorphField(
                  controller: _confirmCtrl,
                  label: 'Confirm new password',
                  labelStyle: labelStyle,
                  mobile: isMobile,
                  prefixIcon: Icons.lock_reset_outlined,
                  obscureText: !_showConfirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => v != _newCtrl.text
                      ? 'Passwords do not match'
                      : null,
                  suffixIcon: _reveal(
                    shown: _showConfirm,
                    color: isMobile ? t.muted : CScholarColors.textMuted,
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: isMobile
                        ? t.dmSans(11, FontWeight.w500, errorInk)
                        : CScholarTextStyles.body(
                            12,
                            FontWeight.w500,
                            CScholarColors.error,
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: isMobile
          ? [
              // Cancel on the left, Update on the right, sharing the row.
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 10),
                    Expanded(child: submitButton),
                  ],
                ),
              ),
            ]
          : [cancelButton, submitButton],
    );
  }
}
