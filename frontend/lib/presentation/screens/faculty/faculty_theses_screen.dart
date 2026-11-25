import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/clay_pagination.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// Faculty: theses this faculty member advises (all statuses).
class FacultyThesesScreen extends ConsumerStatefulWidget {
  const FacultyThesesScreen({super.key});

  @override
  ConsumerState<FacultyThesesScreen> createState() =>
      _FacultyThesesScreenState();
}

class _FacultyThesesScreenState extends ConsumerState<FacultyThesesScreen> {
  String _statusFilter = 'All';
  static const _filters = ['All', 'Draft', 'Approved', 'Published', 'Archived'];

  /// 0-based page for the supervised-thesis list: the same ten-row page the
  /// admin tables use, so "a page" means one thing across the app.
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final thesesAsync = ref.watch(facultyThesesProvider);

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/theses'),
      topbar: FacultyTopbar(user: user),
      mobileTitle: 'My Theses',
      backRoute: '/faculty/dashboard',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(facultyThesesProvider.future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: StaggerColumn(
            // Header-first on the page rhythm; chips step tight, thesis cards
            // walk the result pitch below.
            pitch: MotionPitch.page,
            children: [
              PageHeader(
                title: 'My Theses',
                subtitle: 'Studies you advise, across all statuses.',
                action: NeumorphButton(
                  onPressed: () => context.go('/faculty/thesis/new'),
                  icon: Icons.add,
                  label: 'New Thesis',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                // Filter chips cascade tight — barely a stagger.
                children: _filters
                    .asMap()
                    .entries
                    .map(
                      (entry) => Stagger(
                        index: entry.key,
                        step: MotionPitch.tight.step,
                        max: MotionPitch.tight.max,
                        rise: MotionPitch.tight.rise,
                        child: ClayChip(
                          label: entry.value,
                          selected: _statusFilter == entry.value,
                          // A new status is a new result set: page 1.
                          onTap: () => setState(() {
                            _statusFilter = entry.value;
                            _page = 0;
                          }),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              asyncSlot<List<Thesis>>(
                thesesAsync,
                skeleton: const SkeletonList(count: 4, cardHeight: 110),
                data: (list) {
                  final filtered = _statusFilter == 'All'
                      ? list
                      : list
                            .where(
                              (t) =>
                                  t.status.toLowerCase() ==
                                  _statusFilter.toLowerCase(),
                            )
                            .toList();
                  if (filtered.isEmpty) {
                    final all = _statusFilter == 'All';
                    return EmptyState(
                      icon: Icons.article_outlined,
                      title: all
                          ? 'No advised theses yet'
                          : 'No ${_statusFilter.toLowerCase()} theses',
                      message: all
                          ? 'Submit a draft to start your advised list.'
                          : 'Try a different status filter.',
                      actionLabel: all ? 'New thesis' : 'Show all theses',
                      onAction: all
                          ? () => context.go('/faculty/thesis/new')
                          : () => setState(() => _statusFilter = 'All'),
                    );
                  }
                  // Ten per page, the same page size as the admin tables.
                  final pageIndex = clampPageIndex(_page, filtered.length);
                  final visible = filtered
                      .skip(pageIndex * kAdminTablePageSize)
                      .take(kAdminTablePageSize)
                      .toList();
                  return Column(
                    // Advised theses walk the result pitch, like every thesis
                    // result list in the app.
                    children: [
                      ...visible.asMap().entries.map(
                        (entry) => Stagger(
                          index: entry.key,
                          step: MotionPitch.result.step,
                          max: MotionPitch.result.max,
                          rise: MotionPitch.result.rise,
                          child: _thesisCard(context, entry.value),
                        ),
                      ),
                      ClayPagination(
                        page: pageIndex + 1,
                        total: filtered.length,
                        padding: const EdgeInsets.only(top: 4),
                        onPageChanged: (p) => setState(() => _page = p - 1),
                      ),
                    ],
                  );
                },
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load theses',
                  message: userFacingError(
                    err,
                    fallback: 'Your studies could not be loaded. Try again.',
                  ),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(facultyThesesProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thesisCard(BuildContext context, Thesis t) {
    final me = ref.read(currentUserProvider);
    final mine = t.status == 'draft' && me != null && t.creatorId == me.id;
    final isOwner = me != null && t.creatorId == me.id;
    // A returned draft must announce itself in the list; the full note is on
    // the detail page, but the submitter should not have to open every row.
    final returned =
        t.status == 'draft' && (t.reviewNotes ?? '').trim().isNotEmpty;
    // Side by side where there is room; on a phone the two chips stack so the
    // long "returned" label cannot overflow the row. The right column is
    // capped so 200% text wraps instead of running past the card edge.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stackChips = screenWidth < 600;
    final statusMaxWidth = screenWidth * 0.48;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CScholarCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: CScholarTextStyles.body(
                      14,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${t.program?.name ?? '—'} • ${t.academicYear?.label ?? '—'} • ${t.authorsString}',
                    style: CScholarTextStyles.body(
                      12,
                      FontWeight.w400,
                      CScholarColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _roleBadge(isOwner),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: statusMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (returned && stackChips) ...[
                    _returnedChip(),
                    const SizedBox(height: 6),
                    ThesisStatusChip(t.status),
                  ] else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (returned) ...[
                          _returnedChip(),
                          const SizedBox(width: 6),
                        ],
                        ThesisStatusChip(t.status),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Wrap (not Row): at 200% text the actions spill onto a
                  // second line instead of overflowing.
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/thesis/${t.id}'),
                        child: Text(
                          'View',
                          style: CScholarTextStyles.body(
                            12,
                            FontWeight.w600,
                            CScholarColors.primaryGreen,
                          ),
                        ),
                      ),
                      if (mine) ...[
                        TextButton(
                          onPressed: () =>
                              context.go('/faculty/thesis/${t.id}/edit'),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              // Violet is the edit affordance: coral sat too
                              // close to the red of the delete control.
                              color: CScholarColors.violetInk,
                            ),
                          ),
                        ),
                        NeumorphIconButton(
                          icon: Icons.delete_outline,
                          size: 36,
                          tooltip: 'Delete draft',
                          // Red is the delete affordance everywhere, not just
                          // on the admin lists.
                          color: CScholarColors.error,
                          onPressed: () => _deleteDraft(context, t),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDraft(BuildContext context, Thesis t) async {
    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Delete Draft'),
        content: Text(
          'Delete "${t.title}"? Published and approved studies can only be removed by an admin.',
        ),
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
      await ref.read(thesisApiProvider).delete(t.id);
      final fresh = await ref.refresh(facultyThesesProvider.future);
      if (context.mounted) {
        final stillThere = fresh.any((x) => x.id == t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              stillThere
                  ? 'Deleted on server, but the list did not refresh — reload the page'
                  : 'Draft deleted',
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
                fallback: "The draft couldn't be deleted. Try again.",
              ),
            ),
          ),
        );
      }
    }
  }

  /// Compact return marker shown beside the status chip. The note itself is
  /// on the detail page, so the list only flags that the study came back.
  Widget _returnedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CScholarColors.errorLight,
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        border: Border.all(
          color: CScholarColors.warningFg.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'RETURNED FOR REVISION',
        style: CScholarTextStyles.body(
          10,
          FontWeight.w700,
          CScholarColors.warningFg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _roleBadge(bool isOwner) {
    final color = isOwner ? CScholarColors.primaryGreen : CScholarColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.upload_file_outlined : Icons.people_outline,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isOwner ? 'SUBMITTED BY YOU' : 'ASSIGNED TO YOU',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
