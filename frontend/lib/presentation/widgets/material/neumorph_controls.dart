import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';

/// Five states, not two. [previewState] exists so the design lab can render
/// every state side by side; leave it null everywhere in the app.
enum NeumorphState { rest, hover, pressed, focus, disabled }

/// One progress value drives every visual channel (gradient, shadow depth, the
/// 1.5px sink). That is why press and release can never de-sync — and why this
/// looks smoother than swapping two `BoxDecoration`s, since Flutter can only
/// interpolate shadow lists of equal length.
const double _kRest = 0;
const double _kHover = 0.35;
const double _kPressed = 1;

/// Shared state machine for every pressable clay control.
///
/// Press and release speak different curves on purpose: the press answers fast
/// on [CScholarCurves.standard] (a control that sinks slowly feels laggy), the
/// release springs back on [CScholarCurves.overshoot] over
/// [CScholarMotion.swap] (the overshoot is what reads as "physical"), and a
/// hover drift deepens over [CScholarMotion.micro]. One progress value still
/// drives every visual channel, so press and release can never de-sync.
class _NeumorphBase extends StatefulWidget {
  const _NeumorphBase({
    required this.child,
    required this.radius,
    required this.gel,
    this.danger = false,
    this.onTap,
    this.previewState,
    this.semanticLabel,
    this.spinContent = false,
  });

  final Widget child;
  final double radius;
  final bool gel;
  final bool danger;
  final VoidCallback? onTap;
  final NeumorphState? previewState;
  final String? semanticLabel;

  /// Rotate the (square) content 90 degrees while pressed. Only the icon
  /// button sets this: its content is a square tile, so the rotation reads as
  /// the glyph turning. A rectangular action button must never spin.
  final bool spinContent;

  @override
  State<_NeumorphBase> createState() => _NeumorphBaseState();
}

class _NeumorphBaseState extends State<_NeumorphBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CScholarDurations.fast,
  );
  final FocusNode _focus = FocusNode();
  bool _hover = false;
  bool _down = false;

  bool get _disabled =>
      widget.onTap == null || widget.previewState == NeumorphState.disabled;

  bool get _isFocused =>
      widget.previewState == NeumorphState.focus || _focus.hasFocus;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not initState: motionEnabled() reads MediaQuery, and the controller must
    // also re-target when the OS reduced-motion setting changes.
    _sync();
  }

  @override
  void didUpdateWidget(covariant _NeumorphBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewState != widget.previewState ||
        oldWidget.onTap != widget.onTap) {
      _sync();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_sync);
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  /// Retarget the single progress value. Entry is faster than release —
  /// leaving a control more slowly than it was pressed reads as "weight", and
  /// the release carries the overshoot spring while the press stays snappy.
  /// Hover drifts (rest <-> hover) run on the micro budget: the gel glow
  /// deepening under the pointer is a twitch, not a state change.
  void _sync() {
    if (!mounted) return;
    final target = _disabled
        ? _kRest
        : (widget.previewState == NeumorphState.pressed || _down)
        ? _kPressed
        : (_hover || widget.previewState == NeumorphState.hover)
        ? _kHover
        : _kRest;
    if (!motionEnabled(context)) {
      _c.value = target;
      return;
    }
    final pressing = target > _c.value;
    if (target == _kPressed || _c.value == _kPressed) {
      _c.duration = pressing ? CScholarDurations.fast : CScholarMotion.swap;
      _c.animateTo(
        target,
        curve: pressing ? CScholarCurves.standard : CScholarCurves.overshoot,
      );
    } else {
      _c.duration = CScholarMotion.micro;
      _c.animateTo(target, curve: CScholarCurves.standard);
    }
  }

  void _setDown(bool down) {
    if (_down == down) return;
    _down = down;
    _sync();
  }

  BoxDecoration _decoration(double t) {
    if (widget.gel) {
      final top = widget.danger
          ? CScholarColors.error
          : CScholarMaterial.gelTop;
      final bottom = widget.danger
          ? Color.lerp(
              CScholarColors.error,
              CScholarMaterial.textPrimary,
              0.22,
            )!
          : CScholarMaterial.gelBottom;
      final deep = widget.danger
          ? Color.lerp(CScholarColors.error, CScholarMaterial.textPrimary, 0.4)!
          : CScholarMaterial.gelDeep;
      return BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(top, bottom, 0.2 + 0.6 * t)!,
            Color.lerp(bottom, deep, t)!,
          ],
        ),
        // Pressing lifts the card's shadow away instead of adding an inset.
        boxShadow: t > 0.5
            ? CScholarMaterial.softShadow(depth: 0.35)
            : CScholarMaterial.softShadow(depth: 0.8),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      color: CScholarMaterial.clay,
      border: Border.all(
        color: Color.lerp(CScholarMaterial.rim, CScholarMaterial.rimStrong, t)!,
      ),
      boxShadow: t > 0.5
          ? CScholarMaterial.softShadow(depth: 0.25)
          : CScholarMaterial.softShadow(depth: 0.5),
    );
  }

  /// Focus must be visible: this is a web app driven by Tab + Enter.
  Widget _focusRing(Widget child) {
    if (!_isFocused) return child;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius + 5),
        border: Border.all(
          color: CScholarMaterial.gelTop.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: child,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      widget.onTap?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _disabled ? 0.0 : _c.value;
        final animate = motionEnabled(context);
        Widget content = Container(
          decoration: _decoration(t),
          child: Opacity(
            opacity: _disabled ? 0.45 : 1,
            child: Transform.translate(
              // 1.5px sink: the surface presses toward the canvas. Clay has no
              // inset well to travel into, so the sink is the whole gesture.
              // The release overshoot may push [t] a hair past its target;
              // that transient IS the spring, so it is not clamped away.
              offset: Offset(0, 1.5 * t),
              // Tactile micro-feedback from the brief: scale(0.96) on press.
              child: Transform.scale(scale: 1 - 0.04 * t, child: widget.child),
            ),
          ),
        );
        if (widget.spinContent) {
          // Icon-button glyph turn: 90 degrees while held, springing back on
          // release. The content is square, so only the glyph visibly turns.
          // Reduced motion gets no rotation at all, never a snapped one.
          content = AnimatedRotation(
            turns: animate && _down ? 0.25 : 0,
            duration: animate ? CScholarMotion.micro : Duration.zero,
            child: content,
          );
        }

        return Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          child: MouseRegion(
            cursor: _disabled
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) {
              _hover = true;
              _sync();
            },
            onExit: (_) {
              _hover = false;
              _sync();
            },
            child: Semantics(
              button: true,
              enabled: !_disabled,
              label: widget.semanticLabel,
              // The child already paints the same words; without this a screen
              // reader announces the label twice ("Add User Add User").
              excludeSemantics: widget.semanticLabel != null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _disabled
                    ? null
                    : (_) {
                        _focus.requestFocus();
                        _setDown(true);
                      },
                onTapUp: _disabled ? null : (_) => _setDown(false),
                onTapCancel: _disabled ? null : () => _setDown(false),
                onTap: _disabled ? null : widget.onTap,
                child: _focusRing(content),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Action button. `gel: true` = primary (green, white text);
/// `gel: false` = secondary (clay, dark text); `danger: true` = destructive
/// (deep red, white text — the only other gel fill in the system).
///
/// [loading] blocks taps and swaps the label for an inline clay sweep plus a
/// "Saving…" label through [AnimatedSwap]. The swap slot is pre-sized to the
/// wider of the two faces (measured with a [TextPainter] at build time, so no
/// layout animation is involved), which is why the button never resizes under
/// the pointer when a submit lands.
class NeumorphButton extends StatelessWidget {
  const NeumorphButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gel = true,
    this.danger = false,
    this.expand = false,
    this.loading = false,
    this.previewState,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gel;
  final bool danger;
  final bool expand;

  /// In-flight state: the button ignores taps and shows progress in place.
  final bool loading;
  final NeumorphState? previewState;

  /// Width of [text] in the button label style, so the swap slot can reserve
  /// the wider face. A fixed [SizedBox] from a build-time measurement keeps
  /// the width stable without ever animating layout.
  static double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    // Ceil: a fractional width rounds down inside a tight box and clips the
    // last glyph. The slot is a floor, never a ceiling (see the caller).
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final isGel = gel || danger;
    final foreground = isGel ? Colors.white : CScholarMaterial.textPrimary;
    final labelStyle = CScholarTextStyles.body(14, FontWeight.w700, foreground);
    // Icon glyph (18px) plus its 8px gap; the sweep plus its 8px gap.
    final labelFace =
        _textWidth(context, label, labelStyle) + (icon != null ? 26 : 0);
    final savingFace = _textWidth(context, 'Saving…', labelStyle) + 48 + 8;
    final slotWidth = labelFace > savingFace ? labelFace : savingFace;
    final button = _NeumorphBase(
      radius: CScholarRadius.full,
      gel: isGel,
      danger: danger,
      onTap: loading ? null : onPressed,
      previewState: previewState,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        // A minimum, not a fixed width: the swap keeps its stable slot, but a
        // label that measures wider than the slot (web fonts land after the
        // first build) grows the button instead of ellipsizing.
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: slotWidth),
          child: AnimatedSwap(
            style: SwapStyle.swap,
            child: loading
                ? Row(
                    key: const ValueKey('saving'),
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        child: ClayLoader(
                          height: 5,
                          tint: isGel ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Saving…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: foreground),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Icon-only button. Always pass a [tooltip] for icon-only web controls.
///
/// When [selectedIcon] is set, the glyph cross-fades and pops through
/// [MorphIcon] instead of hard-swapping — toggles (save, block, visibility)
/// must never repaint their glyph. Null keeps the single static glyph,
/// exactly as before.
class NeumorphIconButton extends StatelessWidget {
  const NeumorphIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.gel = false,
    this.size = 44,
    this.tooltip,
    this.previewState,
    this.selectedIcon,
    this.selected = false,
    this.color,
    this.selectedColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool gel;
  final double size;
  final String? tooltip;
  final NeumorphState? previewState;

  /// Morph target for state toggles. Paired with [selected].
  final IconData? selectedIcon;

  /// Which glyph shows when [selectedIcon] is set.
  final bool selected;

  /// Glyph hue. Defaults to the ink every control has always used; a row
  /// action passes its semantic colour (edit, delete) so the meaning reads
  /// before the tooltip does.
  final Color? color;

  /// Glyph hue while [selectedIcon] is showing, for two-meaning toggles.
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final foreground = gel
        ? Colors.white
        : (color ?? CScholarMaterial.textPrimary);
    final selectedForeground = gel
        ? Colors.white
        : (selectedColor ?? foreground);
    final glyph = selectedIcon == null
        ? Icon(icon, size: size * 0.42, color: foreground)
        : MorphIcon(
            icon: icon,
            selectedIcon: selectedIcon!,
            selected: selected,
            color: foreground,
            selectedColor: selectedForeground,
            size: size * 0.42,
          );
    final button = _NeumorphBase(
      radius: size / 2,
      gel: gel,
      onTap: onPressed,
      previewState: previewState,
      semanticLabel: tooltip,
      // Square tile, so the 90-degree press turn reads as the glyph turning.
      spinContent: true,
      child: SizedBox(width: size, height: size, child: glyph),
    );
    if (tooltip == null) return button;
    // The base already carries the tooltip as its semantic label.
    return Tooltip(
      message: tooltip!,
      excludeFromSemantics: true,
      child: button,
    );
  }
}
