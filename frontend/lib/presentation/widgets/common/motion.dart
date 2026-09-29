import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

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
// Thesis-continuity heroes.
//
// A hero needs exactly one source and one target per route change, and a list
// can show the same thesis twice (results grid + recommendation rail), so the
// tags are namespaced by thesis id and the route that renders the target
// disables its source — the same opt-out [userAvatarHeroTag] has.

/// Card banner block → detail header block. The match badge deliberately gets
/// NO hero: it is a small colour-coded pill, and flying it while the banner
/// expands reads as two competing motions.
String thesisBannerTag(int thesisId) => 'thesis-banner-$thesisId';

/// Card title → detail title.
String thesisTitleTag(int thesisId) => 'thesis-title-$thesisId';

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

// --------------------------------------------------------------------------
// Micro-interaction primitives (motion upgrade, PART 5).
//
// One rule for all of them: if a primitive would need to animate layout to
// work, it is the wrong primitive. Everything below is transform / opacity /
// colour / shadow only. The looping ones live in `motion_ambient.dart`; the
// one-shots live here.

/// A tuned children-swapper: fade + ONE secondary motion, chosen by intent.
///
/// A bare [AnimatedSwitcher] cross-fades, which on a green-on-green clay panel
/// reads as a flicker rather than a change. Each style pairs the fade with the
/// single motion that matches the meaning of the swap — the app had exactly
/// three hand-rolled switchers, and this is the one they all become.
///
/// [child] MUST be keyed (a [ValueKey] on whatever changed) or the switcher
/// cannot see the swap and the change happens by hard repaint.
///
/// Reduced motion returns [child] with NO AnimatedSwitcher at all — nothing to
/// settle, nothing to leak.
enum SwapStyle {
  /// Exiting copy slides up a quarter of its height, cropped. Hint ↔ error
  /// text, label ↔ "Saving…".
  swap,

  /// Incoming rises 6% → 0, outgoing lifts −4%. Skeleton → content.
  rise,

  /// Incoming scale 0.6 → 1.0 through [CScholarCurves.overshoot]. Outline ↔
  /// filled glyph, checkmark, badge. Keep it small: an oversized pop reads as
  /// a bounce.
  pop,

  /// Incoming from `Offset(-0.12, 0)`, outgoing to `Offset(0.12, 0)`. A value
  /// changing along a row.
  slideX,
}

class AnimatedSwap extends StatelessWidget {
  const AnimatedSwap({
    super.key,
    required this.child,
    this.style = SwapStyle.swap,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final SwapStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) return child; // no switcher, no controller
    return AnimatedSwitcher(
      duration: CScholarMotion.swap,
      switchInCurve: CScholarCurves.settle,
      switchOutCurve: CScholarCurves.exit,
      // Same stack as the default layout builder, aligned to [alignment] so a
      // top-anchored swap cannot recentre the column it sits in.
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) =>
          _swapTransition(child, animation, style),
      child: child,
    );
  }

  /// AnimatedSwitcher builds each entry's transition ONCE, and it does so
  /// BEFORE the outgoing controller is reversed — so a status check at build
  /// time would freeze the leaving copy on the entering tween forever. The
  /// status is therefore read PER FRAME inside this builder. Both tweens map
  /// animation value 1 to Offset.zero, so the frame where the status flips
  /// from forward to reverse is seamless. The switcher's curves are already
  /// applied (in: [CScholarCurves.settle], out: [CScholarCurves.exit]); only
  /// `pop` re-curves, because the overshoot must be the scale's own curve, not
  /// the fade's.
  Widget _swapTransition(
    Widget child,
    Animation<double> animation,
    SwapStyle style,
  ) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final entering = animation.status != AnimationStatus.reverse;
        switch (style) {
          case SwapStyle.swap:
            // The leaving copy is cropped: text that slides uncropped smears
            // over whatever sits below the well.
            final content = entering
                ? child
                : SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
            return ClipRect(
              child: FadeTransition(opacity: animation, child: content),
            );
          case SwapStyle.rise:
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin:
                      entering ? const Offset(0, 0.06) : const Offset(0, -0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          case SwapStyle.pop:
            // Applied to BOTH copies: the entering glyph pops through the
            // overshoot, the leaving one shrinks away under the same curve.
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(
                      parent: animation, curve: CScholarCurves.overshoot),
                ),
                child: child,
              ),
            );
          case SwapStyle.slideX:
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin:
                      entering ? const Offset(-0.12, 0) : const Offset(0.12, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
        }
      },
    );
  }
}

/// Outline ↔ filled glyph morph with a springy settle.
///
/// A hard swap is the most common place a Flutter app feels cheap: the eye
/// reads it as a repaint, not a response. The two glyphs cross-fade and scale
/// through [CScholarCurves.overshoot] (via [AnimatedSwap]'s pop style) so the
/// icon *lands*.
///
/// Both glyphs occupy a fixed [size] box, so the swap can never nudge a
/// sibling in the row.
class MorphIcon extends StatelessWidget {
  const MorphIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.color,
    required this.selectedColor,
    this.size = 20,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Color color;
  final Color selectedColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwap(
      style: SwapStyle.pop,
      child: Icon(
        selected ? selectedIcon : icon,
        key: ValueKey(selected),
        size: size,
        color: selected ? selectedColor : color,
      ),
    );
  }
}

/// A pressable state toggle: sinks on press, springs on release, and
/// optionally fires a one-shot expanding ring on the *activating* transition
/// only.
///
/// The ring plays once and stops — it is NOT a loop, so it needs no ambient
/// gate and `pumpAndSettle()` still terminates. It is decoration layered on
/// the gold [CScholarShadows.goldGlow] already reserved for prestige marks, so
/// high contrast drops it along with the glow. The save/bookmark this is built
/// for is the one control a student clicks repeatedly, so its press must
/// answer inside [CScholarMotion.swap] or the whole control feels laggy.
class TactileToggle extends StatefulWidget {
  const TactileToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.icon,
    required this.selectedIcon,
    this.size = 20,
    this.hitTarget = 40,
    this.burst = true,
    this.haptic = true,
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onChanged;
  final IconData icon;
  final IconData selectedIcon;

  /// Glyph size. The glyph stays this size inside the [hitTarget] box — the
  /// touch-target rule is the hit target's job, never the glyph's.
  final double size;

  /// Square hit target around the glyph. 40px is the minimum comfortable tap
  /// target; shrinking it below that to keep a row compact is how a toggle
  /// becomes unusable on a phone.
  final double hitTarget;

  /// One-shot expanding ring on the activating transition. Off under reduced
  /// motion and high contrast.
  final bool burst;

  /// Selection haptic on tap-down. No-op on web; skipped under reduced motion.
  final bool haptic;

  final String? semanticLabel;

  @override
  State<TactileToggle> createState() => _TactileToggleState();
}

class _TactileToggleState extends State<TactileToggle>
    with SingleTickerProviderStateMixin {
  /// One-shot burst, and it STOPS. A repeating ring here would make
  /// `pumpAndSettle()` hang and read as a live indicator — a save is not live.
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: CScholarMotion.swap);

  bool _down = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _toggle() {
    final activating = !widget.selected;
    if (widget.haptic) selectionHaptic();
    widget.onChanged();
    if (activating && mounted) _fireBurst();
  }

  void _fireBurst() {
    if (!widget.burst) return;
    if (!motionEnabled(context)) return;
    // High contrast strips coloured glows (invariant 4), so the ring goes with
    // them — a ring around a flat glyph would read as a focus ring and lie.
    if (MediaQuery.highContrastOf(context)) return;
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final animate = motionEnabled(context);
    return Semantics(
      button: true,
      toggled: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: _toggle,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: RepaintBoundary(
            child: SizedBox(
              width: widget.hitTarget,
              height: widget.hitTarget,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The ring sits BEHIND the glyph and paints only while the
                  // burst plays: a parked controller must leave nothing visible.
                  AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) {
                      if (_burst.value == 0 && !_burst.isAnimating) {
                        return const SizedBox.shrink();
                      }
                      final t = _burst.value;
                      return Transform.scale(
                        scale: 0.7 + t * 1.2,
                        child: Container(
                          width: widget.hitTarget * 0.8,
                          height: widget.hitTarget * 0.8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CScholarMaterial.goldTop.withValues(
                                  alpha: (1 - t).clamp(0.0, 1.0)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedScale(
                    duration: animate ? CScholarMotion.swap : Duration.zero,
                    curve: CScholarCurves.overshoot,
                    scale: _down && animate ? 0.94 : 1.0,
                    child: MorphIcon(
                      icon: widget.icon,
                      selectedIcon: widget.selectedIcon,
                      selected: widget.selected,
                      color: CScholarMaterial.textPrimary,
                      selectedColor: CScholarMaterial.textPrimary,
                      size: widget.size,
                    ),
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

/// Fill-on-first-paint meter for a 0..1 similarity score.
///
/// Two motions, both one-shot: the track fills over [CScholarMotion.page] on
/// [settle], and the numeric label counts up via [CountUpText] at the SAME
/// duration so number and bar finish together (a number that lands before its
/// bar looks like a bug).
///
/// The fill colour comes from `CScholarSimilarity.colorFor(score)` so the meter
/// can never disagree with the label, and the fill never renders below 4.5:1
/// against its track — the existing colorFor tokens were measured on
/// [CScholarMaterial.clayDeep] and all clear 4.5:1 there. Painted like
/// [ClayProgressBar] (a CustomPaint inside a fixed track), so the fill
/// animates without a layout pass and a re-classified score can never reflow
/// the row around it.
class ScoreMeter extends StatelessWidget {
  const ScoreMeter({
    super.key,
    required this.score,
    this.height = 6,
    this.showLabel = true,
  });

  /// 0..1 similarity. Clamped, never trusted: a score of 1.4 would fill past
  /// the track and read as a broken bar.
  final double score;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 1.0).toDouble();
    final tint = CScholarSimilarity.colorFor(clamped);
    final radius = BorderRadius.circular(height / 2);

    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: radius,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: motionDuration(context, CScholarMotion.page),
            curve: CScholarCurves.settle,
            builder: (context, v, _) => CustomPaint(painter: _MeterPainter(v, tint)),
          ),
        ),
      ),
    );
    if (!showLabel) return track;
    return Row(
      children: [
        Expanded(child: track),
        const SizedBox(width: 8),
        CountUpText(
          value: (clamped * 100).round(),
          duration: CScholarMotion.page,
          style: CScholarTextStyles.inter(11.5, FontWeight.w700, tint),
        ),
      ],
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter(this.value, this.tint);

  final double value;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * value, size.height),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(rrect, Paint()..color = tint);
  }

  @override
  bool shouldRepaint(_MeterPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.tint != tint;
}

/// Reports whether its child has scrolled past [trigger], and hands the answer
/// to a builder.
///
/// A [NotificationListener] can only hear a scrollable it is an ANCESTOR of,
/// so this wrapper must sit ABOVE the scroll view — chrome that sits beside
/// the pane (a topbar above it) or inside it (a filter strip) cannot hear its
/// own scroll. [child] is therefore handed THROUGH the builder: the builder
/// wraps the pane in the seated chrome, and chrome that lives INSIDE the pane
/// reads the same state via [seatedOf] instead.
///
/// The seated state is a colour/shadow change over [CScholarMotion.swap] —
/// nothing reflows, which a height-animating collapsing header would. **Do
/// not** use it to animate a height: it exists precisely so nobody writes a
/// collapsing header with [AnimatedSize].
class ScrollVeil extends StatefulWidget {
  const ScrollVeil({
    super.key,
    required this.child,
    required this.builder,
    this.trigger = 12,
  });

  /// The pane that is listened to AND rendered: a scrollable, or a subtree
  /// containing one, whose scroll notifications report how far content has
  /// travelled.
  final Widget child;

  /// Builds the chrome around [child] from the seated state, rebuilt only when
  /// [seated] crosses [trigger] — never per scroll event, so a seated flip
  /// costs one chrome rebuild, not a frame per scroll tick.
  final Widget Function(BuildContext context, Widget child, bool seated)
      builder;

  /// Scroll depth, in px, past which the chrome is seated.
  final double trigger;

  /// The seated state of the enclosing [ScrollVeil], for chrome that sits
  /// INSIDE the pane and cannot be reached by [builder]. Null when there is no
  /// ScrollVeil above, so a caller can fall back to its rest state.
  static bool? seatedOf(BuildContext context) =>
      _SeatedScope.of(context)?.seated;

  @override
  State<ScrollVeil> createState() => _ScrollVeilState();
}

class _ScrollVeilState extends State<ScrollVeil> {
  bool _seated = false;

  bool _handleScroll(ScrollNotification notification) {
    final seated = notification.metrics.pixels > widget.trigger;
    if (seated != _seated) setState(() => _seated = seated);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: _SeatedScope(
        seated: _seated,
        child: widget.builder(context, widget.child, _seated),
      ),
    );
  }
}

/// The seated state, inherited so chrome inside the pane can read it. Depends
/// are notified only on threshold crossings — never per scroll tick.
class _SeatedScope extends InheritedWidget {
  const _SeatedScope({required this.seated, required super.child});

  final bool seated;

  static _SeatedScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SeatedScope>();

  @override
  bool updateShouldNotify(_SeatedScope old) => old.seated != seated;
}
