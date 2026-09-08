// Admin: Thesis Management — list all theses with edit/delete actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminThesisManagementScreen extends ConsumerWidget {
  const AdminThesisManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theses = ref.watch(thesisListProvider(const ThesisListParams()));
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    Widget body() => Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
                onPressed: () => context.go('/admin/dashboard'),
              ),
        title: const Text('Thesis Management', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/admin/thesis/new'),
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Thesis'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: CScholarColors.dividerLight, height: 1)),
      ),
      body: theses.when(
        data: (list) {
          if (list == null || list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 56, color: CScholarColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No theses found', style: TextStyle(fontSize: 16, color: CScholarColors.textSecondary)),
                ],
              ),
            );
          }
          return _buildContent(context, ref, list, isWide);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );

    if (!isWide) return body();

    return Row(
      children: [
        const AdminSidebar(currentPath: '/admin/thesis/management'),
        Container(width: 1, color: CScholarColors.dividerLight),
        Expanded(child: body()),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Thesis> list, bool isWide) {
    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CScholarColors.dividerLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(CScholarColors.backgroundLight),
            columns: const [
              DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: list.map((t) => _tableRow(context, ref, t)).toList(),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _mobileCard(context, ref, list[i]),
    );
  }

  DataRow _tableRow(BuildContext context, WidgetRef ref, Thesis t) {
    return DataRow(
      cells: [
        DataCell(SizedBox(width: 260, child: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis))),
        DataCell(Text(t.program?.name ?? '—')),
        DataCell(Text(t.academicYear?.label ?? '—')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.status == 'published' ? CScholarColors.success.withValues(alpha: 0.1) : CScholarColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              t.status.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: t.status == 'published' ? CScholarColors.success : CScholarColors.orange),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: () => context.go('/thesis/${t.id}'), style: TextButton.styleFrom(foregroundColor: CScholarColors.info, padding: const EdgeInsets.symmetric(vertical: 8), visualDensity: VisualDensity.compact), child: const Text('View', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 4),
              OutlinedButton(onPressed: () => context.go('/admin/thesis/${t.id}/edit'), style: OutlinedButton.styleFrom(foregroundColor: CScholarColors.orange, side: const BorderSide(color: CScholarColors.orange), padding: const EdgeInsets.symmetric(vertical: 8), visualDensity: VisualDensity.compact), child: const Text('Edit', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 4),
              IconButton(onPressed: () => _confirmDelete(context, ref, t), style: IconButton.styleFrom(foregroundColor: CScholarColors.error, visualDensity: VisualDensity.compact), icon: const Icon(Icons.delete_outline, size: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileCard(BuildContext context, WidgetRef ref, Thesis t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${t.program?.name ?? '—'} • ${t.academicYear?.label ?? '—'}', style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.status == 'published' ? CScholarColors.success.withValues(alpha: 0.1) : CScholarColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: t.status == 'published' ? CScholarColors.success : CScholarColors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/admin/thesis/${t.id}/edit'),
                    style: OutlinedButton.styleFrom(foregroundColor: CScholarColors.orange, side: const BorderSide(color: CScholarColors.orange), padding: const EdgeInsets.symmetric(vertical: 6), visualDensity: VisualDensity.compact),
                    child: const Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref, t),
                  style: IconButton.styleFrom(foregroundColor: CScholarColors.error, visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Thesis t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Thesis?'),
        content: Text('Are you sure you want to delete "${t.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(repositoryServiceProvider).deleteThesis(t.id);
              ref.invalidate(thesisListProvider(const ThesisListParams()));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${t.title}" deleted')));
            },
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
