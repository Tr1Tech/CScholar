import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart'
    show NeumorphState;

/// Recessed track + gel ball. The ball settles with a slight overshoot so the
/// toggle feels sprung rather than stepped.
class NeumorphToggle extends StatelessWidget {
  const NeumorphToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.previewState,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final NeumorphState? previewState;

  @override
  Widget build(BuildContext context) {
    final disabled =
        onChanged == null || previewState == NeumorphState.disabled;
    final on = previewState == NeumorphState.pressed ? !value : value;
    final radius = BorderRadius.circular(CScholarRadius.full);
    final animate = motionEnabled(context);
    final duration = animate ? CScholarDurations.normal : Duration.zero;

    final track = GestureDetector(
      onTap: disabled ? null : () => onChanged!(!value),
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: duration,
          curve: CScholarCurves.standard,
          width: 54,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: CScholarMaterial.clayDeep,
            borderRadius: radius,
          ),
          child: AnimatedAlign(
            duration: duration,
            curve: Curves.easeOutBack,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CScholarMaterial.clayHigh, CScholarMaterial.clay],
                ),
                border: Border.all(
                  color: on ? CScholarMaterial.gelTop : CScholarMaterial.rim,
                  width: on ? 2 : 1,
                ),
                boxShadow: CScholarMaterial.clayDrop(depth: 0.5),
              ),
            ),
          ),
        ),
      ),
    );

    if (label == null) {
      return Opacity(opacity: disabled ? 0.5 : 1, child: track);
    }
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label!,
              style: CScholarTextStyles.inter(
                  13, FontWeight.w500, CScholarMaterial.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          track,
        ],
      ),
    );
  }
}

/// Recessed track with a raised pill that GLIDES between segments — the same
/// motion language as the nav rail, so every selection feels like one object
/// moving rather than two elements fading.
class NeumorphSegmented extends StatelessWidget {
  const NeumorphSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CScholarRadius.md);
    final index = selectedIndex.clamp(0, labels.isEmpty ? 0 : labels.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = labels.length;
        if (count == 0) return const SizedBox.shrink();
        final trackWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : count * 110.0;
        final segment = trackWidth / count;
        final duration = motionEnabled(context)
            ? CScholarDurations.normal
            : Duration.zero;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: CScholarMaterial.clayDeep,
            borderRadius: radius,
          ),
          child: SizedBox(
            height: 46,
            // The track owns its width so the segment Row is never handed
            // unbounded constraints: the admin role filter sits inside a
            // horizontal SingleChildScrollView, where `maxWidth` is infinite
            // and a flexed Row would assert ("non-zero flex but incoming width
            // constraints are unbounded") instead of laying out.
            width: trackWidth,
            child: Stack(
              children: [
                  AnimatedPositioned(
                  duration: duration,
                  curve: CScholarCurves.standard,
                  left: segment * index + 4,
                  top: 4,
                  bottom: 4,
                  width: segment - 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(CScholarRadius.sm),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CScholarMaterial.clayHigh,
                          CScholarMaterial.clay,
                        ],
                      ),
                      boxShadow: CScholarMaterial.clayDrop(depth: 0.6),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onChanged == null ? null : () => onChanged!(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              style: CScholarTextStyles.inter(
                                i == index ? 13.5 : 13,
                                i == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                i == index
                                    ? CScholarMaterial.textGreen
                                    : CScholarMaterial.textMuted,
                              ),
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


/// Recessed dropdown selector — the system's ONE dropdown/select control.
///
/// Wraps Flutter's [DropdownButtonHideUnderline] and [DropdownButton] inside
/// the same tonal clay well as [NeumorphField] (same [CScholarMaterial.clayDeep]
/// fill, no outline at rest, focus/error ring tinting).
///
/// Two faces, the way Flutter splits `DropdownButton` / `DropdownButtonFormField`:
///   * [NeumorphSelectField] — controlled and dumb (`value:` in, `onChanged:`
///     out). Use it for filter bars and anything else the screen resets
///     externally (a `FormField` never re-syncs `initialValue` after the user
///     picks a value, so an uncontrolled select would keep showing a stale
///     selection after "Clear filters").
///   * [NeumorphSelect] — a thin [FormField] adapter over [NeumorphSelectField]
///     so standard `Form` validation (`validator:`, `Form.validate()`, error
///     rendering) keeps working, matching [NeumorphField]. Use it in forms.
class NeumorphSelect<T> extends FormField<T> {
  NeumorphSelect({
    super.key,
    super.initialValue,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
    String? label,
    String? hintText,
    String? errorText,
    IconData? prefixIcon,
    bool isDense = true,
    bool isExpanded = true,
    super.enabled = true,
    FocusNode? focusNode,
    super.validator,
    AutovalidateMode? autovalidateMode,
    Color? dropdownColor,
    EdgeInsetsGeometry? contentPadding,
  }) : super(
          autovalidateMode:
              autovalidateMode ?? AutovalidateMode.onUserInteraction,
          builder: (field) {
            return NeumorphSelectField<T>(
              value: field.value,
              items: items,
              onChanged: (v) {
                field.didChange(v);
                onChanged?.call(v);
              },
              label: label,
              hintText: hintText,
              // An explicit errorText is a screen-level failure and outranks
              // the validator's complaint — same merge as NeumorphField.
              errorText: (errorText ?? '').isNotEmpty
                  ? errorText
                  : field.errorText,
              prefixIcon: prefixIcon,
              isDense: isDense,
              isExpanded: isExpanded,
              enabled: enabled,
              focusNode: focusNode,
              dropdownColor: dropdownColor,
              contentPadding: contentPadding,
            );
          },
        );
}

/// Controlled half of [NeumorphSelect]: renders [value], reports picks through
/// [onChanged], owns focus and painting, owns nothing else.
class NeumorphSelectField<T> extends StatefulWidget {
  const NeumorphSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.isDense = true,
    this.isExpanded = true,
    this.enabled = true,
    this.focusNode,
    this.dropdownColor,
    this.contentPadding,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final bool isDense;
  final bool isExpanded;
  final bool enabled;
  final FocusNode? focusNode;
  final Color? dropdownColor;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<NeumorphSelectField<T>> createState() =>
      _NeumorphSelectFieldState<T>();
}

class _NeumorphSelectFieldState<T> extends State<NeumorphSelectField<T>> {
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
    final flat = MediaQuery.highContrastOf(context);

    final focused = _focus.hasFocus;
    final disabled = !widget.enabled;
    final error = widget.errorText;
    final hasError = (error ?? '').isNotEmpty;
    final radius = BorderRadius.circular(CScholarRadius.md);

    // No outline at rest: the tonal well IS the affordance (see NeumorphField).
    // Focus, error and the high-contrast fallback all draw the same 1.5px rim.
    final Color? borderColor = flat
        ? CScholarMaterial.rimStrong
        : hasError
            ? CScholarColors.error
            : focused
                ? CScholarMaterial.gelTop
                : null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!.toUpperCase(),
              style: CScholarTextStyles.inter(
                11,
                FontWeight.w700,
                CScholarMaterial.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: CScholarMaterial.clayDeep,
              borderRadius: radius,
              border: borderColor == null
                  ? null
                  // Same rule as NeumorphField: a rim we draw at all is 1.5px,
                  // so the high-contrast fallback matches a focus ring.
                  : Border.all(color: borderColor, width: 1.5),
            ),
            child: Padding(
                padding: widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(
                      widget.prefixIcon,
                      size: 18,
                      color: CScholarMaterial.textMuted,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<T>(
                        value: widget.value,
                        focusNode: _focus,
                        isDense: widget.isDense,
                        isExpanded: widget.isExpanded,
                        dropdownColor:
                            widget.dropdownColor ?? CScholarMaterial.clay,
                        borderRadius: BorderRadius.circular(CScholarRadius.md),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: disabled
                              ? CScholarMaterial.rim
                              : CScholarMaterial.textMuted,
                          size: 20,
                        ),
                        hint: widget.hintText != null
                            ? Text(
                                widget.hintText!,
                                style: CScholarTextStyles.inter(
                                  13.5,
                                  FontWeight.w400,
                                  CScholarMaterial.textFaint,
                                ),
                              )
                            : null,
                        style: CScholarTextStyles.inter(
                          14,
                          FontWeight.w400,
                          CScholarMaterial.textPrimary,
                        ),
                        items: widget.items,
                        onChanged: disabled ? null : widget.onChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Text(
              error!,
              style: CScholarTextStyles.inter(
                12,
                FontWeight.w500,
                CScholarColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

