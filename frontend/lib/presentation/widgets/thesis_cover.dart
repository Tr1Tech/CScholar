import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Deterministic generative cover art per thesis (v2 design).
/// No image assets, no backend: the thesis id picks a dark gradient +
/// icon, so every study has a stable, recognizable cover.
class ThesisCover extends StatelessWidget {
  final int seed;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  const ThesisCover({
    super.key,
    required this.seed,
    this.width = 92,
    this.height = 112,
    this.borderRadius = 12,
    this.iconSize = 44,
  });

  static const _gradients = CScholarColors.coverGradients;

  static const _icons = [
    Icons.article_outlined,
    Icons.science_outlined,
    Icons.computer_outlined,
    Icons.psychology_outlined,
    Icons.engineering_outlined,
    Icons.analytics_outlined,
    Icons.school_outlined,
    Icons.lightbulb_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[seed % _gradients.length];
    final icon = _icons[(seed ~/ _gradients.length) % _icons.length];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -14,
            child: Icon(icon,
                size: iconSize + 28,
                color: Colors.white.withValues(alpha: 0.16)),
          ),
          Center(
            child: Icon(icon,
                size: iconSize, color: Colors.white.withValues(alpha: 0.9)),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: CScholarMaterial.goldTop,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
