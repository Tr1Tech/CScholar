import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
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
                  children: [
                    _navItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      label: 'Dashboard',
                      path: '/admin/dashboard',
                    ),
                    _navItem(
                      context,
                      icon: Icons.article_outlined,
                      selectedIcon: Icons.article,
                      label: 'Theses / Capstone',
                      path: '/admin/thesis/management',
                    ),
                    _navItem(
                      context,
                      icon: Icons.people_outline,
                      selectedIcon: Icons.people,
                      label: 'Users',
                      path: '/admin/users',
                    ),
                    _navItem(
                      context,
                      icon: Icons.school_outlined,
                      selectedIcon: Icons.school,
                      label: 'Programs',
                      path: '/admin/programs',
                    ),
                    _navItem(
                      context,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      path: '/admin/settings',
                    ),
                  ],
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
                          Text(
                            'Log Out',
                            style: CScholarTextStyles.inter(
                              13,
                              FontWeight.w500,
                              CScholarColors.textSecondary,
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

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String path,
  }) {
    final isSelected = currentPath == path;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AnimatedContainer(
        duration: CScholarDurations.fast,
        curve: CScholarCurves.standard,
        decoration: BoxDecoration(
          color: isSelected
              ? CScholarColors.navActiveBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CScholarRadius.md),
          boxShadow: isSelected ? CScholarShadows.primaryGlow : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(CScholarRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(CScholarRadius.md),
            onTap: () => context.go(path),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : CScholarColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: CScholarTextStyles.inter(
                      13,
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                      isSelected
                          ? Colors.white
                          : CScholarColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
