import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Wraps a subtree so that every [GlassPanel] inside it shares ONE blur pass.
///
/// Put this around any screen that shows more than one glass layer (topbar +
/// rail + hero search). Flutter's engine then filters the backdrop once
/// instead of once per panel.
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BackdropGroup(child: child);
}

/// Dialog shell — dialogs are floating chrome, so per the fusion law they are
/// glass: one shared recipe (fill, rim, blur, kill switch, high-contrast
/// fallback) instead of thirteen hand-styled AlertDialogs.
///
/// Same slots as [AlertDialog] (title / content / actions), so migrating a
/// site is mechanical: move the three slots across untouched. Content keeps
/// its own width (the SizedBox the AlertDialog had); the shell only sizes to
/// it. Actions lay out end-aligned like AlertDialog's button row.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    this.title,
    required this.content,
    this.actions = const [],
  });

  final Widget? title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: GlassPanel(
        radius: CScholarRadius.xl,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              title!,
              const SizedBox(height: 12),
            ],
            content,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Glass panel — chrome and overlays only (topbar, nav rail, sticky search,
/// dialogs, sheets). Never inside a scrolling list item: blur cost scales
/// with the number of blurred layers.
///
/// Dialogs use the shared [GlassDialog] shell above rather than calling this
/// directly, so every dialog gets the same surface, padding and action row.
///
/// Text safety: glass that carries text must sit on the >= .55 white fill
/// ([glassChrome]). Below that, treat the glass as decoration only.
///
/// Degrades automatically to a solid clay surface with a strong rim when:
///   * `MediaQuery.highContrastOf(context)` is true, or
///   * [CScholarMaterial.glassEnabled] is false (low-power mode).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = CScholarRadius.xl,
    this.fill = CScholarMaterial.glassChrome,
    this.blur = CScholarMaterial.blurChrome,
    this.padding = const EdgeInsets.all(16),
    this.lifted = true,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final Color fill;
  final double blur;
  final EdgeInsetsGeometry padding;
  final bool lifted;

  /// Overrides the default lifted shadow. Pass `const []` for a flush panel, or
  /// a bespoke list when the glass sits on a dark hero: there the sage-tinted
  /// default reads as soot, so the hero casts its own deep-green shadow.
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final flat = !CScholarMaterial.glassEnabled || MediaQuery.highContrastOf(context);
    final borderRadius = BorderRadius.circular(radius);

    if (flat) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: CScholarMaterial.clay,
          borderRadius: borderRadius,
          border: Border.all(color: CScholarMaterial.rimStrong),
        ),
        child: Padding(padding: padding, child: child),
      );
    }

    // The rim is painted OUTSIDE the clip, otherwise ClipRRect halves it.
    final inner = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter.grouped(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, borderRadius: borderRadius),
          child: Stack(
            children: [
              // specular sheen: white from the top, fading out
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [CScholarMaterial.glassSpecular, Colors.transparent],
                        stops: [0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    final sheathed = BackdropGroup.of(context) == null
        // Standalone panel: establish its own group so `.grouped` always has
        // an ancestor to bind to.
        ? BackdropGroup(child: inner)
        : inner;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: CScholarMaterial.glassRim),
          boxShadow: shadows ??
              (lifted
                  ? [
                      // Tinted, never black: glass still floats on the sage
                      // canvas, and a black-alpha shadow there reads as dirt
                      // rather than depth. Same law as clayDrop.
                      BoxShadow(
                        color: CScholarMaterial.shadowDark.withValues(alpha: 0.42),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                        spreadRadius: -10,
                      ),
                    ]
                  : null),
        ),
        child: sheathed,
      ),
    );
  }
}
