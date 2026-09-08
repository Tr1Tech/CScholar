// Saved Studies — Stitch design v2
// Uses shared StudentLayout (sidebar + topbar)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class SavedThesesScreen extends ConsumerWidget {
  const SavedThesesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedThesisIdsProvider);
    final allTheses = ref.watch(thesisListProvider(const ThesisListParams()));

    return StudentLayout(
      currentIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saved Studies', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                    Text('${savedIds.length} studies saved', style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/repository'),
                  style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Discover More'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Saved list
            Expanded(
              child: allTheses.when(
                data: (list) {
                  if (list == null || list.isEmpty) {
                    return _emptyState('No studies in repository');
                  }
                  final saved = list.where((t) => savedIds.contains(t.id)).toList();
                  if (saved.isEmpty) {
                    return _emptyState('No saved studies yet');
                  }
                  return ListView.builder(
                    itemCount: saved.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Dismissible(
                        key: ValueKey(saved[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => ref.read(savedThesisIdsProvider.notifier).toggle(saved[i].id),
                        background: Container(
                          decoration: BoxDecoration(
                            color: CScholarColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                        ),
                        child: ThesisCard(thesis: saved[i]),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Could not load saved studies')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline, size: 64, color: CScholarColors.textHint),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: CScholarColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Start exploring the repository to save studies', style: TextStyle(fontSize: 13, color: CScholarColors.textHint)),
        ],
      ),
    );
  }
}
