// Repository / Search screen — browse and search theses

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'newest';
  bool _showFilters = false;
  bool _isSemanticSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theses = ref.watch(thesisListProvider(const ThesisListParams()));
    final filters = ref.watch(searchFiltersProvider);
    final programs = ref.watch(programsProvider);
    final categories = ref.watch(categoriesProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('CScholar', style: TextStyle(color: CScholarColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: CScholarColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: CScholarColors.textSecondary),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: Row(
        children: [
          // Sidebar filters (desktop)
          if (isWide)
            Container(
              width: 260,
              color: Colors.white,
              child: _filterSidebar(programs, categories, filters),
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Search bar
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 16, isWide ? 24 : 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search thesis, capstone, adviser, keywords...',
                            hintStyle: const TextStyle(color: CScholarColors.textHint),
                            prefixIcon: const Icon(Icons.search, color: CScholarColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: CScholarColors.textHint),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(searchQueryProvider.notifier).setQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: CScholarColors.backgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => ref.read(searchQueryProvider.notifier).setQuery(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Semantic search toggle pill
                      GestureDetector(
                        onTap: () => setState(() => _isSemanticSearch = !_isSemanticSearch),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSemanticSearch ? CScholarColors.orange.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSemanticSearch ? CScholarColors.orange : CScholarColors.dividerLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: _isSemanticSearch ? CScholarColors.orange : CScholarColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isSemanticSearch ? CScholarColors.orange : CScholarColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _doSearch(ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: CScholarColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search'),
                      ),
                      const SizedBox(width: 8),
                      if (!isWide)
                        IconButton(
                          icon: Icon(
                            _showFilters ? Icons.filter_list_off : Icons.filter_list,
                            color: _hasActiveFilters(filters) ? CScholarColors.primaryGreen : CScholarColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _showFilters = !_showFilters),
                        ),
                    ],
                  ),
                ),

                // Active filter chips
                if (_hasActiveFilters(filters))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 16, color: CScholarColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (filters.programId != null)
                                Chip(
                                  label: Text('Program: ${filters.programId}'),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => ref.read(searchFiltersProvider.notifier).setProgram(null),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (filters.researchType != null)
                                Chip(
                                  label: Text(filters.researchType!),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => ref.read(searchFiltersProvider.notifier).setResearchType(null),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (filters.status != null)
                                Chip(
                                  label: Text(filters.status!),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => ref.read(searchFiltersProvider.notifier).setStatus(null),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(searchFiltersProvider.notifier).clear(),
                          child: const Text('Clear all', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // Mobile filter panel
                if (!isWide && _showFilters)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: _filterSidebar(programs, categories, filters),
                  ),

                // Semantic search banner
                if (_isSemanticSearch)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: CScholarColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CScholarColors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: CScholarColors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing AI-powered semantic matches for "${_searchController.text}"',
                            style: const TextStyle(fontSize: 13, color: CScholarColors.orange, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Results header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      theses.when(
                        data: (t) => Text(
                          '${t?.length ?? 0} results',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: CScholarColors.textSecondary),
                        ),
                        loading: () => const Text('Loading...', style: TextStyle(color: CScholarColors.textSecondary)),
                        error: (_, __) => const Text('Error loading results', style: TextStyle(color: CScholarColors.error)),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Newest')),
                          DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                          DropdownMenuItem(value: 'title', child: Text('Title A–Z')),
                          DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
                        ],
                        onChanged: (v) => setState(() => _sortBy = v ?? 'newest'),
                      ),
                    ],
                  ),
                ),

                // Results grid
                Expanded(
                  child: theses.when(
                    data: (thesesList) {
                      if (thesesList == null || thesesList.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: CScholarColors.textHint),
                              SizedBox(height: 16),
                              Text('No studies found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                              SizedBox(height: 8),
                              Text('Try adjusting your search or filters', style: TextStyle(color: CScholarColors.textSecondary)),
                            ],
                          ),
                        );
                      }
                      final sorted = _sortResults(thesesList);
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 0, isWide ? 24 : 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : (size.width > 500 ? 2 : 1),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.45 : 1.6,
                        ),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          // Show mock semantic similarity scores when AI search is on
                          final mockScores = [0.94, 0.89, 0.87, 0.85, 0.82, 0.79, 0.76, 0.73];
                          final score = _isSemanticSearch ? mockScores[index % mockScores.length] : null;
                          return ThesisCard(thesis: sorted[index], similarityScore: score);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        backgroundColor: Colors.white,
        indicatorColor: CScholarColors.primaryGreenVeryLight,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/student/dashboard');
          if (i == 1) {}
          if (i == 2) context.go('/saved');
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

  void _doSearch(WidgetRef ref) {
    final params = ThesisListParams(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      programId: ref.read(searchFiltersProvider).programId,
      academicYearId: ref.read(searchFiltersProvider).academicYearId,
      researchType: ref.read(searchFiltersProvider).researchType,
      status: ref.read(searchFiltersProvider).status,
    );
    ref.invalidate(thesisListProvider(params));
  }

  bool _hasActiveFilters(SearchFilters f) =>
      f.programId != null || f.academicYearId != null || f.researchType != null || f.status != null;

  List<Thesis> _sortResults(List<Thesis> list) {
    final sorted = List<Thesis>.from(list);
    switch (_sortBy) {
      case 'oldest':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'title':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'relevance':
        // Keep mock order
        break;
      default: // newest
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  Widget _filterSidebar(AsyncValue<List<Program>> programs, AsyncValue<List<Category>> categories, SearchFilters filters) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
        const SizedBox(height: 16),

        // Research Type
        const Text('Research Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('Thesis', filters.researchType == 'Thesis', () {
              ref.read(searchFiltersProvider.notifier).setResearchType(
                    filters.researchType == 'Thesis' ? null : 'Thesis',
                  );
            }),
            _filterChip('Capstone', filters.researchType == 'Capstone', () {
              ref.read(searchFiltersProvider.notifier).setResearchType(
                    filters.researchType == 'Capstone' ? null : 'Capstone',
                  );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Status
        const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('Published', filters.status == 'published', () {
              ref.read(searchFiltersProvider.notifier).setStatus(filters.status == 'published' ? null : 'published');
            }),
            _filterChip('Approved', filters.status == 'approved', () {
              ref.read(searchFiltersProvider.notifier).setStatus(filters.status == 'approved' ? null : 'approved');
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Programs
        const Text('Program', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textSecondary)),
        const SizedBox(height: 8),
        programs.when(
          data: (list) => Column(
            children: list.map((p) => RadioListTile<int?>(
              title: Text(p.name, style: const TextStyle(fontSize: 14)),
              value: p.id,
              groupValue: filters.programId,
              onChanged: (v) => ref.read(searchFiltersProvider.notifier).setProgram(v),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Error loading programs', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 20),

        // Clear
        OutlinedButton(
          onPressed: () => ref.read(searchFiltersProvider.notifier).clear(),
          style: OutlinedButton.styleFrom(
            foregroundColor: CScholarColors.primaryGreen,
            side: const BorderSide(color: CScholarColors.primaryGreen),
          ),
          child: const Text('Clear All Filters'),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CScholarColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? CScholarColors.primaryGreen : CScholarColors.dividerLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : CScholarColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
