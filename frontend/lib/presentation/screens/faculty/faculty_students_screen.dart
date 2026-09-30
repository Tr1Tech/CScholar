import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';

/// Faculty: authors (advisees) linked to this faculty member's advised theses.
class FacultyStudentsScreen extends ConsumerWidget {
  const FacultyStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final adviseesAsync = ref.watch(facultyAdviseesProvider);

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/students'),
      topbar: FacultyTopbar(user: user),
      mobileTitle: 'My Students',
      backRoute: '/faculty/dashboard',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(facultyAdviseesProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: StaggerColumn(
            children: [
              const PageHeader(
                title: 'My Students',
                subtitle: 'Advisees across your supervised studies.',
              ),
              const SizedBox(height: 20),
              asyncSlot<List<Map<String, dynamic>>>(
                adviseesAsync,
                skeleton: const SkeletonList(count: 6, cardHeight: 96),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No advisees yet',
                      message: 'Authors of studies you submit or advise will appear here.',
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final count = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 560 ? 2 : 1);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: count,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.6,
                        children: list.map((a) => _adviseeCard(context, ref, a)).toList(),
                      );
                    },
                  );
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

  Widget _adviseeCard(BuildContext context, WidgetRef ref, Map<String, dynamic> a) {
    final name = [
      a['first_name'],
      a['middle_name'],
      a['last_name'],
    ].where((p) => (p as String?)?.isNotEmpty == true).join(' ');
    final count = (a['thesis_count'] as num?)?.toInt() ?? 0;
    return InkWell(
      onTap: () => _showAdviseeTheses(context, ref, a['id'] as int, name.isEmpty ? 'Advisee' : name),
      borderRadius: BorderRadius.circular(CScholarRadius.xl),
      child: CScholarCard(
        padding: const EdgeInsets.all(18),
        lift: true,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: CScholarColors.thesisChipBg,
              child: Text(
                _initials(name),
                style: CScholarTextStyles.inter(13, FontWeight.w700, CScholarColors.primaryGreen),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name.isEmpty ? 'Unnamed' : name,
                      style: CScholarTextStyles.inter(13.5, FontWeight.w700, CScholarColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text((a['email'] as String?) ?? '',
                      style: CScholarTextStyles.inter(11.5, FontWeight.w400, CScholarColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$count ${count == 1 ? 'study' : 'studies'}',
                      style: CScholarTextStyles.inter(11.5, FontWeight.w600, CScholarColors.primaryGreen)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdviseeTheses(BuildContext context, WidgetRef ref, int authorId, String name) {
    final theses = ref.read(facultyThesesProvider).value ?? [];
    final mine = theses.where((t) => (t.authors ?? []).any((a) => a.id == authorId)).toList();
    showClayDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: mine.isEmpty
              ? const Text('No supervised studies found for this advisee.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: mine
                      .map((t) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(t.status.toUpperCase(),
                                style: const TextStyle(fontSize: 11, color: CScholarColors.textMuted)),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.go('/thesis/${t.id}');
                              },
                              child: const Text('View', style: TextStyle(fontSize: 12)),
                            ),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
