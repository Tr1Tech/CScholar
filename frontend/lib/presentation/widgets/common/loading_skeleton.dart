import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Block and sweep tones for the surface this skeleton sits on.
///
/// The mobile shell carries its own light/dark flag in a scope; the rest of the
/// app follows the Material theme. On dark the pair is inverted (blocks sit
/// above the canvas) so a loading page never glows white.
({Color base, Color highlight}) _skeletonTones(BuildContext context) {
  final scope = CScholarMobileThemeScope.maybeOf(context);
  final dark =
      scope?.isDark ?? (Theme.of(context).brightness == Brightness.dark);
  return dark
      ? (
          base: CScholarMaterial.skeletonBaseDark,
          highlight: CScholarMaterial.skeletonHighlightDark,
        )
      : (
          base: CScholarMaterial.skeletonBase,
          highlight: CScholarMaterial.skeletonHighlight,
        );
}

/// Holds a skeleton back until the load has run long enough to be worth
/// painting.
///
/// A response that lands inside [CScholarMotion.skeletonDelay] never paints a
/// placeholder at all: flashing one on and off reads as a glitch, not as
/// feedback. The block still occupies its layout box from the first frame (it
/// is laid out at opacity 0), so a fast response lands exactly where the
/// skeleton would have been and the page never jumps.
///
/// This lives on the skeleton widgets rather than on the async slot so every
/// loading branch obeys it — `asyncSlot`, a hand-rolled `when(loading:)`, the
/// design lab catalogue — without each caller remembering to opt in.
class DeferredSkeleton extends StatefulWidget {
  const DeferredSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<DeferredSkeleton> createState() => _DeferredSkeletonState();
}

class _DeferredSkeletonState extends State<DeferredSkeleton> {
  bool _revealed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(CScholarMotion.skeletonDelay, () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    // A load that finished first must not leave a timer behind.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _revealed ? 1 : 0,
      duration: motionDuration(context, CScholarDurations.fast),
      curve: CScholarCurves.standard,
      // Hidden is not idle: the shimmer's ticker stays stopped until the block
      // is actually painted.
      child: TickerMode(enabled: _revealed, child: widget.child),
    );
  }
}

/// Shimmer skeletons shown while lists/cards load (design plan, item 8).
/// Same card rhythm as real content so the swap doesn't jump the layout.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final tones = _skeletonTones(context);
    return DeferredSkeleton(
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: tones.base,
          highlightColor: tones.highlight,
          child: Container(
            decoration: BoxDecoration(
              color: tones.base,
              borderRadius: BorderRadius.circular(CScholarRadius.softCard),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double cardHeight;
  const SkeletonList({super.key, this.count = 4, this.cardHeight = 96});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => SkeletonCard(height: cardHeight)),
    );
  }
}

/// Skeleton with the real card's silhouette: a 76px banner block, two text
/// lines and a short tag row, shimmered in one pass.
///
/// [SkeletonCard] is one rounded rectangle, so swapping it for a real
/// [ThesisCard] (76px banner + text block + tag row) always jumps. The point
/// here is that the CONTENT occupies the same box the skeleton did, so
/// [AsyncCrossFade]'s 8px rise is the only movement at the swap — the page
/// never jumps. Heights are derived from the real card's paddings, not
/// guessed: keep them in sync when [ThesisCard] changes.
///
/// The shimmer sweep is [CScholarMotion.shimmer] and the sweep is a moving
/// [LinearGradient] (sliding `begin`/`end` alignments, via the same
/// `Shimmer.fromColors` the plain skeletons use) rather than a ShaderMask.
/// The shimmer is a LOOP, so it is gated by [ambientMotionEnabled]: gated off,
/// the blocks render static and no ticker is left behind — and the whole
/// sweep sits inside its own [RepaintBoundary].
class ThesisSkeleton extends StatelessWidget {
  const ThesisSkeleton({super.key, this.bannerHeight = 76});

  /// Banner block height — matches the real card's cover band. Do not shrink
  /// it to fit a tighter list: the silhouette must match the card it replaces
  /// or the swap jumps.
  final double bannerHeight;

  Widget _block(Color color, {double? height, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = _skeletonTones(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(tones.base, height: bannerHeight),
        const SizedBox(height: 12),
        _block(tones.base, height: 14),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.72,
          child: _block(tones.base, height: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _block(tones.base, height: 22, width: 64),
            const SizedBox(width: 8),
            _block(tones.base, height: 22, width: 52),
          ],
        ),
      ],
    );
    if (!ambientMotionEnabled(context)) {
      return DeferredSkeleton(child: column);
    }
    return DeferredSkeleton(
      child: RepaintBoundary(
        child: Shimmer.fromColors(
          baseColor: tones.base,
          highlightColor: tones.highlight,
          period: CScholarMotion.shimmer,
          child: column,
        ),
      ),
    );
  }
}
