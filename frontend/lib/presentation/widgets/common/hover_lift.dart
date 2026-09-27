import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Desktop/web hover lift for cards (design plan, item 8).
/// Transform + shadow only — never layout — so it holds frame rate.
/// Inert on touch devices and under reduced motion.
class HoverLift extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double lift;

  /// Corner radius of the lifting shadow. It must match the child's own radius
  /// or the hover shadow will not hug the surface's corners.
  final double radius;

  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.lift = -3,
    this.radius = CScholarRadius.xl,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final animate = motionEnabled(context);
    final radius = BorderRadius.circular(widget.radius);
    final content = AnimatedContainer(
      duration: animate ? CScholarDurations.fast : Duration.zero,
      curve: CScholarCurves.standard,
      transform: Matrix4.translationValues(0, _hovering && animate ? widget.lift : 0, 0),
      decoration: BoxDecoration(
        boxShadow: _hovering && animate ? CScholarShadows.elevated : null,
        borderRadius: radius,
      ),
      child: widget.child,
    );
    final tappable = widget.onTap == null
        ? content
        : InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: content,
          );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: RepaintBoundary(child: tappable),
    );
  }
}
