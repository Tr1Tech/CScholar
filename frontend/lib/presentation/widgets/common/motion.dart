import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// Motion helpers (design plan, item 8).
///
/// - One transition everywhere: fade + 12px rise, 250ms, easeOut.
/// - Non-essential motion is skipped when the OS requests reduced motion.

/// True unless the OS asked for reduced motion.
bool motionEnabled(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// Shared route transition for GoRouter pages.
Widget cscholarTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (!motionEnabled(context)) return child;
  final curved = CurvedAnimation(parent: animation, curve: CScholarCurves.entrance);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
      child: child,
    ),
  );
}

/// Theme-wide page transition: every route fades + rises slightly.
/// Applied once in MaterialApp theme — no per-route code needed.
class CScholarTransitionBuilder extends PageTransitionsBuilder {
  const CScholarTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return cscholarTransition(context, animation, secondaryAnimation, child);
  }
}
