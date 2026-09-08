// Student Dashboard — Stitch design v2
// Uses shared StudentLayout (sidebar + topbar)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final recentTheses = ref.watch(recentThesesProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return StudentLayout(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CScholarColors.dividerLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_timeOfDay()}, ${user?.username ?? 'Student'}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What are you researching today?',
                    style: TextStyle(fontSize: 14, color: CScholarColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KPI stat cards
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _statCard('${stats.value?['studies'] ?? '1,248'}', 'Archived Studies', Icons.menu_book_outlined, CScholarColors.primaryGreen),
                _statCard('${stats.value?['programs'] ?? '3'}', 'CEIT Programs', Icons.account_balance_outlined, CScholarColors.info),
                _statCard('${stats.value?['years'] ?? '5'}', 'Academic Years', Icons.calendar_today_outlined, CScholarColors.orange),
                _statCard('${stats.value?['saved'] ?? '12'}', 'Your Saved', Icons.bookmark_outline, CScholarColors.gold),
              ],
            ),
            const SizedBox(height: 24),

            // Two-column: Recent + Recommended
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent studies
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CScholarColors.dividerLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Studies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                            TextButton(
                              onPressed: () => context.go('/repository'),
                              child: const Text('View All', style: TextStyle(fontSize: 12, color: CScholarColors.primaryGreen)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        recentTheses.when(
                          data: (theses) => Column(
                            children: theses.take(3).map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _recentItem(t.title, t.program?.name ?? '', t.academicYear?.label ?? '', () => context.go('/thesis/${t.id}')),
                            )).toList(),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('Could not load recent studies'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Recommended
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CScholarColors.dividerLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recommended for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                            TextButton(
                              onPressed: () => context.go('/repository'),
                              child: const Text('View All', style: TextStyle(fontSize: 12, color: CScholarColors.primaryGreen)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _recommendedItem('Campus Navigation and Room Locator', 'BSIT • 2024 - 2025', 91),
                        const SizedBox(height: 12),
                        _recommendedItem('Indoor Positioning System for University Buildings', 'BSCS • 2023 - 2024', 87),
                        const SizedBox(height: 12),
                        _recommendedItem('Student Location Assistance System', 'BSIS • 2023 - 2024', 81),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
              Text(label, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentItem(String title, String program, String year, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CScholarColors.dividerLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreenVeryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_outlined, size: 18, color: CScholarColors.primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(program, style: const TextStyle(fontSize: 11, color: CScholarColors.primaryGreen, fontWeight: FontWeight.w500)),
                      const Text(' • ', style: TextStyle(fontSize: 11, color: CScholarColors.textHint)),
                      Text(year, style: const TextStyle(fontSize: 11, color: CScholarColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendedItem(String title, String subtitle, int percent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: CScholarColors.dividerLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CScholarColors.primaryGreenVeryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: CScholarColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: CScholarColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$percent% similar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CScholarColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  String _timeOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}
