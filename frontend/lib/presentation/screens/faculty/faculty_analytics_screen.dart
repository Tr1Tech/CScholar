import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';

/// Faculty: status / program / year breakdown of advised theses.
class FacultyAnalyticsScreen extends ConsumerWidget {
  const FacultyAnalyticsScreen({super.key});

  // Status bar fills come from CScholarColors.statusFill: measured against the
  // clayDeep track (WCAG 1.4.11), so the two dashboards cannot drift apart.

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
          physics: const AlwaysScrollableScrollPhysics(),
          child: StaggerColumn(
            // Header-first on the page rhythm; each chart group below draws
            // 120ms after its card lands (see _content).
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
                  message: err.toString(),
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
    const order = ['published', 'approved', 'draft', 'archived'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 860;
        final statusCard = _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Status',
                  style: CScholarTextStyles.heading(16, FontWeight.w700, CScholarColors.textPrimary)),
              const SizedBox(height: 4),
              Text('$total supervised ${total == 1 ? 'study' : 'studies'}',
                  style: CScholarTextStyles.body(12, FontWeight.w500, CScholarColors.textMuted)),
              const SizedBox(height: 16),
              // The chart draws 120ms after its card lands — never on the same
              // frame as the card entrance. Rise is 0: the delay is scheduling
              // for the draw, and travel would fight the filling bars.
              EntranceReveal(
                delay: const Duration(milliseconds: 120),
                rise: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (total == 0)
                      const EmptyState(
                        compact: true,
                        icon: Icons.donut_small_outlined,
                        title: 'No status data',
                        message:
                            'Supervised studies appear here once linked.',
                      ),
                    for (final s in order)
                      if ((byStatus[s] as num?)?.toInt() != null && (byStatus[s] as num).toInt() > 0)
                        _barRow(s.toUpperCase(), (byStatus[s] as num).toInt(), total,
                            CScholarColors.statusFill[s] ??
                                CScholarColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        );
        final programCard = _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Program',
                  style: CScholarTextStyles.heading(16, FontWeight.w700, CScholarColors.textPrimary)),
              const SizedBox(height: 16),
              // Same +120 chart beat as the status card.
              EntranceReveal(
                delay: const Duration(milliseconds: 120),
                rise: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (byProgram.isEmpty)
                      const EmptyState(
                        compact: true,
                        icon: Icons.school_outlined,
                        title: 'No program data',
                        message:
                            'Studies linked to a program will appear here.',
                      ),
                    for (final p in byProgram)
                      _simpleRow((p as Map)['program']?.toString() ?? '—',
                          ((p)['count'] as num?)?.toInt() ?? 0),
                  ],
                ),
              ),
            ],
          ),
        );
        final yearCard = _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Academic Year',
                  style: CScholarTextStyles.heading(16, FontWeight.w700, CScholarColors.textPrimary)),
              const SizedBox(height: 16),
              // Same +120 chart beat as the status card.
              EntranceReveal(
                delay: const Duration(milliseconds: 120),
                rise: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (byYear.isEmpty)
                      const EmptyState(
                        compact: true,
                        icon: Icons.calendar_month_outlined,
                        title: 'No year data',
                        message:
                            'Studies from an academic year will appear here.',
                      ),
                    for (final y in byYear)
                      _simpleRow((y as Map)['year']?.toString() ?? '—',
                          ((y)['count'] as num?)?.toInt() ?? 0),
                  ],
                ),
              ),
            ],
          ),
        );
        if (wide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: statusCard),
                  const SizedBox(width: 24),
                  Expanded(child: programCard),
                ],
              ),
              const SizedBox(height: 24),
              yearCard,
            ],
          );
        }
        return Column(
          children: [statusCard, const SizedBox(height: 24), programCard, const SizedBox(height: 24), yearCard],
        );
      },
    );
  }

  Widget _card({required Widget child}) {
    // CScholarCard sizes to content — stretch it full width like before.
    return SizedBox(width: double.infinity, child: CScholarCard(child: child));
  }

  Widget _barRow(String label, int count, int total, Color color) {
    final frac = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: CScholarTextStyles.body(12, FontWeight.w700, CScholarColors.textPrimary)),
              Text('$count',
                  style: CScholarTextStyles.body(12, FontWeight.w600, CScholarColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClayProgressBar(value: frac, height: 8, tint: color),
        ],
      ),
    );
  }

  Widget _simpleRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: CScholarTextStyles.body(13, FontWeight.w600, CScholarColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: CScholarTextStyles.body(12, FontWeight.w700, CScholarColors.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
