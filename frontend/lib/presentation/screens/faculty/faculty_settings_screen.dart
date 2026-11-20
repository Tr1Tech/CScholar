import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';

/// Faculty: account profile + session actions.
class FacultySettingsScreen extends ConsumerWidget {
  const FacultySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/settings'),
      topbar: FacultyTopbar(user: user),
      mobileTitle: 'Settings',
      backRoute: '/faculty/dashboard',
      maxWidth: 720,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Header-first on the page rhythm; info rows below are static text.
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Your faculty account.',
            ),
            const SizedBox(height: 20),
            CScholarCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      GelAvatar(name: user?.username ?? '—', size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? '—',
                              style: CScholarTextStyles.heading(
                                17,
                                FontWeight.w700,
                                CScholarColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '—',
                              style: CScholarTextStyles.body(
                                12.5,
                                FontWeight.w400,
                                CScholarColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CScholarColors.primaryGreenVeryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CScholarMaterial.rimPublished,
                          ),
                        ),
                        child: Text(
                          (user?.role ?? 'faculty').toUpperCase(),
                          style: CScholarTextStyles.body(
                            11,
                            FontWeight.w700,
                            CScholarColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: CScholarMaterial.rim, height: 32),
                  _infoRow('Username', user?.username ?? '—'),
                  _infoRow('Email', user?.email ?? '—'),
                  _infoRow('Role', user?.role ?? '—'),
                  _infoRow(
                    'Status',
                    (user?.isActive ?? true) ? 'Active' : 'Inactive',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CScholarCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session',
                    style: CScholarTextStyles.heading(
                      15,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: NeumorphButton(
                      onPressed: () async {
                        final token = ref.read(apiServiceProvider).token;
                        if (token != null) {
                          await Clipboard.setData(ClipboardData(text: token));
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Session token copied (for API debugging)',
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icons.key_outlined,
                      label: 'Copy session token',
                      gel: false,
                      expand: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: NeumorphButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                      danger: true,
                      icon: Icons.logout,
                      label: 'Log Out',
                      expand: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Same rule as [PageHeader]: the label owns the remaining width and
          // the value is a plain trailing child. With a non-flex label and a
          // flexible value, the trailing edge was an accident of
          // `spaceBetween`; a long value also ate almost the whole row. Cap it
          // at two thirds so the label keeps a readable column.
          final maxValueWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth * 2 / 3
              : double.infinity;
          return Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    12.5,
                    FontWeight.w500,
                    CScholarColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxValueWidth),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: CScholarTextStyles.body(
                    12.5,
                    FontWeight.w600,
                    CScholarColors.textPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
