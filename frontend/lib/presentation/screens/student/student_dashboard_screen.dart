// Student Dashboard — main home screen after login

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final recentTheses = ref.watch(recentThesesProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'CScholar',
              style: TextStyle(
                color: CScholarColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: CScholarColors.textSecondary),
            onPressed: () => context.go('/repository'),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: CScholarColors.textSecondary),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: CScholarColors.orange, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: CScholarColors.primaryGreen,
                    child: Text(
                      (user?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.username ?? 'User',
                    style: const TextStyle(color: CScholarColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down, color: CScholarColors.textSecondary),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Row(children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                const Text('Profile'),
              ])),
              PopupMenuItem(value: 'saved', child: Row(children: [
                const Icon(Icons.bookmark_outline, size: 18),
                const SizedBox(width: 8),
                const Text('Saved Studies'),
              ])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Row(children: [
                const Icon(Icons.logout, size: 18),
                const SizedBox(width: 8),
                const Text('Logout'),
              ])),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                context.go('/');
              } else if (value == 'saved') {
                context.go('/saved');
              } else if (value == 'profile') {
                context.go('/profile');
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting + search
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_timeOfDay()}, ${user?.username ?? 'Student'} 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: CScholarColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'What are you researching today?',
                        style: TextStyle(fontSize: 15, color: CScholarColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                stats.when(
                  data: (s) => _statChip('${s['total'] ?? 0}', 'Studies'),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Large search bar
            GestureDetector(
              onTap: () => context.go('/repository'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CScholarColors.dividerLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: CScholarColors.textHint, size: 22),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Search thesis, capstone, keywords, advisers...',
                        style: TextStyle(color: CScholarColors.textHint, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CScholarColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Stats row
            stats.when(
              data: (s) => isWide
                  ? Row(
                      children: [
                        Expanded(child: _statCard('Total Studies', '${s['total'] ?? 0}', Icons.article_outlined, CScholarColors.primaryGreen)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard('Programs', '${s['programs'] ?? 0}', Icons.school_outlined, CScholarColors.info)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard('This Year', '${s['thisYear'] ?? 0}', Icons.calendar_today_outlined, CScholarColors.orange)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard('Researchers', '${s['researchers'] ?? 0}', Icons.people_outline, CScholarColors.facultyColor)),
                      ],
                    )
                  : Column(
                      children: [
                        Row(children: [
                          Expanded(child: _statCard('Total Studies', '${s['total'] ?? 0}', Icons.article_outlined, CScholarColors.primaryGreen)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('Programs', '${s['programs'] ?? 0}', Icons.school_outlined, CScholarColors.info)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _statCard('This Year', '${s['thisYear'] ?? 0}', Icons.calendar_today_outlined, CScholarColors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('Researchers', '${s['researchers'] ?? 0}', Icons.people_outline, CScholarColors.facultyColor)),
                        ]),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 32),

            // Recent studies
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Studies',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => context.go('/repository'),
                  child: const Text('View all →'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            recentTheses.when(
              data: (theses) {
                if (theses.isEmpty) return const SizedBox();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.5 : 2.2,
                  ),
                  itemCount: theses.length.clamp(0, 3),
                  itemBuilder: (context, index) => ThesisCard(thesis: theses[index]),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            const SizedBox(height: 32),

            // Recommended section
            const Text(
              'Recommended For You',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Based on recent activity',
              style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
            ),
            const SizedBox(height: 14),
            recentTheses.when(
              data: (theses) {
                if (theses.isEmpty) return const SizedBox();
                // Show recommendations from the first thesis as mock
                final recommended = ref.watch(recommendedThesesProvider(theses.first.id));
                return recommended.when(
                  data: (recs) {
                    if (recs.isEmpty) return const SizedBox();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 1,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.5 : 2.2,
                      ),
                      itemCount: recs.length.clamp(0, 3),
                      itemBuilder: (context, index) {
                        final mockScore = [0.92, 0.87, 0.85][index % 3];
                        return ThesisCard(thesis: recs[index], similarityScore: mockScore);
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
      // Bottom nav
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        indicatorColor: CScholarColors.primaryGreenVeryLight,
        onDestinationSelected: (i) {
          if (i == 1) context.go('/repository');
          if (i == 2) context.go('/saved');
          if (i == 3) context.go('/profile');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: CScholarColors.primaryGreen), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search, color: CScholarColors.primaryGreen), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark, color: CScholarColors.primaryGreen), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: CScholarColors.primaryGreen), label: 'Profile'),
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

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CScholarColors.primaryGreenVeryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.primaryGreen)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: CScholarColors.primaryGreenLight)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
