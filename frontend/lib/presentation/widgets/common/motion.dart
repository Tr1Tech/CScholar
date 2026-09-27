import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// Motion helpers (design plan, item 8).
///
/// - One transition everywhere: fade + 12px rise, 250ms, easeOut.
/// - Non-essential motion is skipped when the OS requests reduced motion.

/// True unless the OS asked for reduced motion.
bool motionEnabled(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// Shared route transition for GoRouter pages.
Widget cscholarTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (!motionEnabled(context)) return child;
  final curved = CurvedAnimation(parent: animation, curve: CScholarCurves.entrance);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
      child: child,
    ),
  );
}

/// Theme-wide page transition: every route fades + rises slightly.
/// Applied once in MaterialApp theme — no per-route code needed.
class CScholarTransitionBuilder extends PageTransitionsBuilder {
  const CScholarTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return cscholarTransition(context, animation, secondaryAnimation, child);
  }
}

// --------------------------------------------------------------------------
// Motion vocabulary (design plan, item 8).
//
// ONE place per concern. Every helper is inert when the OS asks for reduced
// motion, so `pumpAndSettle()` always terminates and no timer is left running.
// Animations only ever touch transform / opacity / colour / shadow — never the
// layout of a large subtree.

/// Reduced-motion-aware duration. [Duration.zero] when motion is off, so the
/// implicit widget snaps instead of tweening.
Duration motionDuration(BuildContext context, Duration duration) =>
    motionEnabled(context) ? duration : Duration.zero;

/// Reduced-motion-aware multiplier. `1.0` (no motion) when motion is off.
double motionScale(BuildContext context, double value) =>
    motionEnabled(context) ? value : 1.0;

/// One-shot entrance: fade + rise. Plays once when it is first shown; a
/// [delay] lets a parent stagger a short column. Returns the child untouched
/// under reduced motion, so no ticker and no timer are created at all.
class EntranceReveal extends StatefulWidget {
  const EntranceReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.rise = 12,
    this.duration = CScholarDurations.normal,
  });

  final Widget child;
  final Duration delay;
  final double rise;
  final Duration duration;

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  )..value = 1;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!motionEnabled(context)) {
      _c.value = 1;
      return;
    }
    if (!_started) {
      _started = true;
      _c.value = 0;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) return widget.child;
    final total = widget.delay + widget.duration;
    final begin = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    final curve = CurvedAnimation(
      parent: _c,
      curve: Interval(begin, 1, curve: CScholarCurves.entrance),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * widget.rise),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Capped staggering for a small column of [EntranceReveal]s. Delay is
/// `index * step`, clamped to [max] so a long list can never crawl in.
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 40),
    this.max = const Duration(milliseconds: 240),
    this.rise = 12,
  });

  final int index;
  final Widget child;
  final Duration step;
  final Duration max;
  final double rise;

  @override
  Widget build(BuildContext context) {
    final delay = Duration(
      microseconds: (index * step.inMicroseconds).clamp(0, max.inMicroseconds),
    );
    return EntranceReveal(delay: delay, rise: rise, child: child);
  }
}

/// A [Column] whose children rise in one after another — the standard page
/// entrance for the blocks below a header.
///
/// Children must not be [Expanded]/[Flexible]: the motion wrapper sits between
/// the child and the Flex, and an Expanded needs the Flex as its direct parent.
/// Under reduced motion every child is returned untouched (no tickers at all).
class StaggerColumn extends StatelessWidget {
  const StaggerColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.startIndex = 0,
    this.step = const Duration(milliseconds: 40),
    this.max = const Duration(milliseconds: 240),
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final int startIndex;
  final Duration step;
  final Duration max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          Stagger(
            index: startIndex + i,
            step: step,
            max: max,
            child: children[i],
          ),
      ],
    );
  }
}

/// Press feedback for a custom surface (card, tile) that is not a clay button:
/// a small scale-down + sink while the pointer is down, springing back on
/// release. Inert on touch and under reduced motion. Transform only.
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.child,
    this.onTap,
    this.radius = CScholarRadius.xl,
    this.sink = 1.5,
    this.scale = 0.98,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final double sink;
  final double scale;
  final String? semanticLabel;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final animate = motionEnabled(context);
    final t = _down && animate ? 1.0 : 0.0;
    final content = AnimatedContainer(
      duration: motionDuration(context, CScholarDurations.fast),
      curve: CScholarCurves.standard,
      transform: Matrix4.identity()
        ..translateByDouble(0.0, widget.sink * t, 0.0, 1.0)
        ..scaleByDouble(1 - (1 - widget.scale) * t,
            1 - (1 - widget.scale) * t, 1.0, 1.0),
      transformAlignment: Alignment.center,
      child: widget.child,
    );
    if (widget.onTap == null) return content;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: content,
        ),
      ),
    );
  }
}

/// Async slot swap: keeps the layout height while the loading and loaded
/// states cross-fade (plus an 8px rise), so the page never jumps. The
/// skeleton is shown as-is; no spinner is introduced here.
class AsyncCrossFade extends StatelessWidget {
  const AsyncCrossFade({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
  });

  final bool isLoading;
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, CScholarDurations.normal);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: CScholarCurves.entrance,
      switchOutCurve: CScholarCurves.entrance,
      transitionBuilder: (widget, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: widget,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey<bool>(isLoading),
        child: isLoading ? skeleton : child,
      ),
    );
  }
}

/// KPI number that counts up on first paint (0 -> [value]) and tweens between
/// values afterwards. Reduced motion snaps straight to [value].
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = CScholarDurations.slow,
    this.textAlign,
  });

  final num value;
  final TextStyle style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context) || !value.isFinite) {
      return Text(_format(value), style: style, textAlign: textAlign);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: CScholarCurves.standard,
      builder: (context, v, _) =>
          Text(_format(v), style: style, textAlign: textAlign),
    );
  }

  static String _format(num v) {
    if (v.isFinite && v == v.roundToDouble()) {
      return v.round().toString();
    }
    return v.toStringAsFixed(0);
  }
}
