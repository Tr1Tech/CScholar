import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart'
    show NeumorphState;

/// Tonal input well — the system's ONE text input.
///
/// It is a [FormField], not a bare `TextField`, so screens can keep their
/// `Form` + `validator` + `Form.validate()` flow. (Every validated form in this
/// app already works that way; a drop-in that ignored `validate()` would force
/// each screen to hand-roll error state.) `controller` is still supported for
/// screens that own one.
///
/// The rim stays even though the field is inset: an inset-only field has no
/// visible boundary and vanishes in high contrast or on cheap panels.
class NeumorphField extends FormField<String> {
  NeumorphField({
    super.key,
    TextEditingController? controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.obscureText = false,
    super.enabled,
    this.previewState,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    super.validator,
    AutovalidateMode? autovalidateMode,
  })  : super(
          initialValue: controller?.text ?? '',
          // `enabled` forwards straight to FormField's own property, so the
          // field and the Form can never disagree about whether it is active.
          // Validate as the user types, not only on submit: a 4-character
          // password rule discovered after pressing Sign In is a dead end.
          autovalidateMode:
              autovalidateMode ?? AutovalidateMode.onUserInteraction,
          builder: (field) => _NeumorphFieldBody(
            field: field,
            controller: controller,
            label: label,
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            obscureText: obscureText,
            // A super parameter is in scope for the initializer list, so this
            // is FormField's value (default true) — not a second flag.
            enabled: enabled,
            previewState: previewState,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            minLines: minLines,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        );

  /// Uppercase label above the field. Also the field's semantic label.
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;

  /// Trailing control — the password reveal button, for example.
  final Widget? suffixIcon;

  /// Explicit error, merged with any [FormField.validator] result.
  final String? errorText;
  final bool obscureText;

  /// Renders one state on purpose. Design lab only — leave null in the app.
  final NeumorphState? previewState;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
}

/// The visual half. Holds the focus state and paints the recessed well.
///
/// It is a separate StatefulWidget so [NeumorphField] stays declarative: the
/// FormField owns validation, this owns focus and painting.
class _NeumorphFieldBody extends StatefulWidget {
  const _NeumorphFieldBody({
    required this.field,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.suffixIcon,
    required this.errorText,
    required this.obscureText,
    required this.enabled,
    required this.previewState,
    required this.keyboardType,
    required this.textInputAction,
    required this.autofillHints,
    required this.textCapitalization,
    required this.maxLines,
    required this.minLines,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final FormFieldState<String> field;
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final NeumorphState? previewState;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_NeumorphFieldBody> createState() => _NeumorphFieldBodyState();
}

class _NeumorphFieldBodyState extends State<_NeumorphFieldBody> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final bool _ownsFocus = widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final flat = MediaQuery.highContrastOf(context);
    final preview = widget.previewState;

    final focused = preview == NeumorphState.focus || _focus.hasFocus;
    final disabled = !widget.enabled || preview == NeumorphState.disabled;
    // An explicit errorText is a screen-level failure (a rejected sign-in, say)
    // and outranks the validator's format complaint.
    final error = (widget.errorText ?? '').isNotEmpty
        ? widget.errorText
        : field.errorText;
    final hasError = (error ?? '').isNotEmpty;
    final radius = BorderRadius.circular(CScholarRadius.md);
    final animate = motionEnabled(context);

    // No outline at rest: the tonal well IS the affordance, and a drawn rim on
    // every field is exactly what the clay pass removed. Focus and error still
    // ring (they must stay visible), and high contrast keeps a strong rim as
    // its fallback — the whole no-rim-at-rest decision leans on that one.
    //
    // The ring arrives as an opacity fade of a fixed-contrast layer over
    // [CScholarMotion.micro], never as a colour tween: the midpoint of a
    // colour tween is where the AA floor breaks. The AnimatedContainer lerps
    // null <-> Border, i.e. transparent alpha <-> the fixed hue, so the
    // settled state is byte-identical to the instant ring it replaces
    // (gelTop / error / rimStrong at full opacity, 1.5px). Reduced motion
    // snaps the ring in with a zero duration instead of fading it.
    final Color? borderColor = flat
        ? CScholarMaterial.rimStrong
        : hasError
            ? CScholarColors.error
            : focused
                ? CScholarMaterial.gelTop
                : null;

    // The placeholder lifts 2px on focus — a transform, so layout never
    // moves. Reduced motion gets no lift at all, never a snapped one.
    final lift = focused && !disabled && animate ? -2.0 : 0.0;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!.toUpperCase(),
              style: CScholarTextStyles.inter(11, FontWeight.w700,
                  CScholarMaterial.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
          ],
          AnimatedContainer(
            duration: animate ? CScholarMotion.micro : Duration.zero,
            curve: CScholarCurves.standard,
            decoration: BoxDecoration(
              color: CScholarMaterial.clayDeep,
              borderRadius: radius,
              border: borderColor == null
                  ? null
                  // Any rim we DO draw is 1.5px. Focus and error are state, and
                  // the high-contrast fallback is what the no-rim decision
                  // leans on, so it gets a state ring's weight — not a thinner
                  // hairline that reads as a leftover from the old pass.
                  : Border.all(color: borderColor, width: 1.5),
            ),
            child: AnimatedContainer(
              duration: animate ? CScholarMotion.micro : Duration.zero,
              curve: CScholarCurves.standard,
              transform: Matrix4.translationValues(0, lift, 0),
              child: TextField(
                controller: widget.controller,
              focusNode: _focus,
              enabled: !disabled,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              textCapitalization: widget.textCapitalization,
              // A multiline maxLines and obscureText are mutually exclusive
              // in Flutter's TextField, so obscure wins.
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              cursorColor: CScholarMaterial.gelTop,
              style: CScholarTextStyles.inter(
                  14, FontWeight.w400, CScholarMaterial.textPrimary),
              onChanged: (v) {
                field.didChange(v);
                widget.onChanged?.call(v);
              },
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: CScholarTextStyles.inter(
                    13.5, FontWeight.w400, CScholarMaterial.textFaint),
                prefixIcon: widget.prefixIcon == null
                    ? null
                    : Icon(widget.prefixIcon,
                        size: 18, color: CScholarMaterial.textMuted),
                suffixIcon: widget.suffixIcon,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            ),
          ),
          // Error replaces the hint through AnimatedSwap: one swap style for
          // every hint <-> error change in the app. The switcher only exists
          // while an error is shown, so appearing and clearing stay instant
          // (Form.validate() asserts them on a single pump) while one error
          // replacing another cross-fades. The child is keyed on the message
          // itself — without the key the switcher cannot see the swap.
          if (hasError)
            AnimatedSwap(
              style: SwapStyle.swap,
              alignment: Alignment.topLeft,
              child: Padding(
                key: ValueKey(error),
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  error!,
                  style: CScholarTextStyles.inter(
                      12, FontWeight.w500, CScholarColors.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

