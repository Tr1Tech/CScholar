import 'package:flutter/material.dart';

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

  static const _gradients = [
    [Color(0xFF04331A), Color(0xFF0B6B3A)],
    [Color(0xFF0B1E3A), Color(0xFF1D4ED8)],
    [Color(0xFF1E1B4B), Color(0xFF6D28D9)],
    [Color(0xFF042F2E), Color(0xFF0D9488)],
    [Color(0xFF3B0764), Color(0xFFA21CAF)],
    [Color(0xFF451A03), Color(0xFFC2410C)],
    [Color(0xFF111827), Color(0xFF374151)],
    [Color(0xFF064E3B), Color(0xFFCA8A04)],
  ];

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
                color: Color(0xFFF9DC07),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
