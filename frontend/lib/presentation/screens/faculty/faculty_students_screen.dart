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
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';

/// Faculty: authors (advisees) linked to this faculty member's advised theses.
///
/// A roster, not a card wall: every row carries the study the student worked
/// on, so the page answers "who are they and what did they do" at a glance.
class FacultyStudentsScreen extends ConsumerStatefulWidget {
  const FacultyStudentsScreen({super.key});

  @override
  ConsumerState<FacultyStudentsScreen> createState() => _FacultyStudentsScreenState();
}

class _FacultyStudentsScreenState extends ConsumerState<FacultyStudentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final adviseesAsync = ref.watch(facultyAdviseesProvider);
    final theses = ref.watch(facultyThesesProvider).value ?? const <Thesis>[];

    // Author id -> studies. One fetch of "my theses" is enough to give every
    // row its title, program, year, and status without a second endpoint.
    final byAuthor = <int, List<Thesis>>{};
    for (final thesis in theses) {
      for (final author in thesis.authors ?? const <Author>[]) {
        byAuthor.putIfAbsent(author.id, () => <Thesis>[]).add(thesis);
      }
    }

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/students'),
      topbar: FacultyTopbar(user: user),
      mobileTitle: 'My Students',
      backRoute: '/faculty/dashboard',
      child: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(facultyThesesProvider);
          return ref.refresh(facultyAdviseesProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: StaggerColumn(
            pitch: MotionPitch.page,
            children: [
              const PageHeader(
                title: 'My Students',
                subtitle: 'Advisees across your supervised studies.',
              ),
              const SizedBox(height: 18),
              asyncSlot<List<Map<String, dynamic>>>(
                adviseesAsync,
                skeleton: const SkeletonList(count: 7, cardHeight: 92),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No advisees yet',
                      message: 'Authors of studies you submit or advise will appear here.',
                    );
                  }
                  return _roster(list, byAuthor, theses);
                },
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load advisees',
                  message: err.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(facultyAdviseesProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roster(
    List<Map<String, dynamic>> list,
    Map<int, List<Thesis>> byAuthor,
    List<Thesis> theses,
  ) {
    final needle = _query.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? list
        : list.where((a) {
            final studies = byAuthor[a['id']] ?? const <Thesis>[];
            return _name(a).toLowerCase().contains(needle) ||
                studies.any(
                  (t) => (t.program?.code ?? '').toLowerCase().contains(needle),
                );
          }).toList();

    final programs = theses
        .map((t) => t.program?.code)
        .whereType<String>()
        .where((code) => code.isNotEmpty)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _metaPill('${list.length} ${list.length == 1 ? 'advisee' : 'advisees'}'),
            _metaPill('${theses.length} ${theses.length == 1 ? 'study' : 'studies'}'),
            _metaPill('${programs.length} ${programs.length == 1 ? 'program' : 'programs'}'),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: NeumorphField(
                controller: _searchController,
                hintText: 'Search name or program',
                prefixIcon: Icons.search,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: 'No matching advisees',
            message: 'Nobody matches "$_query". Try a name, a program, or a study title.',
            actionLabel: 'Clear search',
            onAction: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          )
        else
          for (final entry in filtered.asMap().entries) ...[
            Stagger(
              index: entry.key,
              step: MotionPitch.tight.step,
              max: MotionPitch.tight.max,
              rise: MotionPitch.tight.rise,
              child: _adviseeRow(entry.value, byAuthor[entry.value['id']] ?? const <Thesis>[]),
            ),
            if (entry.key != filtered.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _adviseeRow(Map<String, dynamic> advisee, List<Thesis> studies) {
    final name = _name(advisee);
    final count = (advisee['thesis_count'] as num?)?.toInt() ?? studies.length;
    final programs = studies
        .map((t) => t.program?.code)
        .whereType<String>()
        .where((code) => code.isNotEmpty)
        .toSet();
    final programLabel = programs.isEmpty
        ? null
        : programs.length == 1
        ? programs.first
        : '${programs.length} programs';
    final meta = [
      ?programLabel,
      '$count ${count == 1 ? 'study' : 'studies'}',
    ].join(' · ');

    return InkWell(
      onTap: () => _showAdviseeTheses(context, advisee['id'] as int, name, count),
      borderRadius: BorderRadius.circular(CScholarRadius.xl),
      child: CScholarCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        lift: true,
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: CScholarColors.thesisChipBg,
              child: Text(
                _initials(name),
                style: CScholarTextStyles.body(12, FontWeight.w700, CScholarColors.primaryGreen),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unnamed student' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.body(
                      13.5,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: CScholarTextStyles.body(11.5, FontWeight.w500, CScholarColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: CScholarColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _metaPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: CScholarMaterial.chipNeutral,
        borderRadius: BorderRadius.circular(CScholarRadius.full),
      ),
      child: Text(
        label,
        style: CScholarTextStyles.body(11.5, FontWeight.w600, CScholarColors.textSecondary),
      ),
    );
  }

  void _showAdviseeTheses(BuildContext context, int authorId, String name, int count) {
    final theses = ref.read(facultyThesesProvider).value ?? [];
    final mine = theses.where((t) => (t.authors ?? []).any((a) => a.id == authorId)).toList();
    final total = mine.isEmpty ? count : mine.length;

    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total supervised ${total == 1 ? 'study' : 'studies'}',
                style: CScholarTextStyles.body(11.5, FontWeight.w500, CScholarColors.textMuted),
              ),
              const SizedBox(height: 10),
              if (mine.isEmpty)
                const Text('No supervised studies found for this advisee.')
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: mine.length,
                    separatorBuilder: (_, _) => const Divider(height: 18),
                    itemBuilder: (_, index) {
                      final study = mine[index];
                      final meta = [
                        study.program?.code ?? '',
                        study.academicYear?.label ?? '',
                      ].where((part) => part.isNotEmpty).join(' · ');
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  study.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: CScholarTextStyles.body(
                                    12.5,
                                    FontWeight.w600,
                                    CScholarColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ThesisStatusChip(study.status),
                                    if (meta.isNotEmpty)
                                      Text(
                                        meta,
                                        style: CScholarTextStyles.body(
                                          11,
                                          FontWeight.w500,
                                          CScholarColors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/thesis/${study.id}');
                            },
                            child: const Text('View', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  String _name(Map<String, dynamic> advisee) {
    return [
      advisee['first_name'],
      advisee['middle_name'],
      advisee['last_name'],
    ].where((part) => (part as String?)?.isNotEmpty == true).join(' ');
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
