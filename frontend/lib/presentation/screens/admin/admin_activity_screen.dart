import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/relative_time.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';

/// Admin: one place for activity, search demand, and the security audit trail.
class AdminActivityScreen extends ConsumerStatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  ConsumerState<AdminActivityScreen> createState() =>
      _AdminActivityScreenState();
}

class _AdminActivityScreenState extends ConsumerState<AdminActivityScreen> {
  static const _tabs = ['Activity', 'Searches', 'Security'];
  static const _actionOptions = <String, String>{
    '': 'All actions',
    'login_success': 'Successful sign-in',
    'login_failed': 'Failed sign-in',
    'password_changed': 'Password change',
    'user_created': 'User created',
    'user_updated': 'User updated',
    'user_deactivated': 'User deactivated',
    'user_reactivated': 'User reactivated',
    'thesis_created': 'Thesis created',
    'thesis_updated': 'Thesis updated',
    'thesis_status_changed': 'Thesis status changed',
    'thesis_deleted': 'Thesis deleted',
    'thesis_bulk_status': 'Bulk status change',
    'program_deleted': 'Program deleted',
    'academic_year_deleted': 'Academic year deleted',
    'category_deleted': 'Category deleted',
    'import_started': 'Import started',
  };

  int _tab = 0;
  int _activityPage = 1;
  int _auditPage = 1;
  String _action = '';

  void _refresh() {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(activityLogProvider(_activityPage));
    ref.invalidate(
      auditLogsProvider((
        page: _auditPage,
        action: _action.isEmpty ? null : _action,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/activity'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Activity & Logs',
      backRoute: '/admin/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StaggerColumn(
          pitch: MotionPitch.page,
          children: [
            PageHeader(
              title: 'Activity & Logs',
              subtitle:
                  'Submissions, review decisions, import batches, search demand, and security events.',
              actions: [
                NeumorphButton(
                  onPressed: _refresh,
                  icon: Icons.refresh,
                  label: 'Refresh',
                  gel: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            NeumorphSegmented(
              labels: _tabs,
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 20),
            asyncSlot<Map<String, dynamic>>(
              stats,
              skeleton: const SkeletonList(count: 1, cardHeight: 150),
              data: (s) => _statsStrip(s),
              error: (err, _) => EmptyState(
                compact: true,
                icon: Icons.error_outline,
                title: "Couldn't load activity totals",
                message: userFacingError(
                  err,
                  fallback: 'Activity totals could not be loaded.',
                ),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),
            const SizedBox(height: 20),
            switch (_tab) {
              0 => _activityTab(),
              1 => _searchesTab(stats),
              _ => _securityTab(),
            },
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _statsStrip(Map<String, dynamic> s) {
    final searches = (s['searches_7d'] as num?)?.toInt() ?? 0;
    final semantic = (s['semantic_searches'] as num?)?.toInt() ?? 0;
    final totalSearches = (s['searches'] as num?)?.toInt() ?? 0;
    final share = totalSearches == 0
        ? 0
        : ((semantic * 100) / totalSearches).round();
    final cards = [
      (
        label: 'SEARCHES · 7 DAYS',
        value: '$searches',
        trend: '${s['search_growth'] ?? 0}% vs previous week',
        icon: Icons.search,
      ),
      (
        label: 'SEMANTIC SHARE',
        value: '$share%',
        trend: '$semantic of $totalSearches searches',
        icon: Icons.auto_awesome_outlined,
      ),
      (
        label: 'AI RECOMMENDATIONS',
        value: '${s['recommendations_served'] ?? 0}',
        trend: 'impressions logged',
        icon: Icons.recommend_outlined,
      ),
      (
        label: 'REVIEWS · 7 DAYS',
        value: '${s['reviews_7d'] ?? 0}',
        trend: '${s['imports_7d'] ?? 0} import batches',
        icon: Icons.fact_check_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 520 ? 2 : 1);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: kpiGridDelegate(context, count),
          children: [
            for (final card in cards)
              KpiCard(
                label: card.label,
                value: card.value,
                trend: card.trend,
                icon: card.icon,
                iconBg: CScholarColors.thesisChipBg,
                iconColor: CScholarColors.primaryGreen,
              ),
          ],
        );
      },
    );
  }

  Widget _activityTab() {
    final feed = ref.watch(activityLogProvider(_activityPage));
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent activity',
            style: CScholarTextStyles.heading(
              16,
              FontWeight.w700,
              CScholarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New submissions, review decisions, and import batches.',
            style: CScholarTextStyles.body(
              12,
              FontWeight.w400,
              CScholarColors.textMuted,
            ),
          ),
          Divider(color: CScholarMaterial.rim, height: 20),
          asyncSlot<RecentActivityPage>(
            feed,
            skeleton: const SkeletonList(count: 5, cardHeight: 62),
            data: (page) {
              if (page.items.isEmpty) {
                return const EmptyState(
                  compact: true,
                  icon: Icons.history,
                  title: 'No activity yet',
                  message: 'Submissions and reviews will appear here.',
                );
              }
              return Column(
                children: [
                  for (final item in page.items) ...[
                    _activityRow(item),
                    Divider(color: CScholarMaterial.rim, height: 12),
                  ],
                  _pager(
                    page: page.page,
                    total: page.total,
                    limit: page.limit,
                    onPrevious: page.page > 1
                        ? () => setState(() => _activityPage = page.page - 1)
                        : null,
                    onNext:
                        page.page * page.limit < page.total
                        ? () => setState(() => _activityPage = page.page + 1)
                        : null,
                  ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              compact: true,
              icon: Icons.error_outline,
              title: "Couldn't load activity",
              message: userFacingError(
                err,
                fallback: 'The activity feed could not be loaded.',
              ),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(activityLogProvider(_activityPage)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> item) {
    final kind = (item['kind'] ?? 'submission').toString();
    final style = switch (kind) {
      'review' => (
        icon: Icons.fact_check_outlined,
        bg: CScholarColors.infoLight,
        tint: CScholarColors.info,
      ),
      'import' => (
        icon: Icons.upload_file_outlined,
        bg: CScholarColors.violetTint,
        tint: CScholarColors.violetInk,
      ),
      _ => (
        icon: Icons.add_circle_outline,
        bg: CScholarColors.thesisChipBg,
        tint: CScholarColors.primaryGreen,
      ),
    };
    final program = (item['program'] ?? '').toString();
    return InkWell(
      borderRadius: BorderRadius.circular(CScholarRadius.md),
      onTap: kind == 'submission' && item['id'] != null
          ? () => context.go('/thesis/${item['id']}')
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              // tile-exempt: activity kind marker, not a standalone icon tile
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(CScholarRadius.md),
              ),
              child: Icon(style.icon, size: 18, color: style.tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['title'] ?? 'Untitled').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.body(
                      13,
                      FontWeight.w600,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      (item['activity_type'] ?? '').toString(),
                      if (program.isNotEmpty) program,
                      (item['subtitle'] ?? '').toString(),
                    ].where((part) => part.isNotEmpty).join(' · '),
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
            Text(
              relativeTime(item['created_at'] as String?),
              style: CScholarTextStyles.body(
                11,
                FontWeight.w400,
                CScholarColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchesTab(AsyncValue<Map<String, dynamic>> stats) {
    return asyncSlot<Map<String, dynamic>>(
      stats,
      skeleton: const SkeletonList(count: 2, cardHeight: 180),
      data: (s) {
        final rows = (s['top_queries'] as List<dynamic>?) ?? const [];
        final total = (s['searches'] as num?)?.toInt() ?? 0;
        final week = (s['searches_7d'] as num?)?.toInt() ?? 0;
        final semantic = (s['semantic_searches'] as num?)?.toInt() ?? 0;
        return CScholarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search demand',
                style: CScholarTextStyles.heading(
                  16,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total logged searches · $week in the last 7 days · '
                '$semantic semantic',
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w400,
                  CScholarColors.textMuted,
                ),
              ),
              Divider(color: CScholarMaterial.rim, height: 20),
              if (rows.isEmpty)
                const EmptyState(
                  compact: true,
                  icon: Icons.search_off,
                  title: 'No searches logged yet',
                  message:
                      'Run a keyword or semantic search and it will appear here.',
                )
              else
                for (final raw in rows)
                  _queryRow(Map<String, dynamic>.from(raw as Map)),
            ],
          ),
        );
      },
      error: (err, _) => EmptyState(
        compact: true,
        icon: Icons.error_outline,
        title: "Couldn't load searches",
        message: userFacingError(
          err,
          fallback: 'Search activity could not be loaded.',
        ),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(dashboardStatsProvider),
      ),
    );
  }

  Widget _queryRow(Map<String, dynamic> row) {
    final mode = (row['mode'] ?? 'keyword').toString();
    final semantic = mode == 'semantic';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (row['query'] ?? '').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(
                13,
                FontWeight.w600,
                CScholarColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: semantic
                  ? CScholarColors.infoLight
                  : CScholarColors.thesisChipBg,
              borderRadius: BorderRadius.circular(CScholarRadius.full),
            ),
            child: Text(
              semantic ? 'Semantic' : 'Keyword',
              style: CScholarTextStyles.body(
                10.5,
                FontWeight.w700,
                semantic ? CScholarColors.info : CScholarColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${row['count'] ?? 0}',
              textAlign: TextAlign.end,
              style: CScholarTextStyles.body(
                12,
                FontWeight.w700,
                CScholarColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityTab() {
    final logs = ref.watch(
      auditLogsProvider((page: _auditPage, action: _action.isEmpty ? null : _action)),
    );
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security audit log',
                      style: CScholarTextStyles.heading(
                        16,
                        FontWeight.w700,
                        CScholarColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign-ins, account changes, content edits, and taxonomy deletes.',
                      style: CScholarTextStyles.body(
                        12,
                        FontWeight.w400,
                        CScholarColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 210,
                child: NeumorphSelectField<String>(
                  value: _action,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    for (final entry in _actionOptions.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _action = value;
                      _auditPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          Divider(color: CScholarMaterial.rim, height: 20),
          asyncSlot<AuditLogPage>(
            logs,
            skeleton: const SkeletonList(count: 6, cardHeight: 64),
            data: (page) {
              if (page.items.isEmpty) {
                return const EmptyState(
                  compact: true,
                  icon: Icons.shield_outlined,
                  title: 'No security events',
                  message: 'Sign-ins and admin changes will appear here.',
                );
              }
              return Column(
                children: [
                  for (final item in page.items) ...[
                    _auditRow(item),
                    Divider(color: CScholarMaterial.rim, height: 12),
                  ],
                  _pager(
                    page: page.page,
                    total: page.total,
                    limit: page.limit,
                    onPrevious: page.page > 1
                        ? () => setState(() => _auditPage = page.page - 1)
                        : null,
                    onNext:
                        page.page * page.limit < page.total
                        ? () => setState(() => _auditPage = page.page + 1)
                        : null,
                  ),
                ],
              );
            },
            error: (err, _) => EmptyState(
              compact: true,
              icon: Icons.error_outline,
              title: "Couldn't load the audit log",
              message: userFacingError(
                err,
                fallback: 'The security audit log could not be loaded.',
              ),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(
                auditLogsProvider((
                  page: _auditPage,
                  action: _action.isEmpty ? null : _action,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditRow(Map<String, dynamic> item) {
    final action = (item['action'] ?? '').toString();
    final visual = _auditVisual(action);
    final actor = (item['actor_username'] ?? 'unknown').toString();
    final role = (item['actor_role'] ?? '').toString();
    final ip = (item['ip_address'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // tile-exempt: audit action marker, not a standalone icon tile
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: visual.bg,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
            ),
            child: Icon(visual.icon, size: 18, color: visual.tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['summary'] ?? action).toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    13,
                    FontWeight.w600,
                    CScholarColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    action,
                    '$actor${role.isEmpty ? '' : ' · $role'}',
                    if (ip.isNotEmpty) ip,
                  ].join(' · '),
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
          Text(
            relativeTime(item['created_at'] as String?),
            style: CScholarTextStyles.body(
              11,
              FontWeight.w400,
              CScholarColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color bg, Color tint}) _auditVisual(String action) {
    if (action.contains('failed') || action.contains('deleted')) {
      return (
        icon: Icons.gpp_bad_outlined,
        bg: CScholarColors.errorLight,
        tint: CScholarColors.error,
      );
    }
    if (action.contains('login') || action.contains('password')) {
      return (
        icon: Icons.lock_outline,
        bg: CScholarColors.infoLight,
        tint: CScholarColors.info,
      );
    }
    if (action.contains('user_')) {
      return (
        icon: Icons.person_outline,
        bg: CScholarColors.violetTint,
        tint: CScholarColors.violetInk,
      );
    }
    if (action.contains('created')) {
      return (
        icon: Icons.add_circle_outline,
        bg: CScholarColors.thesisChipBg,
        tint: CScholarColors.primaryGreen,
      );
    }
    return (
      icon: Icons.edit_note_outlined,
      bg: CScholarColors.thesisChipBg,
      tint: CScholarColors.primaryGreen,
    );
  }

  Widget _pager({
    required int page,
    required int total,
    required int limit,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  }) {
    final totalPages = total == 0 ? 1 : (total + limit - 1) ~/ limit;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Page $page of $totalPages · $total events',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(
                12,
                FontWeight.w600,
                CScholarColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          NeumorphIconButton(
            icon: Icons.chevron_left,
            size: 34,
            tooltip: 'Previous page',
            onPressed: onPrevious,
          ),
          const SizedBox(width: 8),
          NeumorphIconButton(
            icon: Icons.chevron_right,
            size: 34,
            tooltip: 'Next page',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
