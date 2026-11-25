import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// The one light/dark switch — top-right of every shell, on web and mobile.
///
/// It reads the PAINTED mode ([CScholarPalette.of]) and calls the scope's
/// toggle — reporting the icon's own centre, which is where the iris wipe
/// opens from. It needs no provider scope of its own: the chrome renders in any
/// host (tests, the design lab, a sheet) and simply stays inert when no app
/// shell is above it.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, this.size = 38, this.tooltip});

  /// Diameter of the round chrome button. The mobile header draws its own
  /// 34px version, so this defaults to the desktop's larger hit target.
  final double size;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scope = CScholarPaletteScope.maybeOf(context);
    final isDark = CScholarPalette.of(context).isDark;
    final flat = MediaQuery.highContrastOf(context);
    final label = isDark ? 'Switch to light mode' : 'Switch to dark mode';
    return Semantics(
      button: true,
      toggled: isDark,
      label: label,
      child: Tooltip(
        message: tooltip ?? label,
        child: _HoverPop(
          onTap: () {
            selectionHaptic();
            scope?.onToggle?.call(_iconCentre(context));
          },
          child: SizedBox(
            // 44px hit area; the visible circle keeps its design size.
            width: size < CScholarTapTarget.minimum
                ? CScholarTapTarget.minimum
                : size,
            height: size < CScholarTapTarget.minimum
                ? CScholarTapTarget.minimum
                : size,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: CScholarMaterial.clay,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: flat
                        ? CScholarMaterial.rimStrong
                        : CScholarMaterial.rim,
                    width: flat ? 1.5 : 1,
                  ),
                  boxShadow: flat
                      ? null
                      : CScholarMaterial.softShadow(depth: 0.5),
                ),
                alignment: Alignment.center,
                child: AnimatedSwap(
                  style: SwapStyle.pop,
                  // The swap is keyed on the mode so the glyph POPS in rather
                  // than hard-cutting — the only motion the button itself
                  // needs, because the screen behind it is doing the dramatic
                  // part.
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey<bool>(isDark),
                    size: size * 0.47,
                    color: isDark
                        ? CScholarColors.primaryGreenHover
                        : CScholarColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pointer feedback for the round chrome buttons: a 1.04 hover scale and a
/// 0.94 press sink. Transform only, inert on touch/reduced motion.
class _HoverPop extends StatefulWidget {
  const _HoverPop({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_HoverPop> createState() => _HoverPopState();
}

class _HoverPopState extends State<_HoverPop> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final animate = motionEnabled(context);
    final scale = !animate ? 1.0 : (_down ? 0.94 : (_hover ? 1.04 : 1.0));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: animate ? CScholarDurations.fast : Duration.zero,
          curve: CScholarCurves.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Centre of the button on screen — the point the iris wipe opens from.
Offset _iconCentre(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  return Offset.zero;
}

/// The auth screens (login / register) own the whole viewport, so the switch
/// floats in the top-right corner instead of riding a topbar.
class ThemeModeCorner extends StatelessWidget {
  const ThemeModeCorner({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Align(
          alignment: Alignment.topRight,
          child: const ThemeModeButton(size: 42),
        ),
      ),
    );
  }
}
