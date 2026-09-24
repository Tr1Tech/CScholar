import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';

/// Faculty: status / program / year breakdown of advised theses.
class FacultyAnalyticsScreen extends ConsumerWidget {
  const FacultyAnalyticsScreen({super.key});

  static const _statusColors = {
    'published': CScholarColors.primaryGreen,
    'approved': CScholarColors.info,
    'draft': CScholarColors.orange,
    'archived': CScholarColors.textSecondary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
    final analyticsAsync = ref.watch(facultyAnalyticsProvider);

    final body = RefreshIndicator(
      onRefresh: () => ref.refresh(facultyAnalyticsProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analytics',
                    style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Breakdown of your supervised studies.',
                    style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted)),
                const SizedBox(height: 20),
                analyticsAsync.when(
                  data: (a) => _content(context, a),
                  loading: () => const Center(
                      child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (err, _) => _card(
                    child: Center(
                        child: Text('Could not load analytics: $err',
                            style: CScholarTextStyles.inter(
                                13, FontWeight.w500, CScholarColors.textMuted))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
            onPressed: () => context.go('/faculty/dashboard'),
          ),
          title: const Text('Analytics',
              style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          const FacultySidebar(currentPath: '/faculty/analytics'),
          Expanded(child: body),
        ],
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
                  style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary)),
              const SizedBox(height: 4),
              Text('$total supervised ${total == 1 ? 'study' : 'studies'}',
                  style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted)),
              const SizedBox(height: 16),
              if (total == 0)
                Text('No data yet',
                    style: CScholarTextStyles.inter(13, FontWeight.w500, CScholarColors.textMuted)),
              for (final s in order)
                if ((byStatus[s] as num?)?.toInt() != null && (byStatus[s] as num).toInt() > 0)
                  _barRow(s.toUpperCase(), (byStatus[s] as num).toInt(), total,
                      _statusColors[s] ?? CScholarColors.textSecondary),
            ],
          ),
        );
        final programCard = _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Program',
                  style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary)),
              const SizedBox(height: 16),
              if (byProgram.isEmpty)
                Text('No data yet',
                    style: CScholarTextStyles.inter(13, FontWeight.w500, CScholarColors.textMuted)),
              for (final p in byProgram)
                _simpleRow((p as Map)['program']?.toString() ?? '—',
                    ((p)['count'] as num?)?.toInt() ?? 0),
            ],
          ),
        );
        final yearCard = _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Academic Year',
                  style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary)),
              const SizedBox(height: 16),
              if (byYear.isEmpty)
                Text('No data yet',
                    style: CScholarTextStyles.inter(13, FontWeight.w500, CScholarColors.textMuted)),
              for (final y in byYear)
                _simpleRow((y as Map)['year']?.toString() ?? '—',
                    ((y)['count'] as num?)?.toInt() ?? 0),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: child,
    );
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
                  style: CScholarTextStyles.inter(12, FontWeight.w700, CScholarColors.textPrimary)),
              Text('$count',
                  style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: CScholarColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
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
                style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: CScholarTextStyles.inter(12, FontWeight.w700, CScholarColors.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
