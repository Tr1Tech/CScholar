import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.go('/repository?q=${Uri.encodeComponent(query)}');
    } else {
      context.go('/repository');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final recentTheses = ref.watch(recentThesesProvider);
    final stats = ref.watch(publicStatsProvider);
    final savedIds = ref.watch(savedThesisIdsProvider);
    final academicYears = ref.watch(academicYearsProvider);

    // Recommendations are generated from the most recent database record.
    final recentList = recentTheses.value;
    final recommendationSourceId =
        (recentList != null && recentList.isNotEmpty) ? recentList.first.id : null;
    final recommendedTheses = recommendationSourceId == null
        ? AsyncValue.data(<SemanticResult>[])
        : ref.watch(recommendedThesesProvider(recommendationSourceId));

    return StudentLayout(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Greeting & Prominent Search Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(CScholarRadius.xl),
                    border: Border.all(color: CScholarColors.borderLight),
                    boxShadow: CScholarShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_timeOfDay()}${(user?.username ?? '').isEmpty ? '' : ', ${user!.username}'}!',
                        style: CScholarTextStyles.poppins(
                          24,
                          FontWeight.w800,
                          CScholarColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'What are you researching today?',
                        style: CScholarTextStyles.inter(
                          14,
                          FontWeight.w400,
                          CScholarColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Prominent Search Bar: the well owns the surface, the
                      // button sits beside it (both on the clay canvas).
                      Container(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: Row(
                          children: [
                            Expanded(
                              child: NeumorphField(
                                controller: _searchController,
                                hintText: 'Search thesis, capstone, topic, author, keyword...',
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _search(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _search,
                              style: FilledButton.styleFrom(
                                backgroundColor: CScholarColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(CScholarRadius.md)),
                              ),
                              child: const Icon(Icons.search, size: 20, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Metrics Stat Cards Row (4 KPI cards)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 540
                            ? 2
                            : 1;

                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Fixed extent, not an aspect ratio — see [kpiGridDelegate].
                      gridDelegate: kpiGridDelegate(
                        context,
                        crossAxisCount,
                        extent: metricCardIntrinsicHeight,
                      ),
                      children: [
                        _metricCard(
                          title: 'Archived Studies',
                          value: '${stats.value?['studies'] ?? 0}',
                          icon: Icons.article_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: CScholarColors.primaryGreen,
                        ),
                        _metricCard(
                          title: 'CEIT Programs',
                          value: '${stats.value?['programs'] ?? 0}',
                          icon: Icons.account_balance_outlined,
                          iconBg: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0369A1),
                        ),
                        _metricCard(
                          title: 'Academic Years',
                          value: '${academicYears.value?.length ?? 0}',
                          icon: Icons.calendar_today_outlined,
                          iconBg: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF6D28D9),
                        ),
                        _metricCard(
                          title: 'Your Saved',
                          value: '${savedIds.length}',
                          icon: Icons.bookmark_outline,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: CScholarColors.warningFg,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 3. Two-Column Content Grid: Recent Studies & Recommended
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMultiCol = constraints.maxWidth > 880;

                    final leftCol = _recentStudiesCard(recentTheses);
                    final rightCol = _recommendedStudiesCard(recommendedTheses);

                    if (isMultiCol) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftCol),
                          const SizedBox(width: 20),
                          Expanded(child: rightCol),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          leftCol,
                          const SizedBox(height: 20),
                          rightCol,
                        ],
                      );
                    }
                  },
                ),
                const CScholarFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool gold = false,
  }) {
    return CScholarCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClayIconTile(
            icon: icon,
            size: 44,
            gold: gold,
            background: iconBg,
            tint: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: CScholarTextStyles.inter(
                    12,
                    FontWeight.w500,
                    CScholarColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CScholarTextStyles.poppins(
                    22,
                    FontWeight.w800,
                    CScholarColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentStudiesCard(AsyncValue<List<dynamic>> recentTheses) {
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Studies',
                style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
              ),
              TextButton(
                onPressed: () => context.go('/repository'),
                child: Row(
                  children: [
                    Text('View All', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: CScholarColors.primaryGreen),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: CScholarColors.borderLight, height: 16),
          const SizedBox(height: 6),
          recentTheses.when(
            data: (theses) {
              if (theses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent studies available'),
                );
              }
              return Column(
                children: theses.take(4).map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(CScholarRadius.md),
                      onTap: () => context.go('/thesis/${t.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CScholarMaterial.clayDeep,
                          borderRadius: BorderRadius.circular(CScholarRadius.md),
                          border: Border.all(color: CScholarMaterial.rim),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClayIconTile(
                              icon: Icons.article_outlined,
                              size: 36,
                              gel: false,
                              background: CScholarColors.primaryGreenLight,
                              tint: CScholarColors.primaryGreen,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CScholarTextStyles.inter(13.5, FontWeight.w600, CScholarColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if ((t.program?.name ?? '').isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            t.program!.name,
                                            style: CScholarTextStyles.inter(10.5, FontWeight.w700, const Color(0xFF0369A1)),
                                          ),
                                        ),
                                      if ((t.program?.name ?? '').isNotEmpty &&
                                          (t.academicYear?.label ?? '').isNotEmpty)
                                        const SizedBox(width: 8),
                                      if ((t.academicYear?.label ?? '').isNotEmpty)
                                        Text(
                                          t.academicYear!.label,
                                          style: CScholarTextStyles.inter(11.5, FontWeight.w400, CScholarColors.textMuted),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SkeletonList(count: 4, cardHeight: 64),
            error: (_, _) => const Text('Error loading studies'),
          ),
        ],
      ),
    );
  }

  Widget _recommendedStudiesCard(AsyncValue<List<SemanticResult>> recommended) {
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended for You',
                style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
              ),
              TextButton(
                onPressed: () => context.go('/repository'),
                child: Row(
                  children: [
                    Text('View All', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: CScholarColors.primaryGreen),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: CScholarColors.borderLight, height: 16),
          const SizedBox(height: 6),
          recommended.when(
            data: (recs) {
              if (recs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No recommendations yet',
                      style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                    ),
                  ),
                );
              }
              return Column(
                children: recs.take(4).map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(CScholarRadius.md),
                      onTap: () => context.go('/thesis/${r.thesis.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CScholarMaterial.clayDeep,
                          borderRadius: BorderRadius.circular(CScholarRadius.md),
                          border: Border.all(color: CScholarMaterial.rim),
                        ),
                        child: Row(
                          children: [
                            ClayIconTile(
                              icon: Icons.auto_awesome,
                              size: 36,
                              gel: false,
                              background: CScholarColors.goldSoft,
                              tint: CScholarColors.warningFg,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.thesis.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CScholarTextStyles.inter(13.5, FontWeight.w600, CScholarColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.thesis.program?.name ?? ''}${(r.thesis.program?.name ?? '').isEmpty ? '' : ' • '}${(r.similarity * 100).round()}% match',
                                    style: CScholarTextStyles.inter(11.5, FontWeight.w400, CScholarColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: CScholarColors.primaryGreenVeryLight,
                                borderRadius: BorderRadius.circular(CScholarRadius.full),
                                border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${(r.similarity * 100).round()}%',
                                style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SkeletonList(count: 4, cardHeight: 64),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Recommendations unavailable',
                  style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
