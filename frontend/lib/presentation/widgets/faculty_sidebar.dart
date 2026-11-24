import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/clay_nav_list.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';

/// Shared faculty sidebar — same look as the faculty dashboard sidebar.
class FacultySidebar extends ConsumerWidget {
  final String currentPath;
  const FacultySidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Floating card: the rounding needs breathing room inside parent Rows.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 248,
        child: ClaySurface(
          radius: CScholarRadius.xxl,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 6),
                child: CScholarLogo(
                  iconSize: 34,
                  subtitle: 'Search • Discover • Build',
                ),
              ),
              const SizedBox(height: 12),
              _nav(context),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                // MaterialType.transparency supplies the ink surface the
                // ListTile paints on. The panel around it is a DecoratedBox,
                // which would otherwise swallow both the background and the
                // splashes (and assert in debug).
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      size: 20,
                      color: CScholarColors.textSecondary,
                    ),
                    title: Text(
                      'Log Out',
                      style: CScholarTextStyles.body(
                        13,
                        FontWeight.w500,
                        CScholarColors.textSecondary,
                      ),
                    ),
                    dense: true,
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Sidebar routes, in order. The pill needs a row NUMBER, so the active row
  /// is derived from [currentPath] here rather than per item; a route matching
  /// none yields -1 and the pill fades out (same contract as the admin rail).
  static const List<
    ({String label, IconData icon, IconData selectedIcon, String path})
  >
  _routes = [
    (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: '/faculty/dashboard',
    ),
    (
      label: 'My Theses',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
      path: '/faculty/theses',
    ),
    (
      label: 'My Students',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      path: '/faculty/students',
    ),
    (
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      path: '/faculty/analytics',
    ),
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      path: '/faculty/settings',
    ),
  ];

  Widget _nav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClayNavList(
        rail: 'faculty',
        selectedIndex: _routes.indexWhere((route) => route.path == currentPath),
        links: [
          for (final route in _routes)
            ClayNavLink(
              label: route.label,
              icon: route.icon,
              selectedIcon: route.selectedIcon,
              onTap: () => context.go(route.path),
            ),
        ],
      ),
    );
  }
}
