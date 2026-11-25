import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_widgets.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

class SavedThesesScreen extends ConsumerStatefulWidget {
  const SavedThesesScreen({super.key});

  @override
  ConsumerState<SavedThesesScreen> createState() => _SavedThesesScreenState();
}

class _SavedThesesScreenState extends ConsumerState<SavedThesesScreen> {
  static const _tabs = ['All', 'Thesis', 'Capstone'];

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
                  subtitle:
                      'Your bookmarked research studies and reference papers',
                  action: NeumorphButton(
                    onPressed: () => context.go('/repository'),
                    icon: Icons.search,
                    label: 'Find More',
                  ),
                ),

                const SizedBox(height: 24),

                NeumorphSegmented(
                  labels: _tabs,
                  selectedIndex: _tabs.indexOf(_selectedTab),
                  onChanged: (i) => setState(() => _selectedTab = _tabs[i]),
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
                          .where(
                            (t) =>
                                t.researchType.toLowerCase() ==
                                _selectedTab.toLowerCase(),
                          )
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return _emptyState(
                        mobile: false,
                        hasSaved: saved.isNotEmpty,
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
                                  // tile-exempt: ThesisCover paints its own
                                  // illustration, so it is not an icon tile.
                                  // Same thesis cover as the research page: green
                                  // gel tile with the article glyph, scaled down
                                  // to this row's 60px slot.
                                  ThesisCover(
                                    seed: thesis.id,
                                    width: 60,
                                    height: 60,
                                    borderRadius: 16,
                                    iconSize: 26,
                                  ),
                                  const SizedBox(width: 18),

                                  // Title & Meta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () => context.go(
                                            '/thesis/${thesis.id}',
                                          ),
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
                                            if ((thesis.program?.name ?? '')
                                                .isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      CScholarMaterial.clayDeep,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        CScholarRadius.sm,
                                                      ),
                                                  border: Border.all(
                                                    color: CScholarMaterial.rim,
                                                  ),
                                                ),
                                                child: Text(
                                                  thesis.program!.name,
                                                  style:
                                                      CScholarTextStyles.body(
                                                        11,
                                                        FontWeight.w700,
                                                        CScholarColors
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ),
                                            if ((thesis.program?.name ?? '')
                                                    .isNotEmpty &&
                                                (thesis.academicYear?.label ??
                                                        '')
                                                    .isNotEmpty)
                                              const SizedBox(width: 8),
                                            if ((thesis.academicYear?.label ??
                                                    '')
                                                .isNotEmpty)
                                              Text(
                                                thesis.academicYear!.label,
                                                style: CScholarTextStyles.body(
                                                  12,
                                                  FontWeight.w500,
                                                  CScholarColors.textMuted,
                                                ),
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
                                        onPressed: () =>
                                            context.go('/thesis/${thesis.id}'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              CScholarColors.primaryGreen,
                                          backgroundColor: CScholarColors
                                              .primaryGreenVeryLight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              CScholarRadius.md,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'View',
                                          style: CScholarTextStyles.body(
                                            12.5,
                                            FontWeight.w600,
                                            CScholarColors.primaryGreen,
                                          ),
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
                                            ref
                                                .read(
                                                  savedThesisIdsProvider
                                                      .notifier,
                                                )
                                                .toggle(thesis.id);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Removed "${thesis.title}" from saved studies',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: Icons.bookmark_outline,
                                          selectedIcon: Icons.bookmark,
                                          semanticLabel:
                                              'Saved — tap to remove',
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
                    message: userFacingError(
                      err,
                      fallback:
                          'Your saved studies could not be loaded. Try again.',
                    ),
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

  /// Selectable pill for the mobile filter sheet — same geometry as the
  /// repository sheet, so both filters read as one system.
  Widget _mobileChoicePill(
    CScholarMobileTheme t,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        // The chip itself stays compact; this transparent padding keeps the
        // whole pill a comfortable 44px touch target.
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Container(
          // No `alignment` here: an aligned Container expands to the max
          // width it is offered, which turns each pill in the Wrap into a
          // full-width row. Center with widthFactor keeps the label centered
          // while the pill stays intrinsic.
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? t.green : t.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? t.green : t.line),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: t.dmSans(
                10,
                FontWeight.w700,
                // Dark mode's green is a light mint accent, so white on it is
                // unreadable: selected pills flip to ink there.
                active
                    ? (t.isDark
                          ? CScholarMobileColors.ink
                          : CScholarColors.white)
                    : t.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The mint "Filters" pill from the search page.
  Widget _mobileFilterPill(CScholarMobileTheme t) {
    final active = _selectedTab == 'All' ? 0 : 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: t.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 17, color: t.green),
          const SizedBox(width: 5),
          Text(
            'Filters${active > 0 ? ' ($active)' : ''}',
            style: t.dmSans(10, FontWeight.w700, t.green),
          ),
        ],
      ),
    );
  }

  /// Same bottom sheet as the search page: draft the choice locally, then
  /// commit it with "Show saved". Only the research type applies here — the
  /// saved list is already a personal subset.
  void _showMobileFilterSheet(BuildContext context) {
    var type = _selectedTab;
    MobileFilterSheet.show<void>(
      context,
      StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final t = CScholarMobileTheme.of(sheetContext);
          final ctaFill = t.green;
          final ctaInk = t.isDark
              ? CScholarMobileColors.ink
              : CScholarColors.white;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your library', style: t.eyebrow),
                      const SizedBox(height: 3),
                      Text(
                        'Filters',
                        style: t.manrope(23, FontWeight.w700, t.ink),
                      ),
                    ],
                  ),
                  Semantics(
                    button: true,
                    label: 'Close filters',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: SizedBox(
                          width: CScholarTapTarget.minimum,
                          height: CScholarTapTarget.minimum,
                          child: Center(
                            child: Container(
                              // tile-exempt: bottom-sheet close affordance.
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: t.surfaceSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: t.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESEARCH TYPE', style: t.eyebrow),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 0,
                      children: [
                        for (final option in _tabs)
                          _mobileChoicePill(
                            t,
                            option,
                            option == type,
                            () => setSheet(() => type = option),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setSheet(() => type = 'All'),
                    child: Text(
                      'Clear all',
                      style: t.dmSans(11, FontWeight.w700, t.muted),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = type);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ctaFill,
                          borderRadius: BorderRadius.circular(
                            CScholarMobileRadius.cta,
                          ),
                        ),
                        child: Text(
                          'Show saved',
                          style: t.dmSans(11, FontWeight.w800, ctaInk),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Empty panel for the current tab.
  ///
  /// Two different situations share this slot: a reader with no bookmarks at
  /// all (send them to the repository) and a reader whose bookmarks are all in
  /// another bucket (send them back to All, instead of implying nothing is
  /// saved and hiding the filter that caused it).
  Widget _emptyState({required bool mobile, required bool hasSaved}) {
    if (!hasSaved) {
      return EmptyState(
        mobile: mobile,
        icon: Icons.bookmark_border,
        title: 'No saved studies',
        message: 'Browse the repository to save research papers and capstone projects for later reference.',
        actionLabel: 'Browse Repository',
        onAction: () => context.go('/repository'),
      );
    }
    return EmptyState(
      mobile: mobile,
      icon: Icons.filter_list_off,
      title: switch (_selectedTab) {
        'Thesis' => 'No saved theses',
        'Capstone' => 'No saved capstones',
        _ => 'No saved studies',
      },
      message: 'Your saved studies are filed under another type.',
      actionLabel: 'Show all saved',
      onAction: () => setState(() => _selectedTab = 'All'),
    );
  }

  /// Mobile Saved (`cscholar-mobile-ui/src/App.tsx:839-878`): page intro
  /// + card stack or tall empty state. Same `savedThesesProvider` and tab
  /// filter — only the layout is prototype-skinned.
  Widget _mobileBody(
    BuildContext context,
    AsyncValue<List<dynamic>> savedTheses,
  ) {
    final t = CScholarMobileTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
      child: StaggerColumn(
        pitch: MotionPitch.page,
        children: [
          Text('Your library', style: t.eyebrow),
          const SizedBox(height: 7),
          Text('Saved research.', style: t.pageTitle),
          const SizedBox(height: 7),
          Text('Keep important work close at hand.', style: t.bodyMuted),
          const SizedBox(height: 16),
          // Search-page pattern: a saved count on the left, the mint Filters
          // pill on the right, and a bottom sheet for the research type.
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${savedTheses.value?.length ?? 0} ',
                        style: t.dmSans(11, FontWeight.w700, t.ink),
                      ),
                      TextSpan(
                        text: (savedTheses.value?.length ?? 0) == 1
                            ? 'saved study'
                            : 'saved studies',
                        style: t.dmSans(11, FontWeight.w400, t.muted),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _showMobileFilterSheet(context),
                child: _mobileFilterPill(t),
              ),
            ],
          ),
          const SizedBox(height: 12),
          asyncSlot<List<dynamic>>(
            savedTheses,
            skeleton: const SkeletonList(count: 3, cardHeight: 96),
            data: (saved) {
              var filtered = saved;
              if (_selectedTab != 'All') {
                filtered = filtered
                    .where(
                      (t) =>
                          t.researchType.toLowerCase() ==
                          _selectedTab.toLowerCase(),
                    )
                    .toList();
              }
              if (filtered.isEmpty) {
                // Same panel and copy as the web Saved page — the mobile skin
                // only swaps the material.
                return _emptyState(mobile: true, hasSaved: saved.isNotEmpty);
              }
              return Column(
                key: ValueKey(filtered.map((t) => t.id).join(',')),
                children: [
                  for (var i = 0; i < filtered.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
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
                              onOpen: () => context.go('/thesis/${thesis.id}'),
                              onSave: () {
                                ref
                                    .read(savedThesisIdsProvider.notifier)
                                    .toggle(thesis.id);
                                MobileToast.show(
                                  context,
                                  'Removed "${thesis.title}" from saved',
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              mobile: true,
              icon: Icons.error_outline,
              title: 'Unable to load saved studies',
              message: userFacingError(
                err,
                fallback: 'Your saved studies could not be loaded. Try again.',
              ),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(savedThesesProvider),
            ),
          ),
        ],
      ),
    );
  }
}
