// Admin: Thesis Management — Stitch design v2
// Sidebar + topbar + data table

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/clay_pagination.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
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

  /// Status filters map to the lifecycle states the table can show. "All" is
  /// the absence of a filter, not a value the API knows.
  static const _statuses = [
    'All',
    'Draft',
    'Approved',
    'Published',
    'Archived',
  ];
  String _status = 'All';

  /// 0-based page for the record table (ten rows a page, like every admin
  /// table).
  int _page = 0;

  /// Selected record ids for the bulk Approve/Publish actions. Kept across
  /// pages so a librarian can select from more than one screenful; the bar
  /// shows the running count and a Clear action.
  final Set<int> _selected = {};
  bool _bulkRunning = false;

  String? get _researchType => _type == 'All' ? null : _type;

  String? get _statusValue => _status == 'All' ? null : _status.toLowerCase();

  /// Params for the watched list: show-all plus the live admin search text.
  /// Mutations refresh through [_params] too, so the table always
  /// re-queries the exact key on screen (filter-preserving refresh).
  ThesisListParams _params() {
    final q = ref.read(adminSearchProvider(AdminSearchSection.theses)).trim();
    return ThesisListParams(
      showAll: true,
      query: q.isEmpty ? null : q,
      researchType: _researchType,
      status: _statusValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    // A new search is a new result set: back to page 1.
    ref.listen(adminSearchProvider(AdminSearchSection.theses), (_, _) {
      if (mounted) {
        setState(() {
          _page = 0;
          // A new result set changes which records the bar applies to.
          _selected.clear();
        });
      }
    });
    final searchQuery = ref
        .watch(adminSearchProvider(AdminSearchSection.theses))
        .trim();
    final params = ThesisListParams(
      showAll: true,
      query: searchQuery.isEmpty ? null : searchQuery,
      researchType: _researchType,
      status: _statusValue,
    );
    final theses = ref.watch(thesisListProvider(params));

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/thesis/management'),
      topbar: const AdminTopbar(section: AdminSearchSection.theses),
      mobileTitle: 'Thesis Management',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              actions: [
                // Library staff arrive here to add studies, whether one at a
                // time or a whole batch. Keeping both entry points on the
                // collection puts the task where the records live, instead
                // of making "Bulk Import" a separate destination.
                NeumorphButton(
                  onPressed: () => context.go('/admin/import'),
                  icon: Icons.upload_file_outlined,
                  label: 'Bulk Import',
                  gel: false,
                ),
                NeumorphButton(
                  onPressed: () => context.go('/admin/thesis/new'),
                  icon: Icons.add,
                  label: 'Add Thesis',
                ),
              ],
            ),
            const SizedBox(height: 20),
            CScholarCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // One label-less filter row: Type keeps the sliding-pill
                  // track, while Status folds into a compact dropdown. Both
                  // are sent with the request, not applied client-side.
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final typeFilter = NeumorphSegmented(
                          labels: _types,
                          selectedIndex: _types.indexOf(_type),
                          // Different type = different result set = page 1.
                          onChanged: (i) => setState(() {
                            _type = _types[i];
                            _page = 0;
                            _selected.clear();
                          }),
                        );
                        final statusFilter = NeumorphSelectField<String>(
                          value: _status,
                          items: _statusItems,
                          // The dense dropdown face is 24px; 11px padding on
                          // each side makes the well 46px, exactly the height
                          // of the Type segmented track. The default
                          // clayDeep fill matches that track too, so the two
                          // read as one material.
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          onChanged: (status) {
                            if (status == null) return;
                            // Different status = different result set = page 1.
                            setState(() {
                              _status = status;
                              _page = 0;
                              _selected.clear();
                            });
                          },
                        );
                        // Below this width the two controls together would
                        // squeeze the segment labels, so they stack instead.
                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              typeFilter,
                              const SizedBox(height: 10),
                              statusFilter,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: typeFilter),
                            const SizedBox(width: 12),
                            SizedBox(width: 214, child: statusFilter),
                          ],
                        );
                      },
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
                                : (_type != 'All' || _status != 'All')
                                ? 'No theses match the selected filters.'
                                : 'Add the first record, or import a spreadsheet with Bulk Import above.',
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
                      // rest of the admin shell has. Ten rows a page.
                      final pageIndex = clampPageIndex(_page, list.length);
                      final visible = list
                          .skip(pageIndex * kAdminTablePageSize)
                          .take(kAdminTablePageSize)
                          .toList();
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_selected.isNotEmpty) ...[
                              _bulkBar(context, list),
                              const SizedBox(height: 8),
                            ],
                            for (final t in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _row(context, t),
                              ),
                            ClayPagination(
                              page: pageIndex + 1,
                              total: list.length,
                              padding: const EdgeInsets.only(top: 8),
                              onPageChanged: (p) =>
                                  setState(() => _page = p - 1),
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
                        message: userFacingError(
                          err,
                          fallback:
                              'The thesis list could not be loaded. Try again.',
                        ),
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

  /// Status options carry the same dot colour as the table's status badge, so
  /// the cues survive the compressed dropdown — in the menu and on the closed
  /// face, since DropdownButton renders the selected item itself.
  List<DropdownMenuItem<String>> get _statusItems => [
    for (final status in _statuses)
      DropdownMenuItem<String>(
        value: status,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusDotColor(status),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                _statusLabel(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  13,
                  FontWeight.w600,
                  CScholarColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
  ];

  static String _statusLabel(String status) =>
      status == 'All' ? 'All statuses' : status;

  static Color _statusDotColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return CScholarColors.adminColor;
      case 'approved':
        return CScholarColors.facultyColor;
      case 'published':
        // The deep brand green (#174F3D) reads almost black in a 7px dot;
        // the hover green keeps the cue legible at this size.
        return CScholarColors.primaryGreenHover;
      default:
        return CScholarColors.textMuted;
    }
  }

  /// One record, drawn like a Programs row: mark, title, context, actions.
  Widget _row(BuildContext context, Thesis t) {
    return CScholarCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: CScholarRadius.xl,
      child: Row(
        children: [
          // control-exempt: per-row selection box for batch approve/publish;
          // the design system has no multi-select table control, and the native
          // box provides the selection semantics screen readers expect.
          Checkbox(
            value: _selected.contains(t.id),
            activeColor: CScholarColors.primaryGreen,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (checked) => setState(() {
              if (checked == true) {
                _selected.add(t.id);
              } else {
                _selected.remove(t.id);
              }
            }),
          ),
          const SizedBox(width: 4),
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
    // Approving is a review decision: returning it to draft needs the notes
    // the authors will act on, instead of a silent revert.
    final returningForRevision =
        thesis.status == 'approved' && newStatus == 'draft';
    String? reviewNotes;
    if (returningForRevision) {
      reviewNotes = await _askForReviewNotes(context, thesis);
      if (reviewNotes == null || !context.mounted) return;
    }

    // Archive and publish both change who can see the study, so they name the
    // consequence before it happens (FB-3). Draft/approve stay one tap: they
    // are internal review states and remain reversible from this menu.
    if (newStatus == 'archived' || newStatus == 'published') {
      final publishing = newStatus == 'published';
      final confirmed = await showClayDialog<bool>(
        context: context,
        builder: (ctx) => GlassDialog(
          title: Text(publishing ? 'Publish thesis?' : 'Archive thesis?'),
          content: Text(
            publishing
                ? '"${thesis.title}" will appear in the public repository immediately.'
                : '"${thesis.title}" will leave the public repository. You can restore it later from Archived.',
          ),
          actions: [
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx, false),
              label: publishing ? 'Keep unpublished' : 'Keep published',
              gel: false,
            ),
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx, true),
              label: publishing ? 'Publish' : 'Archive',
              danger: !publishing,
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      await ref
          .read(thesisApiProvider)
          .updateStatus(thesis.id, newStatus, reviewNotes: reviewNotes);
      // Await the refetch (not just invalidate) so the table rebuilds with
      // fresh rows before we confirm — and drop the cached detail view too.
      ref.invalidate(thesisDetailProvider(thesis.id));
      final fresh = await ref.refresh(thesisListProvider(_params()).future);
      final row = (fresh ?? []).where((t) => t.id == thesis.id).toList();
      // A status filter can hide the row that just moved out of it — that is
      // still a successful update, not a stale list.
      final movedOutOfFilter =
          row.isEmpty && _statusValue != null && _statusValue != newStatus;
      if (context.mounted) {
        if ((row.isNotEmpty && row.first.status == newStatus) ||
            movedOutOfFilter) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _statusMessage(
                  newStatus,
                  returningForRevision: returningForRevision,
                ),
              ),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback:
                    "The status couldn't be changed. Refresh and try again.",
              ),
            ),
          ),
        );
      }
    }
  }

  Widget _bulkBar(BuildContext context, List<Thesis> list) {
    final allSelected =
        list.isNotEmpty && list.every((t) => _selected.contains(t.id));
    final summary = Row(
      children: [
        Text(
          '${_selected.length} selected',
          style: CScholarTextStyles.body(
            12.5,
            FontWeight.w700,
            CScholarColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => setState(() {
            if (allSelected) {
              _selected.clear();
            } else {
              _selected.addAll(list.map((t) => t.id));
            }
          }),
          child: Text(
            allSelected ? 'Clear selection' : 'Select all on this list',
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        NeumorphButton(
          label: 'Approve selected',
          gel: false,
          onPressed: _bulkRunning ? null : () => _bulkStatus('approved'),
        ),
        NeumorphButton(
          label: 'Publish selected',
          gel: false,
          onPressed: _bulkRunning ? null : () => _bulkStatus('published'),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CScholarColors.primaryGreenVeryLight,
        borderRadius: BorderRadius.circular(CScholarRadius.lg),
        border: Border.all(
          color: CScholarColors.primaryGreen.withValues(alpha: 0.18),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 8), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  Future<void> _bulkStatus(String status) async {
    if (_selected.isEmpty || _bulkRunning) return;
    if (status != 'approved' && status != 'published') return;
    final ids = _selected.toList();
    final verb = status == 'approved' ? 'approve' : 'publish';
    final past = status == 'approved' ? 'approved' : 'published';

    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(
          status == 'approved' ? 'Approve selected?' : 'Publish selected?',
        ),
        content: Text(
          'You are about to $verb ${ids.length} studies. '
          '${status == 'approved' ? 'Approved studies are still internal until published.' : 'Published studies become visible in the public repository.'}',
        ),
        actions: [
          NeumorphButton(
            label: 'Cancel',
            gel: false,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          NeumorphButton(
            label: status == 'approved' ? 'Approve' : 'Publish',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _bulkRunning = true);
    try {
      final result = await ref.read(thesisApiProvider).bulkStatus(ids, status);
      final updated = (result['updated'] as List?)?.length ?? 0;
      final skipped = (result['skipped'] as List?)?.length ?? 0;
      for (final id in ids) {
        ref.invalidate(thesisDetailProvider(id));
      }
      setState(() {
        _selected.clear();
        // Follow the rows the librarian just moved, so the next step
        // (publish after approve) is on screen instead of hidden by a filter.
        if (status == 'approved' && _statusValue == 'draft') {
          _status = 'Approved';
          _page = 0;
        } else if (status == 'published' && _statusValue == 'approved') {
          _status = 'Published';
          _page = 0;
        }
      });
      final _ = await ref.refresh(thesisListProvider(_params()).future);
      if (!mounted) return;
      final skipNote = skipped > 0
          ? ' $skipped skipped — only a draft can be approved, and only '
                'an approved study can be published.'
          : '';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$updated $past.$skipNote')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(
              e,
              fallback: "Nothing was changed. The server could not complete the bulk update; try again.",
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _bulkRunning = false);
    }
  }

  /// Collects the required review notes for an approved -> draft return.
  /// Returns null when the admin cancels, so no status change happens.
  Future<String?> _askForReviewNotes(BuildContext context, Thesis thesis) {
    final notesCtrl = TextEditingController();
    String? error;
    return showClayDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => GlassDialog(
          title: const Text('Return for Revision'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explain what needs to change in "${thesis.title}". '
                'These notes stay on the record for the authors.',
                style: CScholarTextStyles.body(
                  12.5,
                  FontWeight.w400,
                  CScholarColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              NeumorphField(
                controller: notesCtrl,
                label: 'Review notes *',
                hintText: 'What should the authors revise?',
                minLines: 3,
                maxLines: 4,
                errorText: error,
              ),
            ],
          ),
          actions: [
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx),
              label: 'Cancel',
              gel: false,
            ),
            NeumorphButton(
              onPressed: () {
                final notes = notesCtrl.text.trim();
                if (notes.isEmpty) {
                  setDialog(() => error = 'Review notes are required');
                  return;
                }
                Navigator.pop(ctx, notes);
              },
              label: 'Return for Revision',
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmation copy that states the consequence for students, not just the
  /// database value — `approved` is invisible to them until it is published.
  static String _statusMessage(
    String status, {
    required bool returningForRevision,
  }) {
    switch (status) {
      case 'approved':
        return 'Approved — hidden from students until published';
      case 'published':
        return 'Published — now visible to students';
      case 'draft':
        return returningForRevision
            ? 'Returned for revision — review notes saved'
            : 'Moved back to draft — hidden from students';
      case 'archived':
        return 'Archived — removed from the public repository';
      default:
        return 'Thesis status changed to $status';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: "The thesis couldn't be deleted. Try again.",
              ),
            ),
          ),
        );
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
      // Only the targets the server accepts from the current status: an
      // archived thesis can be restored to draft or published but not
      // approved, so that option is dropped instead of returning a 409.
      itemBuilder: (_) {
        // From approved, going back to draft is a review decision with notes,
        // so it is named for what it does instead of "Set Draft".
        final draftLabel = widget.status == 'approved'
            ? 'Return for Revision'
            : 'Set Draft';
        return [
          for (final item in [
            ('draft', draftLabel),
            ('approved', 'Approve'),
            ('published', 'Publish'),
            ('archived', 'Archive'),
          ])
            if (ThesisStatusTransitions.allows(widget.status, item.$1))
              PopupMenuItem(value: item.$1, child: Text(item.$2)),
        ];
      },
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
