// Profile screen — student/faculty own profile

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final savedCount = ref.watch(savedThesisIdsProvider).length;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/student/dashboard'),
        ),
        title: const Text('Profile', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: CScholarColors.error),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          children: [
            // Avatar + name card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CScholarColors.dividerLight),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: CScholarColors.primaryGreen,
                    child: Text(
                      (user?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? 'Student',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CScholarColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreenVeryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (user?.role ?? 'student').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: CScholarColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _statCard(Icons.bookmark, '$savedCount', 'Saved Studies', CScholarColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(Icons.history, '—', 'Views', CScholarColors.info),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Menu items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CScholarColors.dividerLight),
              ),
              child: Column(
                children: [
                  _menuItem(Icons.person_outline, 'Edit Profile', () {}),
                  const Divider(height: 1),
                  _menuItem(Icons.notifications_outlined, 'Notifications', () {}),
                  const Divider(height: 1),
                  _menuItem(Icons.security_outlined, 'Privacy & Security', () {}),
                  const Divider(height: 1),
                  _menuItem(Icons.help_outline, 'Help & Support', () {}),
                  const Divider(height: 1),
                  _menuItem(Icons.info_outline, 'About CScholar', () {}),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: CScholarColors.error,
                  side: const BorderSide(color: CScholarColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
            const SizedBox(height: 24),

            // Version info
            const Text(
              'CScholar v0.1.0 · CEIT Thesis Repository',
              style: TextStyle(fontSize: 12, color: CScholarColors.textHint),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        backgroundColor: Colors.white,
        indicatorColor: CScholarColors.primaryGreenVeryLight,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/student/dashboard');
          if (i == 1) context.go('/repository');
          if (i == 2) context.go('/saved');
          if (i == 3) {}
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: CScholarColors.primaryGreen), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search, color: CScholarColors.primaryGreen), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark, color: CScholarColors.primaryGreen), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: CScholarColors.primaryGreen), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: CScholarColors.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: CScholarColors.textHint),
      onTap: onTap,
    );
  }
}
