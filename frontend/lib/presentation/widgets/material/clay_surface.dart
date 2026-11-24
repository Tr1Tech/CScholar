import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Soft surface — the standard content surface (cards, sections, tiles).
///
/// Soft UI v4: a near-white slab on the paper canvas, seated by a hairline and
/// a two-layer diffuse green-tinted shadow. There is no gradient and no inset
/// shadow — the flat fill is the surface.
///
/// When high contrast is on it degrades to a solid fill + a strong rim — no
/// shadows. That is the one place a drawn boundary is the point.
class ClaySurface extends StatelessWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.radius = CScholarRadius.softCard,
    this.padding = const EdgeInsets.all(22),
    this.depth = 1,
    this.color,
    this.showRim = false,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;

  /// Fill override. Null resolves the live surface token at paint time, so a
  /// default card follows the light/dark mode instead of freezing one mode.
  final Color? color;
  final bool showRim;

  /// Rare override for the drop shadow. Null uses the card shadow for [depth].
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color ?? CScholarMaterial.clay,
        border: Border.all(
          color: flat ? CScholarMaterial.rimStrong : CScholarMaterial.rim,
        ),
        boxShadow: flat
            ? null
            : (shadows ?? CScholarMaterial.cardShadow(depth: depth)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
