import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';

/// Shared faculty sidebar — same look as the faculty dashboard sidebar.
class FacultySidebar extends ConsumerWidget {
  final String currentPath;
  const FacultySidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: CScholarColors.primaryGreen,
        border: Border(right: BorderSide(color: CScholarColors.borderLight)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'CScholar',
                  style: CScholarTextStyles.poppins(18, FontWeight.w800, Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _item(context, Icons.dashboard_outlined, 'Dashboard', '/faculty/dashboard'),
          _item(context, Icons.article_outlined, 'My Theses', '/faculty/theses'),
          _item(context, Icons.people_outlined, 'My Students', '/faculty/students'),
          _item(context, Icons.analytics_outlined, 'Analytics', '/faculty/analytics'),
          _item(context, Icons.settings_outlined, 'Settings', '/faculty/settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: const Icon(Icons.logout, size: 20, color: Color(0xFFA7F3D0)),
              title: Text(
                'Log Out',
                style: CScholarTextStyles.inter(13, FontWeight.w500, const Color(0xFFA7F3D0)),
              ),
              dense: true,
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _initials(user?.username),
                    style: CScholarTextStyles.inter(11, FontWeight.w700, Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user?.username ?? '',
                    style: CScholarTextStyles.inter(12, FontWeight.w500, Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String route) {
    final isActive = currentPath == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, size: 20, color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7)),
        title: Text(
          label,
          style: CScholarTextStyles.inter(
            13,
            isActive ? FontWeight.w600 : FontWeight.w500,
            isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
        selected: isActive,
        selectedTileColor: Colors.white.withValues(alpha: 0.15),
        dense: true,
        onTap: () => context.go(route),
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
