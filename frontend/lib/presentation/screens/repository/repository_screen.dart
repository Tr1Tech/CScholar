import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/common/clay_pagination.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_widgets.dart';
import 'package:frontend/presentation/widgets/result_card.dart';
import 'package:frontend/presentation/widgets/rec_rail.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

/// Ten result cards a page on both the web list and the mobile stack — the same
/// page size the admin tables use, and enough for one comfortable screen of
/// reading before the pager.
const int _kRepositoryPageSize = 10;

/// Research repository: light control header (title, search, quick topics,
/// filters) over the results list with the AI rail.
/// Semantic mode can be preselected via `?mode=semantic`.
class RepositoryScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final bool initialSemantic;
  const RepositoryScreen({
    super.key,
    this.initialQuery,
    this.initialSemantic = false,
  });

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final _searchController = TextEditingController();
  final _heroController = TextEditingController();
  final _keywordController = TextEditingController();
  String _query = '';
  String _keyword = '';
  bool _isSemantic = false;
  int? _selectedProgramId;
  int? _selectedYearId;
  int? _selectedCategoryId;
  String? _selectedType;
  String _sortBy = 'Latest';
  Timer? _debounce;

  /// Records the query only after the reader has stopped typing, so "machine"
  /// is not saved three times on the way to "machine learning".
  Timer? _recentTimer;

  /// 0-based repository page. Reset to 0 whenever the result-defining filters
  /// change (see [_lastFilterSignature]) so a new search never starts on
  /// page 4 of its own results.
  int _page = 0;
  String _lastFilterSignature = '';

  // The AI rail pins inside this row: the row's bottom is where floating stops.
  final GlobalKey _resultsRowKey = GlobalKey();

  /// Top of the result list. A page change scrolls back to it, so "Next" on
  /// either shell lands on the first card of the new page, not its footer.
  final GlobalKey _resultsTopKey = GlobalKey();

  void _goToPage(int page) {
    setState(() => _page = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _resultsTopKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: motionEnabled(context) ? CScholarMotion.swap : Duration.zero,
        curve: CScholarCurves.standard,
        alignment: 0.02,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _isSemantic = widget.initialSemantic;
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _query = widget.initialQuery!.trim();
      _searchController.text = _query;
      _heroController.text = _query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _recentTimer?.cancel();
    _searchController.dispose();
    _heroController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedProgramId != null) count++;
    if (_selectedYearId != null) count++;
    if (_selectedCategoryId != null) count++;
    if (_selectedType != null) count++;
    if (_keyword.isNotEmpty) count++;
    return count;
  }

  void _clearFilters() {
    _recentTimer?.cancel();
    setState(() {
      _selectedProgramId = null;
      _selectedYearId = null;
      _selectedCategoryId = null;
      _selectedType = null;
      _keyword = '';
      _keywordController.clear();
      _searchController.clear();
      _heroController.clear();
      _query = '';
      _sortBy = 'Latest';
    });
  }

  /// Selectable pill for the mobile filter sheet — same geometry as the
  /// keyword tags on a result card, so the sheet reads as the same system.
  /// Mobile tokens, not [ClayChip]: the sheet sits on the mobile paper/clay
  /// pair, and the desktop chip's hard-coded clay would go white on dark.
  Widget _mobileChoicePill(
    CScholarMobileTheme t,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? t.green : t.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? t.green : t.line),
        ),
        child: Text(
          label,
          style: t.dmSans(
            10,
            FontWeight.w700,
            // Dark mode's "green" is a light mint accent, so white on it is
            // unreadable: selected pills flip to ink there.
            active
                ? (t.isDark ? CScholarMobileColors.ink : CScholarColors.white)
                : t.muted,
          ),
        ),
      ),
    );
  }

  /// Adds [q] to the device's recent searches. Called immediately on submit
  /// and from the typing timer below, so a live search still counts even when
  /// the reader never presses Enter.
  void _recordSearch(String q) {
    _recentTimer?.cancel();
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    ref.read(recentSearchesProvider.notifier).record(trimmed);
  }

  void _scheduleSearchRecord(String q) {
    _recentTimer?.cancel();
    if (q.trim().isEmpty) return;
    _recentTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _recordSearch(q);
    });
  }

  void _submitHero() {
    _debounce?.cancel();
    final q = _heroController.text.trim();
    setState(() {
      _query = q;
      _searchController.text = q;
    });
    _recordSearch(q);
  }

  /// Live search: results filter while typing (debounced so we don't
  /// hammer the API — and the embedding model — on every keystroke).
  void _onHeroChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final q = v.trim();
      if (q != _query) setState(() => _query = q);
      _scheduleSearchRecord(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Normalise the page here, before the provider read, so a theses provider
    // is never queried for a page that the old filter set produced.
    final filterSignature = _filterSignature;
    if (_lastFilterSignature != filterSignature) {
      _lastFilterSignature = filterSignature;
      _page = 0;
    }

    final useSemantic = _isSemantic && _query.trim().isNotEmpty;
    final theses = ref.watch(thesisPageProvider(_pageParams));
    final semantic = useSemantic
        ? ref.watch(semanticSearchProvider(_query.trim()))
        : const AsyncValue<List<SemanticResult>>.data([]);
    final savedIds = ref.watch(savedThesisIdsProvider);

    if (MobileStudentScaffold.useMobileShell(context)) {
      return StudentLayout(
        currentIndex: 1,
        child: _mobileBody(
          context,
          useSemantic: useSemantic,
          theses: theses,
          semantic: semantic,
          savedIds: savedIds,
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isWide = size.width > CScholarBreakpoints.mobile;

    return StudentLayout(
      currentIndex: 1,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: 24,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: StaggerColumn(
                    pitch: MotionPitch.page,
                    children: [
                      // Control header opens the page: title, search and
                      // filters in one light card — no full-bleed hero.
                      EntranceReveal(
                        rise: 0,
                        child: _controlHeader(context, isWide),
                      ),
                      const SizedBox(height: 20),
                      _resultsColumn(
                        context,
                        useSemantic,
                        theses,
                        semantic,
                        savedIds,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const CScholarFooter(),
          ],
        ),
      ),
    );
  }

  /// Mobile Search (`cscholar-mobile-ui/src/App.tsx:673-747` + sheet
  /// `App.tsx:519-566`): page intro, search field, 4 topic chips,
  /// results heading + Filters button, card stack. Same query/debounce,
  /// filters, and providers — only the layout is prototype-skinned.
  Widget _mobileBody(
    BuildContext context, {
    required bool useSemantic,
    required AsyncValue<ThesisPage> theses,
    required AsyncValue<List<SemanticResult>> semantic,
    required Set<int> savedIds,
  }) {
    final t = CScholarMobileTheme.of(context);
    if (_searchController.text != _query) {
      _searchController.text = _query;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
      child: StaggerColumn(
        pitch: MotionPitch.page,
        children: [
          Text('University repository', style: t.eyebrow),
          const SizedBox(height: 7),
          Text('Find your next idea.', style: t.pageTitle),
          const SizedBox(height: 22),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 19, color: t.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 450), () {
                        if (!mounted) return;
                        final q = v.trim();
                        if (q != _query) {
                          setState(() => _query = q);
                        }
                        _scheduleSearchRecord(q);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search research',
                      hintStyle: t.dmSans(13, FontWeight.w400, t.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    style: t.dmSans(13, FontWeight.w400, t.ink),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _recentTimer?.cancel();
                      setState(() {
                        _query = '';
                        _searchController.clear();
                      });
                    },
                    child: Icon(Icons.close, size: 17, color: t.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search mode. The desktop header owns this toggle; the mobile shell
          // has no equivalent chrome, and semantic ranking is the feature to
          // show — so it gets a first-class control here.
          _mobileModeToggle(context, t),
          if (_isSemantic && _query.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: t.green2),
                  const SizedBox(width: 5),
                  Text('Type a query to rank by meaning', style: t.caption),
                ],
              ),
            ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                for (final topic in [
                  'AI',
                  'Sustainability',
                  'Accessibility',
                  'Data privacy',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _query = topic;
                          _searchController.text = topic;
                        });
                        _recordSearch(topic);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: t.line),
                        ),
                        child: Text(
                          topic,
                          style: t.dmSans(9, FontWeight.w700, t.muted),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            key: _resultsTopKey,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Count whichever list is on screen: keyword results normally,
              // semantic matches when ranking by meaning. Flexible: at 200%
              // text the count and the Filters pill have to share one row.
              Flexible(
                child: Builder(
                  builder: (context) {
                    final count = useSemantic
                        ? semantic.maybeWhen(
                            data: (r) => r.length,
                            orElse: () => null,
                          )
                        : theses.maybeWhen(
                            data: (page) => page.total,
                            orElse: () => null,
                          );
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${count ?? 0} ',
                            style: t.dmSans(11, FontWeight.w700, t.ink),
                          ),
                          TextSpan(
                            text: 'results',
                            style: t.dmSans(11, FontWeight.w400, t.muted),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Sheet-local drafts: picking a chip rewrites the draft, and
                  // only "Show results" commits it to the screen.
                  var type = _selectedType;
                  var program = _selectedProgramId;
                  var year = _selectedYearId;
                  var category = _selectedCategoryId;

                  MobileFilterSheet.show<void>(
                    context,
                    StatefulBuilder(
                      builder: (sheetContext, setSheet) {
                        final t = CScholarMobileTheme.of(sheetContext);

                        Widget group<T>(
                          String label,
                          List<(String, T?)> options,
                          T? selected,
                          ValueChanged<T?> onPick,
                        ) {
                          if (options.length <= 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label.toUpperCase(), style: t.eyebrow),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: [
                                    for (final (name, value) in options)
                                      _mobileChoicePill(
                                        t,
                                        name,
                                        value == selected,
                                        () => setSheet(() => onPick(value)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        void apply() {
                          setState(() {
                            _selectedType = type;
                            _selectedProgramId = program;
                            _selectedYearId = year;
                            _selectedCategoryId = category;
                          });
                          Navigator.of(sheetContext).pop();
                        }

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
                                    Text('Refine results', style: t.eyebrow),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Filters',
                                      style: t.manrope(
                                        23,
                                        FontWeight.w700,
                                        t.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(sheetContext).pop(),
                                  // tile-exempt: bottom-sheet close affordance.
                                  child: Container(
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
                              ],
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 360),
                              child: SingleChildScrollView(
                                // Watched here, not read once at open: the
                                // mobile shell never builds the desktop filter
                                // row, so these lists have no other subscriber
                                // and would stay empty on the first tap.
                                child: Consumer(
                                  builder: (context, filterRef, _) {
                                    final programs =
                                        filterRef
                                            .watch(programsProvider)
                                            .value ??
                                        const <Program>[];
                                    final years =
                                        filterRef
                                            .watch(academicYearsProvider)
                                            .value ??
                                        const <AcademicYear>[];
                                    final categories =
                                        filterRef
                                            .watch(categoriesProvider)
                                            .value ??
                                        const <Category>[];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        group<String>(
                                          'Research type',
                                          [
                                            ('All', null),
                                            ('Thesis', 'Thesis'),
                                            ('Capstone', 'Capstone'),
                                          ],
                                          type,
                                          (v) => type = v,
                                        ),
                                        group<int>(
                                          'Program',
                                          [
                                            ('All', null),
                                            for (final p in programs)
                                              (p.name, p.id),
                                          ],
                                          program,
                                          (v) => program = v,
                                        ),
                                        group<int>(
                                          'Academic year',
                                          [
                                            ('All', null),
                                            for (final y in years)
                                              (y.label, y.id),
                                          ],
                                          year,
                                          (v) => year = v,
                                        ),
                                        group<int>(
                                          'Category',
                                          [
                                            ('All', null),
                                            for (final c in categories)
                                              (c.name, c.id),
                                          ],
                                          category,
                                          (v) => category = v,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setSheet(() {
                                    type = null;
                                    program = null;
                                    year = null;
                                    category = null;
                                  }),
                                  child: Text(
                                    'Clear all',
                                    style: t.dmSans(
                                      11,
                                      FontWeight.w700,
                                      t.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: apply,
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
                                        'Show results',
                                        style: t.dmSans(
                                          11,
                                          FontWeight.w800,
                                          ctaInk,
                                        ),
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
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: t.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 17, color: t.green),
                      const SizedBox(width: 5),
                      Text(
                        'Filters${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}',
                        style: t.dmSans(10, FontWeight.w700, t.green),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileResults(context, useSemantic, theses, semantic, savedIds),
        ],
      ),
    );
  }

  /// Two-way search mode control in the mobile skin: a soft track with the
  /// active segment seated on the surface. Semantic is the demo path — it
  /// swaps keyword ranking for embedding similarity (with match scores).
  Widget _mobileModeToggle(BuildContext context, CScholarMobileTheme t) {
    Widget segment(
      String label,
      bool active,
      IconData? icon,
      VoidCallback onTap,
    ) {
      return Semantics(
        button: true,
        selected: active,
        label: '$label search',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: motionDuration(context, CScholarDurations.fast),
            curve: CScholarCurves.standard,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? t.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? t.line : Colors.transparent),
              boxShadow: active ? CScholarMobileShadows.card : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: active ? t.green : t.muted),
                  const SizedBox(width: 5),
                ],
                // Flexible, not a bare Text: a Row hands non-flex children
                // unbounded width, so at 200% text the label overflowed the
                // segment instead of ellipsizing.
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.dmSans(
                      10,
                      FontWeight.w700,
                      active ? t.ink : t.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: segment(
              'Normal',
              !_isSemantic,
              null,
              () => setState(() => _isSemantic = false),
            ),
          ),
          Expanded(
            child: segment(
              'Semantic',
              _isSemantic,
              Icons.auto_awesome,
              () => setState(() => _isSemantic = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileResults(
    BuildContext context,
    bool useSemantic,
    AsyncValue<ThesisPage> theses,
    AsyncValue<List<SemanticResult>> semantic,
    Set<int> savedIds,
  ) {
    if (useSemantic) {
      return asyncSlot<List<SemanticResult>>(
        semantic,
        skeleton: Column(
          children: [
            for (var i = 0; i < 4; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 11),
                child: SkeletonList(count: 1, cardHeight: 96),
              ),
          ],
        ),
        data: (results) {
          final filtered = _filterSemanticResults(results);
          if (filtered.isEmpty) {
            return _mobileEmpty(context, semantic: true);
          }
          return Column(
            key: ValueKey(_resultSignature),
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
                        final r = filtered[i];
                        return MobileThesisCard(
                          thesis: r.thesis,
                          saved: savedIds.contains(r.thesis.id),
                          matchPercent: (r.similarity * 100).round(),
                          onOpen: () => context.go(
                            '/thesis/${r.thesis.id}',
                            extra: r.similarity,
                          ),
                          onSave: () => ref
                              .read(savedThesisIdsProvider.notifier)
                              .toggle(r.thesis.id),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
        error: (err, _) => _mobileEmpty(
          context,
          message: err.toString(),
          error: true,
          semantic: true,
        ),
      );
    }
    return asyncSlot<ThesisPage>(
      theses,
      skeleton: Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 11),
              child: SkeletonList(count: 1, cardHeight: 96),
            ),
        ],
      ),
      data: (page) {
        final list = page.theses;
        if (list.isEmpty) {
          return _mobileEmpty(context);
        }
        return Column(
          key: ValueKey(_resultSignature),
          children: [
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Stagger(
                  index: i,
                  step: MotionPitch.result.step,
                  max: MotionPitch.result.max,
                  rise: MotionPitch.result.rise,
                  child: Builder(
                    builder: (context) {
                      final t = list[i];
                      return MobileThesisCard(
                        thesis: t,
                        saved: savedIds.contains(t.id),
                        onOpen: () => context.go('/thesis/${t.id}'),
                        onSave: () => ref
                            .read(savedThesisIdsProvider.notifier)
                            .toggle(t.id),
                      );
                    },
                  ),
                ),
              ),
            _mobilePager(context, page),
          ],
        );
      },
      error: (err, _) =>
          _mobileEmpty(context, message: err.toString(), error: true),
    );
  }

  /// Mobile pager in the shell's own material: a count line over two round
  /// chevrons. Ten cards a page, same as the web list.
  Widget _mobilePager(BuildContext context, ThesisPage page) {
    if (page.pages <= 1) return const SizedBox.shrink();
    final t = CScholarMobileTheme.of(context);
    final canGoBack = page.page > 1;
    final canGoForward = page.page < page.pages;
    final first = (page.page - 1) * page.pageSize + 1;
    final last = page.page * page.pageSize > page.total
        ? page.total
        : page.page * page.pageSize;

    Widget chevron(IconData icon, bool enabled, VoidCallback onTap) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          // tile-exempt: round pager chevron, not an icon tile.
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: enabled ? t.surfaceSoft : t.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line),
          ),
          child: Icon(icon, size: 18, color: enabled ? t.ink : t.muted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(
        children: [
          Text('Showing $first–$last of ${page.total}', style: t.caption),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              chevron(
                Icons.chevron_left,
                canGoBack,
                () => _goToPage(page.page - 2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Page ${page.page} of ${page.pages}',
                  style: t.dmSans(11, FontWeight.w700, t.ink),
                ),
              ),
              chevron(
                Icons.chevron_right,
                canGoForward,
                () => _goToPage(page.page),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileEmpty(
    BuildContext context, {
    String? message,
    bool error = false,
    bool semantic = false,
  }) {
    // Mirrors the web results column: same copy, same action (Reset/Retry),
    // same empty panel — only the material switches to the mobile skin.
    return EmptyState(
      mobile: true,
      icon: error ? Icons.error_outline : Icons.search_off,
      title: error
          ? (semantic ? 'Semantic search error' : 'Could not load studies')
          : 'No studies found matching your filters',
      message: error
          ? message
          : (message ?? 'Try a broader keyword or clear your filters.'),
      actionLabel: error ? 'Retry' : 'Reset all filters',
      onAction: error
          ? () {
              if (semantic) {
                ref.invalidate(semanticSearchProvider(_query.trim()));
              } else {
                ref.invalidate(thesisPageProvider(_pageParams));
              }
            }
          : _clearFilters,
    );
  }

  /// Everything that defines the result set, excluding the page. Changing any
  /// of it starts a new set, so [_page] resets before the next provider read.
  String get _filterSignature =>
      '$_query|$_selectedProgramId|'
      '$_selectedYearId|$_selectedCategoryId|$_keyword|$_sortBy|'
      '$_selectedType|$_isSemantic';

  /// Signature of the page on screen. Keying the result columns on it makes a
  /// new query, filter, sort, mode flip or page build a FRESH subtree, so the
  /// result cascade replays and the list reads as re-forming instead of
  /// popping in place.
  String get _resultSignature => '$_filterSignature|p$_page';

  ThesisListParams get _pageParams => ThesisListParams(
    query: _query.isEmpty ? null : _query,
    programId: _selectedProgramId,
    academicYearId: _selectedYearId,
    categoryId: _selectedCategoryId,
    keyword: _keyword.isEmpty ? null : _keyword,
    sortBy: _sortBy,
    researchType: _selectedType,
    page: _page + 1,
    pageSize: _kRepositoryPageSize,
  );

  /// Results list, with the AI rail beside it on wide screens.
  /// Rail and list scroll together as one column — no nested scroll views.
  Widget _resultsColumn(
    BuildContext context,
    bool useSemantic,
    AsyncValue<ThesisPage> theses,
    AsyncValue<List<SemanticResult>> semantic,
    Set<int> savedIds,
  ) {
    final list = StaggerColumn(
      // Page rhythm for the header block; the result rows below cascade on
      // the result pitch, and the rail glides in from the right.
      pitch: MotionPitch.page,
      children: [
        KeyedSubtree(
          key: _resultsTopKey,
          child: _resultsHeader(context, useSemantic, theses),
        ),
        const SizedBox(height: 16),
        if (useSemantic)
          asyncSlot<List<SemanticResult>>(
            semantic,
            // Silhouette skeletons: banner block + text lines + tag row, the
            // same box the cards land in, so the cross-fade is the only
            // movement at the swap — the page never jumps.
            skeleton: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: ThesisSkeleton(),
                  ),
              ],
            ),
            data: (results) {
              if (results.isEmpty) {
                return Column(
                  key: ValueKey(_resultSignature),
                  children: [_semanticUnavailableNote(), _noResultsFound()],
                );
              }
              final filtered = _filterSemanticResults(results);
              if (filtered.isEmpty) {
                return Column(
                  key: ValueKey(_resultSignature),
                  children: [_noResultsFound()],
                );
              }
              return Column(
                // Thesis results step on the result pitch: long enough to be
                // seen, clamped hard so forty results never crawl. Keyed on
                // the result signature, so every re-form replays the landing.
                key: ValueKey(_resultSignature),
                children: [
                  for (var i = 0; i < filtered.length; i++)
                    Stagger(
                      index: i,
                      step: MotionPitch.result.step,
                      max: MotionPitch.result.max,
                      rise: MotionPitch.result.rise,
                      // New batches settle (0.98), not just fade.
                      scaleFrom: 0.98,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ResultCard(
                          thesis: filtered[i].thesis,
                          isSaved: savedIds.contains(filtered[i].thesis.id),
                          similarity: filtered[i].similarity,
                          onToggleSave: () => ref
                              .read(savedThesisIdsProvider.notifier)
                              .toggle(filtered[i].thesis.id),
                        ),
                      ),
                    ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Semantic search error',
              message: err.toString(),
              actionLabel: 'Retry',
              onAction: () =>
                  ref.invalidate(semanticSearchProvider(_query.trim())),
            ),
          )
        else
          asyncSlot<ThesisPage>(
            theses,
            // Same silhouette skeletons as the semantic branch.
            skeleton: Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: ThesisSkeleton(),
                  ),
              ],
            ),
            data: (page) {
              final list = page.theses;
              if (list.isEmpty) {
                return Column(
                  key: ValueKey(_resultSignature),
                  children: [_noResultsFound()],
                );
              }
              return Column(
                // Same result rhythm for the keyword branch: both result lists
                // read as one re-forming cascade, never a pop-in.
                key: ValueKey(_resultSignature),
                children: [
                  for (var i = 0; i < list.length; i++)
                    Stagger(
                      index: i,
                      step: MotionPitch.result.step,
                      max: MotionPitch.result.max,
                      rise: MotionPitch.result.rise,
                      // New batches settle (0.98), not just fade.
                      scaleFrom: 0.98,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ResultCard(
                          thesis: list[i],
                          isSaved: savedIds.contains(list[i].id),
                          onToggleSave: () => ref
                              .read(savedThesisIdsProvider.notifier)
                              .toggle(list[i].id),
                        ),
                      ),
                    ),
                  ClayPagination(
                    page: page.page,
                    total: page.total,
                    pageSize: page.pageSize,
                    padding: const EdgeInsets.only(top: 2),
                    onPageChanged: (p) => _goToPage(p - 1),
                  ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load studies',
              message: err.toString(),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(thesisPageProvider(_pageParams)),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 900) return list;
        return Row(
          key: _resultsRowKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: list),
            const SizedBox(width: 20),
            // The rail arrives on the page rhythm with the same fade + rise
            // as every other block — one entrance language, never a sidebar
            // sliding in from the side while the list rises.
            Expanded(
              flex: 5,
              child: _StickyRail(
                rowKey: _resultsRowKey,
                child: Stagger(
                  index: 0,
                  step: MotionPitch.page.step,
                  max: MotionPitch.page.max,
                  rise: MotionPitch.page.rise,
                  child: RecRail(query: _query),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Seated state for the filter strip, read from the shell's [ScrollVeil].
  ///
  /// At rest the strip is flush and rimless; once content scrolls underneath
  /// it gains the strong rim and a deeper shadow. Colour/shadow only over
  /// [CScholarMotion.swap] — nothing reflows. The rest-state border is
  /// transparent (not absent) so seating never changes the box by a pixel.
  /// No veil above (mobile shell) reads as rest; reduced motion snaps.
  Widget _seatedStrip(Widget child) {
    final seated = ScrollVeil.seatedOf(context) ?? false;
    final animate = motionEnabled(context);
    return AnimatedContainer(
      duration: animate ? CScholarMotion.swap : Duration.zero,
      curve: CScholarCurves.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(
          color: seated ? CScholarMaterial.rimStrong : Colors.transparent,
        ),
        boxShadow: seated ? CScholarMaterial.softShadow(depth: 0.8) : const [],
      ),
      child: child,
    );
  }

  Widget _resultsHeader(
    BuildContext context,
    bool useSemantic,
    AsyncValue<ThesisPage> theses,
  ) {
    final size = MediaQuery.of(context).size;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          useSemantic ? 'Semantic Results' : 'Search Results',
          style: CScholarTextStyles.heading(
            20,
            FontWeight.w800,
            CScholarColors.textPrimary,
          ),
        ),
        if (!useSemantic)
          theses.maybeWhen(
            data: (page) => Text(
              _query.isEmpty
                  ? '${page.total} studies in the repository'
                  : '${page.total} results for "$_query"',
              style: CScholarTextStyles.body(
                12.5,
                FontWeight.w400,
                CScholarColors.textMuted,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          )
        else
          Text(
            'Ranked by meaning, not keywords',
            style: CScholarTextStyles.body(
              12.5,
              FontWeight.w400,
              CScholarColors.textMuted,
            ),
          ),
      ],
    );

    // Wrap, not Row: the filter cluster is ~560px wide at rest and wider at
    // 200% text, so it must be able to break onto a second line instead of
    // pushing the sort well off the edge.
    final controls = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (size.width <= 920)
          NeumorphButton(
            onPressed: () => _showMobileFilters(context),
            icon: Icons.filter_list,
            gel: false,
            label:
                'Filters${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}',
          ),
        NeumorphToggle(
          label: 'Semantic Search',
          value: _isSemantic,
          onChanged: (v) => setState(() => _isSemantic = v),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort: ',
              style: CScholarTextStyles.body(
                12,
                FontWeight.w500,
                CScholarColors.textMuted,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 170,
              child: NeumorphSelectField<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'Latest', child: Text('Latest')),
                  DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                  DropdownMenuItem(
                    value: 'Title (A-Z)',
                    child: Text('Title (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: 'Title (Z-A)',
                    child: Text('Title (Z-A)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sortBy = v);
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    // Below the breakpoint the title owns the line and the controls drop
    // under it; above it they sit beside the title exactly as before.
    if (size.width <= 920) {
      return _seatedStrip(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 12), controls],
        ),
      );
    }

    return _seatedStrip(
      LayoutBuilder(
        builder: (context, constraints) {
          // Non-flex trailing child: a `Flexible` next to the `Expanded` title is
          // a 50/50 split, so the cluster's own `WrapAlignment.end` resolved
          // against the middle of the strip instead of its trailing edge. The
          // cap keeps the title a readable column when the cluster grows at
          // 200% text; the Wrap then breaks onto a second run on its own.
          final maxControlsWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth * 2 / 3
              : double.infinity;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxControlsWidth),
                child: controls,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Light control header — title, search, quick topics and filters in one
  /// clay card. No full-bleed hero: the page stays bright and the search
  /// field is a tonal well on clay, never white-on-green.
  Widget _controlHeader(BuildContext context, bool isWide) {
    final programs = ref.watch(programsProvider);
    final academicYears = ref.watch(academicYearsProvider);
    final categories = ref.watch(categoriesProvider);

    final programName = programs.maybeWhen(
      data: (list) => list
          .where((p) => p.id == _selectedProgramId)
          .map((p) => p.name)
          .join(),
      orElse: () => '',
    );
    final yearLabel = academicYears.maybeWhen(
      data: (list) =>
          list.where((y) => y.id == _selectedYearId).map((y) => y.label).join(),
      orElse: () => '',
    );
    final categoryName = categories.maybeWhen(
      data: (list) => list
          .where((c) => c.id == _selectedCategoryId)
          .map((c) => c.name)
          .join(),
      orElse: () => '',
    );

    final pills = <({String label, VoidCallback clear})>[
      if (_selectedType != null)
        (
          label: _selectedType!,
          clear: () => setState(() => _selectedType = null),
        ),
      if (_selectedProgramId != null && programName.isNotEmpty)
        (
          label: programName,
          clear: () => setState(() => _selectedProgramId = null),
        ),
      if (_selectedYearId != null && yearLabel.isNotEmpty)
        (label: yearLabel, clear: () => setState(() => _selectedYearId = null)),
      if (_selectedCategoryId != null && categoryName.isNotEmpty)
        (
          label: categoryName,
          clear: () => setState(() => _selectedCategoryId = null),
        ),
      if (_keyword.isNotEmpty)
        (
          label: '“$_keyword”',
          clear: () {
            _keywordController.clear();
            setState(() => _keyword = '');
          },
        ),
    ];

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 18),
      decoration: BoxDecoration(
        color: CScholarMaterial.clay,
        borderRadius: BorderRadius.circular(CScholarRadius.softCard),
        border: Border.all(color: CScholarMaterial.rim),
        boxShadow: CScholarShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow — scope at a glance, same language as the dashboard.
          Text(
            'CEIT REPOSITORY • SEMANTIC SEARCH',
            style: CScholarTextStyles.body(
              11,
              FontWeight.w800,
              CScholarColors.primaryGreenHover,
              letterSpacing: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find your next idea.',
            style: CScholarTextStyles.heading(
              isWide ? 30 : 24,
              FontWeight.w800,
              CScholarColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search CEIT theses and capstone projects by keyword — or toggle Semantic Search below to rank by meaning.',
            style: CScholarTextStyles.body(
              13,
              FontWeight.w400,
              CScholarColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          // Search row: tonal well on clay + green go button.
          Row(
            children: [
              Expanded(
                child: NeumorphField(
                  controller: _heroController,
                  hintText:
                      'Search by topic, technology, author, or keyword...',
                  prefixIcon: Icons.search_outlined,
                  textInputAction: TextInputAction.search,
                  onChanged: _onHeroChanged,
                  onSubmitted: (_) => _submitHero(),
                ),
              ),
              const SizedBox(width: 8),
              NeumorphIconButton(
                onPressed: _submitHero,
                icon: Icons.arrow_forward,
                tooltip: 'Search',
                gel: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick topics — one tap to value, no filter hunting.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final topic in const [
                'Machine Learning',
                'IoT',
                'Web System',
                'Mobile App',
              ])
                InkWell(
                  borderRadius: BorderRadius.circular(CScholarRadius.full),
                  onTap: () {
                    _heroController.text = topic;
                    _submitHero();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreenLight,
                      borderRadius: BorderRadius.circular(CScholarRadius.full),
                      border: Border.all(color: CScholarMaterial.rimPublished),
                    ),
                    child: Text(
                      topic,
                      style: CScholarTextStyles.body(
                        11.5,
                        FontWeight.w600,
                        CScholarColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: CScholarMaterial.rim, height: 1),
          ),
          // Filters — same card, own section. No more detached strip.
          Row(
            children: [
              Text('FILTERS', style: CScholarTextStyles.sectionLabel),
              const Spacer(),
              if (_activeFilterCount > 0)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text(
                    'Clear all',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: CScholarColors.textMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = isWide
                  ? (constraints.maxWidth - 30) / 4
                  : (constraints.maxWidth - 10) / 2;
              Widget box(Widget child) =>
                  SizedBox(width: boxWidth, child: child);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  box(
                    _clayFilterBox<String>(
                      label: 'Research Type',
                      value: _selectedType,
                      items: const {
                        null: 'All',
                        'Thesis': 'Thesis',
                        'Capstone': 'Capstone',
                      },
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),
                  ),
                  box(
                    _clayFilterBox<int>(
                      label: 'Program',
                      value: _selectedProgramId,
                      asyncItems: programs,
                      itemLabel: (p) => (p as Program).name,
                      itemId: (p) => (p as Program).id,
                      onChanged: (v) => setState(() => _selectedProgramId = v),
                    ),
                  ),
                  box(
                    _clayFilterBox<int>(
                      label: 'Academic Year',
                      value: _selectedYearId,
                      asyncItems: academicYears,
                      itemLabel: (y) => (y as AcademicYear).label,
                      itemId: (y) => (y as AcademicYear).id,
                      onChanged: (v) => setState(() => _selectedYearId = v),
                    ),
                  ),
                  box(
                    _clayFilterBox<int>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      asyncItems: categories,
                      itemLabel: (c) => (c as Category).name,
                      itemId: (c) => (c as Category).id,
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                ],
              );
            },
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$_activeFilterCount active:',
                  style: CScholarTextStyles.body(
                    11.5,
                    FontWeight.w600,
                    CScholarColors.textMuted,
                  ),
                ),
                for (final pill in pills)
                  InkWell(
                    borderRadius: BorderRadius.circular(CScholarRadius.full),
                    onTap: pill.clear,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: CScholarColors.primaryGreenVeryLight,
                        borderRadius: BorderRadius.circular(
                          CScholarRadius.full,
                        ),
                        border: Border.all(
                          color: CScholarMaterial.rimPublished,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pill.label,
                            style: CScholarTextStyles.body(
                              11.5,
                              FontWeight.w700,
                              CScholarColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.close,
                            size: 14,
                            color: CScholarColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Clay dropdown box for the filter grid (tonal well, no glass).
  Widget _clayFilterBox<T>({
    required String label,
    required T? value,
    Map<T?, String>? items,
    AsyncValue<List<dynamic>>? asyncItems,
    String Function(dynamic)? itemLabel,
    T Function(dynamic)? itemId,
    required ValueChanged<T?> onChanged,
  }) {
    Widget dropdown;
    if (items != null) {
      dropdown = NeumorphSelectField<T>(
        value: value,
        items: items.entries
            .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      );
    } else {
      dropdown = asyncItems!.when(
        data: (list) => NeumorphSelectField<T>(
          value: value,
          items: [
            DropdownMenuItem<T>(value: null, child: const Text('All')),
            for (final item in list)
              DropdownMenuItem<T>(
                value: itemId!(item),
                child: Text(itemLabel!(item)),
              ),
          ],
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
        ),
        loading: () => const ClayLoader(height: 8),
        error: (_, _) => NeumorphSelectField<T>(
          value: value,
          items: [DropdownMenuItem<T>(value: null, child: const Text('All'))],
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: CScholarTextStyles.body(
            10.5,
            FontWeight.w700,
            CScholarColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        dropdown,
      ],
    );
  }

  void _showMobileFilters(BuildContext context) {
    final programs = ref.read(programsProvider);
    final academicYears = ref.read(academicYearsProvider);
    final categories = ref.read(categoriesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CScholarMaterial.clay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CScholarRadius.softSheet),
        ),
      ),
      // Slide up on settle over CScholarMotion.page, same as the dialogs, so
      // all floating chrome opens identically. The scrim fades in with the
      // route animation; drag-to-dismiss is the sheet's default and stays.
      sheetAnimationStyle: AnimationStyle(
        duration: CScholarMotion.page,
        reverseDuration: CScholarMotion.page,
        curve: CScholarCurves.settle,
        reverseCurve: CScholarCurves.exit,
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: CScholarTextStyles.heading(
                              18,
                              FontWeight.w700,
                              CScholarColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildFilterContent(
                        programs: programs,
                        academicYears: academicYears,
                        categories: categories,
                        onChangedCallback: () => setModalState(() {}),
                      ),
                      const SizedBox(height: 16),
                      NeumorphButton(
                        onPressed: () => Navigator.pop(context),
                        label: 'Apply Filters',
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterContent({
    required AsyncValue<List<Program>> programs,
    required AsyncValue<List<AcademicYear>> academicYears,
    required AsyncValue<List<Category>> categories,
    VoidCallback? onChangedCallback,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAsyncDropdown<int>(
          label: 'Program',
          value: _selectedProgramId,
          asyncItems: programs,
          itemLabel: (p) => p.name,
          itemId: (p) => p.id,
          onChanged: (v) {
            setState(() => _selectedProgramId = v);
            onChangedCallback?.call();
          },
        ),
        const SizedBox(height: 16),
        _buildAsyncDropdown<int>(
          label: 'Academic Year',
          value: _selectedYearId,
          asyncItems: academicYears,
          itemLabel: (y) => y.label,
          itemId: (y) => y.id,
          onChanged: (v) {
            setState(() => _selectedYearId = v);
            onChangedCallback?.call();
          },
        ),
        const SizedBox(height: 16),
        _buildAsyncDropdown<int>(
          label: 'Category',
          value: _selectedCategoryId,
          asyncItems: categories,
          itemLabel: (c) => c.name,
          itemId: (c) => c.id,
          onChanged: (v) {
            setState(() => _selectedCategoryId = v);
            onChangedCallback?.call();
          },
        ),
        const SizedBox(height: 16),
        _buildStaticDropdown<String>(
          label: 'Research Type',
          value: _selectedType,
          items: const {
            'All': 'All',
            'Thesis': 'Thesis',
            'Capstone': 'Capstone',
            'Applied Research': 'Applied Research',
          },
          allKey: 'All',
          onChanged: (v) {
            setState(() => _selectedType = v);
            onChangedCallback?.call();
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Keywords',
          style: CScholarTextStyles.body(
            11.5,
            FontWeight.w700,
            CScholarColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        NeumorphField(
          controller: _keywordController,
          hintText: 'Enter keyword...',
          onChanged: (v) {
            setState(() => _keyword = v.trim());
            onChangedCallback?.call();
          },
          onSubmitted: (v) {
            setState(() => _keyword = v.trim());
            onChangedCallback?.call();
          },
          suffixIcon: _keyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _keywordController.clear();
                    setState(() => _keyword = '');
                    onChangedCallback?.call();
                  },
                )
              : null,
        ),
        const SizedBox(height: 20),
        NeumorphButton(
          onPressed: () {
            _clearFilters();
            onChangedCallback?.call();
          },
          label: 'Clear Filters',
          gel: false,
          expand: true,
        ),
      ],
    );
  }

  Widget _buildAsyncDropdown<T>({
    required String label,
    required T? value,
    required AsyncValue<List<dynamic>> asyncItems,
    required String Function(dynamic) itemLabel,
    required T Function(dynamic) itemId,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CScholarTextStyles.body(
            11.5,
            FontWeight.w700,
            CScholarColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        asyncItems.when(
          data: (list) {
            final menuItems = <DropdownMenuItem<T>>[
              DropdownMenuItem<T>(value: null, child: const Text('All')),
            ];
            for (final item in list) {
              menuItems.add(
                DropdownMenuItem<T>(
                  value: itemId(item),
                  child: Text(itemLabel(item)),
                ),
              );
            }
            return NeumorphSelectField<T>(
              // Controlled: "Clear Filters" in the sheet resets the screen's
              // value, and the well must follow it.
              value: value,
              items: menuItems,
              onChanged: onChanged,
            );
          },
          loading: () => const ClayLoader(height: 8),
          error: (err, stackTrace) => NeumorphSelectField<T>(
            value: value,
            items: [DropdownMenuItem<T>(value: null, child: const Text('All'))],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStaticDropdown<T>({
    required String label,
    required T? value,
    required Map<String, String> items,
    required String allKey,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CScholarTextStyles.body(
            11.5,
            FontWeight.w700,
            CScholarColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        NeumorphSelectField<T>(
          // Controlled: "Clear Filters" resets the screen's value, and the
          // well must follow it. The 'All' entry maps to null — that
          // null-vs-"All" semantics is preserved exactly.
          value: value,
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key == allKey ? null : e.key as T,
                  child: Text(e.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _semanticUnavailableNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CScholarColors.noteBg,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        border: Border.all(color: CScholarColors.noteRim),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: CScholarColors.noteIcon,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Semantic index unavailable — showing no semantic matches.',
              style: CScholarTextStyles.body(
                12,
                FontWeight.w500,
                CScholarColors.noteInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<SemanticResult> _filterSemanticResults(List<SemanticResult> results) {
    return results.where((r) {
      if (_selectedProgramId != null &&
          r.thesis.programId != _selectedProgramId) {
        return false;
      }
      if (_selectedYearId != null &&
          r.thesis.academicYearId != _selectedYearId) {
        return false;
      }
      if (_selectedType != null && r.thesis.researchType != _selectedType) {
        return false;
      }
      if (_selectedCategoryId != null) {
        final catIds = r.thesis.categories?.map((c) => c.id).toList() ?? [];
        if (!catIds.contains(_selectedCategoryId)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _noResultsFound() {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No studies found matching your filters',
      actionLabel: 'Reset all filters',
      onAction: _clearFilters,
    );
  }
}

/// Keeps the AI rail pinned below the top bar while the results scroll.
///
/// Flutter has no `position: sticky`, and the rail deliberately shares one
/// scroll view with the results (no nested scrollables — see [_resultsColumn]).
/// So the rail keeps its layout slot and is translated down by exactly the
/// distance that slot has travelled past the pin. The translation stops at the
/// results row's bottom, so the rail never floats over the footer, and it is
/// disabled when the card is taller than the viewport (pinning it would hide
/// the rest of the card instead of making it easier to read).
///
/// Geometry is measured post-frame in scroll-content coordinates, so the
/// per-scroll update is just a subtraction against [ScrollPosition.pixels] —
/// no per-frame render-object walks, and no rebuilt child.
class _StickyRail extends StatefulWidget {
  const _StickyRail({required this.child, required this.rowKey});

  final Widget child;

  /// The results row that owns the rail; its bottom is the stop line.
  final GlobalKey rowKey;

  @override
  State<_StickyRail> createState() => _StickyRailState();
}

class _StickyRailState extends State<_StickyRail> {
  /// Breathing room between the scroll viewport's top and the pinned card.
  static const double _topGap = 16;
  final GlobalKey _anchorKey = GlobalKey();
  final ValueNotifier<double> _translation = ValueNotifier<double>(0);
  ScrollableState? _scrollable;

  /// Scroll offset at which the rail's top reaches the pin.
  double? _stickOffset;

  /// Furthest the rail may travel before its bottom reaches the row's bottom.
  double _maxTranslation = 0;

  bool _measureScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (!identical(scrollable, _scrollable)) {
      _scrollable?.position.removeListener(_followScroll);
      _scrollable = scrollable;
      _scrollable?.position.addListener(_followScroll);
    }
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_followScroll);
    _translation.dispose();
    super.dispose();
  }

  /// Re-measure after a frame in which layout may have changed: a new page of
  /// results, a window resize or the first build all move the stop line.
  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (mounted) _measure();
    });
  }

  void _measure() {
    final anchor = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final row = widget.rowKey.currentContext?.findRenderObject() as RenderBox?;
    final scrollable = _scrollable;
    if (anchor == null || row == null || scrollable == null) return;
    if (!anchor.attached || !anchor.hasSize) return;

    final viewport = scrollable.context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;

    final pixels = scrollable.position.pixels;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    // Everything below is in scroll-content coordinates, where the slider's
    // own paint offset no longer matters.
    final railTop = anchor.localToGlobal(Offset.zero).dy - viewportTop + pixels;
    final rowBottom =
        row.localToGlobal(Offset.zero).dy +
        row.size.height -
        viewportTop +
        pixels;

    _stickOffset = railTop - _topGap;
    final fits = anchor.size.height <= viewport.size.height - _topGap;
    _maxTranslation = fits ? rowBottom - railTop - anchor.size.height : 0;
    if (_maxTranslation < 0) _maxTranslation = 0;
    _followScroll();
  }

  void _followScroll() {
    final stickOffset = _stickOffset;
    final position = _scrollable?.position;
    if (stickOffset == null || position == null) return;
    final next = (position.pixels - stickOffset).clamp(0.0, _maxTranslation);
    if (next != _translation.value) _translation.value = next;
  }

  @override
  Widget build(BuildContext context) {
    // Content height can change without a scroll event (results land, filters
    // clear); re-measure after this frame so the stop line is never stale.
    _scheduleMeasure();
    return SizedBox(
      key: _anchorKey,
      child: ValueListenableBuilder<double>(
        valueListenable: _translation,
        child: widget.child,
        builder: (context, dy, child) =>
            Transform.translate(offset: Offset(0, dy), child: child),
      ),
    );
  }
}
