import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/dashboard'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Admin Dashboard',
      child: SingleChildScrollView(
        // PART 7 delay map: header-first on the page rhythm, the KPI strip
        // cascading diagonally on feature, then the analytics card at +120
        // and the content row at +180. The two explicit blocks leave the
        // shared column — nesting them under its index would stack both
        // offsets. Delays schedule paint only; layout lands on frame one.
        child: Column(
          children: [
            StaggerColumn(
              pitch: MotionPitch.page,
              children: [
                // Header Title & Action Buttons
                PageHeader(
                  title: 'Admin Dashboard',
                  subtitle: 'Manage repository entries, user submissions, and access activity.',
                  action: NeumorphButton(
                    onPressed: () => context.go('/admin/thesis/new'),
                    icon: Icons.add,
                    label: 'Add New Thesis',
                  ),
                ),

                const SizedBox(height: 24),

                // 4 KPI Summary Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth > 900
                        ? 4
                        : (constraints.maxWidth > 520 ? 2 : 1);
                    final cards = [
                      (
                        label: 'STUDIES',
                        value: '${stats.value?['studies'] ?? 0}',
                        trend:
                            '+${stats.value?['studies_this_week'] ?? 0} this week',
                        icon: Icons.article_outlined,
                        iconBg: CScholarColors.thesisChipBg,
                        iconColor: CScholarColors.primaryGreen,
                      ),
                      (
                        label: 'PROGRAMS',
                        value: '${stats.value?['programs'] ?? 0}',
                        trend: '${stats.value?['active_programs'] ?? 0} active',
                        icon: Icons.school_outlined,
                        iconBg: CScholarColors.goldLight,
                        iconColor: CScholarColors.goldDeep,
                      ),
                      (
                        label: 'USERS',
                        value: '${stats.value?['users'] ?? 0}',
                        trend: '${stats.value?['active_users'] ?? 0} active',
                        icon: Icons.people_outline,
                        iconBg: CScholarColors.capstoneChipBg,
                        iconColor: CScholarColors.warningFg,
                      ),
                      (
                        label: 'SEARCHES',
                        value: '${stats.value?['searches'] ?? '0'}',
                        trend: '+${stats.value?['search_growth'] ?? 0}%',
                        icon: Icons.search,
                        iconBg: CScholarColors.infoLight,
                        iconColor: CScholarColors.info,
                      ),
                    ];
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Fixed extent, not an aspect ratio: the KPI card's height does
                      // not depend on the cell width (see [kpiGridDelegate]).
                      gridDelegate: kpiGridDelegate(context, count),
                      children: [
                        for (var i = 0; i < cards.length; i++)
                          // Diagonal cascade on the feature rhythm — the strip
                          // walks. StaggerColumn cannot reach GridView children,
                          // so each cell carries its finished delay, computed
                          // against the laid-out column count.
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

            const SizedBox(height: 28),

            // Repository analytics (computed client-side from the admin list)
            EntranceReveal(
              delay: const Duration(milliseconds: 120),
              rise: 0,
              child: _analyticsStrip(ref),
            ),

            const SizedBox(height: 28),

            // Content Layout: Left Recent Activity (2/3) & Right Quick Management (1/3)
            EntranceReveal(
              delay: const Duration(milliseconds: 180),
              rise: 0,
              child: LayoutBuilder(
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
            ),
          ],
        ),
      ),
    );
  }

  /// Studies by status, counted from the admin thesis list (first page).
  /// Client-side on purpose: the admin summary endpoint has no breakdown,
  /// and the list is already fetched for management anyway.
  Widget _analyticsStrip(WidgetRef ref) {
    final list = ref.watch(
      thesisListProvider(const ThesisListParams(showAll: true)),
    );
    return asyncSlot<List<Thesis>?>(
      list,
      skeleton: const SkeletonList(count: 1, cardHeight: 180),
      data: (theses) {
        final items = theses ?? <Thesis>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final counts = <String, int>{};
        for (final t in items) {
          final key = t.status.toLowerCase();
          counts[key] = (counts[key] ?? 0) + 1;
        }
        final total = items.length;
        const order = ['published', 'approved', 'draft', 'archived'];
        // The fills come from CScholarColors.statusFill — measured against the
        // clayDeep track (WCAG 1.4.11), never the local guesses this map held.
        return CScholarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repository Analytics',
                style: CScholarTextStyles.heading(
                  16,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total studies in this view',
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w500,
                  CScholarColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              for (final s in order)
                if ((counts[s] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.toUpperCase(),
                              style: CScholarTextStyles.body(
                                12,
                                FontWeight.w700,
                                CScholarColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${counts[s]}',
                              style: CScholarTextStyles.body(
                                12,
                                FontWeight.w600,
                                CScholarColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClayProgressBar(
                          value: total == 0 ? 0 : counts[s]! / total,
                          height: 8,
                          tint:
                              CScholarColors.statusFill[s] ??
                              CScholarColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _recentActivityFeed() {
    return Consumer(
      builder: (context, ref, _) {
        final activityAsync = ref.watch(recentActivityProvider);
        return asyncSlot<List<Map<String, dynamic>>>(
          activityAsync,
          skeleton: CScholarCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Recent Activity',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CScholarTextStyles.heading(
                                16,
                                FontWeight.w700,
                                CScholarColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CScholarColors.primaryGreenVeryLight,
                              borderRadius: BorderRadius.circular(
                                CScholarRadius.full,
                              ),
                            ),
                            child: Text(
                              'Live audit',
                              style: CScholarTextStyles.body(
                                10.5,
                                FontWeight.w700,
                                CScholarColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: CScholarMaterial.rim, height: 20),
                const SkeletonList(count: 4, cardHeight: 56),
              ],
            ),
          ),
          error: (_, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load activity',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(recentActivityProvider),
          ),
          data: (items) => CScholarCard(
            padding: const EdgeInsets.all(24),
            child: _activityList(items),
          ),
        );
      },
    );
  }

  Widget _activityList(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Recent Activity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.heading(
                  16,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreenVeryLight,
                borderRadius: BorderRadius.circular(CScholarRadius.full),
              ),
              child: Text(
                'Live audit',
                style: CScholarTextStyles.body(
                  10.5,
                  FontWeight.w700,
                  CScholarColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: CScholarMaterial.rim, height: 20),
        if (items.isEmpty)
          const EmptyState(
            compact: true,
            icon: Icons.history,
            title: 'No recent activity',
            message: 'New submissions and updates will appear here.',
          )
        else
          ...items.asMap().entries.expand((entry) {
            final idx = entry.key;
            final item = entry.value;
            final widgets = <Widget>[];
            if (idx > 0) {
              widgets.add(
                const Divider(color: CScholarMaterial.rim, height: 16),
              );
            }
            // Dense feed rows step on the tight rhythm — one gesture, not a
            // second cascade competing with the page.
            widgets.add(
              Stagger(
                index: idx,
                step: MotionPitch.tight.step,
                max: MotionPitch.tight.max,
                rise: MotionPitch.tight.rise,
                child: _activityItem(
                  icon: _iconFor(item['icon'] as String? ?? 'info'),
                  iconBg: _colorFor(item['icon_bg'] as String? ?? '#F3F4F6'),
                  iconColor: _colorFor(
                    item['icon_color'] as String? ?? '#6B7280',
                  ),
                  title: item['title'] as String? ?? '',
                  subtitle: item['subtitle'] as String? ?? '',
                  time: item['time'] as String? ?? '',
                ),
              ),
            );
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
                Text(
                  title,
                  style: CScholarTextStyles.body(
                    13,
                    FontWeight.w600,
                    CScholarColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: CScholarTextStyles.body(
                    11.5,
                    FontWeight.w400,
                    CScholarColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: CScholarTextStyles.body(
              11,
              FontWeight.w400,
              CScholarColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickManagementPanel(BuildContext context) {
    return CScholarCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Management',
            style: CScholarTextStyles.heading(
              16,
              FontWeight.w700,
              CScholarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _managementTile(
            context,
            icon: Icons.add_circle_outline,
            iconColor: CScholarColors.primaryGreen,
            iconBg: CScholarColors.thesisChipBg,
            title: 'Add New Thesis',
            subtitle: 'Upload PDF & register metadata',
            onTap: () => context.go('/admin/thesis/new'),
          ),
          const SizedBox(height: 10),
          _managementTile(
            context,
            icon: Icons.people_alt_outlined,
            iconColor: CScholarColors.warningFg,
            iconBg: CScholarColors.capstoneChipBg,
            title: 'Manage Users',
            subtitle: 'Review student approvals & roles',
            onTap: () => context.go('/admin/users'),
          ),
          const SizedBox(height: 10),
          _managementTile(
            context,
            icon: Icons.category_outlined,
            iconColor: CScholarColors.skyInk,
            iconBg: CScholarColors.skyTint,
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
      borderRadius: BorderRadius.circular(CScholarRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Soft well on the white card: the row's shape comes from its
          // tonal fill, not a drawn outline.
          color: CScholarMaterial.clayDeep,
          borderRadius: BorderRadius.circular(CScholarRadius.xl),
        ),
        child: Row(
          children: [
            ClayIconTile(
              icon: icon,
              size: 36,
              gel: false,
              background: iconBg,
              tint: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CScholarTextStyles.body(
                      13,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: CScholarTextStyles.body(
                      11,
                      FontWeight.w400,
                      CScholarColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: CScholarColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
