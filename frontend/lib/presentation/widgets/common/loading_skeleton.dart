import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

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
