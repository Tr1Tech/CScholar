import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class SavedThesesScreen extends ConsumerStatefulWidget {
  const SavedThesesScreen({super.key});

  @override
  ConsumerState<SavedThesesScreen> createState() => _SavedThesesScreenState();
}

class _SavedThesesScreenState extends ConsumerState<SavedThesesScreen> {
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(savedThesisIdsProvider);
    final allTheses = ref.watch(thesisListProvider(const ThesisListParams()));

    return StudentLayout(
      currentIndex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Studies',
                          style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your bookmarked research studies and reference papers',
                          style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/repository'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CScholarColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                      ),
                      icon: const Icon(Icons.search, size: 18),
                      label: Text('Find More', style: CScholarTextStyles.inter(13, FontWeight.w600, Colors.white)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Filter Tabs (All / Thesis / Capstone)
                Row(
                  children: [
                    _tabButton('All'),
                    const SizedBox(width: 8),
                    _tabButton('Thesis'),
                    const SizedBox(width: 8),
                    _tabButton('Capstone'),
                  ],
                ),

                const SizedBox(height: 24),

                // Studies Cards List
                allTheses.when(
                  data: (list) {
                    if (list == null || list.isEmpty) {
                      return _emptyState('No studies found in repository');
                    }
                    var saved = list.where((t) => savedIds.contains(t.id)).toList();

                    // If user hasn't saved anything yet, provide the top 2 featured studies as demo
                    if (saved.isEmpty) {
                      saved = list.take(2).toList();
                    }

                    // Filter by tab
                    if (_selectedTab != 'All') {
                      saved = saved.where((t) => t.researchType.toLowerCase() == _selectedTab.toLowerCase()).toList();
                    }

                    if (saved.isEmpty) {
                      return _emptyState('No saved ${_selectedTab.toLowerCase()} studies yet');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: saved.length,
                      itemBuilder: (context, i) {
                        final thesis = saved[i];
                        final isTeal = i % 2 == 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(CScholarRadius.xl),
                              border: Border.all(color: CScholarColors.borderLight),
                              boxShadow: CScholarShadows.card,
                            ),
                            child: Row(
                              children: [
                                // Thumbnail device illustration icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isTeal ? const Color(0xFFCCFBF1) : const Color(0xFFCFFAFE),
                                    borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                    border: Border.all(
                                      color: isTeal ? const Color(0xFF99F6E4) : const Color(0xFFA5F3FC),
                                    ),
                                  ),
                                  child: Icon(
                                    isTeal ? Icons.smartphone_outlined : Icons.laptop_chromebook_outlined,
                                    color: isTeal ? const Color(0xFF0D9488) : const Color(0xFF0891B2),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 18),

                                // Title & Meta
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () => context.go('/thesis/${thesis.id}'),
                                        child: Text(
                                          thesis.title,
                                          style: CScholarTextStyles.poppins(
                                            15,
                                            FontWeight.w700,
                                            CScholarColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              thesis.program?.name ?? 'BSIT',
                                              style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '• ${thesis.academicYear?.label ?? '2024 - 2025'}',
                                            style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Actions: View & Remove
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => context.go('/thesis/${thesis.id}'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: CScholarColors.primaryGreen,
                                        backgroundColor: CScholarColors.primaryGreenVeryLight,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                      ),
                                      child: Text(
                                        'View',
                                        style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.primaryGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        ref.read(savedThesisIdsProvider.notifier).toggle(thesis.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Removed "${thesis.title}" from saved studies')),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: CScholarColors.error,
                                        backgroundColor: CScholarColors.errorLight,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                      ),
                                      child: Text(
                                        'Remove',
                                        style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (_, _) => const Text('Error loading saved studies'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String tab) {
    final isSelected = _selectedTab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(CScholarRadius.full),
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? CScholarColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(CScholarRadius.full),
          border: Border.all(
            color: isSelected ? CScholarColors.primaryGreen : CScholarColors.borderLight,
          ),
          boxShadow: isSelected ? CScholarShadows.subtle : null,
        ),
        child: Text(
          tab,
          style: CScholarTextStyles.inter(
            12.5,
            isSelected ? FontWeight.w700 : FontWeight.w500,
            isSelected ? Colors.white : CScholarColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.bookmark_border, size: 56, color: CScholarColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: CScholarTextStyles.poppins(16, FontWeight.w600, CScholarColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the repository to save research papers and capstone projects for later reference.',
              style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/repository'),
              style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
              child: const Text('Browse Repository'),
            ),
          ],
        ),
      ),
    );
  }
}
