import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';

/// Faculty: theses this faculty member advises (all statuses).
class FacultyThesesScreen extends ConsumerStatefulWidget {
  const FacultyThesesScreen({super.key});

  @override
  ConsumerState<FacultyThesesScreen> createState() => _FacultyThesesScreenState();
}

class _FacultyThesesScreenState extends ConsumerState<FacultyThesesScreen> {
  String _statusFilter = 'All';
  static const _filters = ['All', 'Draft', 'Approved', 'Published', 'Archived'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
    final thesesAsync = ref.watch(facultyThesesProvider);

    final body = RefreshIndicator(
      onRefresh: () => ref.refresh(facultyThesesProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Theses',
                              style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Studies you advise, across all statuses.',
                              style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted)),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/faculty/thesis/new'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CScholarColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text('New Thesis',
                          style: CScholarTextStyles.inter(13, FontWeight.w600, Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filters
                      .map((f) => FilterChip(
                            label: Text(f, style: const TextStyle(fontSize: 12)),
                            selected: _statusFilter == f,
                            onSelected: (_) => setState(() => _statusFilter = f),
                            selectedColor: CScholarColors.primaryGreen,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                                color: _statusFilter == f ? Colors.white : CScholarColors.textPrimary),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                thesesAsync.when(
                  data: (list) {
                    final filtered = _statusFilter == 'All'
                        ? list
                        : list.where((t) => t.status.toLowerCase() == _statusFilter.toLowerCase()).toList();
                    if (filtered.isEmpty) {
                      return _emptyCard(
                          _statusFilter == 'All' ? 'No advised theses yet' : 'No ${_statusFilter.toLowerCase()} theses');
                    }
                    return Column(
                      children: filtered.map((t) => _thesisCard(context, t)).toList(),
                    );
                  },
                  loading: () => const Center(
                      child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (err, _) => _emptyCard('Could not load theses: $err'),
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
          title: const Text('My Theses',
              style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          const FacultySidebar(currentPath: '/faculty/theses'),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _thesisCard(BuildContext context, Thesis t) {
    final me = ref.read(currentUserProvider);
    final mine = t.status == 'draft' && me != null && t.creatorId == me.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: CScholarTextStyles.inter(14, FontWeight.w700, CScholarColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(
                  '${t.program?.name ?? '—'} • ${t.academicYear?.label ?? '—'} • ${t.authorsString}',
                  style: CScholarTextStyles.inter(12, FontWeight.w400, CScholarColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(t.status),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.go('/thesis/${t.id}'),
                    child: Text('View',
                        style: CScholarTextStyles.inter(
                            12, FontWeight.w600, CScholarColors.primaryGreen)),
                  ),
                  if (mine) ...[
                    TextButton(
                      onPressed: () => context.go('/faculty/thesis/${t.id}/edit'),
                      child: const Text('Edit',
                          style: TextStyle(fontSize: 12, color: CScholarColors.orange)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: CScholarColors.error),
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      padding: EdgeInsets.zero,
                      tooltip: 'Delete draft',
                      onPressed: () => _deleteDraft(context, t),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDraft(BuildContext context, Thesis t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft'),
        content: Text('Delete "${t.title}"? Published and approved studies can only be removed by an admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.error),
            child: const Text('Delete'),
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
              content: Text(stillThere
                  ? 'Deleted on server, but the list did not refresh — reload the page'
                  : 'Draft deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'published':
        color = CScholarColors.primaryGreen;
        break;
      case 'approved':
        color = CScholarColors.info;
        break;
      case 'draft':
        color = CScholarColors.orange;
        break;
      default:
        color = CScholarColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
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
}
