import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/common/analytics_charts.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';

/// Admin: repository-wide analytics with charts.
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  static const _statusOrder = ['published', 'approved', 'draft', 'archived'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theses = ref.watch(
      thesisListProvider(const ThesisListParams(showAll: true)),
    );
    final programs = ref.watch(programsProvider);
    final years = ref.watch(academicYearsProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/analytics'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Analytics',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            const PageHeader(
              title: 'Analytics',
              subtitle:
                  'Repository health, program distribution, academic years, and search demand.',
            ),
            const SizedBox(height: 20),
            asyncSlot<List<Thesis>?>(
              theses,
              skeleton: const SkeletonList(count: 3, cardHeight: 240),
              data: (list) => _content(
                context,
                ref,
                list ?? const <Thesis>[],
                programs.value ?? const <Program>[],
                years.value ?? const <AcademicYear>[],
                stats.value ?? const <String, dynamic>{},
              ),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: "Couldn't load analytics",
                message: userFacingError(
                  err,
                  fallback: 'Repository analytics could not be loaded.',
                ),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(
                  thesisListProvider(const ThesisListParams(showAll: true)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<Thesis> theses,
    List<Program> programs,
    List<AcademicYear> years,
    Map<String, dynamic> stats,
  ) {
    final programNames = {for (final p in programs) p.id: p.code};
    final yearNames = {for (final y in years) y.id: y.label};

    final statusCounts = <String, int>{};
    final programCounts = <String, int>{};
    final yearCounts = <String, int>{};
    final typeCounts = <String, int>{};
    for (final thesis in theses) {
      final status = thesis.status.toLowerCase();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      final program =
          thesis.program?.code ?? programNames[thesis.programId] ?? 'Program';
      programCounts[program] = (programCounts[program] ?? 0) + 1;
      final year =
          thesis.academicYear?.label ?? yearNames[thesis.academicYearId] ?? 'Year';
      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
      final type = thesis.researchType.isEmpty ? 'Unclassified' : thesis.researchType;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    final statusSlices = [
      for (final status in _statusOrder)
        if ((statusCounts[status] ?? 0) > 0)
          ChartSlice(
            label: _title(status),
            value: statusCounts[status]!,
            color: CScholarColors.statusFill[status] ??
                CScholarColors.textSecondary,
          ),
    ];
    final typeSlices = [
      for (final entry in typeCounts.entries)
        ChartSlice(
          label: entry.key,
          value: entry.value,
          color: entry.key == 'Capstone'
              ? CScholarColors.violetInk
              : CScholarColors.primaryGreen,
        ),
    ];
    final programSlices = [
      for (final entry in programCounts.entries)
        ChartSlice(
          label: entry.key,
          value: entry.value,
          color: CScholarColors.primaryGreen,
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final yearSlices = [
      for (final entry in yearCounts.entries)
        ChartSlice(
          label: entry.key,
          value: entry.value,
          color: CScholarColors.info,
        ),
    ]..sort((a, b) => a.label.compareTo(b.label));

    final total = theses.length;
    final published = statusCounts['published'] ?? 0;
    final searches = (stats['searches'] as num?)?.toInt() ?? 0;
    final topQueries = (stats['top_queries'] as List<dynamic>?) ?? const [];

    final cards = [
      _card(
        title: 'By Status',
        subtitle: '$total studies in the repository',
        child: DonutChart(
          slices: statusSlices,
          centerLabel: 'studies',
        ),
      ),
      _card(
        title: 'By Research Type',
        subtitle: 'Thesis vs Capstone',
        child: DonutChart(
          slices: typeSlices,
          centerLabel: 'studies',
        ),
      ),
      _card(
        title: 'By Program',
        subtitle: 'Studies per CEIT program',
        child: AnalyticsBars(
          slices: programSlices,
          emptyMessage: 'No program data yet',
        ),
      ),
      _card(
        title: 'By Academic Year',
        subtitle: 'Studies per academic year',
        child: ColumnChart(slices: yearSlices),
      ),
      _card(
        title: 'Top Searches',
        subtitle: '$searches logged · last 30 days',
        child: topQueries.isEmpty
            ? Text(
                'No searches logged yet',
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w400,
                  CScholarColors.textMuted,
                ),
              )
            : Column(
                children: [
                  for (final raw in topQueries)
                    _queryRow(Map<String, dynamic>.from(raw as Map)),
                ],
              ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: kpiGridDelegate(
                context,
                wide ? 4 : 2,
                extent: metricCardIntrinsicHeight,
              ),
              children: [
                _metric('STUDIES', '$total', '${statusCounts['draft'] ?? 0} in draft'),
                _metric('PUBLISHED', '$published', '$total total records'),
                _metric('PROGRAMS', '${programCounts.length}', 'with studies'),
                _metric('SEARCHES', '$searches', 'all time'),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
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
                const SizedBox(height: 20),
                cards[4],
              ],
            );
          },
        ),
      ],
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

  Widget _metric(String label, String value, String trend) {
    return CScholarCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: CScholarTextStyles.body(
              10.5,
              FontWeight.w700,
              CScholarColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: CScholarTextStyles.heading(
              26,
              FontWeight.w800,
              CScholarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CScholarTextStyles.body(
              11,
              FontWeight.w500,
              CScholarColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _queryRow(Map<String, dynamic> row) {
    final semantic = (row['mode'] ?? 'keyword').toString() == 'semantic';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (row['query'] ?? '').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(
                12.5,
                FontWeight.w600,
                CScholarColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: semantic
                  ? CScholarColors.infoLight
                  : CScholarColors.thesisChipBg,
              borderRadius: BorderRadius.circular(CScholarRadius.full),
            ),
            child: Text(
              semantic ? 'Semantic' : 'Keyword',
              style: CScholarTextStyles.body(
                10,
                FontWeight.w700,
                semantic ? CScholarColors.info : CScholarColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${row['count'] ?? 0}',
            style: CScholarTextStyles.body(
              11.5,
              FontWeight.w700,
              CScholarColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _title(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
