import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/clay_nav_list.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentPath;
  const AdminSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
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

              // Bottom Sidebar Footer with Logout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CScholarMaterial.rim, width: 1),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(CScholarRadius.md),
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                    hoverColor: CScholarColors.primaryGreenVeryLight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 20,
                            color: CScholarColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Log Out',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CScholarTextStyles.inter(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sidebar routes, in order. The pill needs a row NUMBER, so the active row
  /// is derived from [currentPath] here rather than per item; a route matching
  /// none (the thesis editor under `/admin/thesis/...`) yields -1 and the pill
  /// fades out instead of highlighting the wrong row.
  static const List<
      ({String label, IconData icon, IconData selectedIcon, String path})>
      _routes = [
    (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: '/admin/dashboard',
    ),
    (
      label: 'Theses / Capstone',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
      path: '/admin/thesis/management',
    ),
    (
      label: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      path: '/admin/users',
    ),
    (
      label: 'Programs',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      path: '/admin/programs',
    ),
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      path: '/admin/settings',
    ),
  ];

  Widget _nav(BuildContext context) {
    return ClayNavList(
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
    );
  }
}
