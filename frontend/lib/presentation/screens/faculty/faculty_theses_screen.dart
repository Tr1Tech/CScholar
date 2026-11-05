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
                          onTap: () =>
                              setState(() => _statusFilter = entry.value),
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
                    return EmptyState(
                      icon: Icons.article_outlined,
                      title: _statusFilter == 'All'
                          ? 'No advised theses yet'
                          : 'No ${_statusFilter.toLowerCase()} theses',
                      message: _statusFilter == 'All'
                          ? 'Theses you submit or advise will appear here.'
                          : 'Try a different status filter.',
                    );
                  }
                  return Column(
                    // Advised theses walk the result pitch, like every thesis
                    // result list in the app.
                    children: filtered
                        .asMap()
                        .entries
                        .map(
                          (entry) => Stagger(
                            index: entry.key,
                            step: MotionPitch.result.step,
                            max: MotionPitch.result.max,
                            rise: MotionPitch.result.rise,
                            child: _thesisCard(context, entry.value),
                          ),
                        )
                        .toList(),
                  );
                },
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load theses',
                  message: err.toString(),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ThesisStatusChip(t.status),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                        child: const Text(
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
                        // Red is the delete affordance everywhere, not just on
                        // the admin lists.
                        color: CScholarColors.error,
                        onPressed: () => _deleteDraft(context, t),
                      ),
                    ],
                  ],
                ),
              ],
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
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
          Text(
            isOwner ? 'SUBMITTED BY YOU' : 'ASSIGNED TO YOU',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
