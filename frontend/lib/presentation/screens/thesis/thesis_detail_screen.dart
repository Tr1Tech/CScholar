// Thesis detail screen — full view of one thesis

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';
import 'package:frontend/models/thesis.dart';

class ThesisDetailScreen extends ConsumerWidget {
  final int thesisId;
  const ThesisDetailScreen({super.key, required this.thesisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thesisAsync = ref.watch(thesisDetailProvider(thesisId));
    final recommended = ref.watch(recommendedThesesProvider(thesisId));
    final saved = ref.watch(savedThesisIdsProvider);
    final isSaved = saved.contains(thesisId);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/repository'),
        ),
        title: const Text('Study Details', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: CScholarColors.primaryGreen),
            onPressed: () => ref.read(savedThesisIdsProvider.notifier).toggle(thesisId),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: CScholarColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: thesisAsync.when(
        data: (thesis) {
          if (thesis == null) {
            return const Center(child: Text('Thesis not found'));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: CScholarColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    thesis.researchType.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: thesis.status == 'published'
                                        ? CScholarColors.success.withValues(alpha: 0.1)
                                        : CScholarColors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    thesis.status.toUpperCase(),
                                    style: TextStyle(
                                      color: thesis.status == 'published' ? CScholarColors.success : CScholarColors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(thesis.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary, height: 1.3)),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _metaChip(Icons.school, thesis.program?.name ?? ''),
                                _metaChip(Icons.calendar_today, thesis.academicYear?.label ?? ''),
                                _metaChip(Icons.person, thesis.advisers?.first.fullName ?? ''),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Abstract
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
                            const Text('Abstract', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                            const SizedBox(height: 12),
                            Text(thesis.abstract, style: const TextStyle(fontSize: 15, color: CScholarColors.textSecondary, height: 1.7)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Authors
                      if (thesis.authors != null && thesis.authors!.isNotEmpty) ...[
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
                              const Text('Researchers', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: thesis.authors!.map((a) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: CScholarColors.primaryGreenVeryLight,
                                      child: Text(
                                        '${a.firstName[0]}${a.lastName[0]}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CScholarColors.primaryGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${a.firstName} ${a.lastName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        if (a.email != null) Text(a.email!, style: const TextStyle(fontSize: 12, color: CScholarColors.textHint)),
                                      ],
                                    ),
                                  ],
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Keywords
                      if (thesis.keywords != null && thesis.keywords!.isNotEmpty) ...[
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
                              const Text('Keywords', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: thesis.keywords!.map((k) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: CScholarColors.primaryGreenVeryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(k.term, style: const TextStyle(fontSize: 13, color: CScholarColors.primaryGreen)),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Adviser
                      if (thesis.advisers?.first != null) ...[
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
                              const Text('Adviser', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: CScholarColors.facultyColor.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: CScholarColors.facultyColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(thesis.advisers!.first.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      if (thesis.advisers!.first.email != null) Text(thesis.advisers!.first.email!, style: const TextStyle(fontSize: 13, color: CScholarColors.textHint)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Mobile: Recommendations inline (desktop shows in sidebar)
                      if (!isWide) _buildRecommendationsSection(recommended, isViewing: true),
                    ],
                  ),
                ),

                // Sidebar (desktop only)
                if (isWide) ...[
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 320,
                    child: Column(
                      children: [
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CScholarColors.dividerLight),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download Full Document'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => ref.read(savedThesisIdsProvider.notifier).toggle(thesisId),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: CScholarColors.primaryGreen,
                                    side: const BorderSide(color: CScholarColors.primaryGreen),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                                  label: Text(isSaved ? 'Saved' : 'Save Study'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Recommended
                        _buildRecommendationsSection(recommended, isViewing: true),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  /// Prominent "Because you viewed" recommendations section.
  /// Used both in desktop sidebar and mobile inline view.
  Widget _buildRecommendationsSection(
    AsyncValue<List<Thesis>> recommended, {
    bool isViewing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CScholarColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: CScholarColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isViewing ? 'Because you viewed this study' : 'Recommended Studies',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (isViewing)
                        const Text(
                          'AI-powered semantic recommendations',
                          style: TextStyle(fontSize: 11, color: CScholarColors.textHint),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          recommended.when(
            data: (recs) {
              if (recs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No related studies found.',
                    style: TextStyle(fontSize: 13, color: CScholarColors.textHint),
                  ),
                );
              }
              return Column(
                children: recs.take(3).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value;
                  final mockScore = [0.93, 0.89, 0.84][idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ThesisCard(thesis: t, similarityScore: mockScore),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text(
              'Could not load recommendations',
              style: TextStyle(fontSize: 13, color: CScholarColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CScholarColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CScholarColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
        ],
      ),
    );
  }
}
