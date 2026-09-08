// Shared student layout — Stitch design v2
// Left sidebar + top navbar + scrollable content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';

class StudentLayout extends ConsumerWidget {
  final Widget child;
  final int currentIndex;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmit;

  const StudentLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    if (!isWide) {
      return _mobileLayout(context, ref, user);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          // Left sidebar
          _sidebar(context, ref, user),
          // Main content area
          Expanded(
            child: Column(
              children: [
                _topBar(context, ref, user),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar(BuildContext context, WidgetRef ref, User? user) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CScholarColors.sidebarDeep, CScholarColors.adminSidebar],
        ),
      ),
      child: Column(
        children: [
          // Brand header
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: CScholarColors.primaryGreen, size: 20),
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
                      'CEIT THESIS REPOSITORY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Navigation
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CScholarColors.sidebarDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _navItem(context, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', '/student/dashboard', 0),
                  _navItem(context, Icons.search_outlined, Icons.search, 'Repository', '/repository', 1),
                  _navItem(context, Icons.bookmark_outline, Icons.bookmark, 'Saved Studies', '/saved', 2),
                  _navItem(context, Icons.lightbulb_outline, Icons.lightbulb, 'Recommendations', '/recommendations', 3),
                  _navItem(context, Icons.person_outline, Icons.person, 'Profile', '/profile', 4),
                ],
              ),
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/');
              },
              style: TextButton.styleFrom(foregroundColor: CScholarColors.gold),
              icon: const Icon(Icons.logout, size: 18, color: CScholarColors.gold),
              label: const Text('Log out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, IconData selectedIcon, String label, String path, int index) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? CScholarColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(isSelected ? selectedIcon : icon, size: 20, color: isSelected ? CScholarColors.gold : Colors.white70),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? CScholarColors.gold : Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, WidgetRef ref, User? user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: (_) => onSearchSubmit?.call(),
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search thesis, capstone, topic, author, keyword...',
                  hintStyle: const TextStyle(color: CScholarColors.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20, color: CScholarColors.textHint),
                  filled: true,
                  fillColor: CScholarColors.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: CScholarColors.dividerLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: CScholarColors.dividerLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CScholarColors.primaryGreen)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Notification bell
          IconButton(
            icon: Stack(
              children: const [
                Icon(Icons.notifications_outlined, size: 22, color: CScholarColors.textSecondary),
                Positioned(top: 2, right: 2, child: CircleAvatar(radius: 4, backgroundColor: CScholarColors.orange)),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          // User profile pill
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: CScholarColors.primaryGreen,
                child: Text(
                  (user?.username ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: CScholarColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(user?.username ?? 'User', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
                  Text('Student', style: const TextStyle(fontSize: 11, color: CScholarColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref, User? user) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('CScholar', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: const [
                Icon(Icons.notifications_outlined, size: 20, color: CScholarColors.textSecondary),
                Positioned(top: 2, right: 2, child: CircleAvatar(radius: 3, backgroundColor: CScholarColors.orange)),
              ],
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: _sidebar(context, ref, user),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: CScholarColors.primaryGreenVeryLight,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/student/dashboard');
          if (i == 1) context.go('/repository');
          if (i == 2) context.go('/saved');
          if (i == 3) context.go('/profile');
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
}
