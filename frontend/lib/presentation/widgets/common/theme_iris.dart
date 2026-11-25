import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The iris wipe: the OLD theme, frozen the instant the switch was tapped and
/// painted over the live app everywhere the circle has not reached yet.
///
/// A palette is global, so old and new cannot be on screen at once. The
/// transition therefore captures one frame before the flip
/// ([RenderRepaintBoundary.toImage]) and keeps it on top; the live app — already
/// repainted in the destination palette — shows through an expanding circular
/// hole centred on the switch. That hole IS the wipe.
///
/// The image is never resampled per frame: the clip is the only thing that
/// changes, so the app below is not re-rasterized by the animation.
class ThemeIris extends StatelessWidget {
  const ThemeIris({
    super.key,
    required this.image,
    required this.center,
    required this.progress,
  });

  /// The captured frame, in logical pixels of the viewport.
  final ui.Image image;

  /// Circle centre, in the viewport's own coordinates (the toggle's icon).
  final Offset center;

  /// 0 = the old frame covers everything, 1 = the circle has passed every
  /// corner and the old frame is gone.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CScholarIrisClipper(center: center, progress: progress),
      child: RawImage(
        image: image,
        fit: BoxFit.fill,
        // The capture is taken at device resolution; medium keeps the upscale
        // smooth without paying for a mipmapped sampler on every frame.
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Clips a full-screen layer to everything OUTSIDE the iris circle, so the
/// frozen frame stays visible until the circle sweeps past it.
///
/// The radius is derived from the size, not passed in: it has to end exactly
/// when the farthest corner is covered, and only the clipper knows the viewport.
@visibleForTesting
class CScholarIrisClipper extends CustomClipper<Path> {
  const CScholarIrisClipper({required this.center, required this.progress});

  /// Circle centre, in the layer's own coordinates.
  final Offset center;

  /// 0 → the old frame is untouched; 1 → nothing of it is left on screen.
  final double progress;

  /// Distance from [center] to the farthest corner at this [size].
  static double reachFor(Size size, Offset center) {
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((corner) => (corner - center).distance).reduce(math.max);
  }

  @override
  Path getClip(Size size) {
    final rect = Path()..addRect(Offset.zero & size);
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) return Path(); // nothing left to cover
    if (t <= 0) return rect; // nothing revealed yet
    final circle = Path()
      ..addOval(
        Rect.fromCircle(center: center, radius: reachFor(size, center) * t),
      );
    return Path.combine(PathOperation.difference, rect, circle);
  }

  @override
  bool shouldReclip(CScholarIrisClipper old) =>
      old.center != center || old.progress != progress;
}
