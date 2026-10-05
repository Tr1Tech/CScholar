// Admin: User Management — Stitch design v2
// Sidebar + topbar + user table

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  String _selectedRole = 'All';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (!isWide) {
      return _mobileLayout(context);
    }

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/users'),
      topbar: const AdminTopbar(),
      mobileTitle: 'User Management',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        // Header-first on the page rhythm. The user table is a DataTable
        // (DataRows are not widgets), so its rows enter with the card — row
        // staggering would need a widget-row rebuild, which is relayout.
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            PageHeader(
              title: 'User Management',
              subtitle: 'Accounts, roles, and access status.',
              action: NeumorphButton(
                onPressed: () => _showAddUserDialog(context),
                icon: Icons.person_add,
                label: 'Add User',
              ),
            ),
            const SizedBox(height: 20),
            CScholarCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Role filter: one choice among fixed options — the segmented
                  // control's exact job (single-select, no wrapping).
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _roleSegment(),
                  ),
                  const Divider(height: 1),
                  // Table
                  _userTable(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userTable(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    return asyncSlot(usersAsync,
      // Named arguments, so the loading branch keeps its reading order while
      // the skeleton is the same widget the switcher cross-fades from.
      skeleton: const Padding(
        padding: EdgeInsets.all(48),
        child: SkeletonList(count: 5, cardHeight: 56),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(48),
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load users',
          message: err.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(usersProvider),
        ),
      ),
      data: (users) {
        final filteredUsers = _selectedRole == 'All'
            ? users
            : users
                .where((u) => u.role.toLowerCase() == _selectedRole.toLowerCase())
                .toList();

        if (filteredUsers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.people_outline,
              title: 'No users found',
              message: 'No users matching "$_selectedRole".',
            ),
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
          rows: filteredUsers.map((u) => DataRow(
            cells: [
              DataCell(Text(u.username, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(u.email, style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary))),
              DataCell(RoleChip(u.role)),
              DataCell(ActiveChip(u.isActive)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphButton(
                    onPressed: () => _showEditUserDialog(context, u),
                    label: 'Edit',
                    gel: false,
                  ),
                  const SizedBox(width: 6),
                  NeumorphIconButton(
                    onPressed: () => _toggleActive(context, ref, u),
                    tooltip: u.isActive ? 'Deactivate user' : 'Reactivate user',
                    size: 36,
                    // State morphs instead of hard-swapping.
                    icon: Icons.block,
                    selectedIcon: Icons.check_circle_outline,
                    selected: !u.isActive,
                  ),
                ],
              )),
            ],
          )).toList(),
        );
      },
    );
  }

  static const _roles = ['All', 'Student', 'Faculty', 'Admin'];

  Widget _roleSegment() {
    return NeumorphSegmented(
      labels: _roles,
      selectedIndex:
          _roles.indexOf(_selectedRole).clamp(0, _roles.length - 1),
      onChanged: (i) => setState(() => _selectedRole = _roles[i]),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.username);
    final emailCtrl = TextEditingController(text: user.email);
    String newRole = user.role.toLowerCase();
    const roles = ['student', 'faculty', 'admin'];
    showClayDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => GlassDialog(
          title: Text('Edit User — ${user.username}'),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              NeumorphField(
                controller: nameCtrl,
                label: 'Username',
              ),
              const SizedBox(height: 12),
              NeumorphField(
                controller: emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              NeumorphSelect<String>(
                initialValue: roles.contains(newRole) ? newRole : 'student',
                label: 'Role',
                items: roles
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => newRole = v);
                },
              ),
            ]),
          ),
          actions: [
            NeumorphButton(
                onPressed: () => Navigator.pop(ctx),
                label: 'Cancel',
                gel: false),
            NeumorphButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveUser(context, ref, user,
                    nameCtrl.text.trim(), emailCtrl.text.trim(), newRole);
              },
              label: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String newRole = 'student';
    const roles = ['student', 'faculty', 'admin'];
    var obscure = true;
    showClayDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => GlassDialog(
          title: const Text('Add User'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              NeumorphField(
                controller: nameCtrl,
                label: 'Username',
              ),
              const SizedBox(height: 12),
              NeumorphField(
                controller: emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              NeumorphField(
                controller: passCtrl,
                label: 'Password (min 6 characters)',
                obscureText: obscure,
                suffixIcon: IconButton(
                  // Outline <-> filled morphs instead of hard-swapping.
                  icon: MorphIcon(
                    icon: Icons.visibility,
                    selectedIcon: Icons.visibility_off,
                    selected: obscure,
                    color: CScholarColors.textMuted,
                    selectedColor: CScholarColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () => setDialog(() => obscure = !obscure),
                ),
              ),
              const SizedBox(height: 12),
              NeumorphSelect<String>(
                initialValue: newRole,
                label: 'Role',
                items: roles
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => newRole = v);
                },
              ),
            ]),
          ),
          actions: [
            NeumorphButton(
                onPressed: () => Navigator.pop(ctx),
                label: 'Cancel',
                gel: false),
            NeumorphButton(
              onPressed: () {
                Navigator.pop(ctx);
                _createUser(context, ref, nameCtrl.text.trim(),
                    emailCtrl.text.trim(), passCtrl.text, newRole);
              },
              label: 'Add',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser(BuildContext context, WidgetRef ref, String username,
      String email, String password, String role) async {
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username, email, and password are required')),
        );
      }
      return;
    }
    if (password.length < 6) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
      }
      return;
    }
    try {
      await ref.read(apiServiceProvider).post('/api/users', {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });
      final fresh = await ref.refresh(usersProvider.future);
      if (context.mounted) {
        final found = fresh.any(
            (u) => u.username == username || u.email.toLowerCase() == email.toLowerCase());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(found
                  ? '$username added as $role'
                  : 'Saved on server, but the list did not refresh — reload the page'),
              backgroundColor: found ? CScholarColors.success : null),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _saveUser(BuildContext context, WidgetRef ref, User user,
      String username, String email, String newRole) async {
    if (username.isEmpty || email.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username and email are required')),
        );
      }
      return;
    }
    final me = ref.read(currentUserProvider);
    if (me != null && me.id == user.id && newRole != 'admin') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot remove your own admin role')),
        );
      }
      return;
    }
    try {
      await ref.read(apiServiceProvider).put('/api/users/${user.id}', {
        'username': username,
        'email': email,
        'role': newRole,
      });
      final fresh = await ref.refresh(usersProvider.future);
      final row = fresh.where((u) => u.id == user.id).toList();
      if (context.mounted) {
        if (row.isNotEmpty &&
            row.first.username == username &&
            row.first.email == email &&
            row.first.role.toLowerCase() == newRole) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username} updated'), backgroundColor: CScholarColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved on server, but the list did not refresh — reload the page')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, User user) async {
    final me = ref.read(currentUserProvider);
    if (me != null && me.id == user.id) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot deactivate your own account')),
        );
      }
      return;
    }
    try {
      await ref.read(apiServiceProvider).put(
        '/api/users/${user.id}/active',
        {'is_active': !user.isActive},
      );
      final fresh = await ref.refresh(usersProvider.future);
      final row = fresh.where((u) => u.id == user.id).toList();
      if (context.mounted) {
        if (row.isNotEmpty && row.first.isActive == !user.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(user.isActive ? '${user.username} deactivated' : '${user.username} reactivated'),
              backgroundColor: CScholarColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved on server, but the list did not refresh — reload the page')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Widget _mobileLayout(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: CScholarColors.surface,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('User Management', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _roleSegment(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncSlot(usersAsync,
              skeleton: const SkeletonList(count: 5, cardHeight: 56),
              error: (err, _) => Center(child: Text('Failed to load users: $err')),
              data: (users) {
                final filtered = _selectedRole == 'All'
                    ? users
                    : users.where((u) => u.role.toLowerCase() == _selectedRole.toLowerCase()).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No users found matching "$_selectedRole"'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final u = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _showEditUserDialog(context, u),
                        borderRadius:
                            BorderRadius.circular(CScholarRadius.md),
                        child: CScholarCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          borderRadius: CScholarRadius.md,
                          lift: true,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(u.username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(u.email),
                                  ],
                                ),
                              ),
                              RoleChip(u.role),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
