// Landing / Welcome screen — CScholar entry point

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
          // ── Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: CScholarColors.dividerLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CScholar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CScholarColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CScholarColors.primaryGreen,
                    ),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),

          // ── Hero ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 80,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [CScholarColors.primaryGreen, CScholarColors.primaryGreenLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CEIT Research Repository',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Discover research that\nmatches your ideas.',
                    style: TextStyle(
                      fontSize: isWide ? 48 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Semantic search powered by AI — find related theses and capstone\nprojects across the College of Engineering and Information Technology.',
                    style: TextStyle(
                      fontSize: isWide ? 17 : 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Search bar
                  Container(
                    constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
                    child: TextField(
                      readOnly: true,
                      onTap: () => context.go('/login'),
                      decoration: InputDecoration(
                        hintText: 'Search CEIT thesis and capstone projects...',
                        hintStyle: TextStyle(color: CScholarColors.textHint),
                        prefixIcon: const Icon(Icons.search, color: CScholarColors.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('machine learning'),
                      _chip('mobile app'),
                      _chip('iot'),
                      _chip('database'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Features ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How CScholar Works',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI-powered research discovery for CEIT students and faculty.',
                    style: TextStyle(fontSize: 16, color: CScholarColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  isWide
                      ? Row(
                          children: [
                            Expanded(child: _featureCard(Icons.search, 'Semantic Search', 'Describe what you\'re looking for in plain language — CScholar finds conceptually related research.')),
                            const SizedBox(width: 16),
                            Expanded(child: _featureCard(Icons.auto_awesome, 'AI Recommendations', 'Get personalized study recommendations based on what you\'ve viewed and saved.')),
                            const SizedBox(width: 16),
                            Expanded(child: _featureCard(Icons.bookmark, 'Save & Organize', 'Bookmark theses, organize your research, and build your literature review.')),
                          ],
                        )
                      : Column(
                          children: [
                            _featureCard(Icons.search, 'Semantic Search', 'Describe what you\'re looking for in plain language — CScholar finds conceptually related research.'),
                            const SizedBox(height: 16),
                            _featureCard(Icons.auto_awesome, 'AI Recommendations', 'Get personalized study recommendations based on what you\'ve viewed and saved.'),
                            const SizedBox(height: 16),
                            _featureCard(Icons.bookmark, 'Save & Organize', 'Bookmark theses, organize your research, and build your literature review.'),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // ── Recent Studies ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Studies',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CScholarColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('View all →'),
                  ),
                ],
              ),
            ),
          ),
          recentTheses.when(
            data: (theses) => SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.5 : 2.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ThesisCard(thesis: theses[index]),
                  childCount: theses.length.clamp(0, 3),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // ── Footer ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(32),
              color: CScholarColors.textPrimary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'CScholar — CEIT Thesis Repository',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Caraga State University · College of Engineering and Information Technology',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CScholarColors.primaryGreenVeryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: CScholarColors.primaryGreen, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CScholarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: CScholarColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
