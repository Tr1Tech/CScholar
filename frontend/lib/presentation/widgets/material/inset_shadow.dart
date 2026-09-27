import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// True inset shadows — Flutter's [BoxShadow] has no `inset` property.
///
/// Paints the same algorithm Blink/Chromium uses for inner box shadows:
/// draw a rounded rect hollowed out by a smaller rounded rect, then blur it.
/// Everything is clipped to the shape so the blur never bleeds outside.
///
/// This is the piece that makes clay surfaces look inflated and neumorphic
/// controls look pressed. ~40 lines, no dependency (the `flutter_inset_box_shadow`
/// package gives you `inset: true` but requires hiding `BoxDecoration` and
/// `BoxShadow` in every file that imports it).
///
/// Add [shadows] whose offsets point INTO the shape (e.g. `Offset(0, 6)`,
/// `Offset(0, 3)`) — that is what an inset shadow looks like.
class InsetShadow extends StatelessWidget {
  const InsetShadow({
    super.key,
    required this.child,
    required this.borderRadius,
    this.shadows = const [],
  });

  final Widget child;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    if (shadows.isEmpty) return child;
    return Stack(
      // A Stack defaults to AlignmentDirectional.topStart, which would pin any
      // child smaller than the box (a glyph, a badge) to the top-left corner.
      // Centre by default so InsetShadow is purely an overlay.
      alignment: Alignment.center,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _InsetShadowPainter(
                borderRadius: borderRadius,
                shadows: shadows,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsetShadowPainter extends CustomPainter {
  const _InsetShadowPainter({
    required this.borderRadius,
    required this.shadows,
    required this.textDirection,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(borderRadius.toRRect(rect));
    for (final shadow in shadows) {
      final sigma = shadow.blurSigma; // dart:ui Shadow.convertRadiusToSigma
      final paint = Paint()..color = shadow.color;
      if (sigma > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
      }
      final outer = Path()..addRRect(borderRadius.toRRect(rect.shift(shadow.offset)));
      final inner = Path()
        ..addRRect(borderRadius.toRRect(rect.deflate(shadow.spreadRadius).shift(shadow.offset)));
      canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter oldDelegate) =>
      oldDelegate.textDirection != textDirection ||
      oldDelegate.borderRadius != borderRadius ||
      !listEquals(oldDelegate.shadows, shadows);
}
