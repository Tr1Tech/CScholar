import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/presentation/widgets/common/analytics_charts.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';

/// Faculty: status / program / year breakdown of advised theses.
class FacultyAnalyticsScreen extends ConsumerWidget {
  const FacultyAnalyticsScreen({super.key});

  static const _statusOrder = ['published', 'approved', 'draft', 'archived'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final analyticsAsync = ref.watch(facultyAnalyticsProvider);

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/analytics'),
      topbar: FacultyTopbar(user: user),
      mobileTitle: 'Analytics',
      backRoute: '/faculty/dashboard',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(facultyAnalyticsProvider.future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: StaggerColumn(
            pitch: MotionPitch.page,
            children: [
              const PageHeader(
                title: 'Analytics',
                subtitle: 'Breakdown of your supervised studies.',
              ),
              const SizedBox(height: 20),
              asyncSlot<Map<String, dynamic>>(
                analyticsAsync,
                skeleton: const SkeletonList(count: 3, cardHeight: 220),
                data: (a) => _content(context, a),
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load analytics',
                  message: userFacingError(
                    err,
                    fallback: 'Your analytics could not be loaded. Try again.',
                  ),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(facultyAnalyticsProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Map<String, dynamic> a) {
    final total = (a['total'] as num?)?.toInt() ?? 0;
    final byStatus = Map<String, dynamic>.from(a['by_status'] as Map? ?? {});
    final byProgram = List<dynamic>.from(a['by_program'] as List? ?? []);
    final byYear = List<dynamic>.from(a['by_year'] as List? ?? []);
    final byType = List<dynamic>.from(a['by_type'] as List? ?? []);

    final statusSlices = [
      for (final status in _statusOrder)
        if ((byStatus[status] as num?)?.toInt() != null &&
            (byStatus[status] as num).toInt() > 0)
          ChartSlice(
            label: _title(status),
            value: (byStatus[status] as num).toInt(),
            color:
                CScholarColors.statusFill[status] ??
                CScholarColors.textSecondary,
          ),
    ];
    final typeSlices = [
      for (final raw in byType)
        if (((raw as Map)['count'] as num?) != null)
          ChartSlice(
            label: ((raw)['type'] ?? 'Unclassified').toString(),
            value: (raw['count'] as num).toInt(),
            color: ((raw['type'] ?? '').toString() == 'Capstone')
                ? CScholarColors.violetInk
                : CScholarColors.primaryGreen,
          ),
    ];
    final programSlices = [
      for (final raw in byProgram)
        if (((raw as Map)['count'] as num?) != null)
          ChartSlice(
            label: ((raw)['program'] ?? '—').toString(),
            value: (raw['count'] as num).toInt(),
            color: CScholarColors.primaryGreen,
          ),
    ];
    final yearSlices = [
      for (final raw in byYear)
        if (((raw as Map)['count'] as num?) != null)
          ChartSlice(
            label: ((raw)['year'] ?? '—').toString(),
            value: (raw['count'] as num).toInt(),
            color: CScholarColors.info,
          ),
    ]..sort((a, b) => a.label.compareTo(b.label));

    final cards = [
      _card(
        title: 'By Status',
        subtitle: '$total supervised ${total == 1 ? 'study' : 'studies'}',
        child: DonutChart(slices: statusSlices, centerLabel: 'studies'),
      ),
      _card(
        title: 'By Research Type',
        subtitle: 'Thesis vs Capstone',
        child: DonutChart(slices: typeSlices, centerLabel: 'studies'),
      ),
      _card(
        title: 'By Program',
        subtitle: 'Your studies per CEIT program',
        child: AnalyticsBars(
          slices: programSlices,
          emptyMessage: 'No program data yet',
        ),
      ),
      _card(
        title: 'By Academic Year',
        subtitle: 'Your studies per academic year',
        child: ColumnChart(slices: yearSlices),
      ),
    ];

    if (total == 0) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'No supervised studies yet',
        message: 'Studies linked to your adviser account will appear here.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 860;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 20),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 20),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 20),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CScholarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: CScholarTextStyles.heading(
                16,
                FontWeight.w700,
                CScholarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: CScholarTextStyles.body(
                12,
                FontWeight.w400,
                CScholarColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  String _title(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
