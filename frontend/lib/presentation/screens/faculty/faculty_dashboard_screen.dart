import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
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
      backgroundColor: CScholarMaterial.canvas,
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            const FacultySidebar(currentPath: '/faculty/dashboard'),
          Expanded(
            // Wrapped like the shared shell, so the topbar seats once content
            // scrolls past the ScrollVeil's trigger.
            child: ScrollVeil(
              child: Column(
                children: [
                  FacultyTopbar(user: user),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          // Header, metrics, then the explicitly scheduled panels
                          // below: one Column, same order as before.
                          child: Column(
                            children: [
                              StaggerColumn(
                            pitch: MotionPitch.page,
                            children: [
                              PageHeader(
                                title: 'Faculty Dashboard',
                                subtitle: 'Track your advisees, research activity, and student progress.',
                                action: NeumorphButton(
                                  onPressed: () => context.go('/faculty/thesis/new'),
                                  icon: Icons.add,
                                  label: 'New Thesis',
                                ),
                              ),
                              const SizedBox(height: 24),
                              // KPI Cards
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final count = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 520 ? 2 : 1);
                                  final cards = [
                                    (
                                      label: 'ADVISEES',
                                      value: '${stats.value?['advisees'] ?? 0}',
                                      trend: '${stats.value?['active_projects'] ?? 0} active projects',
                                      icon: Icons.people_outline,
                                      iconBg: CScholarColors.thesisChipBg,
                                      iconColor: CScholarColors.primaryGreen,
                                    ),
                                    (
                                      label: 'MY THESES',
                                      value: '${stats.value?['theses'] ?? 0}',
                                      trend: '${stats.value?['published'] ?? 0} published',
                                      icon: Icons.article_outlined,
                                      iconBg: CScholarColors.capstoneChipBg,
                                      iconColor: CScholarColors.warningFg,
                                    ),
                                    (
                                      label: 'PROGRAMS',
                                      value: '${stats.value?['programs'] ?? 0}',
                                      trend: '${stats.value?['programs'] ?? 0} CEIT programs',
                                      icon: Icons.school_outlined,
                                      iconBg: CScholarColors.goldLight,
                                      iconColor: CScholarColors.goldDeep,
                                    ),
                                    (
                                      label: 'REVIEWS',
                                      value: '${stats.value?['pending_reviews'] ?? 0}',
                                      trend: '${stats.value?['completed_reviews'] ?? 0} completed',
                                      icon: Icons.rate_review_outlined,
                                      iconBg: CScholarColors.infoLight,
                                      iconColor: CScholarColors.info,
                                    ),
                                  ];
                                  return GridView(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    // Fixed extent, not an aspect ratio — see
                                    // [kpiGridDelegate].
                                    gridDelegate: kpiGridDelegate(context, count),
                                    children: [
                                      for (var i = 0; i < cards.length; i++)
                                        // Diagonal cascade on the feature rhythm
                                        // (see the admin dashboard): each cell
                                        // carries its finished delay against
                                        // the laid-out column count.
                                        Stagger(
                                          index: i,
                                          step: MotionPitch.feature.step,
                                          max: MotionPitch.feature.max,
                                          rise: MotionPitch.feature.rise,
                                          delay: StaggerColumn.diagonalDelay(
                                            index: i,
                                            columns: count,
                                            pitch: MotionPitch.feature,
                                          ),
                                          child: KpiCard(
                                            label: cards[i].label,
                                            value: cards[i].value,
                                            trend: cards[i].trend,
                                            icon: cards[i].icon,
                                            iconBg: cards[i].iconBg,
                                            iconColor: cards[i].iconColor,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          // The content row leaves the shared column so its
                          // panels land on their explicit PART 7 beats (+120 /
                          // +180) instead of stacking on the column's index.
                          const SizedBox(height: 28),
                          // Content: Left (Recent Activity) + Right (Advisees).
                          // The panels keep their responsive Row/Column split;
                          // each carries its own beat. The wrappers sit INSIDE
                          // the flex (never between a Flex and its Expanded),
                          // so the layout is untouched.
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 860;
                              final leftPanel = EntranceReveal(
                                delay: const Duration(milliseconds: 120),
                                rise: 0,
                                child: _recentActivityPanel(context, recentActivity),
                              );
                              final rightPanel = EntranceReveal(
                                delay: const Duration(milliseconds: 180),
                                rise: 0,
                                child: _adviseesPanel(context, ref),
                              );
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
              builder: (context, pane, seated) => pane,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityPanel(BuildContext context, AsyncValue<List<Map<String, dynamic>>> activity) {
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Recent Activity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.poppins(
                        16, FontWeight.w700, CScholarColors.textPrimary)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: NeumorphButton(
                  onPressed: () => context.go('/faculty/theses'),
                  label: 'View All',
                  gel: false,
                  icon: Icons.arrow_forward,
                ),
              ),
            ],
          ),
          const Divider(color: CScholarMaterial.rim, height: 20),
          asyncSlot<List<Map<String, dynamic>>>(
            activity,
            skeleton: const SkeletonList(count: 4, cardHeight: 56),
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
                // Dense feed rows step on the tight rhythm (see the admin
                // dashboard): one gesture, not a cascade competing with the
                // page.
                children: items.take(5).toList().asMap().entries.map((entry) {
                  final item = entry.value;
                  return Stagger(
                    index: entry.key,
                    step: MotionPitch.tight.step,
                    max: MotionPitch.tight.max,
                    rise: MotionPitch.tight.rise,
                    child: _activityItem(
                      icon: Icons.article_outlined,
                      iconBg: CScholarColors.thesisChipBg,
                      iconColor: CScholarColors.primaryGreen,
                      title: item['title'] ?? 'Untitled',
                      subtitle: item['subtitle'] ?? 'No details',
                      time: item['created_at'] ?? '',
                    ),
                  );
                }).toList(),
              );
            },
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
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Advisees', style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary)),
          const Divider(color: CScholarMaterial.rim, height: 20),
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
            child: NeumorphButton(
              onPressed: () => context.go('/faculty/students'),
              label: 'View All Advisees',
              gel: false,
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
