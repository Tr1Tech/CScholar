import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// Motion helpers (design plan, item 8).
///
/// - One transition everywhere: fade + 12px rise, 250ms, easeOut.
/// - Non-essential motion is skipped when the OS requests reduced motion.

/// True unless the OS asked for reduced motion.
bool motionEnabled(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// True when a LOOPING animation may run.
///
/// Loops are decoration: they add nothing a user must perceive. So they are the
/// first thing dropped — under reduced motion, under high contrast (where
/// gradients and glows are already stripped, so a drifting blob would be a
/// floating void), and whenever the global ambient switch is off.
bool ambientMotionEnabled(BuildContext context) =>
    CScholarMotion.ambientEnabled &&
    motionEnabled(context) &&
    !MediaQuery.highContrastOf(context);

/// Fire a light selection haptic, but only where it means something.
///
/// [HapticFeedback] is a no-op on web/desktop but still routes through a
/// platform channel, so calling it on every hover costs a message per event.
/// Guarded on the platform AND on motion being enabled — a reduced-motion user
/// gets no haptics either, since the two preferences travel together in
/// practice. The motion check reads the platform dispatcher directly because
/// this helper takes no [BuildContext].
void selectionHaptic() {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  if (WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
    return;
  }
  HapticFeedback.selectionClick();
}

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
// Route-transition heroes.
//
// A hero needs exactly one source and one target across a route change, and
// two heroes sharing a tag inside one subtree assert. The shell therefore takes
// an explicit `heroAvatar: false` on the very route that owns the target.

/// Identity avatar: the shell's pill avatar (source) flies into the profile
/// card's 88px avatar (target).
const String userAvatarHeroTag = 'user-avatar';

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
    this.origin = const Offset(0, 1),
    this.scaleFrom = 1.0,
  });

  final Widget child;
  final Duration delay;
  final double rise;
  final Duration duration;

  /// Direction the block travels *from*. The default [Offset(0, 1)] is the
  /// legacy rise-from-below — [rise] pixels, so every existing call site is
  /// untouched. Any OTHER origin is fractional (a fraction of the child's
  /// size, like [FractionalTranslation]): a right-hand rail enters from
  /// `Offset(0.06, 0)` and steps 6% of its own width, where 0.06 × a 12px
  /// rise would be less than a pixel of movement and read as nothing.
  final Offset origin;

  /// Starting scale, for cards that should *settle* onto the page rather than
  /// just fade. `1.0` (the default) adds no scale transform at all; `0.97`
  /// reads as the block landing. Keep it above 0.95 — a deeper scale is an
  /// arrival, not a settle, and at 200% text it exaggerates the block's
  /// footprint enough to read as a jump.
  final double scaleFrom;

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
      builder: (context, child) {
        final t = curve.value.clamp(0.0, 1.0);
        // The default origin keeps the legacy pixel translate so existing call
        // sites render byte-identically; an explicit origin is fractional and
        // needs the child's own size, which FractionalTranslation measures.
        final content = widget.origin == const Offset(0, 1)
            ? Transform.translate(
                offset: Offset(0, (1 - t) * widget.rise),
                child: child,
              )
            : FractionalTranslation(
                translation: Offset(
                  widget.origin.dx * (1 - t),
                  widget.origin.dy * (1 - t),
                ),
                child: child,
              );
        // scaleFrom == 1.0 (the default) must not add a scale node at all:
        // an extra Transform in every reveal is one more save-layer per block.
        if (widget.scaleFrom == 1.0) {
          return Opacity(opacity: t, child: content);
        }
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
            child: content,
          ),
        );
      },
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
    this.origin = const Offset(0, 1),
    this.delay,
  });

  final int index;
  final Widget child;
  final Duration step;
  final Duration max;
  final double rise;

  /// Direction the block travels *from* — see [EntranceReveal.origin]. The
  /// default rises from below, as every existing call site does.
  final Offset origin;

  /// Explicit delay override. [StaggerColumn]'s grid cascade needs a delay
  /// that is NOT expressible as `index * step` (the row term is weighted
  /// 1.6x), so it hands the finished delay over instead of bending [index]
  /// to fit. When non-null, [index], [step] and [max] are ignored.
  final Duration? delay;

  @override
  Widget build(BuildContext context) {
    final effective = delay ??
        Duration(
          microseconds:
              (index * step.inMicroseconds).clamp(0, max.inMicroseconds),
        );
    return EntranceReveal(
      delay: effective,
      rise: rise,
      origin: origin,
      child: child,
    );
  }
}

/// A [Column] whose children rise in one after another — the standard page
/// entrance for the blocks below a header.
///
/// [pitch] names the entrance rhythm (see [MotionPitch]) and, when given,
/// replaces [step]/[max]/[rise]. It is opt-in: the bare default must stay
/// byte-identical to the original 40ms/240ms stagger, because every screen in
/// the app relies on it until it migrates to a named pitch. [columns] > 1
/// cascades a KPI strip DIAGONALLY instead of left-to-right-then-wrap —
/// otherwise a 3-up grid reads as one horizontal wave with a delayed second
/// wave, not a cascade.
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
    this.rise = 12,
    this.origin = const Offset(0, 1),
    this.pitch,
    this.columns = 1,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final int startIndex;
  final Duration step;
  final Duration max;
  final double rise;
  final Offset origin;
  final MotionPitch? pitch;
  final int columns;

  /// Delay for child [i] under a grid cascade: column term + a 1.6x-weighted
  /// row term, clamped to the pitch's max like every other stagger.
  static Duration _diagonalDelay(
    int i,
    int columns,
    Duration step,
    Duration max,
  ) {
    final us = ((i % columns) * step.inMicroseconds +
            (i ~/ columns) * step.inMicroseconds * 1.6)
        .round();
    return Duration(microseconds: us.clamp(0, max.inMicroseconds));
  }

  @override
  Widget build(BuildContext context) {
    final Duration effStep = pitch?.step ?? step;
    final Duration effMax = pitch?.max ?? max;
    final double effRise = pitch?.rise ?? rise;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          Stagger(
            index: startIndex + i,
            step: effStep,
            max: effMax,
            rise: effRise,
            origin: origin,
            delay: columns > 1
                ? _diagonalDelay(startIndex + i, columns, effStep, effMax)
                : null,
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

/// The standard async slot: [AsyncValue.when] plus [AsyncCrossFade] in one
/// call, so the skeleton the switcher shows and the skeleton the loading branch
/// returns can never drift apart — that mismatch is exactly what makes an async
/// page jump when the data lands.
///
/// A refresh is not a first load: `when` keeps the data branch while a refresh
/// is in flight (`skipLoadingOnRefresh`), so the skeleton is only used when
/// there is nothing to show yet and pull-to-refresh never flashes skeletons
/// over live content.
Widget asyncSlot<T>(
  AsyncValue<T> value, {
  required Widget Function(T data) data,
  required Widget skeleton,
  required Widget Function(Object error, StackTrace stackTrace) error,
}) {
  return AsyncCrossFade(
    isLoading: value.isLoading && !value.isRefreshing,
    skeleton: skeleton,
    child: value.when(data: data, loading: () => skeleton, error: error),
  );
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
