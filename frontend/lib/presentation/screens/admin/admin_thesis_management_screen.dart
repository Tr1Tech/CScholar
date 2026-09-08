// Admin: Thesis Management — Stitch design v2
// Sidebar + topbar + data table

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

    if (!isWide) {
      return _mobileLayout(context, ref, theses);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          const AdminSidebar(currentPath: '/admin/thesis/management'),
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
                  ),
                  child: Row(
                    children: [
                      const Text('Thesis Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => context.go('/admin/thesis/new'),
                        style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Thesis'),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CScholarColors.dividerLight),
                      ),
                      child: theses.when(
                        data: (list) {
                          if (list == null || list.isEmpty) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No theses found')));
                          }
                          return DataTable(
                            headingRowColor: WidgetStateProperty.all(CScholarColors.backgroundLight),
                            columns: const [
                              DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: list.map((t) => DataRow(
                              cells: [
                                DataCell(Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                DataCell(Text(t.program?.name ?? '—')),
                                DataCell(Text(t.academicYear?.label ?? '—')),
                                DataCell(_statusChip(t.status)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => context.go('/thesis/${t.id}'),
                                      child: const Text('View', style: TextStyle(fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/admin/thesis/${t.id}/edit'),
                                      child: const Text('Edit', style: TextStyle(fontSize: 12, color: CScholarColors.orange)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: CScholarColors.error),
                                      onPressed: () => _deleteThesis(context, ref, t),
                                    ),
                                  ],
                                )),
                              ],
                            )).toList(),
                          );
                        },
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                        error: (_, __) => const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Could not load theses'))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'published':
        color = CScholarColors.primaryGreen;
        break;
      case 'pending':
        color = CScholarColors.orange;
        break;
      case 'rejected':
        color = CScholarColors.error;
        break;
      default:
        color = CScholarColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _deleteThesis(BuildContext context, WidgetRef ref, Thesis thesis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Thesis'),
        content: Text('Are you sure you want to delete "${thesis.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(repositoryServiceProvider).deleteThesis(thesis.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thesis deleted')));
            },
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref, AsyncValue<List<Thesis>?> theses) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('Thesis Management', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: theses.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list?.length ?? 0,
          itemBuilder: (ctx, i) {
            final t = list![i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${t.program?.name ?? '—'} • ${t.academicYear?.label ?? '—'}'),
                trailing: _statusChip(t.status),
                onTap: () => context.go('/thesis/${t.id}'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load theses')),
      ),
    );
  }
}
