// Landing / Welcome — Stitch design v2
// Hero section with search bar + featured studies grid

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTheses = ref.watch(recentThesesProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('CScholar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                  const Spacer(),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
          // Hero section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CScholarColors.sidebarDeep, CScholarColors.adminSidebar],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CScholarColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CScholarColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: const Text('CEIT Thesis & Capstone Repository', style: TextStyle(color: CScholarColors.gold, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 16),
                  Text('Discover research that\nmatches your ideas.', style: TextStyle(fontSize: isWide ? 48 : 36, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 16),
                  Text('Search CEIT thesis and capstone projects using keywords or natural-language questions.', style: TextStyle(fontSize: isWide ? 17 : 15, color: Colors.white70, height: 1.5)),
                  const SizedBox(height: 32),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.search, color: CScholarColors.textHint, size: 24)),
                        const SizedBox(width: 12),
                        const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Search thesis, capstone, topic, author, keyword...', border: InputBorder.none), style: TextStyle(fontSize: 15))),
                        FilledButton(
                          onPressed: () => context.go('/login'),
                          style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                          child: const Icon(Icons.arrow_forward, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Popular searches
                  Row(
                    children: [
                      const Text('Popular searches:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 8),
                      _popularChip('machine learning'),
                      _popularChip('web application'),
                      _popularChip('campus navigation'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Featured studies
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Featured Studies', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                      TextButton(onPressed: () => context.go('/login'), child: const Text('View All →', style: TextStyle(color: CScholarColors.primaryGreen))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Explore top-rated and recently published capstone works from CEIT students', style: TextStyle(fontSize: 14, color: CScholarColors.textSecondary)),
                  const SizedBox(height: 24),
                  recentTheses.when(
                    data: (theses) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 0.75 : 1.2,
                      ),
                      itemCount: theses.take(3).length,
                      itemBuilder: (ctx, i) => ThesisCard(thesis: theses[i], similarityScore: [0.96, 0.87, 0.82][i]),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Could not load featured studies'),
                  ),
                ],
              ),
            ),
          ),
          // Stats section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statColumn('1,248', 'Archived Theses'),
                  _statColumn('3', 'CEIT Programs'),
                  _statColumn('5+', 'Academic Years'),
                  _statColumn('100%', 'CEIT Peer Reviewed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CScholarColors.primaryGreen)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
      ],
    );
  }
}
