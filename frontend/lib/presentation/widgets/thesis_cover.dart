import 'package:flutter/material.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Thesis cover tile (v2 design).
///
/// A thesis is a document, so every cover carries the same mark: the Material
/// `article` glyph — a white page with text lines — on the green gel identity
/// tile, with the rounded-square corners, fill and drop shadow of the
/// dashboard's stat tile. Copy, not variation: at the 52–92px list sizes a
/// seeded glyph rotation read as random clutter.
///
/// [seed] stays in the signature so call sites keep a stable per-thesis handle
/// if the art ever gains variation again, but it deliberately does not change
/// the mark.
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
    this.borderRadius = 16,
    this.iconSize = 40,
  });

  /// The gel fill of [ClayIconTile]. A light tile is the mobile shell's flat
  /// green (its old top-to-bottom gradient ended on the pressed green, which
  /// read a step darker than the app); dark keeps the two-stop gel so the
  /// 52–92px tile still looks moulded on the near-black canvas.
  ///
  /// A GETTER, not a static field: a field would freeze the mode it was first
  /// read in, and every cover would then ignore the switch.
  static Gradient get fill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [CScholarMaterial.actionFill, CScholarMaterial.actionFillRest],
  );

  /// Also the dashboard's metric glyph for published studies.
  static const IconData glyph = Icons.article;

  @override
  Widget build(BuildContext context) {
    // The stat tile drops at 0.7; the list cover matches it at its 92px
    // reference size and scales down for the rail so the 52px tile does not
    // wear a card-sized shadow.
    final depth = (width / 92 * 0.7).clamp(0.3, 0.7).toDouble();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: CScholarMaterial.gelDrop(depth: depth),
      ),
      child: Center(
        child: Icon(glyph, size: iconSize, color: Colors.white),
      ),
    );
  }
}
