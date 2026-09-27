import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
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
    final savedTheses = ref.watch(savedThesesProvider);

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
                PageHeader(
                  title: 'Saved Studies',
                  subtitle: 'Your bookmarked research studies and reference papers',
                  action: NeumorphButton(
                    onPressed: () => context.go('/repository'),
                    icon: Icons.search,
                    label: 'Find More',
                  ),
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
                savedTheses.when(
                  data: (saved) {
                    // Filter by tab
                    var filtered = saved;
                    if (_selectedTab != 'All') {
                      filtered = filtered
                          .where((t) =>
                              t.researchType.toLowerCase() == _selectedTab.toLowerCase())
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.bookmark_border,
                        title: 'No saved studies',
                        message:
                            'Browse the repository to save research papers and capstone projects for later reference.',
                        actionLabel: 'Browse Repository',
                        onAction: () => context.go('/repository'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final thesis = filtered[i];
                        final isTeal = i % 2 == 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: CScholarCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                // Thumbnail device illustration icon
                                ClayIconTile(
                                  icon: isTeal
                                      ? Icons.smartphone_outlined
                                      : Icons.laptop_chromebook_outlined,
                                  size: 60,
                                  gel: false,
                                  background: isTeal
                                      ? CScholarColors.tealTint
                                      : CScholarColors.cyanTint,
                                  tint: isTeal
                                      ? CScholarColors.tealInk
                                      : CScholarColors.cyanInk,
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
                                          if ((thesis.program?.name ?? '').isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: CScholarMaterial.clayDeep,
                                                borderRadius: BorderRadius.circular(CScholarRadius.sm),
                                                border: Border.all(color: CScholarMaterial.rim),
                                              ),
                                              child: Text(
                                                thesis.program!.name,
                                                style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary),
                                              ),
                                            ),
                                          if ((thesis.program?.name ?? '').isNotEmpty &&
                                              (thesis.academicYear?.label ?? '').isNotEmpty)
                                            const SizedBox(width: 8),
                                          if ((thesis.academicYear?.label ?? '').isNotEmpty)
                                            Text(
                                              thesis.academicYear!.label,
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
                  loading: () => const SkeletonList(count: 3, cardHeight: 96),
                  error: (err, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to load saved studies',
                    message: err.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(savedThesesProvider),
                  ),
                ),
                const CScholarFooter(),
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
}
