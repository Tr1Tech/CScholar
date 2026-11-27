// Admin: Programs & Categories — Stitch design v2
// Sidebar + topbar + tabbed content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
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
  ConsumerState<AdminProgramsScreen> createState() =>
      _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends ConsumerState<AdminProgramsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _tabIndex = 0;

  static const _tabs = ['Programs', 'Academic Years', 'Categories', 'Advisers'];
  static const _addLabels = [
    'Add Program',
    'Add Academic Year',
    'Add Category',
    'Add Adviser',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
    final isWide = size.width > CScholarBreakpoints.mobile;

    if (!isWide) {
      return _mobileLayout(context, ref);
    }

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/programs'),
      topbar: const AdminTopbar(section: AdminSearchSection.programs),
      mobileTitle: 'Programs & Categories',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Header-first on the page rhythm; tab content below is interactive
        // (TabBarView), so it must never cascade per-row.
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            PageHeader(
              title: 'Programs & Categories',
              subtitle: 'Curate programs, academic years, categories, and adviser accounts.',
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
                  // Same filter language as Users and Theses: one recessed
                  // track with a raised pill. A Material TabBar drew a second
                  // selection language (underline) inside the same card.
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: NeumorphSegmented(
                      labels: _tabs,
                      selectedIndex: _tabIndex,
                      // Drives the controller so the swipe gesture and the
                      // control can never disagree about which tab is current.
                      onChanged: (i) => _tabCtrl.animateTo(i),
                    ),
                  ),
                  const Divider(height: 1),
                  // Tab content
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _programsTab(context, ref),
                        _academicYearsTab(context, ref),
                        _categoriesTab(context, ref),
                        _advisersTab(context, ref),
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

  /// "In use" / "Unused" marker for a metadata row.
  ///
  /// The count is supplied by the list endpoints (`thesis_count`), the same
  /// figure the delete route checks, so the admin can tell at a glance whether
  /// the trash icon will succeed before pressing it. Clicking delete on a used
  /// row still opens the "Cannot delete" dialog with the offending studies.
  Widget _usageBadge({required int count, required String inUseHint}) {
    final used = count > 0;
    final label = used
        ? '$count ${count == 1 ? 'STUDY' : 'STUDIES'}'
        : 'UNUSED';
    return Tooltip(
      message: used
          ? inUseHint
          : 'No studies use this record yet, so it can be deleted.',
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: used
              ? CScholarColors.errorLight
              : CScholarColors.primaryGreenVeryLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              used ? Icons.link : Icons.check_circle_outline,
              size: 11,
              color: used ? CScholarColors.error : CScholarColors.primaryGreen,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: used
                    ? CScholarColors.error
                    : CScholarColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Destructive icon for a row. Displayed muted when the record is in use so
  /// the affordance matches the server rule; it stays tappable because the
  /// blocked dialog is where "View studies" lives.
  Widget _deleteButton({
    required int count,
    required String entityLabel,
    required VoidCallback onPressed,
  }) {
    final used = count > 0;
    return NeumorphIconButton(
      icon: Icons.delete_outline,
      tooltip: used
          ? 'In use by $count ${count == 1 ? 'study' : 'studies'} — click to review'
          : 'Delete $entityLabel',
      color: used ? CScholarColors.textHint : CScholarColors.error,
      onPressed: onPressed,
    );
  }

  /// Empty panel for a tab whose search matched nothing. The clear (×) lives in
  /// the topbar field, so the panel only has to say what was searched.
  Widget _noMatches(IconData icon, String what, String query) => EmptyState(
    icon: icon,
    compact: true,
    title: 'No matches',
    message: 'No $what match "$query".',
  );

  /// Adviser records double as faculty identity: the backend maps a faculty
  /// login to theses through `LOWER(advisers.email) = LOWER(user.email)`. An
  /// imported adviser starts with no email, so this tab is where the admin
  /// completes the link instead of the importer inventing an address.
  Widget _advisersTab(BuildContext context, WidgetRef ref) {
    final advisers = ref.watch(advisersProvider);
    final query = ref
        .watch(adminSearchProvider(AdminSearchSection.programs))
        .trim();
    final needle = query.toLowerCase();
    return asyncSlot(
      advisers,
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (all) {
        final list = needle.isEmpty
            ? all
            : all
                  .where(
                    (a) =>
                        a.fullName.toLowerCase().contains(needle) ||
                        (a.email ?? '').toLowerCase().contains(needle),
                  )
                  .toList();
        if (all.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: EmptyState(
              icon: Icons.badge_outlined,
              compact: true,
              title: 'No advisers yet',
              message:
                  'Add an adviser, then set their CSU email to link their '
                  'faculty account and their theses.',
            ),
          );
        }
        if (list.isEmpty) {
          return _noMatches(Icons.badge_outlined, 'advisers', query);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                "Set an adviser's CSU email to match their CScholar login. "
                'Their My Theses, My Students, and Analytics pages then fill '
                'in automatically. Advisers imported from a spreadsheet start '
                'without an email.',
                style: CScholarTextStyles.body(
                  11.5,
                  FontWeight.w400,
                  CScholarColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final a = list[i];
                  final email = (a.email ?? '').trim();
                  final linked = email.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CScholarCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderRadius: CScholarRadius.xl,
                      child: Row(
                        children: [
                          GelAvatar(name: a.fullName, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CScholarTextStyles.body(
                                    13.5,
                                    FontWeight.w700,
                                    CScholarColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  linked ? email : 'No email — not linked to a faculty account',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CScholarTextStyles.body(
                                    11.5,
                                    FontWeight.w400,
                                    CScholarColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: linked
                                  ? CScholarColors.primaryGreenVeryLight
                                  : CScholarColors.textSecondary.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              linked ? 'LINKED' : 'NO ACCOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: linked
                                    ? CScholarColors.primaryGreen
                                    : CScholarColors.textSecondary,
                              ),
                            ),
                          ),
                          NeumorphIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit adviser / link faculty account',
                            color: CScholarColors.violetInk,
                            onPressed: () =>
                                _showAdviserDialog(context, ref, existing: a),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (err, _) => EmptyState(
        compact: true,
        icon: Icons.error_outline,
        title: "Couldn't load advisers",
        message: userFacingError(
          err,
          fallback: 'The adviser list could not be loaded. Try again.',
        ),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(advisersProvider),
      ),
    );
  }

  Widget _programsTab(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    final query = ref
        .watch(adminSearchProvider(AdminSearchSection.programs))
        .trim();
    final needle = query.toLowerCase();
    return asyncSlot(
      programs,
      // The cross-fade's skeleton IS the loading branch, so the panel cannot
      // jump when the rows land.
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (all) {
        final list = needle.isEmpty
            ? all
            : all
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(needle) ||
                        p.code.toLowerCase().contains(needle) ||
                        (p.college ?? '').toLowerCase().contains(needle),
                  )
                  .toList();
        if (list.isEmpty) {
          return _noMatches(Icons.school_outlined, 'programs', query);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CScholarCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                borderRadius: CScholarRadius.xl,
                child: Row(
                  children: [
                    GelAvatar(name: p.name, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              13.5,
                              FontWeight.w700,
                              CScholarColors.textPrimary,
                            ),
                          ),
                          Text(
                            p.college ?? p.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              11.5,
                              FontWeight.w400,
                              CScholarColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _usageBadge(
                      count: p.thesisCount,
                      inUseHint:
                          '${p.thesisCount} ${p.thesisCount == 1 ? 'study uses' : 'studies use'} '
                          'this program. Reassign them before deleting.',
                    ),
                    NeumorphIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit program',
                      color: CScholarColors.violetInk,
                      onPressed: () =>
                          _showProgramDialog(context, ref, existing: p),
                    ),
                    const SizedBox(width: 8),
                    // Destructive last: the rightmost slot is the one a fast
                    // hand reaches by accident.
                    _deleteButton(
                      count: p.thesisCount,
                      entityLabel: 'program',
                      onPressed: () => _deleteMeta(
                        context,
                        ref,
                        endpoint: '/api/programs',
                        id: p.id,
                        name: p.name,
                        entityLabel: 'program',
                        query: {'program_id': '${p.id}'},
                        refresher: () => ref.invalidate(programsProvider),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      error: (err, _) => EmptyState(
        compact: true,
        icon: Icons.error_outline,
        title: "Couldn't load programs",
        message: userFacingError(
          err,
          fallback: 'Programs could not be loaded. Try again.',
        ),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(programsProvider),
      ),
    );
  }

  Widget _academicYearsTab(BuildContext context, WidgetRef ref) {
    final years = ref.watch(academicYearsProvider);
    final query = ref
        .watch(adminSearchProvider(AdminSearchSection.programs))
        .trim();
    final needle = query.toLowerCase();
    return asyncSlot(
      years,
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (all) {
        final list = needle.isEmpty
            ? all
            : all
                  .where(
                    (y) =>
                        y.label.toLowerCase().contains(needle) ||
                        '${y.startYear} ${y.endYear}'.contains(needle),
                  )
                  .toList();
        if (list.isEmpty) {
          return _noMatches(
            Icons.calendar_today_outlined,
            'academic years',
            query,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final y = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CScholarCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                borderRadius: CScholarRadius.xl,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: CScholarColors.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            y.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              13.5,
                              FontWeight.w700,
                              CScholarColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${y.startYear} - ${y.endYear}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              11.5,
                              FontWeight.w400,
                              CScholarColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!y.isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: CScholarColors.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'INACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: CScholarColors.textSecondary,
                          ),
                        ),
                      ),
                    _usageBadge(
                      count: y.thesisCount,
                      inUseHint:
                          '${y.thesisCount} ${y.thesisCount == 1 ? 'study uses' : 'studies use'} '
                          'this academic year. Set it inactive or reassign them.',
                    ),
                    NeumorphIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit academic year',
                      color: CScholarColors.violetInk,
                      onPressed: () =>
                          _showYearDialog(context, ref, existing: y),
                    ),
                    const SizedBox(width: 8),
                    _deleteButton(
                      count: y.thesisCount,
                      entityLabel: 'academic year',
                      onPressed: () => _deleteMeta(
                        context,
                        ref,
                        endpoint: '/api/academic-years',
                        id: y.id,
                        name: y.label,
                        entityLabel: 'academic year',
                        query: {'year_id': '${y.id}'},
                        refresher: () => ref.invalidate(academicYearsProvider),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      error: (err, _) => EmptyState(
        compact: true,
        icon: Icons.error_outline,
        title: "Couldn't load academic years",
        message: userFacingError(
          err,
          fallback: 'Academic years could not be loaded. Try again.',
        ),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(academicYearsProvider),
      ),
    );
  }

  Widget _categoriesTab(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final query = ref
        .watch(adminSearchProvider(AdminSearchSection.programs))
        .trim();
    final needle = query.toLowerCase();
    return asyncSlot(
      categories,
      skeleton: const SkeletonList(count: 4, cardHeight: 64),
      data: (all) {
        final list = needle.isEmpty
            ? all
            : all
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(needle) ||
                        (c.description ?? '').toLowerCase().contains(needle),
                  )
                  .toList();
        if (list.isEmpty) {
          return _noMatches(Icons.category_outlined, 'categories', query);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final c = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CScholarCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                borderRadius: CScholarRadius.xl,
                child: Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: CScholarColors.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              13.5,
                              FontWeight.w700,
                              CScholarColors.textPrimary,
                            ),
                          ),
                          Text(
                            c.description ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              11.5,
                              FontWeight.w400,
                              CScholarColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _usageBadge(
                      count: c.thesisCount,
                      inUseHint:
                          '${c.thesisCount} ${c.thesisCount == 1 ? 'study is' : 'studies are'} '
                          'tagged with this category. Remove the tag before deleting.',
                    ),
                    NeumorphIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit category',
                      color: CScholarColors.violetInk,
                      onPressed: () =>
                          _showCategoryDialog(context, ref, existing: c),
                    ),
                    const SizedBox(width: 8),
                    _deleteButton(
                      count: c.thesisCount,
                      entityLabel: 'category',
                      onPressed: () => _deleteMeta(
                        context,
                        ref,
                        endpoint: '/api/categories',
                        id: c.id,
                        name: c.name,
                        entityLabel: 'category',
                        query: {'category_id': '${c.id}'},
                        refresher: () => ref.invalidate(categoriesProvider),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      error: (err, _) => EmptyState(
        compact: true,
        icon: Icons.error_outline,
        title: "Couldn't load categories",
        message: userFacingError(
          err,
          fallback: 'Categories could not be loaded. Try again.',
        ),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(categoriesProvider),
      ),
    );
  }

  /// Destructive twin of [_saveMeta]: confirm first, then refresh the list the
  /// row came from. A record still referenced by theses is rejected by the
  /// server's foreign key, and that message is what the snackbar shows.
  Future<int?> _usageCount(WidgetRef ref, Map<String, String> query) async {
    try {
      final qs = query.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/theses?$qs&show_all=true&page=1&per_page=1&log_activity=false');
      if (data is Map && data['total'] is num) {
        return (data['total'] as num).toInt();
      }
    } catch (_) {
      // The delete still has a server-side guard; fall back to the dialog.
    }
    return null;
  }

  Future<void> _showStudiesFor(
    BuildContext context,
    WidgetRef ref,
    Map<String, String> query,
    String title,
  ) async {
    List<dynamic> items = const [];
    try {
      final qs = query.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/theses?$qs&show_all=true&page=1&per_page=100&log_activity=false');
      if (data is Map && data['theses'] is List) {
        items = data['theses'] as List;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: 'The studies for this item could not be loaded.',
              ),
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await showClayDialog<void>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          height: 340,
          child: items.isEmpty
              ? const Center(child: Text('No studies use this item.'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: CScholarMaterial.rim, height: 1),
                  itemBuilder: (rowCtx, i) {
                    final item = items[i] as Map;
                    final status = (item['status'] ?? '').toString();
                    return ListTile(
                      dense: true,
                      title: Text(
                        (item['title'] ?? 'Untitled').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(status.isEmpty
                          ? 'Study'
                          : status[0].toUpperCase() + status.substring(1)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/thesis/${item['id']}');
                      },
                    );
                  },
                ),
        ),
        actions: [
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx),
            label: 'Close',
            gel: false,
          ),
        ],
      ),
    );
  }

  Future<void> _showBlockedByStudies(
    BuildContext context,
    WidgetRef ref,
    String name,
    int? used,
    Map<String, String> query,
    String entityLabel, {
    String? message,
  }) async {
    final subject = used == null
        ? 'This $entityLabel is still used by studies.'
        : '$used ${used == 1 ? 'study uses' : 'studies use'} this $entityLabel.';
    final body = message ??
        '$subject Reassign them first, or keep this $entityLabel. '
            'No studies were deleted.';
    final view = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text('Cannot delete $entityLabel'),
        content: Text(body),
        actions: [
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx, false),
            label: 'Close',
            gel: false,
          ),
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'View studies',
          ),
        ],
      ),
    );
    if (view == true && context.mounted) {
      await _showStudiesFor(context, ref, query, name);
    }
  }

  Future<void> _deleteMeta(
    BuildContext context,
    WidgetRef ref, {
    required String endpoint,
    required int id,
    required String name,
    required String entityLabel,
    required Map<String, String> query,
    required void Function() refresher,
  }) async {
    final used = await _usageCount(ref, query);
    if (!context.mounted) return;

    if (used != null && used > 0) {
      // Authors, advisers, and categories all guard the join row now: the
      // studies stay, and the link is what must go first. Same rule as the
      // server, so the dialog never offers a delete that would be refused.
      final subject = '$used ${used == 1 ? 'study' : 'studies'}';
      final message = switch (entityLabel) {
        'category' =>
          '$subject ${used == 1 ? 'is' : 'are'} tagged with this category. '
              'Remove the tag from those studies first. No studies were changed.',
        'author' =>
          '$subject ${used == 1 ? 'lists' : 'list'} this author. Correct the '
              'name instead, or remove the author from those studies first. '
              'No studies were changed.',
        'adviser' =>
          '$subject ${used == 1 ? 'names' : 'name'} this adviser. Correct the '
              'name instead, or reassign those studies first. '
              'No studies were changed.',
        _ => null,
      };
      await _showBlockedByStudies(
        context,
        ref,
        name,
        used,
        query,
        entityLabel,
        message: message,
      );
      return;
    }

    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Delete'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx, false),
            label: 'Cancel',
            gel: false,
          ),
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Delete',
            danger: true,
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(apiServiceProvider).delete('$endpoint/$id');
      refresher();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name deleted'),
            backgroundColor: CScholarColors.success,
          ),
        );
      }
    } catch (e) {
      final detail = apiErrorDetail(e);
      if (detail != null) {
        if (context.mounted) {
          await _showBlockedByStudies(
            context,
            ref,
            name,
            null,
            query,
            entityLabel,
            message: detail,
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: "The change couldn't be saved. Try again.",
              ),
            ),
          ),
        );
      }
    }
  }

  void _addForTab(BuildContext context) {
    if (_tabIndex == 1) {
      _showYearDialog(context, ref);
    } else if (_tabIndex == 2) {
      _showCategoryDialog(context, ref);
    } else if (_tabIndex == 3) {
      _showAdviserDialog(context, ref);
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
          SnackBar(
            content: Text(successMessage),
            backgroundColor: CScholarColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: "The change couldn't be saved. Try again.",
              ),
            ),
          ),
        );
      }
    }
  }

  void _showProgramDialog(
    BuildContext context,
    WidgetRef ref, {
    Program? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final descCtrl = TextEditingController(text: existing?.college ?? '');
    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(existing == null ? 'Add Program' : 'Edit Program'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeumorphField(controller: nameCtrl, label: 'Name *'),
              const SizedBox(height: 12),
              NeumorphField(controller: codeCtrl, label: 'Code (e.g. BSIT)'),
              const SizedBox(height: 12),
              NeumorphField(controller: descCtrl, label: 'Description'),
            ],
          ),
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
                context,
                ref,
                endpoint: '/api/programs',
                id: existing?.id,
                body: {
                  'name': name,
                  if (codeCtrl.text.trim().isNotEmpty)
                    'code': codeCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                },
                refresher: () => ref.invalidate(programsProvider),
                successMessage: existing == null
                    ? 'Program added'
                    : 'Program updated',
              );
            },
            label: 'Save',
          ),
        ],
      ),
    );
  }

  void _showYearDialog(
    BuildContext context,
    WidgetRef ref, {
    AcademicYear? existing,
  }) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final startCtrl = TextEditingController(
      text: existing != null ? '${existing.startYear}' : '',
    );
    final endCtrl = TextEditingController(
      text: existing != null ? '${existing.endYear}' : '',
    );
    bool isActive = existing?.isActive ?? true;
    showClayDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => GlassDialog(
          title: Text(
            existing == null ? 'Add Academic Year' : 'Edit Academic Year',
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphField(
                  controller: labelCtrl,
                  label: 'Label * (e.g. 2025-2026)',
                ),
                const SizedBox(height: 12),
                NeumorphField(
                  controller: startCtrl,
                  label: 'Start year *',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                NeumorphField(
                  controller: endCtrl,
                  label: 'End year *',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Active', style: TextStyle(fontSize: 13)),
                    ),
                    NeumorphToggle(
                      value: isActive,
                      onChanged: (v) => setDialog(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
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
                    const SnackBar(
                      content: Text(
                        'Label, start year, and end year are required',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _saveMeta(
                  context,
                  ref,
                  endpoint: '/api/academic-years',
                  id: existing?.id,
                  body: {
                    'name': label,
                    'start_year': start,
                    'end_year': end,
                    'is_active': isActive,
                  },
                  refresher: () => ref.invalidate(academicYearsProvider),
                  successMessage: existing == null
                      ? 'Academic year added'
                      : 'Academic year updated',
                );
              },
              label: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeumorphField(controller: nameCtrl, label: 'Name *'),
              const SizedBox(height: 12),
              NeumorphField(controller: descCtrl, label: 'Description'),
            ],
          ),
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
                context,
                ref,
                endpoint: '/api/categories',
                id: existing?.id,
                body: {
                  'name': name,
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                },
                refresher: () => ref.invalidate(categoriesProvider),
                successMessage: existing == null
                    ? 'Category added'
                    : 'Category updated',
              );
            },
            label: 'Save',
          ),
        ],
      ),
    );
  }

  void _showAdviserDialog(
    BuildContext context,
    WidgetRef ref, {
    Adviser? existing,
  }) {
    final firstCtrl = TextEditingController(text: existing?.firstName ?? '');
    final middleCtrl = TextEditingController(text: existing?.middleName ?? '');
    final lastCtrl = TextEditingController(text: existing?.lastName ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(existing == null ? 'Add Adviser' : 'Edit Adviser'),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "The email must match the faculty member's CScholar login. "
                  'Their My Theses, My Students, and Analytics pages populate '
                  'from this link. Leave it blank to keep the adviser unlinked.',
                  style: CScholarTextStyles.body(
                    12,
                    FontWeight.w400,
                    CScholarColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                NeumorphField(controller: firstCtrl, label: 'First name *'),
                const SizedBox(height: 12),
                NeumorphField(controller: middleCtrl, label: 'Middle name'),
                const SizedBox(height: 12),
                NeumorphField(controller: lastCtrl, label: 'Last name *'),
                const SizedBox(height: 12),
                NeumorphField(
                  controller: emailCtrl,
                  label: 'CSU email (faculty login)',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx),
            label: 'Cancel',
            gel: false,
          ),
          NeumorphButton(
            onPressed: () {
              final first = firstCtrl.text.trim();
              final last = lastCtrl.text.trim();
              final middle = middleCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (first.isEmpty || last.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('First and last name are required'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              _saveMeta(
                context,
                ref,
                endpoint: '/api/advisers',
                id: existing?.id,
                body: {
                  'first_name': first,
                  'last_name': last,
                  'middle_name': middle.isEmpty ? null : middle,
                  'email': email.isEmpty ? null : email,
                },
                refresher: () => ref.invalidate(advisersProvider),
                successMessage: existing == null
                    ? 'Adviser added'
                    : (email.isEmpty
                          ? 'Adviser unlinked'
                          : 'Adviser linked to $email'),
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
          tooltip: 'Back to dashboard',
          icon: Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: Text(
          'Programs & Categories',
          style: TextStyle(
            color: CScholarColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: CScholarColors.primaryGreen,
          unselectedLabelColor: CScholarColors.textSecondary,
          indicatorColor: CScholarColors.primaryGreen,
          tabs: const [
            Tab(text: 'Programs'),
            Tab(text: 'Years'),
            Tab(text: 'Categories'),
            Tab(text: 'Advisers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _programsTab(context, ref),
          _academicYearsTab(context, ref),
          _categoriesTab(context, ref),
          _advisersTab(context, ref),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addForTab(context),
        backgroundColor: CScholarColors.primaryFill,
        child: const Icon(Icons.add, color: CScholarColors.white),
      ),
    );
  }
}
