import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Formerly a blur group. Soft UI v4 retires glass, so this is a pass-through
/// kept so callers compile.
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Dialog shell — dialogs are floating chrome, so they get the shared solid
/// surface + overlay shadow recipe. Same slots as [AlertDialog] (title /
/// content / actions), so migrating a site stays mechanical.
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      // A Dialog gives its child the whole window; a text field's intrinsic
      // width then stretches every form dialog edge to edge. Cap the surface
      // at a comfortable reading width (AlertDialog's own 560 is close).
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassPanel(
          radius: CScholarRadius.softSheet,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Stretch every slot to the panel's full inner width. Call sites
            // that still wrap their form in a fixed-width SizedBox are clamped
            // by the tight cross-axis constraint, so no dialog can keep a dead
            // column of space on the right while the title hugs the left.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[title!, const SizedBox(height: 12)],
              content,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Centre the action group, so the buttons sit on the panel's
                // axis instead of hugging one edge under full-width content.
                // Wrap (not Row) keeps two wide buttons from overflowing on a
                // narrow phone or at 200% text — they stack, still centred.
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < actions.length; i++)
                      // The action row staggers by 30ms (a quarter of the micro
                      // budget, derived from the token) so the buttons land after
                      // the panel does: the dialog opens as one motion.
                      EntranceReveal(
                        delay: CScholarMotion.micro ~/ 4,
                        rise: 6,
                        child: actions[i],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating panel — chrome and overlays only (dialogs, sheets, sticky bars).
///
/// Soft UI v4: a solid near-white surface, a hairline and a deep diffuse
/// shadow. No backdrop blur. High contrast swaps in the strong rim and drops
/// the shadow.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = CScholarRadius.softCard,
    this.fill = CScholarMaterial.glassChrome,
    this.blur = CScholarMaterial.blurChrome,
    this.padding = const EdgeInsets.all(16),
    this.lifted = true,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final Color fill;

  /// Retained for API compatibility; unused.
  final double blur;
  final EdgeInsetsGeometry padding;
  final bool lifted;

  /// Overrides the default lifted shadow. Pass `const []` for a flush panel.
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: flat ? CScholarMaterial.clay : fill,
        borderRadius: borderRadius,
        border: Border.all(
          color: flat ? CScholarMaterial.rimStrong : CScholarMaterial.rim,
        ),
        boxShadow: flat || !lifted
            ? null
            : (shadows ?? CScholarMaterial.overlay),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
