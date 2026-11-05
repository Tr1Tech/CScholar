import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// flutter_animate shorthand for the CScholar entrance language.
///
/// ONE rule: every helper here resolves onto the existing motion tokens
/// ([CScholarMotion], [CScholarCurves], [MotionPitch]) so flutter_animate
/// adds execution, not a second design language. The delay maps, durations
/// and curves stay named in one place.
///
/// Reduced motion AND the global kill switch: every helper returns the child
/// untouched when [!animateEnabled] — no ticker, no Timer, no Animate wrapper,
/// same contract as [EntranceReveal].
extension AnimateX on Widget {
  /// Fade + rise entrance. The workhorse: page blocks, cards, rows.
  ///
  /// [pitch] names the stagger rhythm for lists; pass [delay] explicitly
  /// for grid cascades ([StaggerColumn.diagonalDelay]).
  Widget fadeSlideIn(
    BuildContext context, {
    Duration delay = Duration.zero,
    double rise = 12,
    double scaleFrom = 1.0,
    MotionPitch? pitch,
    int? index,
  }) {
    if (!animateEnabled(context)) return this;
    final effectiveDelay = delay != Duration.zero
        ? delay
        : (pitch != null && index != null
            ? Duration(
                microseconds: (index * pitch.step.inMicroseconds)
                    .clamp(0, pitch.max.inMicroseconds),
              )
            : Duration.zero);
    final effectiveRise = pitch?.rise ?? rise;
    var animated = animate().fadeIn(
      delay: effectiveDelay,
      duration: CScholarMotion.softEnter,
      curve: CScholarCurves.softEnter,
    );
    if (effectiveRise > 0) {
      animated = animated.move(
        begin: Offset(0, effectiveRise),
        end: Offset.zero,
        duration: CScholarMotion.softEnter,
        curve: CScholarCurves.softEnter,
      );
    }
    if (scaleFrom < 1.0) {
      animated = animated.scale(
        begin: Offset(scaleFrom, scaleFrom),
        end: const Offset(1, 1),
        duration: CScholarMotion.enter,
        curve: CScholarCurves.settle,
      );
    }
    return animated;
  }

  /// Scale-settle for small identity marks: badges, check glyphs, match
  /// pills. Springy landing on [CScholarCurves.overshoot], never a pop-in.
  Widget scalePop(
    BuildContext context, {
    Duration delay = Duration.zero,
    double begin = 0.6,
  }) {
    if (!animateEnabled(context)) return this;
    return animate().fadeIn(
      delay: delay,
      duration: CScholarMotion.swap,
      curve: CScholarCurves.settle,
    ).scale(
      begin: Offset(begin, begin),
      end: const Offset(1, 1),
      duration: CScholarMotion.swap,
      curve: CScholarCurves.overshoot,
    );
  }

  /// Blur-in for glass chrome: topbar, rail, dialog, sticky search.
  /// Fades + de-blurs over the page budget on [CScholarCurves.settle].
  Widget blurIn(
    BuildContext context, {
    Duration delay = Duration.zero,
    double begin = 8,
  }) {
    if (!animateEnabled(context)) return this;
    return animate().fadeIn(
      delay: delay,
      duration: CScholarMotion.page,
      curve: CScholarCurves.settle,
    ).blur(
      begin: Offset(begin, begin),
      end: Offset.zero,
      duration: CScholarMotion.page,
      curve: CScholarCurves.settle,
    );
  }

  /// Attention nudge: a single shimmer sweep across the child, then stop.
  /// One-shot — for the AI match badge and the hero search glow, never loops.
  ///
  /// [color] is the sweep tint at full strength; it is washed to 40% inside
  /// so the default can be the [CScholarMaterial.shadowLight] token instead
  /// of an inline alpha literal (the adoption guard bans raw Color(0x...)).
  Widget shimmerOnce(
    BuildContext context, {
    Duration delay = Duration.zero,
    Color color = CScholarMaterial.shadowLight,
  }) {
    if (!animateEnabled(context)) return this;
    return animate().shimmer(
      delay: delay,
      duration: CScholarMotion.shimmer,
      color: color.withValues(alpha: 0.4),
    );
  }
}
