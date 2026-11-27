import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/core/utils/vocabulary.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/change_password_dialog.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// Admin: account profile and password.
///
/// Mirrors the faculty settings page: the admin sidebar had no account surface,
/// so changing a password was only possible by signing out first. Sign-out
/// itself lives in the sidebar.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/settings'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Settings',
      backRoute: '/admin/dashboard',
      maxWidth: 720,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Your administrator account.',
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CScholarTextStyles.heading(
                                17,
                                FontWeight.w700,
                                CScholarColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CScholarTextStyles.body(
                                12.5,
                                FontWeight.w400,
                                CScholarColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
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
                          (user?.role ?? 'admin').toUpperCase(),
                          style: CScholarTextStyles.body(
                            11,
                            FontWeight.w700,
                            CScholarColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: CScholarMaterial.rim, height: 32),
                  _infoRow('Username', user?.username ?? '—'),
                  _infoRow('Email', user?.email ?? '—'),
                  _infoRow('Role', roleLabel(user?.role)),
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
                    'Security',
                    style: CScholarTextStyles.heading(
                      15,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Change the password used to sign in to this account.',
                    style: CScholarTextStyles.body(
                      13,
                      FontWeight.w400,
                      CScholarColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: NeumorphButton(
                      onPressed: () => showChangePasswordDialog(context),
                      icon: Icons.lock_reset_outlined,
                      label: 'Change password',
                      expand: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SemanticIndexCard(),
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

/// Admin-only control for the semantic (embedding) index.
///
/// The rebuild endpoint skips studies that already have chunks unless
/// `refresh=true`. Without a control for that flag the button could never
/// actually refresh an already-indexed study, so this card owns the toggle and
/// passes the chosen mode through on every rebuild.
class _SemanticIndexCard extends ConsumerStatefulWidget {
  const _SemanticIndexCard();

  @override
  ConsumerState<_SemanticIndexCard> createState() => _SemanticIndexCardState();
}

class _SemanticIndexCardState extends ConsumerState<_SemanticIndexCard> {
  /// When true, send `refresh=true` so every published/approved study is
  /// re-embedded, not just the ones missing chunks.
  bool _refreshAll = false;
  bool _starting = false;

  Future<void> _rebuild() async {
    setState(() => _starting = true);
    try {
      await ref
          .read(apiServiceProvider)
          .post(
            '/api/embeddings/generate-bulk?refresh=$_refreshAll',
            const {},
          );
      ref.invalidate(embeddingStatusProvider);
      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _refreshAll
                ? 'Full semantic index rebuild started'
                : 'Semantic index rebuild started',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(
              e,
              fallback: 'The index rebuild could not be started.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final bulk = ref.watch(embeddingStatusProvider);
    final embedded = (stats.value?['embedded_theses'] as num?)?.toInt() ?? 0;
    final published = (stats.value?['published_theses'] as num?)?.toInt() ?? 0;
    final chunks = (stats.value?['embedding_chunks'] as num?)?.toInt() ?? 0;
    final running = bulk.value?['running'] == true;
    final busy = running || _starting;

    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory_outlined,
                size: 18,
                color: CScholarColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI / Semantic Index',
                  style: CScholarTextStyles.heading(
                    15,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${AppConfig.embeddingModel} · ${AppConfig.embeddingDim} dimensions',
            style: CScholarTextStyles.body(
              12,
              FontWeight.w500,
              CScholarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stats.when(
              data: (_) =>
                  '$embedded of $published published studies indexed · '
                  '$chunks text chunks',
              loading: () => 'Checking index coverage…',
              error: (error, stack) => 'Index coverage unavailable.',
            ),
            style: CScholarTextStyles.body(
              12,
              FontWeight.w400,
              CScholarColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bulk.when(
              data: (status) => running
                  ? 'Backfill running: ${status['processed'] ?? 0}'
                      '/${status['total'] ?? 0}'
                  : 'Backfill idle. Rebuild after a bulk import.',
              loading: () => 'Checking backfill status…',
              error: (error, stack) => 'Backfill status unavailable.',
            ),
            style: CScholarTextStyles.body(
              12,
              FontWeight.w400,
              CScholarColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Re-embed all studies',
                        style: CScholarTextStyles.body(
                          12.5,
                          FontWeight.w600,
                          CScholarColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Refresh vectors even for studies already indexed. '
                        'Slower than filling gaps.',
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
                Switch.adaptive(
                  value: _refreshAll,
                  onChanged: busy
                      ? null
                      : (value) {
                          selectionHaptic();
                          setState(() => _refreshAll = value);
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NeumorphButton(
              onPressed: busy ? null : _rebuild,
              loading: _starting,
              icon: Icons.refresh,
              label: busy
                  ? 'Rebuilding…'
                  : (_refreshAll ? 'Rebuild all' : 'Rebuild index'),
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}
