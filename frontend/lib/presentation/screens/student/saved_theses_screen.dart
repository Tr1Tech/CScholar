import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_widgets.dart';
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

    if (MobileStudentScaffold.useMobileShell(context)) {
      return StudentLayout(
        currentIndex: 2,
        child: _mobileBody(context, savedTheses),
      );
    }

    return StudentLayout(
      currentIndex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1040),
            // PART 7: header at 0, the list walks on the result pitch. (Removing
            // a saved item re-forms the list in Phase 7 — here items only
            // know how to arrive.)
            child: StaggerColumn(
              pitch: MotionPitch.page,
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

                NeumorphSegmented(
                  labels: const ['All', 'Thesis', 'Capstone'],
                  selectedIndex: ['All', 'Thesis', 'Capstone']
                      .indexOf(_selectedTab),
                  onChanged: (i) => setState(() =>
                      _selectedTab = ['All', 'Thesis', 'Capstone'][i]),
                ),

                const SizedBox(height: 24),

                // Studies Cards List
                asyncSlot(
                  savedTheses,
                  skeleton: const SkeletonList(count: 3, cardHeight: 96),
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

                    // Keyed on the surviving ids: removing one rebuilds the rest
                    // fresh, so the list re-forms (result cascade replays)
                    // instead of closing the gap instantly.
                    return ListView.builder(
                      key: ValueKey(filtered.map((t) => t.id).join(',')),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final thesis = filtered[i];
                        final isTeal = i % 2 == 0;

                        // Saved studies step on the result pitch, same walk as
                        // every thesis result list.
                        return Stagger(
                          index: i,
                          step: MotionPitch.result.step,
                          max: MotionPitch.result.max,
                          rise: MotionPitch.result.rise,
                          child: Padding(
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
                                          style: CScholarTextStyles.heading(
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
                                                style: CScholarTextStyles.body(11, FontWeight.w700, CScholarColors.textSecondary),
                                              ),
                                            ),
                                          if ((thesis.program?.name ?? '').isNotEmpty &&
                                              (thesis.academicYear?.label ?? '').isNotEmpty)
                                            const SizedBox(width: 8),
                                          if ((thesis.academicYear?.label ?? '').isNotEmpty)
                                            Text(
                                              thesis.academicYear!.label,
                                              style: CScholarTextStyles.body(12, FontWeight.w500, CScholarColors.textMuted),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Actions: View & Save toggle. The toggle
                                // reads selected (everything here IS saved);
                                // tapping it unsaves, the row leaves, and the
                                // keyed list above re-forms the survivors
                                // instead of closing the gap instantly.
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
                                        style: CScholarTextStyles.body(12.5, FontWeight.w600, CScholarColors.primaryGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: 'Saved — tap to remove',
                                      // The toggle already announces this.
                                      excludeFromSemantics: true,
                                      child: TactileToggle(
                                        selected: true,
                                        onChanged: () {
                                          ref.read(savedThesisIdsProvider.notifier).toggle(thesis.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Removed "${thesis.title}" from saved studies')),
                                          );
                                        },
                                        icon: Icons.bookmark_outline,
                                        selectedIcon: Icons.bookmark,
                                        semanticLabel: 'Saved — tap to remove',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        );
                      },
                    );
                  },
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

  /// Mobile Saved (`cscholar-mobile-ui/src/App.tsx:839-878`): page intro
  /// + card stack or tall empty state. Same `savedThesesProvider` and tab
  /// filter — only the layout is prototype-skinned.
  Widget _mobileBody(
      BuildContext context, AsyncValue<List<dynamic>> savedTheses) {
    final t = CScholarMobileTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
      child: StaggerColumn(
        pitch: MotionPitch.page,
        children: [
          Text('Your library',
              style: t.eyebrow),
          const SizedBox(height: 7),
          Text('Saved research.',
              style: t.pageTitle),
          const SizedBox(height: 7),
          Text('Keep important work close at hand.',
              style: t.bodyMuted),
          const SizedBox(height: 22),
          asyncSlot<List<dynamic>>(
            savedTheses,
            skeleton:
                const SkeletonList(count: 3, cardHeight: 96),
            data: (saved) {
              var filtered = saved;
              if (_selectedTab != 'All') {
                filtered = filtered
                    .where((t) =>
                        t.researchType.toLowerCase() ==
                        _selectedTab.toLowerCase())
                    .toList();
              }
              if (filtered.isEmpty) {
                // Same panel, copy and action as the web Saved page — the
                // mobile skin only swaps the material.
                return EmptyState(
                  mobile: true,
                  icon: Icons.bookmark_border,
                  title: 'No saved studies',
                  message:
                      'Browse the repository to save research papers and capstone projects for later reference.',
                  actionLabel: 'Browse Repository',
                  onAction: () => context.go('/repository'),
                );
              }
              return Column(
                key: ValueKey(
                    filtered.map((t) => t.id).join(',')),
                children: [
                  for (var i = 0;
                      i < filtered.length;
                      i++)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 11),
                      child: Stagger(
                        index: i,
                        step: MotionPitch.result.step,
                        max: MotionPitch.result.max,
                        rise: MotionPitch.result.rise,
                        child: Builder(
                            builder: (context) {
                          final thesis = filtered[i];
                          return MobileThesisCard(
                            thesis: thesis,
                            saved: true,
                            onOpen: () => context.go(
                                '/thesis/${thesis.id}'),
                            onSave: () {
                              ref
                                  .read(savedThesisIdsProvider
                                      .notifier)
                                  .toggle(thesis.id);
                              MobileToast.show(context,
                                  'Removed "${thesis.title}" from saved');
                            },
                          );
                        }),
                      ),
                    ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              mobile: true,
              icon: Icons.error_outline,
              title: 'Unable to load saved studies',
              message: err.toString(),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(savedThesesProvider),
            ),
          ),
        ],
      ),
    );
  }

}
