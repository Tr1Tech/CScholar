// Reusable admin sidebar for desktop admin screens — Stitch design v2

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentPath;
  const AdminSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CScholarColors.adminSidebar, CScholarColors.sidebarDeep],
        ),
      ),
      child: Column(
        children: [
          // Header — brand logo
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CScholarColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.school, color: CScholarColors.gold, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'CScholar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Navigation items — deep green sidebar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CScholarColors.sidebarDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(4),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    icon: Icons.list_alt_outlined,
                    selectedIcon: Icons.list_alt,
                    label: 'Thesis Management',
                    path: '/admin/thesis/management',
                  ),
                  _navItem(
                    context,
                    icon: Icons.add_box_outlined,
                    selectedIcon: Icons.add_box,
                    label: 'Add Thesis',
                    path: '/admin/thesis/new',
                  ),
                  _navItem(
                    context,
                    icon: Icons.category_outlined,
                    selectedIcon: Icons.category,
                    label: 'Programs & Categories',
                    path: '/admin/programs',
                  ),
                  _navItem(
                    context,
                    icon: Icons.people_outline,
                    selectedIcon: Icons.people,
                    label: 'User Management',
                    path: '/admin/users',
                  ),
                  _navItem(
                    context,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'System Settings',
                    path: '/admin/settings',
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white70, height: 1),
                  const SizedBox(height: 8),
                  _navItem(
                    context,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Back to App',
                    path: '/student/dashboard',
                    isBackToApp: true,
                  ),
                ],
              ),
            ),
          ),
          // Sign Out button — gold accent
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/');
                },
                style: TextButton.styleFrom(
                  foregroundColor: CScholarColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout, size: 18, color: CScholarColors.gold),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CScholarColors.gold),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected
            ? CScholarColors.sidebarActive
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isBackToApp
                      ? CScholarColors.gold
                      : (isSelected ? CScholarColors.gold : Colors.white70),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isBackToApp
                        ? CScholarColors.gold
                        : (isSelected ? CScholarColors.gold : Colors.white70),
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
