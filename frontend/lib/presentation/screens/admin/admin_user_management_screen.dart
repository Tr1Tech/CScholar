// Admin: User Management — list all users, change roles, activate/deactivate

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminUserManagementScreen extends ConsumerWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    // Mock user list — replace with real provider when connecting backend
    final users = _mockUsers;

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
        title: const Text('User Management', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          FilledButton.icon(
            onPressed: () => _showAddUserDialog(context),
            style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add User'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: CScholarColors.dividerLight, height: 1)),
      ),
      body: isWide
          ? _buildDesktopTable(context, users)
          : _buildMobileList(context, users),
    );

    if (!isWide) return body();

    return Row(
      children: [
        const AdminSidebar(currentPath: '/admin/users'),
        Container(width: 1, color: CScholarColors.dividerLight),
        Expanded(child: body()),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<_MockUser> users) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${users.length} users', style: const TextStyle(color: CScholarColors.textSecondary)),
              _buildRoleFilterChips(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CScholarColors.dividerLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(CScholarColors.backgroundLight),
              columns: const [
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: users.map((u) => _buildTableRow(context, u)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<_MockUser> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (ctx, i) => _mobileUserCard(context, users[i]),
    );
  }

  DataRow _buildTableRow(BuildContext context, _MockUser u) {
    return DataRow(
      cells: [
        DataCell(Text(u.name, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(u.email, style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary))),
        DataCell(_roleChip(u.role)),
        DataCell(Text(u.program, style: const TextStyle(fontSize: 13))),
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
              onPressed: () => _toggleActive(context, u),
              style: IconButton.styleFrom(
                foregroundColor: u.isActive ? CScholarColors.error : CScholarColors.success,
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline, size: 20),
            ),
          ],
        )),
      ],
    );
  }

  Widget _mobileUserCard(BuildContext context, _MockUser u) {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CScholarColors.primaryGreenVeryLight,
                  child: Text(u.name[0], style: const TextStyle(color: CScholarColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(u.email, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
                    ],
                  ),
                ),
                _statusChip(u.isActive),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _roleChip(u.role),
                const SizedBox(width: 8),
                Text(u.program, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRoleDialog(context, u),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CScholarColors.info,
                      side: const BorderSide(color: CScholarColors.info),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Change Role', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _toggleActive(context, u),
                  style: IconButton.styleFrom(
                    foregroundColor: u.isActive ? CScholarColors.error : CScholarColors.success,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    Color bg;
    Color fg;
    switch (role) {
      case 'Admin':
        bg = CScholarColors.error.withValues(alpha: 0.1);
        fg = CScholarColors.error;
        break;
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? CScholarColors.success : CScholarColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRoleFilterChips() {
    return Row(
      children: [
        _filterChip('All', true),
        const SizedBox(width: 6),
        _filterChip('Student', false),
        const SizedBox(width: 6),
        _filterChip('Faculty', false),
        const SizedBox(width: 6),
        _filterChip('Admin', false),
      ],
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

  void _showRoleDialog(BuildContext context, _MockUser u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Role — ${u.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select a new role:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          ...['Student', 'Faculty', 'Admin'].map((r) => ListTile(
            leading: Icon(
              r == 'Admin' ? Icons.admin_panel_settings : r == 'Faculty' ? Icons.school : Icons.person,
              color: r == u.role ? CScholarColors.primaryGreen : CScholarColors.textSecondary,
            ),
            title: Text(r),
            trailing: r == u.role ? const Icon(Icons.check, color: CScholarColors.primaryGreen) : null,
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${u.name} role changed to $r'), backgroundColor: CScholarColors.success));
            },
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _toggleActive(BuildContext context, _MockUser u) {
    final newState = !u.isActive;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${u.name} ${newState ? 'activated' : 'deactivated'}'),
        backgroundColor: newState ? CScholarColors.success : CScholarColors.textSecondary,
      ),
    );
  }
}

// Mock data — replace with real API when connecting backend
final _mockUsers = [
  _MockUser(id: 1, name: 'Maria Clara Santos', email: 'maria.c.santos@csu.edu', role: 'Student', program: 'BSIT', isActive: true),
  _MockUser(id: 2, name: 'Juanito Cruz', email: 'juan.cruz@csu.edu', role: 'Faculty', program: 'BSCpE', isActive: true),
  _MockUser(id: 3, name: 'Admin User', email: 'admin@csu.edu', role: 'Admin', program: '—', isActive: true),
  _MockUser(id: 4, name: 'Ana Mae Bathan', email: 'ana.bathan@csu.edu', role: 'Student', program: 'BSECE', isActive: true),
  _MockUser(id: 5, name: 'Pedro Penduko', email: 'pedro.penduko@csu.edu', role: 'Faculty', program: 'BSME', isActive: false),
  _MockUser(id: 6, name: 'Liza Mae Duran', email: 'liza.duran@csu.edu', role: 'Student', program: 'BSIT', isActive: true),
];

class _MockUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String program;
  final bool isActive;

  _MockUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.program,
    required this.isActive,
  });
}
