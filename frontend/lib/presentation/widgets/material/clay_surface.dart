import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/inset_shadow.dart';

/// Clay panel — the standard content surface (cards, sections, tiles).
///
/// Three cues make clay read as a physical object rather than a flat card:
///   1. a same-hue gradient (light top-left -> base) = the "inflate"
///   2. a tinted drop shadow + white top-left highlight = raised, not dropped
///   3. an inset bottom shadow = the dome
///
/// When high contrast is on (or [CScholarMaterial.glassEnabled] is off) it
/// degrades to a solid surface with a strong rim — no shadows, no gradient.
class ClaySurface extends StatelessWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.radius = CScholarRadius.xl,
    this.padding = const EdgeInsets.all(20),
    this.depth = 1,
    this.inset = true,
    this.color = CScholarMaterial.clay,
    this.showRim = true,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final bool inset;
  final Color color;
  final bool showRim;

  /// Rare override for the drop shadow. Null uses the clay pair for [depth].
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    final borderRadius = BorderRadius.circular(radius);

    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: flat
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CScholarMaterial.clayHigh, color],
              ),
        color: flat ? color : null,
        border: showRim
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

    if (flat || !inset) return body;
    return InsetShadow(
      borderRadius: borderRadius,
      shadows: CScholarMaterial.clayInset(),
      child: body,
    );
  }
}
