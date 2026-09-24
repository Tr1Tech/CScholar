import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
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
      searchController: _searchController,
      onSearchSubmit: _search,
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
                      // Prominent Search Bar
                      Container(
                        constraints: const BoxConstraints(maxWidth: 840),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(CScholarRadius.lg),
                          border: Border.all(color: CScholarColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _search(),
                                style: CScholarTextStyles.inter(14, FontWeight.w400, CScholarColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Search thesis, capstone, topic, author, keyword...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: _search,
                              style: FilledButton.styleFrom(
                                backgroundColor: CScholarColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(CScholarRadius.lg - 1)),
                                ),
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

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 900 ? 2.1 : 2.4,
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
                          iconColor: const Color(0xFF0284C7),
                        ),
                        _metricCard(
                          title: 'Academic Years',
                          value: '${academicYears.value?.length ?? 0}',
                          icon: Icons.calendar_today_outlined,
                          iconBg: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF7C3AED),
                        ),
                        _metricCard(
                          title: 'Your Saved',
                          value: '${savedIds.length}',
                          icon: Icons.bookmark_outline,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.lg),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
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
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: CScholarTextStyles.poppins(
                  22,
                  FontWeight.w800,
                  CScholarColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentStudiesCard(AsyncValue<List<dynamic>> recentTheses) {
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
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(CScholarRadius.md),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: CScholarColors.primaryGreenVeryLight,
                                borderRadius: BorderRadius.circular(CScholarRadius.sm),
                              ),
                              child: const Icon(Icons.article_outlined, size: 18, color: CScholarColors.primaryGreen),
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
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (_, _) => const Text('Error loading studies'),
          ),
        ],
      ),
    );
  }

  Widget _recommendedStudiesCard(AsyncValue<List<SemanticResult>> recommended) {
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
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(CScholarRadius.md),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(CScholarRadius.sm),
                              ),
                              child: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFD97706)),
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
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
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
