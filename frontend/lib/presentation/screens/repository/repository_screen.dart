import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const RepositoryScreen({super.key, this.initialQuery});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final _searchController = TextEditingController();
  final _keywordController = TextEditingController();
  String _query = '';
  String _keyword = '';
  bool _isSemantic = false;
  int? _selectedProgramId;
  int? _selectedYearId;
  int? _selectedCategoryId;
  String? _selectedType;
  String _sortBy = 'Relevance';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _query = widget.initialQuery!.trim();
      _searchController.text = _query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      _query = '';
      _sortBy = 'Relevance';
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
    final showDesktopFilter = size.width > 920;

    // Watch providers for filter dropdowns
    final programs = ref.watch(programsProvider);
    final academicYears = ref.watch(academicYearsProvider);
    final categories = ref.watch(categoriesProvider);

    return StudentLayout(
      currentIndex: 1,
      searchController: _searchController,
      searchHint: 'Search thesis, capstone, topic, author, keyword...',
      onSearchChanged: (v) {
        if (!_isSemantic) setState(() => _query = v);
      },
      onSearchSubmit: () => setState(() => _query = _searchController.text),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Left Filters Sidebar (Desktop)
          if (showDesktopFilter)
            Container(
              width: 270,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: CScholarColors.borderLight),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: CScholarTextStyles.poppins(
                            16,
                            FontWeight.w700,
                            CScholarColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.filter_list,
                          size: 18,
                          color: CScholarColors.textSecondary,
                        ),
                      ],
                    ),
                    const Divider(
                      color: CScholarColors.borderLight,
                      height: 24,
                    ),
                    _buildFilterContent(
                      programs: programs,
                      academicYears: academicYears,
                      categories: categories,
                    ),
                  ],
                ),
              ),
            ),

          // 2. Results Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Results Header Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Results',
                                style: CScholarTextStyles.poppins(
                                  20,
                                  FontWeight.w800,
                                  CScholarColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              theses.maybeWhen(
                                data: (list) => Text(
                                  '(${list?.length ?? 0})',
                                  style: CScholarTextStyles.inter(
                                    14,
                                    FontWeight.w600,
                                    CScholarColors.textMuted,
                                  ),
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),
                              if (!showDesktopFilter) ...[
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _showMobileFilters(
                                    context,
                                    programs,
                                    academicYears,
                                    categories,
                                  ),
                                  icon: const Icon(Icons.filter_list, size: 16),
                                  label: Text(
                                    'Filters${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: CScholarColors.primaryGreen,
                                    side: const BorderSide(
                                      color: CScholarColors.primaryGreen,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          Row(
                            children: [
                              // Semantic Switch
                              Row(
                                children: [
                                  Text(
                                    'Semantic Match',
                                    style: CScholarTextStyles.inter(
                                      12,
                                      FontWeight.w600,
                                      CScholarColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _isSemantic,
                                    onChanged: (v) =>
                                        setState(() => _isSemantic = v),
                                    activeThumbColor:
                                        CScholarColors.primaryGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Sort by Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    CScholarRadius.md,
                                  ),
                                  border: Border.all(
                                    color: CScholarColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Sort: ',
                                      style: CScholarTextStyles.inter(
                                        12,
                                        FontWeight.w500,
                                        CScholarColors.textMuted,
                                      ),
                                    ),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _sortBy,
                                        isDense: true,
                                        style: CScholarTextStyles.inter(
                                          12,
                                          FontWeight.w600,
                                          CScholarColors.textPrimary,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Relevance',
                                            child: Text('Relevance'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Latest',
                                            child: Text('Latest'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Highest Similarity',
                                            child: Text('Highest Similarity'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Most Viewed',
                                            child: Text('Most Viewed'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _sortBy = v!),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Results List — semantic when toggle is on + query present.
                      if (useSemantic)
                        semantic.when(
                          data: (results) {
                            if (results.isEmpty) {
                              return Column(
                                children: [
                                  _semanticUnavailableNote(),
                                  _noResultsFound(),
                                ],
                              );
                            }
                            // Apply dropdown filters client-side
                            final filtered = _filterSemanticResults(results);
                            if (filtered.isEmpty) {
                              return _noResultsFound();
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final r = filtered[i];
                                final isSaved = savedIds.contains(r.thesis.id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildResultCard(
                                    thesis: r.thesis,
                                    isSaved: isSaved,
                                    similarityScore: r.similarity,
                                    onBookmarkToggle: () => ref
                                        .read(savedThesisIdsProvider.notifier)
                                        .toggle(r.thesis.id),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Text('Semantic search error: $err'),
                          ),
                        )
                      else
                        theses.when(
                          data: (list) {
                            if (list == null || list.isEmpty) {
                              return _noResultsFound();
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final thesis = list[i];
                                final isSaved = savedIds.contains(thesis.id);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildResultCard(
                                    thesis: thesis,
                                    isSaved: isSaved,
                                    similarityScore: null,
                                    onBookmarkToggle: () => ref
                                        .read(savedThesisIdsProvider.notifier)
                                        .toggle(thesis.id),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, _) => Center(child: Text('Error: $err')),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required Thesis thesis,
    required bool isSaved,
    required VoidCallback onBookmarkToggle,
    double? similarityScore,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academic Year & Degree Program Badge
                Row(
                  children: [
                    Text(
                      thesis.academicYear?.label ?? 'N/A',
                      style: CScholarTextStyles.inter(
                        11.5,
                        FontWeight.w600,
                        CScholarColors.textMuted,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: CScholarTextStyles.inter(
                        11.5,
                        FontWeight.w400,
                        CScholarColors.borderLight,
                      ),
                    ),
                    Text(
                      thesis.program?.name ?? 'N/A',
                      style: CScholarTextStyles.inter(
                        11.5,
                        FontWeight.w600,
                        const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                InkWell(
                  onTap: () => context.go('/thesis/${thesis.id}'),
                  child: Text(
                    thesis.title,
                    style: CScholarTextStyles.poppins(
                      16,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Authors
                Text(
                  'By: ${thesis.authorsString}',
                  style: CScholarTextStyles.inter(
                    12.5,
                    FontWeight.w500,
                    CScholarColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Abstract snippet
                Text(
                  thesis.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.inter(
                    12.5,
                    FontWeight.w400,
                    CScholarColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Actions: View Details & Bookmark
                Row(
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/thesis/${thesis.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CScholarColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            CScholarRadius.md,
                          ),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: CScholarTextStyles.inter(
                          12.5,
                          FontWeight.w600,
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: isSaved ? 'Remove from Saved' : 'Save Study',
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        size: 22,
                        color: isSaved
                            ? CScholarColors.primaryGreen
                            : CScholarColors.textHint,
                      ),
                      onPressed: onBookmarkToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Match / Similarity Badge
          if (similarityScore != null) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreenVeryLight,
                borderRadius: BorderRadius.circular(CScholarRadius.full),
                border: Border.all(
                  color: CScholarColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CScholarColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(similarityScore * 100).round()}% similar',
                    style: CScholarTextStyles.inter(
                      11.5,
                      FontWeight.w700,
                      CScholarColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
        // Program Select
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

        // Academic Year Select
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

        // Category Select
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

        // Research Type Select
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

        // Keywords Field
        Text(
          'Keywords',
          style: CScholarTextStyles.inter(
            11.5,
            FontWeight.w700,
            CScholarColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _keywordController,
          onChanged: (v) {
            setState(() => _keyword = v.trim());
            onChangedCallback?.call();
          },
          onSubmitted: (v) {
            setState(() => _keyword = v.trim());
            onChangedCallback?.call();
          },
          style: CScholarTextStyles.inter(
            13,
            FontWeight.w400,
            CScholarColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Enter keyword...',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
        ),
        const SizedBox(height: 20),

        // Clear Filters Action
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _clearFilters();
              onChangedCallback?.call();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: CScholarColors.textSecondary,
              side: const BorderSide(
                color: CScholarColors.borderLight,
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  CScholarRadius.md,
                ),
              ),
            ),
            child: Text(
              'Clear Filters',
              style: CScholarTextStyles.inter(
                12,
                FontWeight.w600,
                CScholarColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMobileFilters(
    BuildContext context,
    AsyncValue<List<Program>> programs,
    AsyncValue<List<AcademicYear>> academicYears,
    AsyncValue<List<Category>> categories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                          Text(
                            'Filters',
                            style: CScholarTextStyles.poppins(
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: CScholarColors.primaryGreen,
                          ),
                          child: const Text('Apply Filters'),
                        ),
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

  /// Async-loaded dropdown for programs, years, categories from API
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
          style: CScholarTextStyles.inter(
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
              final id = itemId(item);
              final lbl = itemLabel(item);
              menuItems.add(DropdownMenuItem<T>(value: id, child: Text(lbl)));
            }
            return DropdownButtonFormField<T>(
              initialValue: value,
              isDense: true,
              isExpanded: true,
              style: CScholarTextStyles.inter(
                13,
                FontWeight.w400,
                CScholarColors.textPrimary,
              ),
              items: menuItems,
              onChanged: onChanged,
            );
          },
          loading: () => const SizedBox(
            height: 36,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, stackTrace) => DropdownButtonFormField<T>(
            initialValue: value,
            isDense: true,
            items: [DropdownMenuItem<T>(value: null, child: const Text('All'))],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Static dropdown for research type and other simple lists
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
          style: CScholarTextStyles.inter(
            11.5,
            FontWeight.w700,
            CScholarColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isDense: true,
          isExpanded: true,
          style: CScholarTextStyles.inter(
            13,
            FontWeight.w400,
            CScholarColors.textPrimary,
          ),
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
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFF57F17)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Semantic index unavailable — showing no AI matches.',
              style: CScholarTextStyles.inter(
                12,
                FontWeight.w500,
                const Color(0xFF7A5C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apply dropdown filters to semantic search results client-side.
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
      return true;
    }).toList();
  }

  Widget _noResultsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 56,
              color: CScholarColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No studies found matching your filters',
              style: CScholarTextStyles.poppins(
                16,
                FontWeight.w600,
                CScholarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Reset all filters',
                style: CScholarTextStyles.inter(
                  13,
                  FontWeight.w600,
                  CScholarColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
