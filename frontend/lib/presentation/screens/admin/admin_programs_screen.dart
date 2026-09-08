// Admin: Programs & Categories management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminProgramsScreen extends ConsumerStatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  ConsumerState<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends ConsumerState<AdminProgramsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider);
    final years = ref.watch(academicYearsProvider);
    final categories = ref.watch(categoriesProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    Widget body() => Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
                onPressed: () => context.go('/admin/dashboard'),
              ),
        title: const Text('Programs & Categories', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: CScholarColors.dividerLight, height: 1)),
      ),
      body: Column(
        children: [
          Container(color: Colors.white, child: TabBar(
            controller: _tabController,
            labelColor: CScholarColors.primaryGreen,
            unselectedLabelColor: CScholarColors.textSecondary,
            indicatorColor: CScholarColors.primaryGreen,
            tabs: const [
              Tab(text: 'Programs'),
              Tab(text: 'Academic Years'),
              Tab(text: 'Categories'),
            ],
          )),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _buildProgramsTab(programs, isWide),
              _buildYearsTab(years, isWide),
              _buildCategoriesTab(categories, isWide),
            ],
          )),
        ],
      ),
    );

    if (!isWide) return body();

    return Row(
      children: [
        const AdminSidebar(currentPath: '/admin/programs'),
        Container(width: 1, color: CScholarColors.dividerLight),
        Expanded(child: body()),
      ],
    );
  }

  Widget _buildProgramsTab(AsyncValue<List<Program>> programs, bool isWide) {
    return programs.when(
      data: (list) => _buildDataTable(
        isWide: isWide,
        cols: const ['Code', 'Program Name', 'College'],
        rows: list.map((p) => [p.code, p.name, p.college ?? 'CEIT']).toList(),
        emptyMessage: 'No programs found',
        addAction: () => _showAddProgramDialog(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildYearsTab(AsyncValue<List<AcademicYear>> years, bool isWide) {
    return years.when(
      data: (list) => _buildDataTable(
        isWide: isWide,
        cols: const ['Label', 'Start Year', 'End Year', 'Status'],
        rows: list.map((y) => [y.label, y.startYear.toString(), y.endYear.toString(), y.isActive ? 'Active' : 'Inactive']).toList(),
        emptyMessage: 'No academic years found',
        addAction: () => _showAddYearDialog(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCategoriesTab(AsyncValue<List<Category>> categories, bool isWide) {
    return categories.when(
      data: (list) => _buildDataTable(
        isWide: isWide,
        cols: const ['Name', 'Description'],
        rows: list.map((c) => [c.name, c.description ?? '—']).toList(),
        emptyMessage: 'No categories found',
        addAction: () => _showAddCategoryDialog(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDataTable({
    required bool isWide,
    required List<String> cols,
    required List<List<String>> rows,
    required String emptyMessage,
    required VoidCallback addAction,
  }) {
    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${rows.length} records', style: const TextStyle(color: CScholarColors.textSecondary)),
                FilledButton.icon(
                  onPressed: addAction,
                  style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Add New', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CScholarColors.dividerLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(CScholarColors.backgroundLight),
                columns: cols.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text(c))).toList())).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final r = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CScholarColors.dividerLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: r.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 80, child: Text('${cols[e.key]}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CScholarColors.textSecondary))),
                    Expanded(child: Text(r[e.key], style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddProgramDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Program'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g., BSIT)')),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameCtrl.text} added'), backgroundColor: CScholarColors.success));
            },
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddYearDialog() {
    final labelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Academic Year'),
        content: TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g., 2025–2026)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${labelCtrl.text} added'), backgroundColor: CScholarColors.success));
            },
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameCtrl.text} added'), backgroundColor: CScholarColors.success));
            },
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
