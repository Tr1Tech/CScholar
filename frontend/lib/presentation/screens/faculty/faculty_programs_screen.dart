import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';

/// Faculty: the studies they advise, grouped by CEIT program.
class FacultyProgramsScreen extends ConsumerWidget {
  const FacultyProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theses = ref.watch(facultyThesesProvider);
    final programs = ref.watch(programsProvider);

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/programs'),
      topbar: FacultyTopbar(user: user),
      mobileTitle: 'Programs',
      backRoute: '/faculty/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            const PageHeader(
              title: 'Programs',
              subtitle:
                  'Your advised studies grouped by CEIT program. Open a program to see its studies.',
            ),
            const SizedBox(height: 20),
            asyncSlot<List<Thesis>>(
              theses,
              skeleton: const SkeletonList(count: 3, cardHeight: 120),
              data: (list) => _content(
                context,
                list,
                programs.value ?? const <Program>[],
              ),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: "Couldn't load your programs",
                message: userFacingError(
                  err,
                  fallback: 'Your advised studies could not be loaded.',
                ),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(facultyThesesProvider),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<Thesis> theses,
    List<Program> programs,
  ) {
    if (theses.isEmpty) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No programs yet',
        message: 'Programs appear once you advise a study.',
      );
    }
    final names = {for (final p in programs) p.id: p};
    final grouped = <int, List<Thesis>>{};
    for (final thesis in theses) {
      grouped.putIfAbsent(thesis.programId, () => []).add(thesis);
    }
    final ids = grouped.keys.toList()
      ..sort((a, b) {
        final byCount = grouped[b]!.length.compareTo(grouped[a]!.length);
        if (byCount != 0) return byCount;
        return _label(names[a], a).compareTo(_label(names[b], b));
      });

    return Column(
      children: [
        for (var i = 0; i < ids.length; i++) ...[
          _programCard(context, names[ids[i]], ids[i], grouped[ids[i]]!),
          if (i != ids.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _programCard(
    BuildContext context,
    Program? program,
    int programId,
    List<Thesis> theses,
  ) {
    final label = _label(program, programId);
    return CScholarCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          leading: Container(
            // tile-exempt: program code badge, not an icon tile
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CScholarColors.thesisChipBg,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
            ),
            child: Text(
              program?.code ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(
                10.5,
                FontWeight.w800,
                CScholarColors.primaryGreen,
              ),
            ),
          ),
          title: Text(
            label,
            style: CScholarTextStyles.body(
              13.5,
              FontWeight.w700,
              CScholarColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${theses.length} ${theses.length == 1 ? 'study' : 'studies'}',
            style: CScholarTextStyles.body(
              11.5,
              FontWeight.w400,
              CScholarColors.textMuted,
            ),
          ),
          children: [
            for (final thesis in theses)
              InkWell(
                borderRadius: BorderRadius.circular(CScholarRadius.md),
                onTap: () => context.go('/thesis/${thesis.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thesis.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CScholarTextStyles.body(
                                12.5,
                                FontWeight.w600,
                                CScholarColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                thesis.academicYear?.label ?? '',
                                thesis.researchType,
                              ].where((part) => part.isNotEmpty).join(' · '),
                              style: CScholarTextStyles.body(
                                11,
                                FontWeight.w400,
                                CScholarColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _statusChip(thesis.status),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: CScholarColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final fill =
        CScholarColors.statusFill[status.toLowerCase()] ??
        CScholarColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CScholarRadius.full),
      ),
      child: Text(
        status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1),
        style: CScholarTextStyles.body(10, FontWeight.w700, fill),
      ),
    );
  }

  String _label(Program? program, int id) {
    if (program == null) return 'Program $id';
    return program.name.isEmpty ? program.code : program.name;
  }
}
