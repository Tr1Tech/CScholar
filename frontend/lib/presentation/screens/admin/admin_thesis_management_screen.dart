// Admin: Thesis Management — Stitch design v2
// Sidebar + topbar + data table

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';

class AdminThesisManagementScreen extends ConsumerStatefulWidget {
  const AdminThesisManagementScreen({super.key});

  @override
  ConsumerState<AdminThesisManagementScreen> createState() =>
      _AdminThesisManagementScreenState();
}

class _AdminThesisManagementScreenState
    extends ConsumerState<AdminThesisManagementScreen> {
  /// Params for the watched list: show-all plus the live admin search text.
  /// Mutations refresh through [_params] too, so the table always
  /// re-queries the exact key on screen (filter-preserving refresh).
  ThesisListParams _params() {
    final q = ref.read(adminThesisSearchProvider).trim();
    return ThesisListParams(showAll: true, query: q.isEmpty ? null : q);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(adminThesisSearchProvider).trim();
    final params = ThesisListParams(
        showAll: true, query: searchQuery.isEmpty ? null : searchQuery);
    final theses = ref.watch(thesisListProvider(params));

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/thesis/management'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Thesis Management',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        // Header-first on the page rhythm (same DataTable note as user
        // management: rows are not widgets and enter with the card).
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            PageHeader(
              title: 'Thesis Management',
              subtitle: 'Review statuses, edit records, and curate the repository.',
              action: NeumorphButton(
                onPressed: () => context.go('/admin/thesis/new'),
                icon: Icons.add,
                label: 'Add Thesis',
              ),
            ),
            const SizedBox(height: 20),
            CScholarCard(
              padding: EdgeInsets.zero,
              child: asyncSlot<List<Thesis>?>(
                theses,
                skeleton: const Padding(
                  padding: EdgeInsets.all(24),
                  child: SkeletonList(count: 5, cardHeight: 56),
                ),
                data: (list) {
                  if (list == null || list.isEmpty) {
                    final searching = searchQuery.isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.article_outlined,
                        title: searching ? 'No matches' : 'No theses found',
                        message: searching
                            ? 'No theses match "$searchQuery".'
                            : 'Add the first record to start the repository.',
                        actionLabel:
                            searching ? 'Clear search' : null,
                        onAction: searching
                            ? () => ref
                                .read(adminThesisSearchProvider.notifier)
                                .clear()
                            : null,
                      ),
                    );
                  }
                  // Horizontal scroll: the fixed-width table overflows on
                  // narrow windows instead of clipping.
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 20,
                      columnSpacing: 24,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 72,
                      headingRowColor: WidgetStateProperty.all(
                          CScholarColors.backgroundLight),
                      columns: const [
                        DataColumn(
                            label: Text('Title',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Program',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Year',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: list.map((t) => DataRow(
                            cells: [
                              DataCell(SizedBox(
                                width: 470,
                                child: Text(t.title,
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(Text(t.program?.name ?? '—')),
                              DataCell(Text(t.academicYear?.label ?? '—')),
                              DataCell(ThesisStatusChip(t.status)),
                              DataCell(SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Status dropdown
                                    PopupMenuButton<String>(
                                      tooltip: 'Change status',
                                      icon: const Icon(Icons.edit_note_outlined,
                                          size: 18,
                                          color: CScholarColors.textSecondary),
                                      onSelected: (s) =>
                                          _changeStatus(context, ref, t, s),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: 'draft', child: Text('Set Draft')),
                                        PopupMenuItem(
                                            value: 'approved', child: Text('Approve')),
                                        PopupMenuItem(
                                            value: 'published',
                                            child: Text('Publish')),
                                        PopupMenuItem(
                                            value: 'archived',
                                            child: Text('Archive')),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    TextButton(
                                      onPressed: () =>
                                          context.go('/thesis/${t.id}'),
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(38, 36),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                      ),
                                      child: const Text('View',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: () => context
                                          .go('/admin/thesis/${t.id}/edit'),
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(38, 36),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                      ),
                                      child: const Text('Edit',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: CScholarColors.orange)),
                                    ),
                                    NeumorphIconButton(
                                      icon: Icons.delete_outline,
                                      tooltip: 'Delete thesis',
                                      size: 36,
                                      onPressed: () =>
                                          _deleteThesis(context, ref, t),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          )).toList(),
                    ),
                  );
                },
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load theses',
                    message: err.toString(),
                            actionLabel: 'Retry',
                            onAction: () =>
                                ref.invalidate(thesisListProvider(_params())),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref,
      Thesis thesis, String newStatus) async {
    try {
      await ref.read(thesisApiProvider).updateStatus(thesis.id, newStatus);
      // Await the refetch (not just invalidate) so the table rebuilds with
      // fresh rows before we confirm — and drop the cached detail view too.
      ref.invalidate(thesisDetailProvider(thesis.id));
      final fresh =
          await ref.refresh(thesisListProvider(_params()).future);
      final row = (fresh ?? []).where((t) => t.id == thesis.id).toList();
      if (context.mounted) {
        if (row.isNotEmpty && row.first.status == newStatus) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thesis status changed to $newStatus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Saved on server, but the list did not refresh — reload the page')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteThesis(
      BuildContext context, WidgetRef ref, Thesis thesis) async {
    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Delete Thesis'),
        content: Text('Are you sure you want to delete "${thesis.title}"?'),
        actions: [
          NeumorphButton(
              onPressed: () => Navigator.pop(ctx, false),
              label: 'Cancel',
              gel: false),
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
      await ref.read(thesisApiProvider).delete(thesis.id);
      ref.invalidate(thesisDetailProvider(thesis.id));
      final fresh =
          await ref.refresh(thesisListProvider(_params()).future);
      if (context.mounted) {
        final stillThere = (fresh ?? []).any((t) => t.id == thesis.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(stillThere
                  ? 'Deleted on server, but the list did not refresh — reload the page'
                  : 'Thesis deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete thesis: $e')));
      }
    }
  }
}
