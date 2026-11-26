import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/csu_mark.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Prototype header (`cscholar-mobile-ui/src/App.tsx:364-422`, styled
/// `index.css:361-389`): brand mark with the wordmark beside it, theme toggle
/// + avatar actions on the right. Depth screens swap the brand for a back
/// action and put the page title in the wordmark's slot.
class MobileStudentHeader extends ConsumerWidget {
  final bool isDepth;
  final String depthTitle;

  /// Where the depth back action lands when the detail route was opened with
  /// `go` (nothing to pop). Null falls back to the student dashboard.
  final String? backRoute;

  const MobileStudentHeader({
    super.key,
    this.isDepth = false,
    this.depthTitle = 'Thesis details',
    this.backRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The PAINTED mode comes from the scope, not the provider: the provider
    // flips on tap, the colours flip at the midpoint of the root transition.
    // The glyph uses the provider so the button answers the tap immediately.
    final t = CScholarMobileTheme.of(context);
    final isDark = ref.watch(mobileThemeModeProvider);
    final user = ref.watch(currentUserProvider);
    final bg = t.paper.withValues(alpha: 0.88);

    String initials = 'AS';
    final name = (user?.username ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        initials = parts.first
            .substring(0, parts.first.length >= 2 ? 2 : 1)
            .toUpperCase();
      } else {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      }
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.fromLTRB(21, 24, 21, 9),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: t.ink.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          if (isDepth)
            _RoundButton(
              theme: t,
              icon: Icons.arrow_back,
              semanticLabel: 'Go back',
              onTap: (_) {
                // Prototype detail back returns to the hub it came from.
                // Detail routes are opened with `go`, so the stack is often
                // empty; fall back to the focused list route instead of
                // asserting in GoRouter.pop.
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(backRoute ?? '/student/dashboard');
                }
              },
            )
          else
            // The one brand mark: same identity block as the web shells.
            const CSUMark(size: 30),
          const SizedBox(width: 10),
          // The wordmark reads as a lockup with the mark ("[icon] CScholar"),
          // not as a centered page title: it sits directly beside the icon and
          // only the right-hand actions stay pinned to the edge. Depth screens
          // follow the same rule with the back action in the icon's slot.
          Expanded(
            child: Text(
              isDepth ? depthTitle : 'CScholar',
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.manrope(
                14,
                FontWeight.w700,
                t.ink,
                letterSpacing: -0.14,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundButton(
                theme: t,
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                iconColor: isDark
                    ? CScholarColors.primaryGreenHover
                    : CScholarColors.primaryGreen,
                semanticLabel: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                // Report the switch's OWN centre so the iris wipe opens from
                // the icon, exactly like the desktop and auth switches. Calling
                // the notifier directly left the origin null, so the reveal
                // started at the viewport corner instead.
                onTap: (buttonContext) {
                  final scope = CScholarPaletteScope.maybeOf(buttonContext);
                  final toggle = scope?.onToggle;
                  if (toggle != null) {
                    toggle(_centreOf(buttonContext));
                  } else {
                    // No app shell above (design lab, tests): stay inert-but-
                    // correct instead of crashing.
                    ref.read(mobileThemeModeProvider.notifier).toggle();
                  }
                },
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Open your profile',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go('/profile'),
                    child: SizedBox(
                      width: CScholarTapTarget.minimum,
                      height: CScholarTapTarget.minimum,
                      child: Center(
                        child: Container(
                          // tile-exempt: header avatar.
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: t.mint,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: t.dmSans(10, FontWeight.w800, t.green),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final CScholarMobileTheme theme;
  final IconData icon;
  final String semanticLabel;

  /// Receives this button's own [BuildContext] so a caller can locate the
  /// button on screen (the theme switch reports its centre as the iris
  /// origin). Most callers ignore it.
  final void Function(BuildContext buttonContext) onTap;

  /// Glyph colour. Defaults to the shell's green; the theme switch passes the
  /// same web token pair (primaryGreen / primaryGreenHover) so phone and
  /// desktop never show a different switch.
  final Color? iconColor;

  const _RoundButton({
    required this.theme,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          selectionHaptic();
          onTap(context);
        },
        child: SizedBox(
          width: CScholarTapTarget.minimum,
          height: CScholarTapTarget.minimum,
          child: Center(
            child: Container(
              // tile-exempt: round chrome button.
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                // Same chrome recipe as the web ThemeModeButton: clay,
                // hairline, one soft shadow. The near-white fill was the
                // phone drifting from the shared topbar.
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
              child: Icon(icon, size: 17, color: iconColor ?? theme.green),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centre of the widget owning [context] on screen — the point the iris wipe
/// opens from. Mirrors the auth shell's helper so the phone and desktop
/// switches report the same thing.
Offset _centreOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  return Offset.zero;
}
