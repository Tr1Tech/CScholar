import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// Shared desktop/mobile shell for all roles (design plan, item 4).
///
/// Desktop: fixed sidebar + optional topbar + centered max-width content.
/// Mobile: app bar (optional back) + content + optional bottom nav.
/// The shell owns structure only — screens own scrolling and padding inside
/// [child], except the standard desktop content padding.
class CScholarShell extends StatelessWidget {
  final Widget sidebar;
  final Widget child;
  final Widget? topbar;
  final String mobileTitle;
  final String? backRoute;
  final Widget? bottomNav;
  final double desktopBreakpoint;
  final double maxWidth;
  final EdgeInsetsGeometry desktopPadding;

  const CScholarShell({
    super.key,
    required this.sidebar,
    required this.child,
    this.topbar,
    this.mobileTitle = '',
    this.backRoute,
    this.bottomNav,
    this.desktopBreakpoint = 920,
    this.maxWidth = 1200,
    this.desktopPadding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > desktopBreakpoint;

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: CScholarColors.backgroundSoft,
        appBar: AppBar(
          // Clay, not white: the bar sits on the sage canvas and must share its
          // hue family (see material_tokens). No elevation and no bottom
          // hairline — the tonal fill and the canvas step are the boundary.
          backgroundColor: CScholarMaterial.clay,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: backRoute == null
              ? null
              : NeumorphIconButton(
                  icon: Icons.arrow_back,
                  size: 40,
                  tooltip: 'Back',
                  onPressed: () => context.go(backRoute!),
                ),
          title: Text(
            mobileTitle,
            style: const TextStyle(
                color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Every shelled page opens the same way: one fade + rise.
        body: EntranceReveal(child: child),
        bottomNavigationBar: bottomNav,
      );
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundSoft,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebar,
          Expanded(
            child: Column(
              children: [
                topbar ?? const SizedBox.shrink(),
                Expanded(
                  child: Padding(
                    padding: desktopPadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: EntranceReveal(child: child),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
