import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentPath;
  const AdminSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: CScholarColors.adminSidebar,
        border: Border(
          right: BorderSide(color: Color(0xFF003800), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Admin Brand Header
          Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x33000000), width: 1),
              ),
            ),
            child: const CScholarLogo(
              iconSize: 36,
              isDark: true,
              subtitle: 'CEIT REPOSITORY',
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
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  label: 'Repository',
                  path: '/repository',
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
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  label: 'Analytics',
                  path: '/admin/programs',
                ),
                _navItem(
                  context,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  path: '/admin/settings',
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0x33FFFFFF), height: 16),
                _navItem(
                  context,
                  icon: Icons.arrow_back_outlined,
                  selectedIcon: Icons.arrow_back,
                  label: 'Back to Student View',
                  path: '/student/dashboard',
                  isBackToApp: true,
                ),
              ],
            ),
          ),

          // Bottom Sidebar Footer with Logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x33000000), width: 1),
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
                hoverColor: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 20,
                        color: Color(0xFFA7F3D0),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Log Out',
                        style: CScholarTextStyles.inter(
                          13,
                          FontWeight.w500,
                          const Color(0xFFA7F3D0),
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
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String path,
    bool isBackToApp = false,
  }) {
    final isSelected = currentPath == path;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(CScholarRadius.md),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected
                      ? CScholarColors.gold
                      : isBackToApp
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFD1FAE5),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: CScholarTextStyles.inter(
                    13,
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                    isSelected
                        ? Colors.white
                        : isBackToApp
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
