import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Clay panel — the standard content surface (cards, sections, tiles).
///
/// Clay reads as a physical slab from three things, none of which is an
/// outline or an inner shadow:
///   1. its own fill, lighter than the canvas
///   2. a same-hue gradient (light top-left -> base) = the "inflate" shading
///   3. ONE soft downward shadow that seats it on the canvas
///
/// No border and no inset by default. A drawn rim on every surface is what made
/// the earlier neumorphic pass look boxed-in; the slab IS the boundary now. Pass
/// [showRim] only where a small or low-contrast surface genuinely needs one.
///
/// When high contrast is on it degrades to a solid fill + a strong rim — no
/// shadows, no gradient. That is the one place a drawn boundary is the point.
class ClaySurface extends StatelessWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.radius = CScholarRadius.xl,
    this.padding = const EdgeInsets.all(20),
    this.depth = 1,
    this.color = CScholarMaterial.clay,
    this.showRim = false,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final Color color;
  final bool showRim;

  /// Rare override for the drop shadow. Null uses the clay shadow for [depth].
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: flat
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CScholarMaterial.clayHigh, color],
              ),
        color: flat ? color : null,
        border: flat || showRim
            ? Border.all(
                color: flat ? CScholarMaterial.rimStrong : CScholarMaterial.rim,
              )
            : null,
        boxShadow: flat
            ? null
            : (shadows ?? CScholarMaterial.clayDrop(depth: depth)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
