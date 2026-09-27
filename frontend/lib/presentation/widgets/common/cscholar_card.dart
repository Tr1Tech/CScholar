import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/hover_lift.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';

/// The single content card — every panel, section and table wrapper.
///
/// Delegates to [ClaySurface] (material system v3), so the tinted shadow pair,
/// the inflate gradient, the inner bottom shadow and the automatic high-contrast
/// fallback all come from one place. Screens must never hand-roll card
/// decoration; that is what produced three different card looks before.
class CScholarCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<BoxShadow>? shadows;

  /// Adds the web/desktop hover lift (design plan, item 8). Opt in only for
  /// cards the user can click — a lift is a promise of interactivity. It is a
  /// transform plus a shadow, so it never moves layout, and it is inert under
  /// reduced motion and on touch.
  final bool lift;

  const CScholarCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = CScholarRadius.xl,
    this.shadows,
    this.lift = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = ClaySurface(
      radius: borderRadius,
      padding: padding,
      shadows: shadows,
      child: child,
    );
    return lift ? HoverLift(radius: borderRadius, child: surface) : surface;
  }
}
