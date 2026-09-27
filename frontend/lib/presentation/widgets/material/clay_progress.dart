import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Recessed track + gel fill, painted instead of laid out: the animation costs
/// one small repaint (inside its own RepaintBoundary), never a layout pass.
class ClayProgressBar extends StatelessWidget {
  const ClayProgressBar({
    super.key,
    this.value = 0,
    this.height = 10,
    this.animate = true,
    this.tint,
  });

  final double value;
  final double height;
  final bool animate;

  /// Semantic fill. Defaults to the brand gel pair; pass a token when the bar
  /// encodes meaning (the dashboard status charts do) so the fill stays a
  /// legend rather than decoration.
  ///
  /// A bar is a graphical object, so the fill must clear 3:1 against the
  /// [CScholarMaterial.clayDeep] track (WCAG 1.4.11). Measured on that track:
  /// #007A14 4.54:1, #1D4ED8 5.50:1, #A34A08 4.87:1, #556377 5.01:1. The old
  /// chart colour #FF9900 is only 1.76:1 — never use it as a bar fill.
  final Color? tint;

  /// Gel ramp — see [_gelRamp], shared with [ClayLoader] so a value bar and an
  /// indeterminate loader can never drift apart.
  List<Color> get _ramp => _gelRamp(tint);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    final target = value.clamp(0.0, 1.0);
    final ramp = _ramp;

    Widget paint(double v) => SizedBox(
          height: height,
          width: double.infinity,
          child: RepaintBoundary(
            child: CustomPaint(painter: _BarPainter(v, ramp)),
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: radius,
      ),
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: motionEnabled(context)
                  ? CScholarDurations.slow
                  : Duration.zero,
              curve: CScholarCurves.standard,
              builder: (context, v, _) => paint(v),
            )
          : paint(target),
    );
  }
}

/// Gel ramp: the brand pair, or a two-stop shade of `tint` so a semantic fill
/// still reads as a moulded gel instead of a flat div. The 0.22 shade matches
/// the system's own ramp (gelTop #007A14 -> gelBottom #00610F).
List<Color> _gelRamp(Color? tint) => tint == null
    ? const [CScholarMaterial.gelTop, CScholarMaterial.gelBottom]
    : [tint, Color.lerp(tint, CScholarMaterial.textPrimary, 0.22)!];

class _BarPainter extends CustomPainter {
  const _BarPainter(this.value, this.ramp);

  final double value;
  final List<Color> ramp;

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * value, size.height),
      Radius.circular(size.height / 2),
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: ramp,
      ).createShader(rrect.outerRect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      oldDelegate.value != value || !listEquals(oldDelegate.ramp, ramp);
}

/// Indeterminate companion to [ClayProgressBar]: the same recessed clay track
/// and gel ramp, but the fill sweeps instead of measuring a value.
///
/// This exists because an `AsyncValue.when(loading:)` slot has to say "working"
/// without a number, and stock Material chrome was the only way to say it. The
/// faculty thesis form's five dropdown providers each dropped a bare
/// `LinearProgressIndicator()` there — Material blue, no track, no rim, no
/// inset, and blind to the motion policy below.
///
/// Motion: under reduced motion the sweep is replaced by the same segment
/// pinned at a fixed phase, so the control still reads as in progress without
/// animating. That is the loaders' version of how `HoverLift` pins a card flat
/// rather than lifting it.
///
/// High contrast needs no extra branch here: the segment is a gel stop on the
/// [CScholarMaterial.clayDeep] track, which clears 3:1 as a graphical object
/// (WCAG 1.4.11) — the same contract the tier 3 tests pin for bar fills.
class ClayLoader extends StatefulWidget {
  const ClayLoader({super.key, this.height = 10, this.tint});

  /// Track height. Mirrors [ClayProgressBar.height]; 8 reads well in a form
  /// slot where the loader replaces a control that is still loading.
  final double height;

  /// Semantic fill, exactly as [ClayProgressBar.tint]. Defaults to the brand gel.
  final Color? tint;

  @override
  State<ClayLoader> createState() => _ClayLoaderState();
}

class _ClayLoaderState extends State<ClayLoader>
    with SingleTickerProviderStateMixin {
  /// One sweep. Deliberately longer than `CScholarDurations.slow` — a loading
  /// loop that completes in 300ms reads as a flicker, not as progress — so the
  /// value is local rather than a global duration token.
  static const Duration _sweep = Duration(milliseconds: 1100);

  /// Phase painted when motion is off: the segment sits centred on the track.
  static const double _pinnedPhase = 0.5;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _sweep);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The OS motion policy can flip while the loader is on screen, so keep the
    // ticker in step. When it is stopped the painter falls back to
    // [_pinnedPhase], so a parked controller still paints a full segment.
    if (motionEnabled(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height / 2);
    final ramp = _gelRamp(widget.tint);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: radius,
      ),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              // Read the phase inside this builder: the controller drives this
              // callback rather than the enclosing State, so a phase captured
              // outside it would freeze at the widget's last rebuild.
              painter: _SweepPainter(
                motionEnabled(context) ? _controller.value : _pinnedPhase,
                ramp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indeterminate fill: a gel segment sliding the length of the track. Unlike
/// [_BarPainter] the phase is not a measurement, so it never widens or narrows —
/// it only travels.
class _SweepPainter extends CustomPainter {
  const _SweepPainter(this.phase, this.ramp);

  /// 0..1 sweep position, not a value.
  final double phase;
  final List<Color> ramp;

  /// Segment length as a fraction of the track: long enough to read as a bar
  /// segment, short enough that its trailing edge stays inside the track while
  /// it is fully on it.
  static const double _span = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final radius = Radius.circular(size.height / 2);
    final track = Offset.zero & size;

    // The segment starts and ends fully off the track, so clip to the track.
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(track, radius));
    final segment = size.width * _span;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size.width + segment) * phase - segment,
        0,
        segment,
        size.height,
      ),
      radius,
    );
    final paint = Paint()
      ..shader = LinearGradient(colors: ramp).createShader(track);
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) =>
      oldDelegate.phase != phase || !listEquals(oldDelegate.ramp, ramp);
}

