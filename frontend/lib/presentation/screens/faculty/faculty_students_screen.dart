import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';

/// Faculty: authors (advisees) linked to this faculty member's advised theses.
class FacultyStudentsScreen extends ConsumerWidget {
  const FacultyStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
    final adviseesAsync = ref.watch(facultyAdviseesProvider);

    final body = RefreshIndicator(
      onRefresh: () => ref.refresh(facultyAdviseesProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Students',
                    style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Advisees across your supervised studies.',
                    style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted)),
                const SizedBox(height: 20),
                adviseesAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return _emptyCard('No advisees linked to your account yet');
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
                  loading: () => const Center(
                      child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (err, _) => _emptyCard('Could not load advisees: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
            onPressed: () => context.go('/faculty/dashboard'),
          ),
          title: const Text('My Students',
              style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          const FacultySidebar(currentPath: '/faculty/students'),
          Expanded(child: body),
        ],
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CScholarRadius.xl),
          border: Border.all(color: CScholarColors.borderLight),
          boxShadow: CScholarShadows.card,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFDCFCE7),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
      ),
      child: Center(
        child: Text(message,
            style: CScholarTextStyles.inter(13, FontWeight.w500, CScholarColors.textMuted)),
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
