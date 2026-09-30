import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/result_card.dart';
import 'package:frontend/presentation/widgets/rec_rail.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

/// V2 repository (new design): gradient hero with glass search + live
/// filter boxes, result cards with generative covers, AI rail.
/// Semantic mode can be preselected via `?mode=semantic`.
class RepositoryScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const RepositoryScreen({super.key, this.initialQuery});

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

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null &&
        widget.initialQuery!.trim().isNotEmpty) {
      _query = widget.initialQuery!.trim();
      _searchController.text = _query;
      _heroController.text = _query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

  void _submitHero() {
    _debounce?.cancel();
    final q = _heroController.text.trim();
    setState(() {
      _query = q;
      _searchController.text = q;
    });
  }

  /// Live search: results filter while typing (debounced so we don't
  /// hammer the API — and the embedding model — on every keystroke).
  void _onHeroChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final q = v.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final useSemantic = _isSemantic && _query.trim().isNotEmpty;
    final theses = ref.watch(
      thesisListProvider(
        ThesisListParams(
          query: _query.isEmpty ? null : _query,
          programId: _selectedProgramId,
          academicYearId: _selectedYearId,
          categoryId: _selectedCategoryId,
          keyword: _keyword.isEmpty ? null : _keyword,
          sortBy: _sortBy,
          researchType: _selectedType,
        ),
      ),
    );
    final semantic = useSemantic
        ? ref.watch(semanticSearchProvider(_query.trim()))
        : const AsyncValue<List<SemanticResult>>.data([]);
    final savedIds = ref.watch(savedThesisIdsProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 920;

    return StudentLayout(
      currentIndex: 1,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _hero(context, isWide),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _resultsColumn(context, useSemantic, theses,
                      semantic, savedIds),
                ),
              ),
            ),
            const CScholarFooter(),
          ],
        ),
      ),
    );
  }

  /// Results list, with the AI rail beside it on wide screens.
  /// Rail and list scroll together as one column — no nested scroll views.
  Widget _resultsColumn(
    BuildContext context,
    bool useSemantic,
    AsyncValue<List<Thesis>?> theses,
    AsyncValue<List<SemanticResult>> semantic,
    Set<int> savedIds,
  ) {
    final list = StaggerColumn(
      children: [
        _resultsHeader(context, useSemantic, theses),
        const SizedBox(height: 16),
        if (useSemantic)
          asyncSlot<List<SemanticResult>>(
            semantic,
            skeleton: const SkeletonList(count: 4, cardHeight: 150),
            data: (results) {
              if (results.isEmpty) {
                return Column(
                  children: [
                    _semanticUnavailableNote(),
                    _noResultsFound(),
                  ],
                );
              }
              final filtered = _filterSemanticResults(results);
              if (filtered.isEmpty) return _noResultsFound();
              return Column(
                children: [
                  for (final r in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ResultCard(
                        thesis: r.thesis,
                        isSaved: savedIds.contains(r.thesis.id),
                        similarity: r.similarity,
                        onToggleSave: () => ref
                            .read(savedThesisIdsProvider.notifier)
                            .toggle(r.thesis.id),
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
          asyncSlot<List<Thesis>?>(
            theses,
            skeleton: const SkeletonList(count: 4, cardHeight: 150),
            data: (list) {
              if (list == null || list.isEmpty) return _noResultsFound();
              return Column(
                children: [
                  for (final thesis in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ResultCard(
                        thesis: thesis,
                        isSaved: savedIds.contains(thesis.id),
                        onToggleSave: () => ref
                            .read(savedThesisIdsProvider.notifier)
                            .toggle(thesis.id),
                      ),
                    ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load studies',
              message: err.toString(),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(thesisListProvider(
                ThesisListParams(
                  query: _query.isEmpty ? null : _query,
                  programId: _selectedProgramId,
                  academicYearId: _selectedYearId,
                  categoryId: _selectedCategoryId,
                  keyword: _keyword.isEmpty ? null : _keyword,
                  sortBy: _sortBy,
                  researchType: _selectedType,
                ),
              )),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 900) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: list),
            const SizedBox(width: 20),
            Expanded(flex: 5, child: RecRail(query: _query)),
          ],
        );
      },
    );
  }

  Widget _resultsHeader(BuildContext context, bool useSemantic,
      AsyncValue<List<Thesis>?> theses) {
    final size = MediaQuery.of(context).size;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(useSemantic ? 'Semantic Results' : 'Search Results',
            style: CScholarTextStyles.poppins(
                20, FontWeight.w800, CScholarColors.textPrimary)),
        if (!useSemantic)
          theses.maybeWhen(
            data: (list) => Text(
              _query.isEmpty
                  ? '${list?.length ?? 0} studies in the repository'
                  : 'Showing ${list?.length ?? 0} results for "$_query"',
              style: CScholarTextStyles.inter(12.5, FontWeight.w400,
                  CScholarColors.textMuted),
            ),
            orElse: () => const SizedBox.shrink(),
          )
        else
          Text('Ranked by meaning, not keywords',
              style: CScholarTextStyles.inter(12.5, FontWeight.w400,
                  CScholarColors.textMuted)),
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
            Text('Sort: ',
                style: CScholarTextStyles.inter(12, FontWeight.w500,
                    CScholarColors.textMuted)),
            const SizedBox(width: 6),
            SizedBox(
              width: 170,
              child: NeumorphSelectField<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'Latest', child: Text('Latest')),
                  DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                  DropdownMenuItem(
                      value: 'Title (A-Z)', child: Text('Title (A-Z)')),
                  DropdownMenuItem(
                      value: 'Title (Z-A)', child: Text('Title (Z-A)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sortBy = v);
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              ),
            ),
          ],
        ),
      ],
    );

    // Below the breakpoint the title owns the line and the controls drop
    // under it; above it they sit beside the title exactly as before.
    if (size.width <= 920) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        // Loose, so at 200% text the cluster wraps onto a second line instead
        // of forcing the title column to zero width.
        Flexible(child: controls),
      ],
    );
  }

  Widget _hero(BuildContext context, bool isWide) {
    final programs = ref.watch(programsProvider);
    final academicYears = ref.watch(academicYearsProvider);
    final categories = ref.watch(categoriesProvider);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 32 : 16, vertical: isWide ? 36 : 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CScholarColors.heroDeep,
            CScholarColors.heroMid,
            CScholarColors.heroGlow,
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          // One shared blur pass for the search pane plus the four filter
          // panes below it — that is what GlassGroup exists for.
          child: GlassGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Discover. Learn. Build the Future.',
                  style: CScholarTextStyles.poppins(
                      isWide ? 30 : 24,
                      FontWeight.w800,
                      CScholarColors.white,
                      height: 1.2)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  'Find relevant theses and capstone projects using semantic search and AI-powered recommendations.',
                  style: CScholarTextStyles.inter(
                      13.5, FontWeight.w400, CScholarMaterial.shadowDark,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              // Glass search box — the shared primitive, so the low-power kill
              // switch (glassEnabled) and the high-contrast fallback apply.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: GlassPanel(
                  radius: CScholarRadius.lg,
                  // Deliberate overrides of the chrome recipe — .62 fill /
                  // 18 blur. The hero copy sits behind this box, so it needs a
                  // more opaque, sharper pane to stay legible.
                  fill: CScholarColors.white.withValues(alpha: 0.92),
                  blur: 12,
                  padding: const EdgeInsets.all(6),
                  // The hero's dark gradient is the only content behind this
                  // box, so a cast shadow would land on nothing.
                  shadows: const [],
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search,
                            color: CScholarColors.textHint, size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _heroController,
                          onChanged: _onHeroChanged,
                          onSubmitted: (_) => _submitHero(),
                          style: CScholarTextStyles.inter(14,
                              FontWeight.w400, CScholarColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText:
                                'Try searching for a topic, technology, or keyword...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      NeumorphIconButton(
                        onPressed: _submitHero,
                        icon: Icons.arrow_forward,
                        tooltip: 'Search',
                        gel: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Live filter boxes
              LayoutBuilder(
                builder: (context, constraints) {
                  final boxes = [
                    _heroFilterBox<String>(
                      label: 'Research Type',
                      value: _selectedType,
                      items: const {
                        null: 'All',
                        'Thesis': 'Thesis',
                        'Capstone': 'Capstone',
                      },
                      onChanged: (v) =>
                          setState(() => _selectedType = v),
                    ),
                    _heroFilterBox<int>(
                      label: 'Program',
                      value: _selectedProgramId,
                      asyncItems: programs,
                      itemLabel: (p) => (p as Program).name,
                      itemId: (p) => (p as Program).id,
                      onChanged: (v) =>
                          setState(() => _selectedProgramId = v),
                    ),
                    _heroFilterBox<int>(
                      label: 'Academic Year',
                      value: _selectedYearId,
                      asyncItems: academicYears,
                      itemLabel: (y) => (y as AcademicYear).label,
                      itemId: (y) => (y as AcademicYear).id,
                      onChanged: (v) =>
                          setState(() => _selectedYearId = v),
                    ),
                    _heroFilterBox<int>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      asyncItems: categories,
                      itemLabel: (c) => (c as Category).name,
                      itemId: (c) => (c as Category).id,
                      onChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                    ),
                  ];
                  if (constraints.maxWidth > 860) {
                    return Row(
                      children: [
                        for (var i = 0; i < boxes.length; i++) ...[
                          Expanded(child: boxes[i]),
                          if (i < boxes.length - 1)
                            const SizedBox(width: 10),
                        ],
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: _activeFilterCount > 0
                              ? _clearFilters
                              : null,
                          icon: const Icon(Icons.clear_all,
                              size: 16, color: CScholarColors.white),
                          label: const Text('Clear all',
                              style: TextStyle(
                                  fontSize: 12, color: CScholarColors.white)),
                        ),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...boxes.map((b) => SizedBox(
                          width: (constraints.maxWidth - 10) / 2, child: b)),
                      if (_activeFilterCount > 0)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all,
                              size: 16, color: CScholarColors.white),
                          label: const Text('Clear all',
                              style: TextStyle(
                                  fontSize: 12, color: CScholarColors.white)),
                        ),
                    ],
                  );
                },
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroFilterBox<T>({
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
        // Controlled: the screen owns the filter value, so "Clear all" stays
        // in sync by construction (a FormField would keep the stale pick).
        value: value,
        items: items.entries
            .map((e) =>
                DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
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
                  value: itemId!(item), child: Text(itemLabel!(item))),
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
    // Floating chrome over the dark hero overlay is glass per the fusion law.
    // Same recipe as the hero search box above (.92 fill / 12 blur, no cast
    // shadow — a shadow here would land on the gradient, not on content).
    return GlassPanel(
      radius: CScholarRadius.md,
      fill: CScholarColors.white.withValues(alpha: 0.92),
      blur: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: CScholarTextStyles.inter(
                  10.5, FontWeight.w500, CScholarColors.textMuted)),
          dropdown,
        ],
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                          Text('Filters',
                              style: CScholarTextStyles.poppins(18,
                                  FontWeight.w700, CScholarColors.textPrimary)),
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
        Text('Keywords',
            style: CScholarTextStyles.inter(
                11.5, FontWeight.w700, CScholarColors.textSecondary)),
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
        Text(label,
            style: CScholarTextStyles.inter(
                11.5, FontWeight.w700, CScholarColors.textSecondary)),
        const SizedBox(height: 6),
        asyncItems.when(
          data: (list) {
            final menuItems = <DropdownMenuItem<T>>[
              DropdownMenuItem<T>(value: null, child: const Text('All')),
            ];
            for (final item in list) {
              menuItems.add(DropdownMenuItem<T>(
                  value: itemId(item), child: Text(itemLabel(item))));
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
        Text(label,
            style: CScholarTextStyles.inter(
                11.5, FontWeight.w700, CScholarColors.textSecondary)),
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
          const Icon(Icons.info_outline,
              size: 18, color: CScholarColors.noteIcon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Semantic index unavailable — showing no AI matches.',
              style: CScholarTextStyles.inter(
                  12, FontWeight.w500, CScholarColors.noteInk),
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
        final catIds =
            r.thesis.categories?.map((c) => c.id).toList() ?? [];
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
