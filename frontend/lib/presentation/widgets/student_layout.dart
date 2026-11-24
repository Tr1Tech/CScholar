import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/clay_nav_list.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';

/// V2 light student shell (new design): airy wash background, light
/// sidebar card with green-pill active item, pill search topbar.
/// Same public API as before so callers don't change.
class StudentLayout extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  /// Whether the shell's avatar is a hero SOURCE for [userAvatarHeroTag].
  ///
  /// The profile route passes `false`: its card renders the matching target,
  /// and two heroes sharing a tag inside one subtree is an assertion — there,
  /// the shell's pill and the route body are the same subtree.
  final bool heroAvatar;

  /// Depth screens (thesis detail, future sub-flows) hide the mobile bottom
  /// nav and show a back action + focused title — prototype `isDepth`.
  /// No effect on the desktop shell.
  final bool isDepth;
  final String depthTitle;

  /// List route the depth back action returns to when there is no page to pop.
  final String? depthBackRoute;

  const StudentLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.heroAvatar = true,
    this.isDepth = false,
    this.depthTitle = 'Thesis details',
    this.depthBackRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;
    if (MobileStudentScaffold.useMobileShell(
      context,
      widthOverride: size.width,
    )) {
      return MobileStudentScaffold(
        currentIndex: currentIndex,
        isDepth: isDepth,
        depthTitle: depthTitle,
        depthBackRoute: depthBackRoute,
        child: child,
      );
    }
    return Scaffold(
      backgroundColor: CScholarColors.shellWash,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _sidebar(context, ref, user),
          ),
          Expanded(
            // Wrapped like the shared shell, so the topbar seats once content
            // scrolls past the ScrollVeil's trigger.
            child: ScrollVeil(
              child: Column(
                children: [
                  _topBar(context, ref, user),
                  Expanded(child: child),
                ],
              ),
              builder: (context, pane, seated) => pane,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar(BuildContext context, WidgetRef ref, User? user) {
    return SizedBox(
      width: 248,
      child: ClaySurface(
        radius: CScholarRadius.xxl,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Logo
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 6),
              child: CScholarLogo(
                iconSize: 34,
                subtitle: 'Search • Discover • Build',
              ),
            ),
            const SizedBox(height: 12),
            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [_nav(context)],
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 20,
                        color: CScholarColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log out',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CScholarTextStyles.body(
                            13,
                            FontWeight.w500,
                            CScholarColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sidebar destinations, in the same order as [currentIndex] (and as the
  /// mobile [NavigationBar] below). The active row is a NUMBER, not a bool, so
  /// the gel pill can slide to it.
  static const List<
    ({String label, IconData icon, IconData selectedIcon, String path})
  >
  _routes = [
    (
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: '/student/dashboard',
    ),
    (
      label: 'Research',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      path: '/repository',
    ),
    (
      label: 'Saved',
      icon: Icons.bookmark_outline,
      selectedIcon: Icons.bookmark,
      path: '/saved',
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: '/profile',
    ),
  ];

  Widget _nav(BuildContext context) {
    return ClayNavList(
      rail: 'student',
      selectedIndex: currentIndex,
      links: [
        for (final route in _routes)
          ClayNavLink(
            label: route.label,
            icon: route.icon,
            selectedIcon: route.selectedIcon,
            onTap: () => context.go(route.path),
          ),
      ],
    );
  }

  Widget _topBar(BuildContext context, WidgetRef ref, User? user) {
    return Topbar(
      // Shares the raised clay pill / gel avatar with the admin and faculty
      // bars so every role's identity reads the same. Still taps through to the
      // profile, as the old bespoke chip did.
      trailing: InkWell(
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        onTap: () => context.go('/profile'),
        child: TopbarUserPill(
          name: user?.username,
          role: _roleLabel(user?.role),
          // A hero flight is motion: under reduced motion the pill stays a
          // plain avatar (the profile card's target then simply appears).
          heroAvatar: heroAvatar && motionEnabled(context),
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'faculty':
        return 'Faculty';
      default:
        return 'Student';
    }
  }
}
