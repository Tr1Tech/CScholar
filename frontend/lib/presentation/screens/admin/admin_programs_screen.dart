// Admin: Programs & Categories — Stitch design v2
// Sidebar + topbar + tabbed content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

class AdminProgramsScreen extends ConsumerStatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  ConsumerState<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends ConsumerState<AdminProgramsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _tabIndex = 0;

  static const _addLabels = ['Add Program', 'Add Academic Year', 'Add Category'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabIndex != _tabCtrl.index && mounted) {
        setState(() => _tabIndex = _tabCtrl.index);
      }
    });
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

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/programs'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Programs & Categories',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        // Header-first on the page rhythm; tab content below is interactive
        // (TabBarView), so it must never cascade per-row.
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            PageHeader(
              title: 'Programs & Categories',
              subtitle: 'Curate programs, academic years, and categories.',
              action: NeumorphButton(
                onPressed: () => _addForTab(context),
                icon: Icons.add,
                label: _addLabels[_tabIndex],
              ),
            ),
            const SizedBox(height: 20),
            CScholarCard(
              padding: EdgeInsets.zero,
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
                  SizedBox(
                    height: 520,
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
          ],
        ),
      ),
    );
  }

  Widget _programsTab(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    return asyncSlot(programs,
      // The cross-fade's skeleton IS the loading branch, so the panel cannot
      // jump when the rows land.
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final p = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CScholarCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: CScholarRadius.md,
              child: Row(
                children: [
                  GelAvatar(name: p.name, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: CScholarTextStyles.inter(13.5,
                                FontWeight.w700, CScholarColors.textPrimary)),
                        Text(p.college ?? p.code,
                            style: CScholarTextStyles.inter(11.5,
                                FontWeight.w400, CScholarColors.textMuted)),
                      ],
                    ),
                  ),
                  NeumorphIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit program',
                    onPressed: () =>
                        _showProgramDialog(context, ref, existing: p),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      error: (_, _) => const Center(child: Text('Could not load programs')),
    );
  }

  Widget _academicYearsTab(BuildContext context, WidgetRef ref) {
    final years = ref.watch(academicYearsProvider);
    return asyncSlot(years,
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final y = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CScholarCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: CScholarRadius.md,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: CScholarColors.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(y.label,
                            style: CScholarTextStyles.inter(13.5,
                                FontWeight.w700, CScholarColors.textPrimary)),
                        Text('${y.startYear} - ${y.endYear}',
                            style: CScholarTextStyles.inter(11.5,
                                FontWeight.w400, CScholarColors.textMuted)),
                      ],
                    ),
                  ),
                  if (!y.isActive)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CScholarColors.textSecondary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('INACTIVE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: CScholarColors.textSecondary)),
                    ),
                  NeumorphIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit academic year',
                    onPressed: () =>
                        _showYearDialog(context, ref, existing: y),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      error: (_, _) => const Center(child: Text('Could not load academic years')),
    );
  }

  Widget _categoriesTab(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return asyncSlot(categories,
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final c = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CScholarCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: CScholarRadius.md,
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: CScholarColors.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: CScholarTextStyles.inter(13.5,
                                FontWeight.w700, CScholarColors.textPrimary)),
                        Text(c.description ?? '',
                            style: CScholarTextStyles.inter(11.5,
                                FontWeight.w400, CScholarColors.textMuted)),
                      ],
                    ),
                  ),
                  NeumorphIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit category',
                    onPressed: () =>
                        _showCategoryDialog(context, ref, existing: c),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      error: (_, _) => const Center(child: Text('Could not load categories')),
    );
  }

  void _addForTab(BuildContext context) {
    if (_tabIndex == 1) {
      _showYearDialog(context, ref);
    } else if (_tabIndex == 2) {
      _showCategoryDialog(context, ref);
    } else {
      _showProgramDialog(context, ref);
    }
  }

  Future<void> _saveMeta(
    BuildContext context,
    WidgetRef ref, {
    required String endpoint,
    required int? id,
    required Map<String, dynamic> body,
    required void Function() refresher,
    required String successMessage,
  }) async {
    try {
      if (id == null) {
        await ref.read(apiServiceProvider).post(endpoint, body);
      } else {
        await ref.read(apiServiceProvider).put('$endpoint/$id', body);
      }
      refresher();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: CScholarColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showProgramDialog(BuildContext context, WidgetRef ref, {Program? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final descCtrl = TextEditingController(text: existing?.college ?? '');
    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(existing == null ? 'Add Program' : 'Edit Program'),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            NeumorphField(controller: nameCtrl, label: 'Name *'),
            const SizedBox(height: 12),
            NeumorphField(controller: codeCtrl, label: 'Code (e.g. BSIT)'),
            const SizedBox(height: 12),
            NeumorphField(controller: descCtrl, label: 'Description'),
          ]),
        ),
        actions: [
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx),
            label: 'Cancel',
            gel: false,
          ),
          NeumorphButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              Navigator.pop(ctx);
              _saveMeta(
                context, ref,
                endpoint: '/api/programs',
                id: existing?.id,
                body: {
                  'name': name,
                  if (codeCtrl.text.trim().isNotEmpty) 'code': codeCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                },
                refresher: () => ref.invalidate(programsProvider),
                successMessage: existing == null ? 'Program added' : 'Program updated',
              );
            },
            label: 'Save',
          ),
        ],
      ),
    );
  }

  void _showYearDialog(BuildContext context, WidgetRef ref, {AcademicYear? existing}) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final startCtrl = TextEditingController(text: existing != null ? '${existing.startYear}' : '');
    final endCtrl = TextEditingController(text: existing != null ? '${existing.endYear}' : '');
    bool isActive = existing?.isActive ?? true;
    showClayDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => GlassDialog(
          title: Text(existing == null ? 'Add Academic Year' : 'Edit Academic Year'),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              NeumorphField(controller: labelCtrl, label: 'Label * (e.g. 2025-2026)'),
              const SizedBox(height: 12),
              NeumorphField(controller: startCtrl, label: 'Start year *', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              NeumorphField(controller: endCtrl, label: 'End year *', keyboardType: TextInputType.number),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(child: Text('Active', style: TextStyle(fontSize: 13))),
                  NeumorphToggle(
                    value: isActive,
                    onChanged: (v) => setDialog(() => isActive = v),
                  ),
                ],
              ),
            ]),
          ),
          actions: [
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx),
              label: 'Cancel',
              gel: false,
            ),
            NeumorphButton(
              onPressed: () {
                final label = labelCtrl.text.trim();
                final start = int.tryParse(startCtrl.text.trim());
                final end = int.tryParse(endCtrl.text.trim());
                if (label.isEmpty || start == null || end == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Label, start year, and end year are required')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _saveMeta(
                  context, ref,
                  endpoint: '/api/academic-years',
                  id: existing?.id,
                  body: {'name': label, 'start_year': start, 'end_year': end, 'is_active': isActive},
                  refresher: () => ref.invalidate(academicYearsProvider),
                  successMessage: existing == null ? 'Academic year added' : 'Academic year updated',
                );
              },
              label: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            NeumorphField(controller: nameCtrl, label: 'Name *'),
            const SizedBox(height: 12),
            NeumorphField(controller: descCtrl, label: 'Description'),
          ]),
        ),
        actions: [
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx),
            label: 'Cancel',
            gel: false,
          ),
          NeumorphButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              Navigator.pop(ctx);
              _saveMeta(
                context, ref,
                endpoint: '/api/categories',
                id: existing?.id,
                body: {
                  'name': name,
                  if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                },
                refresher: () => ref.invalidate(categoriesProvider),
                successMessage: existing == null ? 'Category added' : 'Category updated',
              );
            },
            label: 'Save',
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: CScholarMaterial.clay,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('Programs & Categories', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: CScholarColors.primaryGreen,
          unselectedLabelColor: CScholarColors.textSecondary,
          indicatorColor: CScholarColors.primaryGreen,
          tabs: const [
            Tab(text: 'Programs'),
            Tab(text: 'Years'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _programsTab(context, ref),
          _academicYearsTab(context, ref),
          _categoriesTab(context, ref),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addForTab(context),
        backgroundColor: CScholarColors.primaryGreen,
        child: const Icon(Icons.add, color: CScholarColors.white),
      ),
    );
  }
}
