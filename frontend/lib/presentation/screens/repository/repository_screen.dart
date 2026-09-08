// Repository / Search — Stitch design v2
// Uses shared StudentLayout (sidebar + topbar)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isSemantic = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theses = ref.watch(thesisListProvider(ThesisListParams(query: _query.isEmpty ? null : _query)));

    return StudentLayout(
      currentIndex: 1,
      searchController: _searchController,
      searchHint: 'Search thesis, capstone, topic, author, keyword...',
      onSearchChanged: (v) => setState(() => _query = v),
      onSearchSubmit: () => setState(() => _query = _searchController.text),
      child: Row(
        children: [
          // Filters sidebar (desktop)
          if (MediaQuery.of(context).size.width > 900)
            Container(
              width: 240,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                  const SizedBox(height: 16),
                  _filterSection('Program', ['BSIT', 'BSCS', 'BSIS', 'BSECE', 'BSCpE', 'BSME']),
                  const SizedBox(height: 16),
                  _filterSection('Year', ['2024-2025', '2023-2024', '2022-2023']),
                  const SizedBox(height: 16),
                  _filterSection('Type', ['Thesis', 'Capstone']),
                ],
              ),
            ),
          // Main content
          Expanded(
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
                          const Text('Repository', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                          Text('${theses.value?.length ?? 0} studies found', style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                        ],
                      ),
                      // Semantic search toggle
                      Row(
                        children: [
                          const Text('Semantic Search', style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isSemantic,
                            onChanged: (v) => setState(() => _isSemantic = v),
                            activeThumbColor: CScholarColors.primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Results grid
                  Expanded(
                    child: theses.when(
                      data: (list) {
                        if (list == null || list.isEmpty) {
                          return const Center(child: Text('No studies found'));
                        }
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) => ThesisCard(
                            thesis: list[i],
                            similarityScore: _isSemantic ? [0.96, 0.91, 0.87, 0.82, 0.78][i % 5] : null,
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const Center(child: Text('Could not load studies')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
        const SizedBox(height: 8),
        ...options.map((o) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}, activeColor: CScholarColors.primaryGreen),
              Text(o, style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
            ],
          ),
        )),
      ],
    );
  }
}
