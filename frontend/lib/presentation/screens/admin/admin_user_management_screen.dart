// Admin: User Management — Stitch design v2
// Sidebar + topbar + user table

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/clay_pagination.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends ConsumerState<AdminUserManagementScreen> {
  String _selectedRole = 'All';

  /// Access status filter. "All" is the absence of a filter, not a value the
  /// account data knows.
  static const _statuses = ['All', 'Active', 'Inactive'];
  String _status = 'All';

  /// 0-based page for the user table (both the desktop table and the mobile
  /// list share it, so the two layouts never point at different rows).
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    // A new search starts a new result set: page 1, never "page 7 of 1".
    ref.listen(adminSearchProvider(AdminSearchSection.users), (_, _) {
      if (mounted) setState(() => _page = 0);
    });
    final size = MediaQuery.of(context).size;
    final isWide = size.width > CScholarBreakpoints.mobile;

    if (!isWide) {
      return _mobileLayout(context);
    }

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/users'),
      topbar: const AdminTopbar(section: AdminSearchSection.users),
      mobileTitle: 'User Management',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Header-first on the page rhythm. Rows rebuild on every filter and
        // search change, so they enter with the card instead of re-cascading
        // each time a keystroke lands.
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
                  // One label-less filter row, matching Thesis Management:
                  // Role keeps the sliding-pill track, access status folds into
                  // a compact dropdown with the same pill height and fill.
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final roleFilter = _roleSegment();
                        final statusFilter = _statusSelect();
                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              roleFilter,
                              const SizedBox(height: 10),
                              statusFilter,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: roleFilter),
                            const SizedBox(width: 12),
                            SizedBox(width: 214, child: statusFilter),
                          ],
                        );
                      },
                    ),
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
    final query = ref
        .watch(adminSearchProvider(AdminSearchSection.users))
        .trim();
    final needle = query.toLowerCase();
    return asyncSlot(
      usersAsync,
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
          compact: true,
          title: 'Failed to load users',
          message: userFacingError(
            err,
            fallback: 'The user list could not be loaded. Try again.',
          ),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(usersProvider),
        ),
      ),
      data: (users) {
        final filteredUsers = users
            .where(
              (u) =>
                  _selectedRole == 'All' ||
                  u.role.toLowerCase() == _selectedRole.toLowerCase(),
            )
            .where(
              (u) =>
                  _status == 'All' ||
                  (_status == 'Active' ? u.isActive : !u.isActive),
            )
            .where(
              (u) =>
                  needle.isEmpty ||
                  u.username.toLowerCase().contains(needle) ||
                  u.email.toLowerCase().contains(needle),
            )
            .toList();

        if (filteredUsers.isEmpty) {
          final searching = query.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.people_outline,
              compact: true,
              title: searching ? 'No matches' : 'No users found',
              message: searching
                  ? 'No users match "$query".'
                  : (_selectedRole != 'All' || _status != 'All')
                  ? 'No users match the selected filters.'
                  : 'No accounts in the system yet.',
              actionLabel: searching ? 'Clear search' : null,
              onAction: searching
                  ? () => ref
                        .read(
                          adminSearchProvider(AdminSearchSection.users)
                              .notifier,
                        )
                        .clear()
                  : null,
            ),
          );
        }
        // Card rows, same language as Programs: identity mark, bold name with
        // the email beneath, role and status as chips, actions as round
        // buttons. Rows are widgets now, so hover and press behave like the
        // rest of the admin shell. Ten per page, matching every admin table.
        final pageIndex = clampPageIndex(_page, filteredUsers.length);
        final visibleUsers = filteredUsers
            .skip(pageIndex * kAdminTablePageSize)
            .take(kAdminTablePageSize)
            .toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final u in visibleUsers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CScholarCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    borderRadius: CScholarRadius.xl,
                    child: Row(
                      children: [
                        GelAvatar(name: u.username, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CScholarTextStyles.body(
                                  13.5,
                                  FontWeight.w700,
                                  CScholarColors.textPrimary,
                                ),
                              ),
                              Text(
                                u.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CScholarTextStyles.body(
                                  11.5,
                                  FontWeight.w400,
                                  CScholarColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        RoleChip(u.role),
                        const SizedBox(width: 8),
                        ActiveChip(u.isActive),
                        const SizedBox(width: 8),
                        NeumorphIconButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit user',
                          color: CScholarColors.violetInk,
                          onPressed: () => _showEditUserDialog(context, u),
                        ),
                        const SizedBox(width: 8),
                        // Destructive last, on every list: the rightmost slot
                        // is the one a fast hand reaches by accident.
                        NeumorphIconButton(
                          onPressed: () => _toggleActive(context, ref, u),
                          tooltip: u.isActive
                              ? 'Deactivate user'
                              : 'Reactivate user',
                          // State morphs instead of hard-swapping, and the hue
                          // travels with it: red to revoke, green to restore.
                          icon: Icons.block,
                          selectedIcon: Icons.check_circle_outline,
                          color: CScholarColors.error,
                          selectedColor: CScholarColors.primaryGreen,
                          selected: !u.isActive,
                        ),
                      ],
                    ),
                  ),
                ),
              ClayPagination(
                page: pageIndex + 1,
                total: filteredUsers.length,
                padding: const EdgeInsets.only(top: 8),
                onPageChanged: (p) => setState(() => _page = p - 1),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _roles = ['All', 'Student', 'Faculty', 'Admin'];

  Widget _roleSegment() {
    return NeumorphSegmented(
      labels: _roles,
      selectedIndex: _roles.indexOf(_selectedRole).clamp(0, _roles.length - 1),
      // A role filter changes the set being paged, so it starts at page 1.
      onChanged: (i) => setState(() {
        _selectedRole = _roles[i];
        _page = 0;
      }),
    );
  }

  /// Shared access-status control, so the desktop row and the mobile stack
  /// cannot drift in height or fill.
  NeumorphSelectField<String> _statusSelect() => NeumorphSelectField<String>(
    value: _status,
    items: _statusItems,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    onChanged: (status) {
      if (status == null) return;
      setState(() {
        _status = status;
        _page = 0;
      });
    },
  );

  /// Access-status options carry the same green/slate cue as [ActiveChip], in
  /// the menu and on the closed face alike.
  List<DropdownMenuItem<String>> get _statusItems => [
    for (final status in _statuses)
      DropdownMenuItem<String>(
        value: status,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusDotColor(status),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                status == 'All' ? 'All statuses' : status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  13,
                  FontWeight.w600,
                  CScholarColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
  ];

  static Color _statusDotColor(String status) => status == 'Active'
      // A 7px dot of the deep brand green reads near-black; the hover green
      // stays legible at this size.
      ? CScholarColors.primaryGreenHover
      : CScholarColors.textMuted;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphField(controller: nameCtrl, label: 'Username'),
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
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r[0].toUpperCase() + r.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => newRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx),
              label: 'Cancel',
              gel: false,
            ),
            NeumorphButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveUser(
                  context,
                  ref,
                  user,
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  newRole,
                );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphField(controller: nameCtrl, label: 'Username'),
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
                    tooltip: obscure ? 'Show password' : 'Hide password',
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
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r[0].toUpperCase() + r.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => newRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx),
              label: 'Cancel',
              gel: false,
            ),
            NeumorphButton(
              onPressed: () {
                Navigator.pop(ctx);
                _createUser(
                  context,
                  ref,
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  passCtrl.text,
                  newRole,
                );
              },
              label: 'Add',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser(
    BuildContext context,
    WidgetRef ref,
    String username,
    String email,
    String password,
    String role,
  ) async {
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username, email, and password are required'),
          ),
        );
      }
      return;
    }
    if (password.length < 6) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters'),
          ),
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
          (u) =>
              u.username == username ||
              u.email.toLowerCase() == email.toLowerCase(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              found ? '$username added as $role' : 'Saved on server, but the list did not refresh — reload the page',
            ),
            backgroundColor: found ? CScholarColors.success : null,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: "The account change couldn't be saved. Try again.",
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveUser(
    BuildContext context,
    WidgetRef ref,
    User user,
    String username,
    String email,
    String newRole,
  ) async {
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
          const SnackBar(
            content: Text('You cannot remove your own admin role'),
          ),
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
            SnackBar(
              content: Text('${user.username} updated'),
              backgroundColor: CScholarColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Saved on server, but the list did not refresh — reload the page',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: "The account change couldn't be saved. Try again.",
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) async {
    final me = ref.read(currentUserProvider);
    if (me != null && me.id == user.id) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot deactivate your own account'),
          ),
        );
      }
      return;
    }
    // Deactivating locks the account out of the app, so confirm first.
    // Reactivating is safe and reversible, so it proceeds immediately.
    if (user.isActive) {
      final confirmed = await showClayDialog<bool>(
        context: context,
        builder: (ctx) => GlassDialog(
          title: const Text('Deactivate User'),
          content: Text(
            'Deactivate ${user.username}? They will be signed out and unable '
            'to sign in again until an admin reactivates the account.',
          ),
          actions: [
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx, false),
              label: 'Cancel',
              gel: false,
            ),
            NeumorphButton(
              onPressed: () => Navigator.pop(ctx, true),
              label: 'Deactivate',
              danger: true,
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    try {
      await ref.read(apiServiceProvider).put('/api/users/${user.id}/active', {
        'is_active': !user.isActive,
      });
      final fresh = await ref.refresh(usersProvider.future);
      final row = fresh.where((u) => u.id == user.id).toList();
      if (context.mounted) {
        if (row.isNotEmpty && row.first.isActive == !user.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isActive
                    ? '${user.username} deactivated'
                    : '${user.username} reactivated',
              ),
              backgroundColor: CScholarColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Saved on server, but the list did not refresh — reload the page',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback: "The account change couldn't be saved. Try again.",
              ),
            ),
          ),
        );
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
          tooltip: 'Back to dashboard',
          icon: Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: Text(
          'User Management',
          style: TextStyle(
            color: CScholarColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            child: asyncSlot(
              usersAsync,
              skeleton: const SkeletonList(count: 5, cardHeight: 56),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load users',
                  message: userFacingError(
                    err,
                    fallback: 'The user list could not be loaded. Try again.',
                  ),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(usersProvider),
                ),
              ),
              data: (users) {
                final filtered = _selectedRole == 'All'
                    ? users
                    : users
                          .where(
                            (u) =>
                                u.role.toLowerCase() ==
                                _selectedRole.toLowerCase(),
                          )
                          .toList();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.group_off_outlined,
                      title: 'No users found',
                      message: 'No users matching "$_selectedRole".',
                      actionLabel: 'Show all roles',
                      onAction: () => setState(() => _selectedRole = 'All'),
                    ),
                  );
                }
                final pageIndex = clampPageIndex(_page, filtered.length);
                final visible = filtered
                    .skip(pageIndex * kAdminTablePageSize)
                    .take(kAdminTablePageSize)
                    .toList();
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visible.length,
                        itemBuilder: (ctx, i) {
                          final u = visible[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _showEditUserDialog(context, u),
                              borderRadius: BorderRadius.circular(
                                CScholarRadius.md,
                              ),
                              child: CScholarCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                borderRadius: CScholarRadius.md,
                                lift: true,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                      ),
                    ),
                    // Same ten-row pages as the desktop table: the two layouts
                    // share [_page], so switching widths keeps your place.
                    ClayPagination(
                      page: pageIndex + 1,
                      total: filtered.length,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      onPageChanged: (p) => setState(() => _page = p - 1),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
