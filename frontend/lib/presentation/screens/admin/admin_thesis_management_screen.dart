// Admin: Thesis Management — Stitch design v2
// Sidebar + topbar + data table

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';
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
  /// Type segment. "All" is the absence of a filter, not a value the API
  /// knows, so the request drops it.
  static const _types = ['All', 'Thesis', 'Capstone'];
  String _type = 'All';

  String? get _researchType => _type == 'All' ? null : _type;

  /// Params for the watched list: show-all plus the live admin search text.
  /// Mutations refresh through [_params] too, so the table always
  /// re-queries the exact key on screen (filter-preserving refresh).
  ThesisListParams _params() {
    final q = ref.read(adminSearchProvider(AdminSearchSection.theses)).trim();
    return ThesisListParams(
      showAll: true,
      query: q.isEmpty ? null : q,
      researchType: _researchType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref
        .watch(adminSearchProvider(AdminSearchSection.theses))
        .trim();
    final params = ThesisListParams(
      showAll: true,
      query: searchQuery.isEmpty ? null : searchQuery,
      researchType: _researchType,
    );
    final theses = ref.watch(thesisListProvider(params));

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/thesis/management'),
      topbar: const AdminTopbar(section: AdminSearchSection.theses),
      mobileTitle: 'Thesis Management',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        // Header-first on the page rhythm. Rows rebuild on every filter and
        // search change, so they enter with the card instead of re-cascading
        // each time a keystroke lands.
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            PageHeader(
              title: 'Thesis Management',
              subtitle:
                  'Review statuses, edit records, and curate the repository.',
              action: NeumorphButton(
                onPressed: () => context.go('/admin/thesis/new'),
                icon: Icons.add,
                label: 'Add Thesis',
              ),
            ),
            const SizedBox(height: 20),
            CScholarCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Same filter language as Users and Programs: one recessed
                  // track with a pill that glides. This one is sent with the
                  // request, not applied client-side.
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: NeumorphSegmented(
                      labels: _types,
                      selectedIndex: _types.indexOf(_type),
                      onChanged: (i) => setState(() => _type = _types[i]),
                    ),
                  ),
                  const Divider(height: 1),
                  asyncSlot<List<Thesis>?>(
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
                            compact: true,
                            title: searching ? 'No matches' : 'No theses found',
                            message: searching
                                ? 'No theses match "$searchQuery".'
                                : 'Add the first record to start the repository.',
                            actionLabel: searching ? 'Clear search' : null,
                            onAction: searching
                                ? () => ref
                                      .read(
                                        adminSearchProvider(
                                          AdminSearchSection.theses,
                                        ).notifier,
                                      )
                                      .clear()
                                : null,
                          ),
                        );
                      }
                      // Card rows, the same language as Programs: the
                      // record's identity mark, a bold title with its context
                      // beneath, and its actions as raised round buttons. A
                      // DataTable cannot carry the hover and press life the
                      // rest of the admin shell has.
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final t in list)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _row(context, t),
                              ),
                          ],
                        ),
                      );
                    },
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.error_outline,
                        compact: true,
                        title: 'Could not load theses',
                        message: err.toString(),
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.invalidate(thesisListProvider(_params())),
                      ),
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

  /// One record, drawn like a Programs row: mark, title, context, actions.
  Widget _row(BuildContext context, Thesis t) {
    return CScholarCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: CScholarRadius.xl,
      child: Row(
        children: [
          ThesisCover(
            seed: t.id,
            width: 34,
            height: 42,
            borderRadius: 10,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    13.5,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
                Text(
                  '${t.program?.name ?? '—'} · ${t.academicYear?.label ?? '—'}',
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
          const SizedBox(width: 12),
          // The status control: the chip plus a caret and a hover rim, so it
          // reads as something to click rather than a read-only badge.
          _StatusMenu(
            status: t.status,
            onSelected: (s) => _changeStatus(context, ref, t, s),
          ),
          const SizedBox(width: 8),
          NeumorphIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'View thesis',
            // Colour is meaning: green reads, coral edits, red destroys.
            color: CScholarColors.primaryGreen,
            onPressed: () => context.go('/thesis/${t.id}'),
          ),
          const SizedBox(width: 8),
          NeumorphIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit thesis',
            color: CScholarColors.violetInk,
            onPressed: () => context.go('/admin/thesis/${t.id}/edit'),
          ),
          const SizedBox(width: 8),
          NeumorphIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete thesis',
            color: CScholarColors.error,
            onPressed: () => _deleteThesis(context, ref, t),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Thesis thesis,
    String newStatus,
  ) async {
    try {
      await ref.read(thesisApiProvider).updateStatus(thesis.id, newStatus);
      // Await the refetch (not just invalidate) so the table rebuilds with
      // fresh rows before we confirm — and drop the cached detail view too.
      ref.invalidate(thesisDetailProvider(thesis.id));
      final fresh = await ref.refresh(thesisListProvider(_params()).future);
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
                'Saved on server, but the list did not refresh — reload the page',
              ),
            ),
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
    BuildContext context,
    WidgetRef ref,
    Thesis thesis,
  ) async {
    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Delete Thesis'),
        content: Text('Are you sure you want to delete "${thesis.title}"?'),
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
      await ref.read(thesisApiProvider).delete(thesis.id);
      ref.invalidate(thesisDetailProvider(thesis.id));
      final fresh = await ref.refresh(thesisListProvider(_params()).future);
      if (context.mounted) {
        final stillThere = (fresh ?? []).any((t) => t.id == thesis.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              stillThere
                  ? 'Deleted on server, but the list did not refresh — reload the page'
                  : 'Thesis deleted',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete thesis: $e')));
      }
    }
  }
}

/// Status as a control rather than a badge.
///
/// The bare chip was read as a static indicator, so this one carries a caret,
/// lifts its rim under the pointer, and shows the click cursor. Same palette
/// as [ThesisStatusChip] through [ThesisStatusStyle], so the two cannot drift.
class _StatusMenu extends StatefulWidget {
  const _StatusMenu({required this.status, required this.onSelected});

  final String status;
  final ValueChanged<String> onSelected;

  @override
  State<_StatusMenu> createState() => _StatusMenuState();
}

class _StatusMenuState extends State<_StatusMenu> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final style = ThesisStatusStyle.of(widget.status);
    return PopupMenuButton<String>(
      tooltip: 'Change status',
      // Under the control, not over the row it belongs to.
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      onSelected: widget.onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'draft', child: Text('Set Draft')),
        PopupMenuItem(value: 'approved', child: Text('Approve')),
        PopupMenuItem(value: 'published', child: Text('Publish')),
        PopupMenuItem(value: 'archived', child: Text('Archive')),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: motionEnabled(context)
              ? CScholarMotion.micro
              : Duration.zero,
          curve: CScholarCurves.standard,
          padding: const EdgeInsets.only(left: 10, right: 6, top: 3, bottom: 3),
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(CScholarRadius.full),
            border: Border.all(color: _hover ? style.fg : style.rim),
            // Hover lifts the shadow instead of adding a second fill, the same
            // way every other clay control answers the pointer.
            boxShadow: CScholarMaterial.softShadow(depth: _hover ? 0.5 : 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                style.label,
                style: CScholarTextStyles.body(
                  11,
                  FontWeight.w700,
                  style.fg,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: style.fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
