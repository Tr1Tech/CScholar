import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';

/// V2 light student shell (new design): airy wash background, light
/// sidebar card with green-pill active item, pill search topbar.
/// Same public API as before so callers don't change.
class StudentLayout extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const StudentLayout({
    super.key,
    required this.child,
    required this.currentIndex,
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
      backgroundColor: CScholarColors.shellWash,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _sidebar(context, ref, user),
          ),
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
                children: [
                  _navItem(
                    context,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    path: '/student/dashboard',
                    index: 0,
                  ),
                  _navItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book,
                    label: 'Research',
                    path: '/repository',
                    index: 1,
                  ),
                  _navItem(
                    context,
                    icon: Icons.bookmark_outline,
                    selectedIcon: Icons.bookmark,
                    label: 'Saved',
                    path: '/saved',
                    index: 2,
                  ),
                  _navItem(
                    context,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    path: '/profile',
                    index: 3,
                  ),
                ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.logout,
                          size: 20, color: CScholarColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Log out',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.inter(13, FontWeight.w500,
                                CScholarColors.textSecondary)),
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
      child: AnimatedContainer(
        duration: CScholarDurations.fast,
        curve: CScholarCurves.standard,
        decoration: BoxDecoration(
          color: isSelected
              ? CScholarColors.navActiveBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? CScholarShadows.primaryGlow : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.inter(
                      13,
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                      isSelected
                          ? Colors.white
                          : CScholarColors.textSecondary,
                    ),
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
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref, User? user) {
    return Scaffold(
      backgroundColor: CScholarColors.shellWash,
      appBar: AppBar(
        backgroundColor: CScholarMaterial.clay,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 64,
        title: const CScholarLogo(iconSize: 28, subtitle: 'CEIT REPOSITORY'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: GelAvatar(name: user?.username ?? '', size: 34),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: CScholarMaterial.clay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // 4 tabs (0-3); desktop and mobile indices match.
        selectedIndex: currentIndex.clamp(0, 3),
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
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
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
