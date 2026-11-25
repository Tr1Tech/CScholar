import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/csu_mark.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Mobile-only shell for the auth screens.
///
/// The web auth screens are a floating glass slab over ambient washes. The
/// mobile system has none of that: it is warm paper, a 74px header and surface
/// cards. This shell reproduces the student shell's chrome (brand tile or back
/// action, centered title, round theme toggle) so signing in looks like the
/// first screen of the app rather than a shrunken website.
///
/// It only resolves [CScholarMobileTheme] for its subtree; colours still come
/// from the painted palette, which is why it reads the mode from
/// [CScholarPaletteScope] rather than the provider (the provider flips on tap,
/// the painting flips mid-wipe).
class MobileAuthShell extends StatelessWidget {
  const MobileAuthShell({
    super.key,
    required this.child,
    this.title = 'CScholar',
    this.showBack = false,
    this.onBack,
    this.footer,
    this.scrollController,
  });

  final Widget child;

  /// Header title. Login keeps the wordmark; register names the task.
  final String title;

  /// Depth-style header: a round back button replaces the brand tile.
  final bool showBack;
  final VoidCallback? onBack;

  /// Pinned above the safe area. Hidden while the keyboard is open so the
  /// form keeps the room; the slide-up keyboard already signals the context.
  final Widget? footer;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final paintedDark =
        CScholarPaletteScope.maybeOf(context)?.isDark ??
        CScholarPalette.active.isDark;

    return CScholarMobileThemeScope(
      isDark: paintedDark,
      child: Builder(
        builder: (context) {
          final t = CScholarMobileTheme.of(context);
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                (paintedDark
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: t.paper,
                    ),
            child: Scaffold(
              backgroundColor: t.paper,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _AuthHeader(
                      title: title,
                      showBack: showBack,
                      onBack: onBack,
                      theme: t,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        // Keyboard is handled by the scaffold resize; the
                        // extra bottom padding is a comfortable tail, not a
                        // spacer for the keyboard itself.
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          keyboardOpen ? 24 : 8,
                        ),
                        child: child,
                      ),
                    ),
                    if (!keyboardOpen && footer != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          14 + bottomInset,
                        ),
                        child: footer,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.title,
    required this.showBack,
    required this.onBack,
    required this.theme,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final CScholarMobileTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.ink.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            MobileChromeButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Go back',
              size: 34,
              onTap: onBack,
            )
          else
            // The one brand mark: same identity block as the web shells.
            const CSUMark(size: 30),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.manrope(
                14,
                FontWeight.w700,
                theme.ink,
                letterSpacing: -0.14,
              ),
            ),
          ),
          const _AuthThemeButton(size: 34),
        ],
      ),
    );
  }
}

/// The mode switch, in the same 34px round chrome as the student header.
class _AuthThemeButton extends StatelessWidget {
  const _AuthThemeButton({this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = CScholarPalette.of(context).isDark;
    final scope = CScholarPaletteScope.maybeOf(context);

    return MobileChromeButton(
      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      iconColor: isDark
          ? CScholarColors.primaryGreenHover
          : CScholarColors.primaryGreen,
      semanticLabel: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      size: size,
      toggled: isDark,
      onTap: scope?.onToggle == null
          ? null
          : () => scope!.onToggle!(_centreOf(context)),
    );
  }
}

/// Round chrome action used by the header (back arrow, theme switch).
class MobileChromeButton extends StatelessWidget {
  const MobileChromeButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.size = 34,
    this.onTap,
    this.toggled,
    this.iconColor,
  });

  final IconData icon;
  final String semanticLabel;
  final double size;
  final VoidCallback? onTap;
  final bool? toggled;

  /// Glyph colour. Defaults to the shell's green; the theme switch passes the
  /// same web token pair (primaryGreen / primaryGreenHover).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    final flat = MediaQuery.highContrastOf(context);
    return Semantics(
      button: true,
      toggled: toggled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                selectionHaptic();
                onTap!();
              },
        child: Container(
          // tile-exempt: round chrome button.
          width: size,
          height: size,
          decoration: BoxDecoration(
            // Same chrome recipe as the web ThemeModeButton: clay, hairline,
            // one soft shadow — not the near-white circle the phone had.
            color: CScholarMaterial.clay,
            shape: BoxShape.circle,
            border: Border.all(
              color: flat ? CScholarMaterial.rimStrong : CScholarMaterial.rim,
              width: flat ? 1.5 : 1,
            ),
            boxShadow: flat ? null : CScholarMaterial.softShadow(depth: 0.5),
          ),
          child: Icon(icon, size: size * 0.5, color: iconColor ?? t.green),
        ),
      ),
    );
  }
}

/// The screen centre of the widget that owns [context] — the iris wipe opens
/// from the switch itself, not the viewport corner.
Offset _centreOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  return Offset.zero;
}

/// Bottom-of-screen affordance: the sign-in/register cross-link plus the
/// campus affiliation. Sits outside the scroll view, so it stays put while a
/// short form scrolls.
class MobileAuthFooter extends StatelessWidget {
  const MobileAuthFooter({super.key, this.leading, this.action, this.onAction});

  final String? leading;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    final hasLink = leading != null && action != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLink)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(leading!, style: t.dmSans(13, FontWeight.w400, t.muted)),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  action!,
                  style: t.dmSans(13, FontWeight.w700, t.green),
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 12, color: t.green),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Caraga State University · CEIT Campus Portal',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.dmSans(10.5, FontWeight.w400, t.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Surface card used by both auth forms (radius 23, hairline, soft shadow).
class MobileAuthCard extends StatelessWidget {
  const MobileAuthCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(CScholarMobileRadius.card),
        border: Border.all(color: t.line),
        boxShadow: CScholarMobileShadows.card,
      ),
      child: child,
    );
  }
}

/// Recessed well with a letterspaced label above it.
///
/// The error lives OUTSIDE the well, under it — the reason the field cannot
/// just be a `TextFormField` with an `errorText` decoration. `FormField`
/// drives validation; the controller remains the source of truth.
class MobileAuthField extends StatelessWidget {
  const MobileAuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);

    return FormField<String>(
      initialValue: controller.text,
      validator: (_) => validator?.call(controller.text),
      builder: (state) {
        final error = state.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                label.toUpperCase(),
                style: t.dmSans(
                  10,
                  FontWeight.w800,
                  t.green2,
                  height: 1.2,
                  letterSpacing: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(
                minHeight: CScholarTapTarget.primary,
              ),
              // 3px vertical inset + the text's own 12px = the original 15px
              // well, while leaving room for a 44px reveal control without
              // growing the field (A11Y-1).
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
              decoration: BoxDecoration(
                color: t.surfaceSoft,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: error == null
                      ? Colors.transparent
                      : t.dangerInk.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: t.muted),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Semantics(
                      label: label,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: TextField(
                          controller: controller,
                          obscureText: obscureText,
                          enabled: enabled,
                          keyboardType: keyboardType,
                          textInputAction: textInputAction,
                          autofillHints: autofillHints,
                          textCapitalization: textCapitalization,
                          onChanged: state.didChange,
                          onSubmitted: onSubmitted,
                          style: t.dmSans(13.5, FontWeight.w500, t.ink),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: t.dmSans(13, FontWeight.w400, t.muted),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (suffix != null) ...[const SizedBox(width: 8), suffix!],
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                // Must-read error copy: 12px floor (DS-4) and announced as a
                // polite live region when validation produces it (A11Y-14).
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: t.dmSans(12, FontWeight.w500, t.dangerInk),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Reveal/hide affordance for a field's well (the eye icon).
///
/// 44×44 hit target (A11Y-1), but no extra height: the field reserves 50px and
/// the text carries its own 12px inset, so this control never changes the
/// well's height. The glyph stays 18px inside the target.
class MobileAuthSuffixButton extends StatelessWidget {
  const MobileAuthSuffixButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return IconButton(
      onPressed: onPressed,
      tooltip: semanticLabel,
      iconSize: 18,
      constraints: const BoxConstraints(
        minWidth: CScholarTapTarget.minimum,
        minHeight: CScholarTapTarget.minimum,
      ),
      style: IconButton.styleFrom(
        minimumSize: CScholarTapTarget.square,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: t.muted,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

/// Select-style well that opens a picker and validates like a field.
///
/// The visible value comes from the screen (`valueLabel`), while the form
/// state is kept in sync through `state.didChange`, so going back and forth
/// between registration steps never loses or re-asks for the program.
class MobileAuthPicker<T> extends StatelessWidget {
  const MobileAuthPicker({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.valueLabel,
    required this.pick,
    required this.onChanged,
    this.icon,
    this.validator,
  });

  final String label;
  final String hint;
  final T? value;
  final String? valueLabel;
  final Future<T?> Function() pick;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final error = state.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                label.toUpperCase(),
                style: t.dmSans(
                  10,
                  FontWeight.w800,
                  t.green2,
                  height: 1.2,
                  letterSpacing: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: label,
              value: valueLabel ?? hint,
              excludeSemantics: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    final picked = await pick();
                    if (picked == null) return;
                    state.didChange(picked);
                    onChanged(picked);
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: CScholarTapTarget.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: t.surfaceSoft,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: error == null
                            ? Colors.transparent
                            : t.dangerInk.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: t.muted),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            valueLabel ?? hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: valueLabel == null
                                ? t.dmSans(13, FontWeight.w400, t.muted)
                                : t.dmSans(13.5, FontWeight.w500, t.ink),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: t.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                // Must-read error copy: 12px floor (DS-4) and announced as a
                // polite live region when validation produces it (A11Y-14).
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: t.dmSans(12, FontWeight.w500, t.dangerInk),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Green pill CTA (radius 22) with the soft gel drop and a loading state.
class MobileAuthButton extends StatelessWidget {
  const MobileAuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    // The solid fill must carry white text in both modes: on dark that is the
    // deep action green, not the pale mint accent the mobile theme returns.
    final fill = CScholarPalette.active.action;
    final disabled = onPressed == null || loading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CScholarMobileRadius.cta),
        // The brand's own green-tinted gel shadow, never a black drop.
        boxShadow: CScholarMaterial.gelDrop(depth: 1),
      ),
      child: FilledButton(
        onPressed: disabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: Colors.white,
          disabledBackgroundColor: fill.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(CScholarMobileRadius.cta),
            ),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.manrope(15, FontWeight.w700, Colors.white),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailing, size: 17, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Secondary action for the step footer (same height and radius as the CTA,
/// tonal fill instead of green).
class MobileAuthGhostButton extends StatelessWidget {
  const MobileAuthGhostButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: t.surfaceSoft,
        foregroundColor: t.ink,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(CScholarMobileRadius.cta),
          ),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.manrope(14, FontWeight.w700, t.ink),
      ),
    );
  }
}

/// Inline error slot: coral wash, destructive ink, no layout jump when empty.
class MobileAuthError extends StatelessWidget {
  const MobileAuthError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Error: $message',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.coralSoft,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: t.dangerInk.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: t.dangerInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: t.dmSans(12, FontWeight.w500, t.dangerInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-segment progress for the registration steps.
class MobileAuthStepProgress extends StatelessWidget {
  const MobileAuthStepProgress({super.key, required this.step, this.total = 2});

  /// Zero-based current step.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 14),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < total; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                      child: AnimatedContainer(
                        duration: CScholarDurations.fast,
                        curve: CScholarCurves.standard,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= step ? t.green : t.mint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${step + 1} / $total',
            style: t.dmSans(9.5, FontWeight.w800, t.muted, letterSpacing: 0.9),
          ),
        ],
      ),
    );
  }
}

/// Small pill switch that matches the prototype (36×21, green track).
class MobileAuthSwitch extends StatelessWidget {
  const MobileAuthSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: !enabled
            ? null
            : () {
                selectionHaptic();
                onChanged!(!value);
              },
        child: AnimatedContainer(
          duration: CScholarDurations.fast,
          curve: CScholarCurves.standard,
          width: 36,
          height: 21,
          decoration: BoxDecoration(
            color: value
                ? t.green
                : t.muted.withValues(alpha: enabled ? 0.35 : 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: CScholarDurations.fast,
            curve: CScholarCurves.standard,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 15,
              height: 15,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: CScholarColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CScholarMobileColors.ink.withValues(alpha: 0.18),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
