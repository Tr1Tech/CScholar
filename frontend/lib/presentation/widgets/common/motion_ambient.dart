import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Ambient motion — the loops from [CScholarMotion]'s AMBIENT budget.
///
/// These live apart from `motion.dart` because they are the only primitives
/// that tick forever while a state holds, and every one of them must be gated
/// by [ambientMotionEnabled] and isolated in a [RepaintBoundary]: a loop
/// without a gate makes `pumpAndSettle()` never terminate, and one without a
/// boundary repaints its ancestors every frame. Each widget below carries its
/// own boundary, so a forgotten caller wrap cannot break either rule.
///
/// Reduced motion is inert, not fast: every widget returns a STATIC equivalent
/// (no controller, no ticker, no compositing layer) when
/// [ambientMotionEnabled] is false — which covers reduced motion, high
/// contrast and the global kill switch in one check.

/// Breathing status dot: scale 0.85 ↔ 1.15 and fill alpha 1 ↔ 0.6 on a 1200ms
/// symmetric loop ([CScholarCurves.anticipate] — an asymmetric loop visibly
/// hitches at the turnaround).
///
/// Returns a STATIC dot when [ambientMotionEnabled] is false, so reduced
/// motion, high contrast, low-power and tests get no ticker at all. Carries
/// its own [RepaintBoundary]: the loop repaints every frame, but only inside
/// this layer.
///
/// Three meanings only: live, syncing, recording — and never motion alone (a
/// pulsing dot needs its text label). A dot that pulses decoratively teaches
/// users to ignore it.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 8});

  /// Dot fill. A status colour the caller owns — the label beside it carries
  /// the word, so the pulse is never the only thing saying "live".
  final Color color;

  /// Dot diameter at rest; the loop swings it to ±15%.
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CScholarMotion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// The gates can flip while the dot is on screen. The MediaQuery gates are
  /// inherited (so a flip lands in didChangeDependencies), but the global
  /// ambient switch is a plain static — a build is the only place that flip is
  /// seen, which is what lets a test turn every loop off in one line.
  void _sync() {
    if (ambientMotionEnabled(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else if (_c.isAnimating) {
      _c.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
    );
    if (!ambientMotionEnabled(context)) return dot;
    // Fill alpha, not an Opacity widget: the loop repaints every frame and an
    // Opacity would add a save-layer to each of them.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = CurvedAnimation(
            parent: _c,
            curve: CScholarCurves.anticipate,
            reverseCurve: CScholarCurves.anticipate,
          ).value;
          return Transform.scale(
            scale: 0.85 + 0.30 * t,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color
                    .withValues(alpha: (1 - 0.4 * t).clamp(0.0, 1.0)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wraps a gold object so its halo slowly deepens and recedes (2400ms,
/// symmetric).
///
/// Only the SHADOW animates. The object is not moved or scaled: a scaled gold
/// tile would break the clay read, and at 200% text it could clip its
/// neighbours. Strength swings between [min] and [max] multiples of
/// [CScholarShadows.goldGlow], rebuilt via
/// `CScholarMaterial.goldGlow(strength: ...)` so the recipe keeps one source
/// of truth.
///
/// Decor only, per the material law: 2–3 per screen maximum, never behind
/// text, and dropped entirely when [ambientMotionEnabled] is false (reduced
/// motion and high contrast both make it false) — the static glow the caller
/// already paints is untouched. Carries its own [RepaintBoundary].
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({
    super.key,
    required this.child,
    this.min = 0.7,
    this.max = 1.15,
    this.borderRadius,
  });

  final Widget child;

  /// Lowest strength, as a multiple of the resting glow.
  final double min;

  /// Highest strength.
  final double max;

  /// Corner radius the glow follows, so it hugs a rounded tile instead of
  /// reading as a rectangular bloom around it. Match the child's own radius —
  /// a mismatched glow reads as a shadow that disagrees with the object.
  final BorderRadius? borderRadius;

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CScholarMotion.breathe,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Same gate discipline as [PulseDot]: MediaQuery flips land in
  /// didChangeDependencies, the global switch is caught in build.
  void _sync() {
    if (ambientMotionEnabled(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else if (_c.isAnimating) {
      _c.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    if (!ambientMotionEnabled(context)) return widget.child;
    final curve = CurvedAnimation(
      parent: _c,
      curve: CScholarCurves.anticipate,
      reverseCurve: CScholarCurves.anticipate,
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, child) {
          final strength = widget.min + (widget.max - widget.min) * curve.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: CScholarMaterial.goldGlow(strength: strength),
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Two slow radial washes drifting behind a hero panel on a 16s loop.
///
/// Placement rules, all of which exist because blur and large radial gradients
/// are the two most expensive things on a Flutter web frame:
///   1. HERO PANELS AND EMPTY STATES ONLY. Never behind a scrolling list,
///      never inside a [ListView] item, never inside a [GlassPanel] (that
///      would force a second backdrop pass), never on a screen that already
///      shows glass chrome at full width.
///   2. At most ONE per screen. Two drifting washes in one viewport is a lava
///      lamp.
///   3. Always fully inside a [RepaintBoundary], and always [IgnorePointer].
///   4. Colours come from [CScholarColors] at low alpha — never a raw hex, and
///      never gold directly behind text: the gold wash bleeds off one CORNER,
///      not the centre of the copy.
///   5. Returns the child alone when [ambientMotionEnabled] is false.
class DriftingWash extends StatefulWidget {
  const DriftingWash({super.key, this.child, this.intensity = 0.28});

  /// The hero's content, rendered ON TOP of the wash layer. The washes stay
  /// inside this widget's bounds (the Stack clips them), so the caller places
  /// this INSIDE the hero panel and the drift reads as light moving on the
  /// panel's own surface.
  final Widget? child;

  /// Peak alpha of each wash. Low on purpose — the washes are noticed only in
  /// peripheral vision, and never seen to loop.
  final double intensity;

  @override
  State<DriftingWash> createState() => _DriftingWashState();
}

class _DriftingWashState extends State<DriftingWash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CScholarMotion.drift,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Same gate discipline as [PulseDot]: MediaQuery flips land in
  /// didChangeDependencies, the global switch is caught in build.
  void _sync() {
    if (ambientMotionEnabled(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else if (_c.isAnimating) {
      _c.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    if (!ambientMotionEnabled(context)) {
      return widget.child ?? const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _WashPainter(t: _c.value, intensity: widget.intensity),
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

/// The two washes: a green one anchored upper-left, a gold one bleeding off
/// the lower-right corner. Both drift on slow phase-shifted orbits so they
/// never move as one, and both fade to transparent well inside the panel.
class _WashPainter extends CustomPainter {
  const _WashPainter({required this.t, required this.intensity});

  /// 0..1 loop phase.
  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _wash(
      canvas,
      size,
      const Offset(0.2, 0.22),
      0.66,
      CScholarColors.primaryGreenLight,
    );
    _wash(canvas, size, const Offset(0.84, 0.8), 0.5, CScholarColors.goldSoft);
  }

  void _wash(
    Canvas canvas,
    Size size,
    Offset anchor,
    double radiusFactor,
    Color color,
  ) {
    final angle = t * 2 * math.pi;
    final center = Offset(
      size.width * anchor.dx + math.sin(angle) * size.width * 0.04,
      size.height * anchor.dy + math.cos(angle) * size.height * 0.05,
    );
    final rect = Rect.fromCircle(
      center: center,
      radius: size.shortestSide * radiusFactor,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: intensity),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_WashPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intensity != intensity;
}
