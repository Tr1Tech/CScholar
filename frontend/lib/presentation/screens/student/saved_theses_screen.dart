// Saved theses screen — user's bookmarked studies

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class SavedThesesScreen extends ConsumerWidget {
  const SavedThesesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedThesisIdsProvider);
    final allTheses = ref.watch(thesisListProvider(const ThesisListParams()));
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/student/dashboard'),
        ),
        title: const Text('Saved Studies', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (savedIds.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(savedThesisIdsProvider.notifier).clear(),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear all'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: allTheses.when(
        data: (theses) {
          final saved = theses?.where((t) => savedIds.contains(t.id)).toList() ?? [];
          if (saved.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 72, color: CScholarColors.textHint.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved studies yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bookmark theses to access them quickly later',
                    style: TextStyle(fontSize: 14, color: CScholarColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/repository'),
                    style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Repository'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: EdgeInsets.all(isWide ? 32 : 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 3 : 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isWide ? 1.5 : 2.2,
            ),
            itemCount: saved.length,
            itemBuilder: (context, index) => ThesisCard(thesis: saved[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        backgroundColor: Colors.white,
        indicatorColor: CScholarColors.primaryGreenVeryLight,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/student/dashboard');
          if (i == 1) context.go('/repository');
          if (i == 2) {}
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
}
