import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(currentPath: '/admin/dashboard'),
          Expanded(
            child: Column(
              children: [
                _topBar(context, ref, user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Title & Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin Dashboard',
                                      style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage repository entries, user submissions, and access activity.',
                                      style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () => context.go('/admin/thesis/new'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: CScholarColors.primaryGreen,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                      ),
                                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                      label: Text('Add New Thesis', style: CScholarTextStyles.inter(13, FontWeight.w600, Colors.white)),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Generating CEIT repository audit export...')),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: CScholarColors.textPrimary,
                                        side: const BorderSide(color: CScholarColors.borderLight),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                      ),
                                      icon: const Icon(Icons.download_outlined, size: 18),
                                      label: Text('Export Report', style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.textPrimary)),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 4 KPI Summary Cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final count = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 520 ? 2 : 1);
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: count,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: constraints.maxWidth > 900 ? 2.0 : 2.4,
                                  children: [
                                    _kpiCard(
                                      label: 'STUDIES',
                                      value: '${stats.value?['studies'] ?? 0}',
                                      trend: '+${stats.value?['studies_this_week'] ?? 0} this week',
                                      icon: Icons.article_outlined,
                                      iconBg: const Color(0xFFDCFCE7),
                                      iconColor: CScholarColors.primaryGreen,
                                    ),
                                    _kpiCard(
                                      label: 'PROGRAMS',
                                      value: '${stats.value?['programs'] ?? 0}',
                                      trend: '${stats.value?['active_programs'] ?? 0} active',
                                      icon: Icons.school_outlined,
                                      iconBg: const Color(0xFFFEF9C3),
                                      iconColor: const Color(0xFFCA8A04),
                                    ),
                                    _kpiCard(
                                      label: 'USERS',
                                      value: '${stats.value?['users'] ?? 0}',
                                      trend: '${stats.value?['active_users'] ?? 0} active',
                                      icon: Icons.people_outline,
                                      iconBg: const Color(0xFFFEF3C7),
                                      iconColor: CScholarColors.orange,
                                    ),
                                    _kpiCard(
                                      label: 'SEARCHES',
                                      value: '${stats.value?['searches'] ?? '0'}',
                                      trend: '+${stats.value?['search_growth'] ?? 0}%',
                                      icon: Icons.search,
                                      iconBg: const Color(0xFFDBEAFE),
                                      iconColor: const Color(0xFF2563EB),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 28),

                            // Content Layout: Left Recent Activity (2/3) & Right Quick Management (1/3)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWideContent = constraints.maxWidth > 860;

                                final leftPanel = _recentActivityFeed();
                                final rightPanel = _quickManagementPanel(context);

                                if (isWideContent) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 7, child: leftPanel),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 4, child: rightPanel),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      leftPanel,
                                      const SizedBox(height: 24),
                                      rightPanel,
                                    ],
                                  );
                                }
                              },
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
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: CScholarColors.borderLight)),
      ),
      child: Row(
        children: [
          // Universal Search
          Container(
            width: 380,
            constraints: const BoxConstraints(maxWidth: 420),
            child: TextField(
              style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search thesis, authors, or keywords...',
                prefixIcon: const Icon(Icons.search, size: 20, color: CScholarColors.textHint),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CScholarRadius.full), borderSide: const BorderSide(color: CScholarColors.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CScholarRadius.full), borderSide: const BorderSide(color: CScholarColors.borderLight)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const Spacer(),
          // Notification Bell
          IconButton(
            tooltip: 'Live activity notifications',
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, size: 22, color: CScholarColors.textSecondary),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: CScholarColors.orange, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 14),
          // Admin Profile Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CScholarRadius.full),
              border: Border.all(color: CScholarColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFDCFCE7),
                  child: Text(
                    'AU',
                    style: CScholarTextStyles.inter(11.5, FontWeight.w700, CScholarColors.primaryGreen),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user?.username ?? 'Admin', style: CScholarTextStyles.inter(12.5, FontWeight.w700, CScholarColors.textPrimary)),
                    Text('Administrator', style: CScholarTextStyles.inter(10.5, FontWeight.w500, CScholarColors.textMuted)),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: CScholarColors.textHint),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String trend,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textMuted, letterSpacing: 0.5),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(CScholarRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: CScholarTextStyles.poppins(26, FontWeight.w800, CScholarColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                trend,
                style: CScholarTextStyles.inter(11.5, FontWeight.w600, CScholarColors.primaryGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentActivityFeed() {
    return Consumer(
      builder: (context, ref, _) {
        final activityAsync = ref.watch(recentActivityProvider);
        return activityAsync.when(
          loading: () => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CScholarRadius.xxl),
              border: Border.all(color: CScholarColors.borderLight),
              boxShadow: CScholarShadows.card,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Recent Activity',
                          style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: CScholarColors.primaryGreenVeryLight,
                            borderRadius: BorderRadius.circular(CScholarRadius.full),
                          ),
                          child: Text('Live audit', style: CScholarTextStyles.inter(10.5, FontWeight.w700, CScholarColors.primaryGreen)),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('View full logs →', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
                    ),
                  ],
                ),
                const Divider(color: CScholarColors.borderLight, height: 20),
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              ],
            ),
          ),
          error: (_, _) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CScholarRadius.xxl),
              border: Border.all(color: CScholarColors.borderLight),
              boxShadow: CScholarShadows.card,
            ),
            padding: const EdgeInsets.all(24),
            child: _activityList([]),
          ),
          data: (items) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CScholarRadius.xxl),
              border: Border.all(color: CScholarColors.borderLight),
              boxShadow: CScholarShadows.card,
            ),
            padding: const EdgeInsets.all(24),
            child: _activityList(items),
          ),
        );
      },
    );
  }

  Widget _activityList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Recent Activity',
                    style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreenVeryLight,
                      borderRadius: BorderRadius.circular(CScholarRadius.full),
                    ),
                    child: Text('Live audit', style: CScholarTextStyles.inter(10.5, FontWeight.w700, CScholarColors.primaryGreen)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text('View full logs →', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
              ),
            ],
          ),
          const Divider(color: CScholarColors.borderLight, height: 20),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No recent activity', style: TextStyle(color: CScholarColors.textSecondary))),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CScholarColors.primaryGreenVeryLight,
                    borderRadius: BorderRadius.circular(CScholarRadius.full),
                  ),
                  child: Text('Live audit', style: CScholarTextStyles.inter(10.5, FontWeight.w700, CScholarColors.primaryGreen)),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text('View full logs →', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
            ),
          ],
        ),
        const Divider(color: CScholarColors.borderLight, height: 20),
        ...items.asMap().entries.expand((entry) {
          final idx = entry.key;
          final item = entry.value;
          final widgets = <Widget>[];
          if (idx > 0) {
            widgets.add(const Divider(color: Color(0xFFF1F5F9), height: 16));
          }
          widgets.add(_activityItem(
            icon: _iconFor(item['icon'] as String? ?? 'info'),
            iconBg: _colorFor(item['icon_bg'] as String? ?? '#F3F4F6'),
            iconColor: _colorFor(item['icon_color'] as String? ?? '#6B7280'),
            title: item['title'] as String? ?? '',
            subtitle: item['subtitle'] as String? ?? '',
            time: item['time'] as String? ?? '',
          ));
          return widgets;
        }),
      ],
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'add':
        return Icons.add_circle_outline;
      case 'person_add':
        return Icons.person_add_outlined;
      case 'edit':
        return Icons.edit_note_outlined;
      case 'search':
        return Icons.search;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorFor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return CScholarColors.textSecondary;
    }
  }

  Widget _activityItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: CScholarTextStyles.inter(11.5, FontWeight.w400, CScholarColors.textMuted)),
              ],
            ),
          ),
          Text(time, style: CScholarTextStyles.inter(11, FontWeight.w400, CScholarColors.textHint)),
        ],
      ),
    );
  }

  Widget _quickManagementPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xxl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Management',
            style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _managementTile(
            context,
            icon: Icons.add_circle_outline,
            iconColor: CScholarColors.primaryGreen,
            iconBg: const Color(0xFFDCFCE7),
            title: 'Add New Thesis',
            subtitle: 'Upload PDF & register metadata',
            onTap: () => context.go('/admin/thesis/new'),
          ),
          const SizedBox(height: 10),
          _managementTile(
            context,
            icon: Icons.people_alt_outlined,
            iconColor: CScholarColors.orange,
            iconBg: const Color(0xFFFEF3C7),
            title: 'Manage Users',
            subtitle: 'Review student approvals & roles',
            onTap: () => context.go('/admin/users'),
          ),
          const SizedBox(height: 10),
          _managementTile(
            context,
            icon: Icons.category_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            title: 'Programs & Tags',
            subtitle: 'Organize college departments',
            onTap: () => context.go('/admin/programs'),
          ),
        ],
      ),
    );
  }

  Widget _managementTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CScholarRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CScholarRadius.lg),
          border: Border.all(color: CScholarColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(CScholarRadius.md)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CScholarTextStyles.inter(13, FontWeight.w700, CScholarColors.textPrimary)),
                  Text(subtitle, style: CScholarTextStyles.inter(11, FontWeight.w400, CScholarColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: CScholarColors.textHint),
          ],
        ),
      ),
    );
  }
}
