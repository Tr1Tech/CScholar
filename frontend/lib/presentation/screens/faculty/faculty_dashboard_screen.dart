import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';

class FacultyDashboardScreen extends ConsumerWidget {
  const FacultyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(facultyStatsProvider);
    final recentActivity = ref.watch(facultyActivityProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            const FacultySidebar(currentPath: '/faculty/dashboard'),
          Expanded(
            child: Column(
              children: [
                FacultyTopbar(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PageHeader(
                              title: 'Faculty Dashboard',
                              subtitle: 'Track your advisees, research activity, and student progress.',
                              action: FilledButton.icon(
                                onPressed: () => context.go('/faculty/thesis/new'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: CScholarColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                ),
                                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                label: Text('New Thesis', style: CScholarTextStyles.inter(13, FontWeight.w600, Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // KPI Cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final count = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 520 ? 2 : 1);
                                return GridView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  // Fixed extent, not an aspect ratio — see
                                  // [kpiGridDelegate].
                                  gridDelegate: kpiGridDelegate(context, count),
                                  children: [
                                    KpiCard(
                                      label: 'ADVISEES',
                                      value: '${stats.value?['advisees'] ?? 0}',
                                      trend: '${stats.value?['active_projects'] ?? 0} active projects',
                                      icon: Icons.people_outline,
                                      iconBg: const Color(0xFFDCFCE7),
                                      iconColor: CScholarColors.primaryGreen,
                                    ),
                                    KpiCard(
                                      label: 'MY THESES',
                                      value: '${stats.value?['theses'] ?? 0}',
                                      trend: '${stats.value?['published'] ?? 0} published',
                                      icon: Icons.article_outlined,
                                      iconBg: const Color(0xFFFEF3C7),
                                      iconColor: CScholarColors.warningFg,
                                    ),
                                    KpiCard(
                                      label: 'PROGRAMS',
                                      value: '${stats.value?['programs'] ?? 0}',
                                      trend: '${stats.value?['programs'] ?? 0} CEIT programs',
                                      icon: Icons.school_outlined,
                                      iconBg: const Color(0xFFFEF9C3),
                                      iconColor: CScholarColors.goldDeep,
                                    ),
                                    KpiCard(
                                      label: 'REVIEWS',
                                      value: '${stats.value?['pending_reviews'] ?? 0}',
                                      trend: '${stats.value?['completed_reviews'] ?? 0} completed',
                                      icon: Icons.rate_review_outlined,
                                      iconBg: const Color(0xFFDBEAFE),
                                      iconColor: CScholarColors.info,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            // Content: Left (Recent Activity) + Right (Advisees)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 860;
                                final leftPanel = _recentActivityPanel(context, recentActivity);
                                final rightPanel = _adviseesPanel(context, ref);
                                if (isWide) {
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

  Widget _recentActivityPanel(BuildContext context, AsyncValue<List<Map<String, dynamic>>> activity) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary)),
              TextButton(
                onPressed: () => context.go('/faculty/theses'),
                child: Text('View All', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
              ),
            ],
          ),
          const Divider(color: CScholarColors.borderLight, height: 20),
          activity.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text('No recent activity', style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted)),
                  ),
                );
              }
              return Column(
                children: items.take(5).map((item) => _activityItem(
                  icon: Icons.article_outlined,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: CScholarColors.primaryGreen,
                  title: item['title'] ?? 'Untitled',
                  subtitle: item['subtitle'] ?? 'No details',
                  time: item['created_at'] ?? '',
                )).toList(),
              );
            },
            loading: () => const SkeletonList(count: 4, cardHeight: 56),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Could not load activity: $err',
                    style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adviseesPanel(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(facultyStatsProvider);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Advisees', style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary)),
          const Divider(color: CScholarColors.borderLight, height: 20),
          stats.when(
            data: (s) {
              final count = (s['advisees'] as num?)?.toInt() ?? 0;
              if (count == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '$count advisee${count == 1 ? '' : 's'} linked to your account',
                    style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            loading: () => const ClayLoader(height: 8),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Could not load advisees: $err',
                  style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go('/faculty/students'),
              child: Text('View All Advisees', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClayIconTile(
            icon: icon,
            size: 34,
            gel: false,
            background: iconBg,
            tint: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: CScholarTextStyles.inter(11.5, FontWeight.w400, CScholarColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: CScholarTextStyles.inter(11, FontWeight.w400, CScholarColors.textHint)),
        ],
      ),
    );
  }
}
