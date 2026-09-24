import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';

/// Faculty: account profile + session actions.
class FacultySettingsScreen extends ConsumerWidget {
  const FacultySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
    final user = ref.watch(currentUserProvider);

    final body = SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Your faculty account.',
                  style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CScholarRadius.xl),
                  border: Border.all(color: CScholarColors.borderLight),
                  boxShadow: CScholarShadows.card,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: Text(
                            _initials(user?.username),
                            style: CScholarTextStyles.inter(18, FontWeight.w800, CScholarColors.primaryGreen),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.username ?? '—',
                                  style: CScholarTextStyles.poppins(
                                      17, FontWeight.w700, CScholarColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(user?.email ?? '—',
                                  style: CScholarTextStyles.inter(
                                      12.5, FontWeight.w400, CScholarColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text((user?.role ?? 'faculty').toUpperCase(),
                              style: CScholarTextStyles.inter(
                                  11, FontWeight.w700, CScholarColors.primaryGreen)),
                        ),
                      ],
                    ),
                    const Divider(color: CScholarColors.borderLight, height: 32),
                    _infoRow('Username', user?.username ?? '—'),
                    _infoRow('Email', user?.email ?? '—'),
                    _infoRow('Role', user?.role ?? '—'),
                    _infoRow('Status', (user?.isActive ?? true) ? 'Active' : 'Inactive'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CScholarRadius.xl),
                  border: Border.all(color: CScholarColors.borderLight),
                  boxShadow: CScholarShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session',
                        style: CScholarTextStyles.poppins(15, FontWeight.w700, CScholarColors.textPrimary)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final token = ref.read(apiServiceProvider).token;
                          if (token != null) {
                            await Clipboard.setData(ClipboardData(text: token));
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Session token copied (for API debugging)')),
                            );
                          }
                        },
                        icon: const Icon(Icons.key_outlined, size: 18),
                        label: const Text('Copy session token'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                        style: FilledButton.styleFrom(backgroundColor: CScholarColors.error),
                        icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                        label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          title: const Text('Settings',
              style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          const FacultySidebar(currentPath: '/faculty/settings'),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CScholarTextStyles.inter(12.5, FontWeight.w500, CScholarColors.textMuted)),
          Flexible(
            child: Text(value,
                style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
