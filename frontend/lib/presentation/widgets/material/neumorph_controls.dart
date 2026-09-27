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
class _NeumorphBase extends StatefulWidget {
  const _NeumorphBase({
    required this.child,
    required this.radius,
    required this.gel,
    this.danger = false,
    this.onTap,
    this.previewState,
    this.semanticLabel,
  });

  final Widget child;
  final double radius;
  final bool gel;
  final bool danger;
  final VoidCallback? onTap;
  final NeumorphState? previewState;
  final String? semanticLabel;

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
  /// leaving a control more slowly than it was pressed reads as "weight".
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
    _c.duration = target > _c.value
        ? CScholarDurations.fast
        : CScholarDurations.normal;
    _c.animateTo(target, curve: CScholarCurves.standard);
  }

  void _setDown(bool down) {
    if (_down == down) return;
    _down = down;
    _sync();
  }

  BoxDecoration _decoration(double t) {
    if (widget.gel) {
      final top = widget.danger ? CScholarColors.error : CScholarMaterial.gelTop;
      final bottom = widget.danger
          ? Color.lerp(CScholarColors.error, CScholarMaterial.textPrimary, 0.22)!
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
            Color.lerp(top, bottom, 0.25 + 0.65 * t)!,
            Color.lerp(bottom, deep, t)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CScholarMaterial.shadowDark.withValues(alpha: 0.30 * (1 - t)),
            blurRadius: 14 * (1 - t) + 2,
            offset: Offset(0, 6 * (1 - t)),
            spreadRadius: -2,
          ),
        ],
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(CScholarMaterial.clayHigh, CScholarMaterial.clayDeep, t)!,
          Color.lerp(CScholarMaterial.clay, CScholarMaterial.clayDeep, t)!,
        ],
      ),
      border: Border.all(
        color: Color.lerp(CScholarMaterial.rim, CScholarMaterial.rimStrong, t)!,
      ),
      boxShadow: [
        BoxShadow(
          color: CScholarMaterial.shadowDark.withValues(alpha: 0.40 * (1 - t)),
          blurRadius: 14 * (1 - t) + 2,
          offset: Offset(0, 7 * (1 - t)),
          spreadRadius: -4,
        ),
      ],
    );
  }

  /// Focus must be visible: neumorphism has no visible focus by default, and
  /// this is a web app driven by Tab + Enter.
  Widget _focusRing(Widget child) {
    if (!_isFocused) return child;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius + 5),
        border: Border.all(
          color: CScholarMaterial.gelTop.withValues(alpha: 0.45),
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
        final content = Container(
          decoration: _decoration(t),
          child: Opacity(
            opacity: _disabled ? 0.45 : 1,
            child: Transform.translate(
              // 1.5px sink: the surface presses toward the canvas. Clay has no
              // inset well to travel into, so the sink is the whole gesture.
              offset: Offset(0, 1.5 * t),
              child: widget.child,
            ),
          ),
        );

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
/// [loading] blocks taps and swaps the label for an inline clay sweep, so a
/// double submit is impossible while a request is in flight.
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

  @override
  Widget build(BuildContext context) {
    final isGel = gel || danger;
    final foreground = isGel ? Colors.white : CScholarMaterial.textPrimary;
    final button = _NeumorphBase(
      radius: CScholarRadius.md,
      gel: isGel,
      danger: danger,
      onTap: loading ? null : onPressed,
      previewState: previewState,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 48,
                child: ClayLoader(height: 5, tint: isGel ? Colors.white : null),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style:
                    CScholarTextStyles.inter(14, FontWeight.w600, foreground),
              ),
            ],
          ],
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Icon-only button. Always pass a [tooltip] for icon-only web controls.
class NeumorphIconButton extends StatelessWidget {
  const NeumorphIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.gel = false,
    this.size = 44,
    this.tooltip,
    this.previewState,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool gel;
  final double size;
  final String? tooltip;
  final NeumorphState? previewState;

  @override
  Widget build(BuildContext context) {
    final foreground = gel ? Colors.white : CScholarMaterial.textPrimary;
    final button = _NeumorphBase(
      radius: size / 2,
      gel: gel,
      onTap: onPressed,
      previewState: previewState,
      semanticLabel: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.42, color: foreground),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}



