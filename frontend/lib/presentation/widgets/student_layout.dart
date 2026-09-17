import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';

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
    final isWide = size.width > 840;

    if (!isWide) {
      return _mobileLayout(context, ref, user);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          _sidebar(context, ref, user),
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
      width: 256,
      decoration: const BoxDecoration(
        color: CScholarColors.sidebarDeep,
        border: Border(
          right: BorderSide(color: Color(0xFF074823), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Branding Header
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
              subtitle: 'CEIT THESIS REPOSITORY',
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
                  path: '/student/dashboard',
                  index: 0,
                ),
                _navItem(
                  context,
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  label: 'Repository',
                  path: '/repository',
                  index: 1,
                ),
                _navItem(
                  context,
                  icon: Icons.bookmark_outline,
                  selectedIcon: Icons.bookmark,
                  label: 'Saved Studies',
                  path: '/saved',
                  index: 2,
                ),
                _navItem(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  label: 'Recommendations',
                  path: '/repository',
                  index: 3,
                ),
                _navItem(
                  context,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  path: '/profile',
                  index: 4,
                ),
              ],
            ),
          ),

          // Sidebar Footer / Logout
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
                hoverColor: CScholarColors.sidebarHover,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 20,
                        color: Color(0xFF86EFAC),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Log out',
                        style: CScholarTextStyles.inter(
                          13,
                          FontWeight.w500,
                          const Color(0xFFBBF7D0),
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
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? CScholarColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(CScholarRadius.md),
          hoverColor: CScholarColors.sidebarHover,
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected ? CScholarColors.gold : const Color(0xFFD1FAE5),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: CScholarTextStyles.inter(
                    13,
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                    isSelected ? Colors.white : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, WidgetRef ref, User? user) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: CScholarColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Global Search Field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: (_) => onSearchSubmit?.call(),
                style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textPrimary),
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search thesis, capstone, topic, author, keyword...',
                  hintStyle: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textHint),
                  prefixIcon: const Icon(Icons.search, size: 20, color: CScholarColors.textHint),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CScholarRadius.lg),
                    borderSide: const BorderSide(color: CScholarColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CScholarRadius.lg),
                    borderSide: const BorderSide(color: CScholarColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CScholarRadius.lg),
                    borderSide: const BorderSide(color: CScholarColors.primaryGreen, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Notifications & Profile
          Row(
            children: [
              // Notification Bell
              IconButton(
                tooltip: 'Notifications',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 22, color: CScholarColors.textSecondary),
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: CScholarColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {},
              ),

              const SizedBox(width: 12),

              // User Profile Pill
              InkWell(
                borderRadius: BorderRadius.circular(CScholarRadius.full),
                onTap: () => context.go('/profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(CScholarRadius.full),
                    border: Border.all(color: CScholarColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFF047857),
                        child: Text(
                          _initials(user?.username ?? 'Juan Dela Cruz'),
                          style: CScholarTextStyles.poppins(
                            12,
                            FontWeight.w700,
                            CScholarColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.username ?? 'Juan Dela Cruz',
                            style: CScholarTextStyles.inter(
                              13,
                              FontWeight.w600,
                              CScholarColors.textPrimary,
                            ),
                          ),
                          Text(
                            user?.role == 'admin' ? 'Administrator' : 'Student',
                            style: CScholarTextStyles.inter(
                              11,
                              FontWeight.w500,
                              CScholarColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, size: 18, color: CScholarColors.textHint),
                    ],
                  ),
                ),
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
        title: const CScholarLogo(iconSize: 28, subtitle: 'CEIT REPOSITORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: CScholarColors.textSecondary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF047857),
                child: Text(
                  _initials(user?.username ?? 'Juan Dela Cruz'),
                  style: CScholarTextStyles.poppins(11, FontWeight.bold, CScholarColors.gold),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: CScholarColors.borderLight),
        ),
      ),
      drawer: Drawer(
        backgroundColor: CScholarColors.sidebarDeep,
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: CScholarLogo(iconSize: 36, isDark: true),
              ),
              const Divider(color: Color(0x33000000)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _navItem(context, icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard', path: '/student/dashboard', index: 0),
                    _navItem(context, icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Repository', path: '/repository', index: 1),
                    _navItem(context, icon: Icons.bookmark_outline, selectedIcon: Icons.bookmark, label: 'Saved Studies', path: '/saved', index: 2),
                    _navItem(context, icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'Recommendations', path: '/repository', index: 3),
                    _navItem(context, icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', path: '/profile', index: 4),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF86EFAC)),
                title: Text('Log out', style: CScholarTextStyles.inter(14, FontWeight.w500, const Color(0xFFBBF7D0))),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, 4),
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/student/dashboard');
              break;
            case 1:
              context.go('/repository');
              break;
            case 2:
              context.go('/saved');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Repository'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
