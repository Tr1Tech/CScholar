import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
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
              _item(context, Icons.dashboard_outlined, Icons.dashboard,
                  'Dashboard', '/faculty/dashboard'),
              _item(context, Icons.article_outlined, Icons.article,
                  'My Theses', '/faculty/theses'),
              _item(context, Icons.people_outlined, Icons.people,
                  'My Students', '/faculty/students'),
              _item(context, Icons.analytics_outlined, Icons.analytics,
                  'Analytics', '/faculty/analytics'),
              _item(context, Icons.settings_outlined, Icons.settings,
                  'Settings', '/faculty/settings'),
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
                    leading: const Icon(Icons.logout,
                        size: 20, color: CScholarColors.textSecondary),
                    title: Text(
                      'Log Out',
                      style: CScholarTextStyles.inter(
                          13, FontWeight.w500, CScholarColors.textSecondary),
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

  Widget _item(BuildContext context, IconData icon, IconData selectedIcon,
      String label, String route) {
    final isActive = currentPath == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: CScholarDurations.fast,
        curve: CScholarCurves.standard,
        decoration: BoxDecoration(
          color: isActive ? CScholarColors.navActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive ? CScholarShadows.primaryGlow : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: Icon(isActive ? selectedIcon : icon,
                size: 20,
                color:
                    isActive ? Colors.white : CScholarColors.textSecondary),
            title: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.inter(
                13,
                isActive ? FontWeight.w600 : FontWeight.w500,
                isActive ? Colors.white : CScholarColors.textSecondary,
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            dense: true,
            onTap: () => context.go(route),
          ),
        ),
      ),
    );
  }
}
