import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Prototype header (`cscholar-mobile-ui/src/App.tsx:364-422`, styled
/// `index.css:361-389`): mini-brand C, centered workspace title, theme
/// toggle + avatar actions. Depth screens swap the brand for a back action.
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
    final isDark = ref.watch(mobileThemeModeProvider);
    final t = CScholarMobileTheme(isDark: isDark);
    final user = ref.watch(currentUserProvider);
    final bg = t.paper.withValues(alpha: 0.88);

    String initials = 'AS';
    final name = (user?.username ?? '').trim();
    if (name.isNotEmpty) {
      final parts =
          name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length == 1) {
        initials = parts.first.substring(
            0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
      } else {
        initials =
            (parts[0][0] + parts[1][0]).toUpperCase();
      }
    }

    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(21, 24, 21, 9),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: t.ink.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isDepth)
            _RoundButton(
              theme: t,
              icon: Icons.arrow_back,
              semanticLabel: 'Go back',
              onTap: () {
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
            // tile-exempt: mini brand mark, not an icon tile.
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: CScholarMobileColors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E174F3D),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'C',
                style: CScholarMobileTextStyles.manrope(
                    15, FontWeight.w800, Colors.white),
              ),
            ),
          Expanded(
            child: Text(
              isDepth ? depthTitle : 'CScholar',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.manrope(
                  14, FontWeight.w700, t.ink,
                  letterSpacing: -0.14),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundButton(
                theme: t,
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                semanticLabel: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onTap: () =>
                    ref.read(mobileThemeModeProvider.notifier).toggle(),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  // tile-exempt: header avatar.
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: t.coralSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: t.dmSans(
                        10,
                        FontWeight.w800,
                        t.green),
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
  final VoidCallback onTap;

  const _RoundButton({
    required this.theme,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          selectionHaptic();
          onTap();
        },
        child: Container(
          // tile-exempt: round chrome button.
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1423372C),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 17,
            color: theme.green,
          ),
        ),
      ),
    );
  }
}
