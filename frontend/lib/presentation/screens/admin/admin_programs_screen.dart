// Admin: Programs & Categories — Stitch design v2
// Sidebar + topbar + tabbed content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminProgramsScreen extends ConsumerStatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  ConsumerState<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends ConsumerState<AdminProgramsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (!isWide) {
      return _mobileLayout(context, ref);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          const AdminSidebar(currentPath: '/admin/programs'),
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
                  ),
                  child: Row(
                    children: [
                      const Text('Programs & Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Program'),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CScholarColors.dividerLight),
                      ),
                      child: Column(
                        children: [
                          // Tab bar
                          TabBar(
                            controller: _tabCtrl,
                            labelColor: CScholarColors.primaryGreen,
                            unselectedLabelColor: CScholarColors.textSecondary,
                            indicatorColor: CScholarColors.primaryGreen,
                            tabs: const [
                              Tab(text: 'Programs'),
                              Tab(text: 'Academic Years'),
                              Tab(text: 'Categories'),
                            ],
                          ),
                          // Tab content
                          Expanded(
                            child: TabBarView(
                              controller: _tabCtrl,
                              children: [
                                _programsTab(context, ref),
                                _academicYearsTab(context, ref),
                                _categoriesTab(context, ref),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _programsTab(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    return programs.when(
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final p = list[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: CScholarColors.primaryGreen,
                child: Text(p.name[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(p.name),
              subtitle: Text('${p.code} • ${p.college ?? 'CEIT'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: CScholarColors.error), onPressed: () {}),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load programs')),
    );
  }

  Widget _academicYearsTab(BuildContext context, WidgetRef ref) {
    final years = ref.watch(academicYearsProvider);
    return years.when(
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final y = list[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined, color: CScholarColors.primaryGreen),
              title: Text(y.label),
              subtitle: Text('${y.startYear} - ${y.endYear}'),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load academic years')),
    );
  }

  Widget _categoriesTab(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return categories.when(
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final c = list[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.category_outlined, color: CScholarColors.primaryGreen),
              title: Text(c.name),
              subtitle: Text(c.description ?? ''),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load categories')),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('Programs & Categories', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: const Center(child: Text('Mobile view - Programs & Categories')),
    );
  }
}
