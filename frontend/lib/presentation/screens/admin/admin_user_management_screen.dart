// Admin: User Management — Stitch design v2
// Sidebar + topbar + user table

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminUserManagementScreen extends ConsumerWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (!isWide) {
      return _mobileLayout(context, ref);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          const AdminSidebar(currentPath: '/admin/users'),
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
                      const Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add User'),
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
                      child: Column(
                        children: [
                          // Filter chips
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _filterChip('All', true),
                                const SizedBox(width: 8),
                                _filterChip('Student', false),
                                const SizedBox(width: 8),
                                _filterChip('Faculty', false),
                                const SizedBox(width: 8),
                                _filterChip('Admin', false),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Table
                          _userTable(context, ref),
                        ],
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

  Widget _userTable(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    return usersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: CScholarColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                err.toString(),
                style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(usersProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: Text('No users found', style: TextStyle(color: CScholarColors.textSecondary))),
          );
        }
        return DataTable(
          headingRowColor: WidgetStateProperty.all(CScholarColors.backgroundLight),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((u) => DataRow(
            cells: [
              DataCell(Text(u.username, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(u.email, style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary))),
              DataCell(_roleChip(u.role)),
              DataCell(_statusChip(u.isActive)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => _showRoleDialog(context, u),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CScholarColors.info,
                      side: const BorderSide(color: CScholarColors.info),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Change Role', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      foregroundColor: u.isActive ? CScholarColors.error : CScholarColors.success,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline, size: 20),
                  ),
                ],
              )),
            ],
          )).toList(),
        );
      },
    );
  }

  Widget _roleChip(String role) {
    Color bg;
    Color fg;
    switch (role) {
      case 'admin':
      case 'Admin':
        bg = CScholarColors.error.withValues(alpha: 0.1);
        fg = CScholarColors.error;
        break;
      case 'faculty':
      case 'Faculty':
        bg = const Color(0xFF7B1FA2).withValues(alpha: 0.1);
        fg = const Color(0xFF7B1FA2);
        break;
      default:
        bg = CScholarColors.info.withValues(alpha: 0.1);
        fg = CScholarColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? CScholarColors.success.withValues(alpha: 0.1) : CScholarColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? CScholarColors.success : CScholarColors.textSecondary),
      ),
    );
  }

  Widget _filterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : CScholarColors.textPrimary)),
      selected: selected,
      onSelected: (_) {},
      backgroundColor: Colors.white,
      selectedColor: CScholarColors.primaryGreen,
      checkmarkColor: Colors.white,
      side: BorderSide(color: selected ? CScholarColors.primaryGreen : CScholarColors.dividerLight),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: InputDecoration(labelText: 'Full Name')),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Email')),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Program')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added'), backgroundColor: CScholarColors.success));
            },
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Role — ${user.username}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select a new role:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          ...['Student', 'Faculty', 'Admin'].map((r) => ListTile(
            leading: Icon(
              r == 'Admin' ? Icons.admin_panel_settings : r == 'Faculty' ? Icons.school : Icons.person,
              color: r == user.role ? CScholarColors.primaryGreen : CScholarColors.textSecondary,
            ),
            title: Text(r),
            trailing: r == user.role ? const Icon(Icons.check, color: CScholarColors.primaryGreen) : null,
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user.username} role changed to $r'), backgroundColor: CScholarColors.success));
            },
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
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
        title: const Text('User Management', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: const Center(child: Text('Mobile view - User Management')),
    );
  }
}
