import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Shimmer skeletons shown while lists/cards load (design plan, item 8).
/// Same card rhythm as real content so the swap doesn't jump the layout.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: CScholarMaterial.clayDeep,
        highlightColor: CScholarMaterial.clayHigh,
        child: Container(
          decoration: BoxDecoration(
            color: CScholarMaterial.clayDeep,
            borderRadius: BorderRadius.circular(CScholarRadius.xl),
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

  Widget _block({double? height, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(height: bannerHeight),
        const SizedBox(height: 12),
        _block(height: 14),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.72,
          child: _block(height: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _block(height: 22, width: 64),
            const SizedBox(width: 8),
            _block(height: 22, width: 52),
          ],
        ),
      ],
    );
    if (!ambientMotionEnabled(context)) return column;
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: CScholarMaterial.clayDeep,
        highlightColor: CScholarMaterial.clayHigh,
        period: CScholarMotion.shimmer,
        child: column,
      ),
    );
  }
}
