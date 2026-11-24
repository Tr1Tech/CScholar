import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion_ambient.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_widgets.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  bool _showRecommended = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final recentTheses = ref.watch(recentThesesProvider);
    final stats = ref.watch(publicStatsProvider);
    final savedIds = ref.watch(savedThesisIdsProvider);
    final academicYears = ref.watch(academicYearsProvider);

    // Personalized feed: the profile is built from what this device has
    // saved/opened (see recommendationsProvider). No per-student table.
    final recommendations = ref.watch(recommendationsProvider);

    if (MobileStudentScaffold.useMobileShell(context)) {
      return StudentLayout(
        currentIndex: 0,
        child: _mobileBody(
          context,
          userName: user?.username ?? 'Alex',
          savedIds: savedIds,
          recentTheses: recentTheses,
          recommendations: recommendations,
        ),
      );
    }

    return StudentLayout(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            // PART 7 delay map: hero at 0 (settling, not just fading), metrics
            // on the page rhythm, then the list at +140 and the rail at +220.
            // The list and rail leave the shared column for explicit delays —
            // nesting them under the column's index would stack both offsets.
            // Delays schedule paint only; every block lays out on frame one,
            // so nothing jumps when its fade lands.
            child: Column(
              children: [
                StaggerColumn(
                  pitch: MotionPitch.page,
                  children: [
                    // 1. Welcome hero mirroring the mobile composition: eyebrow
                    // date, Manrope greeting, discovery subtitle, live orbit.
                    EntranceReveal(
                      scaleFrom: 0.98,
                      rise: 0,
                      child: ClaySurface(
                        padding: const EdgeInsets.all(28),
                        // The screen's one ambient gesture, living on the hero
                        // panel's own surface (never behind glass or a list).
                        // Gated and bounded inside DriftingWash itself.
                        child: DriftingWash(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 760;
                              // The orbit stays in the hero at every width.
                              // Below the two-column breakpoint it sits beside
                              // the greeting and scales with the content width
                              // (the mobile composition anchors it right too),
                              // instead of being dropped and leaving the hero
                              // without its illustration.
                              final orbitSize = isNarrow
                                  ? (constraints.maxWidth * 0.30)
                                        .clamp(96.0, 128.0)
                                        .toDouble()
                                  : 128.0;
                              final left = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _greetingEyebrow(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CScholarTextStyles.body(
                                      11,
                                      FontWeight.w800,
                                      CScholarColors.primaryGreenHover,
                                      letterSpacing: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Good ${_timeOfDay()},\n${_firstName(user?.username)}!',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: CScholarTextStyles.heading(
                                      isNarrow ? 28 : 32,
                                      FontWeight.w800,
                                      CScholarColors.textPrimary,
                                      height: 1.12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'What will you discover today?',
                                    style: CScholarTextStyles.body(
                                      13.5,
                                      FontWeight.w400,
                                      CScholarColors.textMuted,
                                    ),
                                  ),
                                ],
                              );
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: isNarrow ? 1 : 7, child: left),
                                  SizedBox(width: isNarrow ? 16 : 24),
                                  if (isNarrow)
                                    _DesktopOrbit(size: orbitSize)
                                  else
                                    Expanded(
                                      flex: 4,
                                      child: _DesktopOrbit(size: orbitSize),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 1b. Search CTA — same entry point as the mobile pill.
                    EntranceReveal(
                      child: GestureDetector(
                        onTap: () => context.go('/repository'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CScholarColors.primaryGreen,
                            borderRadius: BorderRadius.circular(
                              CScholarRadius.softCard,
                            ),
                            boxShadow: CScholarMaterial.gelDrop(depth: 0.9),
                          ),
                          child: Row(
                            children: [
                              // tile-exempt: icon well inside the search CTA bar.
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: CScholarColors.white.withValues(
                                    alpha: 0.13,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: CScholarColors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search papers, topics, authors',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CScholarTextStyles.body(
                                    14,
                                    FontWeight.w600,
                                    CScholarColors.white,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: CScholarColors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Metrics Stat Cards Row (4 KPI cards)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 540
                            ? 2
                            : 1;

                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          // Fixed extent, not an aspect ratio — see [kpiGridDelegate].
                          gridDelegate: kpiGridDelegate(
                            context,
                            crossAxisCount,
                            extent: metricCardIntrinsicHeight,
                          ),
                          children: [
                            for (var i = 0; i < 4; i++)
                              // Diagonal cascade on the feature rhythm: the
                              // strip walks, it does not wave left-to-right.
                              // StaggerColumn cannot reach GridView children,
                              // so each cell carries its finished delay.
                              Stagger(
                                index: i,
                                step: MotionPitch.feature.step,
                                max: MotionPitch.feature.max,
                                rise: MotionPitch.feature.rise,
                                delay: StaggerColumn.diagonalDelay(
                                  index: i,
                                  columns: crossAxisCount,
                                  pitch: MotionPitch.feature,
                                ),
                                child: [
                                  _metricCard(
                                    title: 'Published Studies',
                                    value: '${stats.value?['studies'] ?? 0}',
                                    icon: Icons.article_outlined,
                                    iconBg: CScholarColors.thesisChipBg,
                                    iconColor: CScholarColors.primaryGreen,
                                  ),
                                  _metricCard(
                                    title: 'CEIT Programs',
                                    value: '${stats.value?['programs'] ?? 0}',
                                    icon: Icons.account_balance_outlined,
                                    iconBg: CScholarColors.skyTint,
                                    iconColor: CScholarColors.skyInk,
                                  ),
                                  _metricCard(
                                    title: 'Academic Years',
                                    value:
                                        '${academicYears.value?.length ?? 0}',
                                    icon: Icons.calendar_today_outlined,
                                    iconBg: CScholarColors.violetTint,
                                    iconColor: CScholarColors.violetInk,
                                  ),
                                  _metricCard(
                                    title: 'Your Saved',
                                    value: '${savedIds.length}',
                                    icon: Icons.bookmark_outline,
                                    iconBg: CScholarColors.cyanTint,
                                    iconColor: CScholarColors.cyanInk,
                                  ),
                                ][i],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Two-Column Content Grid: Recent Studies & Recommended.
                // Explicit PART 7 delays: the list re-forms at +140, the rail
                // glides in from the right at +220. Rise is 0 here — the offset
                // is scheduling, and the cards' own content carries the travel.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMultiCol = constraints.maxWidth > 880;

                    final leftCol = EntranceReveal(
                      delay: const Duration(milliseconds: 140),
                      rise: 0,
                      child: _recentStudiesCard(recentTheses),
                    );
                    final rightCol = EntranceReveal(
                      delay: const Duration(milliseconds: 220),
                      child: _recommendedStudiesCard(recommendations),
                    );

                    if (isMultiCol) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftCol),
                          const SizedBox(width: 20),
                          Expanded(child: rightCol),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          leftCol,
                          const SizedBox(height: 20),
                          rightCol,
                        ],
                      );
                    }
                  },
                ),
                const CScholarFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile Home (`cscholar-mobile-ui/src/App.tsx:578-671`): welcome + orbit,
  /// search CTA, compact stats, recent 2, recommend toggle. Same providers as
  /// the desktop branch above — only the layout is prototype-skinned.
  Widget _mobileBody(
    BuildContext context, {
    required String userName,
    required Set<int> savedIds,
    required AsyncValue<List<dynamic>> recentTheses,
    required AsyncValue<RecommendationFeed> recommendations,
  }) {
    final t = CScholarMobileTheme.of(context);
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final firstName = userName
        .split(' ')
        .firstWhere((p) => p.isNotEmpty, orElse: () => 'Alex');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 106),
      child: StaggerColumn(
        pitch: MotionPitch.page,
        children: [
          // Welcome + orbit.
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 9, 2, 23),
            child: SizedBox(
              height: 158,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                                  style: t.eyebrow,
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Good ${_timeOfDay()},\n$firstName.',
                                  style: t.manrope(
                                    31,
                                    FontWeight.w700,
                                    t.ink,
                                    height: 1.12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Flexible(
                          child: Text(
                            'What will you discover today?',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: -3,
                    top: 7,
                    child: MobileResearchOrbit(),
                  ),
                ],
              ),
            ),
          ),
          // Search CTA -> repository.
          GestureDetector(
            onTap: () => context.go('/repository'),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: CScholarMobileColors.green,
                borderRadius: BorderRadius.circular(22),
                boxShadow: CScholarMaterial.gelDrop(depth: 0.9),
              ),
              child: Row(
                children: [
                  // tile-exempt: icon well inside the mobile search CTA.
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: CScholarColors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 19,
                      color: CScholarColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search papers, topics, authors',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.dmSans(
                        13,
                        FontWeight.w600,
                        CScholarColors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: CScholarColors.white,
                  ),
                ],
              ),
            ),
          ),
          // Compact stats.
          Container(
            margin: const EdgeInsets.fromLTRB(0, 17, 0, 27),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: t.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _compactStat(context, '12', 'Viewed')),
                _divider(context),
                Expanded(
                  child: _compactStat(context, '${savedIds.length}', 'Saved'),
                ),
                _divider(context),
                Expanded(child: _compactStat(context, '3', 'Topics')),
              ],
            ),
          ),
          // Recent research (2).
          _mobileSectionHeading(
            context,
            eyebrow: 'Continue exploring',
            title: 'Recent research',
            actionLabel: 'See all',
            onAction: () => context.go('/repository'),
          ),
          const SizedBox(height: 13),
          asyncSlot<List<dynamic>>(
            recentTheses,
            skeleton: const SkeletonList(count: 2, cardHeight: 96),
            data: (theses) {
              if (theses.isEmpty) {
                return const EmptyState(
                  mobile: true,
                  compact: true,
                  icon: Icons.history,
                  title: 'No recent studies yet',
                  message: 'Studies you open will show up here.',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < theses.take(2).length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == 1 ? 0 : 11),
                      child: Stagger(
                        index: i,
                        step: MotionPitch.result.step,
                        max: MotionPitch.result.max,
                        rise: MotionPitch.result.rise,
                        child: Builder(
                          builder: (context) {
                            final t = theses[i];
                            return MobileThesisCard(
                              thesis: t,
                              saved: savedIds.contains(t.id),
                              onOpen: () => context.go('/thesis/${t.id}'),
                              onSave: () => ref
                                  .read(savedThesisIdsProvider.notifier)
                                  .toggle(t.id),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
            error: (_, _) =>
                Text('Unable to load recent studies', style: t.bodyMuted),
          ),
          const SizedBox(height: 14),
          // Recommend toggle -> reveal rail.
          GestureDetector(
            onTap: () => setState(() => _showRecommended = !_showRecommended),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: t.mint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: t.green),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Recommended for you',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.dmSans(11, FontWeight.w700, t.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 17, color: t.green),
                ],
              ),
            ),
          ),
          if (_showRecommended) ...[
            const SizedBox(height: 10),
            EntranceReveal(
              child: asyncSlot<RecommendationFeed>(
                recommendations,
                skeleton: const SkeletonList(count: 1, cardHeight: 96),
                data: (feed) {
                  if (feed.isEmpty) {
                    return Text('No recommendations yet', style: t.bodyMuted);
                  }
                  final r = feed.items.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(feed.basis, style: t.bodyMuted),
                      ),
                      MobileThesisCard(
                        thesis: r.thesis,
                        saved: savedIds.contains(r.thesis.id),
                        onOpen: () => context.go(
                          '/thesis/${r.thesis.id}',
                          extra: r.score,
                        ),
                        onSave: () => ref
                            .read(savedThesisIdsProvider.notifier)
                            .toggle(r.thesis.id),
                      ),
                    ],
                  );
                },
                error: (_, _) =>
                    Text('Recommendations unavailable', style: t.bodyMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactStat(BuildContext context, String value, String label) {
    final t = CScholarMobileTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.manrope(17, FontWeight.w700, t.ink),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: t.dmSans(10, FontWeight.w400, t.muted),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Container(width: 1, height: 23, color: t.line);
  }

  Widget _mobileSectionHeading(
    BuildContext context, {
    required String eyebrow,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final t = CScholarMobileTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.eyebrow,
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.sectionTitle,
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          Flexible(
            child: GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.dmSans(11, FontWeight.w700, t.green),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _greetingEyebrow() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}'
        .toUpperCase();
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool gold = false,
  }) {
    return CScholarCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClayIconTile(
            icon: icon,
            size: 44,
            gold: gold,
            background: iconBg,
            tint: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: CScholarTextStyles.body(
                    12,
                    FontWeight.w500,
                    CScholarColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CScholarTextStyles.heading(
                    22,
                    FontWeight.w800,
                    CScholarColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentStudiesCard(AsyncValue<List<dynamic>> recentTheses) {
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Studies',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.heading(
                    16,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: NeumorphButton(
                  onPressed: () => context.go('/repository'),
                  label: 'View All',
                  gel: false,
                  icon: Icons.arrow_forward,
                ),
              ),
            ],
          ),
          Divider(color: CScholarMaterial.rim, height: 16),
          const SizedBox(height: 6),
          asyncSlot(
            recentTheses,
            skeleton: const SkeletonList(count: 4, cardHeight: 64),
            data: (theses) {
              if (theses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: EmptyState(
                    compact: true,
                    icon: Icons.history,
                    title: 'No recent studies yet',
                    message: 'Studies you open will show up here.',
                  ),
                );
              }
              return Column(
                // Result rhythm inside the +140 block: the list walks in
                // thesis by thesis instead of landing as one slab.
                children: theses.take(4).toList().asMap().entries.map((entry) {
                  final t = entry.value;
                  return Stagger(
                    index: entry.key,
                    step: MotionPitch.result.step,
                    max: MotionPitch.result.max,
                    rise: MotionPitch.result.rise,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(CScholarRadius.md),
                        onTap: () => context.go('/thesis/${t.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CScholarMaterial.clayDeep,
                            borderRadius: BorderRadius.circular(
                              CScholarRadius.md,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClayIconTile(
                                icon: Icons.article_outlined,
                                size: 36,
                                gel: false,
                                background: CScholarColors.primaryGreenLight,
                                tint: CScholarColors.primaryGreen,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CScholarTextStyles.body(
                                        13.5,
                                        FontWeight.w600,
                                        CScholarColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if ((t.program?.name ?? '').isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CScholarColors.skyTint,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              t.program!.name,
                                              style: CScholarTextStyles.body(
                                                10.5,
                                                FontWeight.w700,
                                                CScholarColors.skyInk,
                                              ),
                                            ),
                                          ),
                                        if ((t.program?.name ?? '')
                                                .isNotEmpty &&
                                            (t.academicYear?.label ?? '')
                                                .isNotEmpty)
                                          const SizedBox(width: 8),
                                        if ((t.academicYear?.label ?? '')
                                            .isNotEmpty)
                                          Text(
                                            t.academicYear!.label,
                                            style: CScholarTextStyles.body(
                                              11.5,
                                              FontWeight.w400,
                                              CScholarColors.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            error: (_, _) => const Text('Error loading studies'),
          ),
        ],
      ),
    );
  }

  Widget _recommendedStudiesCard(
    AsyncValue<RecommendationFeed> recommendations,
  ) {
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recommended for You',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.heading(
                    16,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: NeumorphButton(
                  onPressed: () => context.go('/repository'),
                  label: 'View All',
                  gel: false,
                  icon: Icons.arrow_forward,
                ),
              ),
            ],
          ),
          Divider(color: CScholarMaterial.rim, height: 16),
          const SizedBox(height: 6),
          asyncSlot(
            recommendations,
            skeleton: const SkeletonList(count: 4, cardHeight: 64),
            data: (feed) {
              if (feed.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No recommendations yet',
                      style: CScholarTextStyles.body(
                        12,
                        FontWeight.w500,
                        CScholarColors.textMuted,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Same result rhythm for the rail's own rows, inside the rail
                // block gliding in from the right at +220.
                children: [
                  if (feed.basis.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        feed.basis,
                        style: CScholarTextStyles.body(
                          11.5,
                          FontWeight.w400,
                          CScholarColors.textMuted,
                        ),
                      ),
                    ),
                  ...feed.items.asMap().entries.map((entry) {
                    final r = entry.value;
                    final score = r.score;
                    final hasPct = score != null && score >= 0.5;
                    final program = r.thesis.program?.name ?? '';
                    final detail = hasPct
                        ? '${(score * 100).round()}% match'
                        : (r.reason == 'new' ? 'New' : 'Related');
                    return Stagger(
                      index: entry.key,
                      step: MotionPitch.result.step,
                      max: MotionPitch.result.max,
                      rise: MotionPitch.result.rise,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            CScholarRadius.md,
                          ),
                          onTap: () => context.go(
                            '/thesis/${r.thesis.id}',
                            extra: score,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CScholarMaterial.clayDeep,
                              borderRadius: BorderRadius.circular(
                                CScholarRadius.md,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClayIconTile(
                                  icon: Icons.auto_awesome,
                                  size: 36,
                                  gel: false,
                                  background: CScholarColors.primaryGreenLight,
                                  tint: CScholarColors.primaryGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.thesis.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: CScholarTextStyles.body(
                                          13.5,
                                          FontWeight.w600,
                                          CScholarColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$program${program.isEmpty ? '' : ' • '}$detail',
                                        style: CScholarTextStyles.body(
                                          11.5,
                                          FontWeight.w400,
                                          CScholarColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: hasPct
                                      ? 'Semantically similar to the studies you saved or opened — ${(score * 100).round()}%.'
                                      : (r.reason == 'new'
                                            ? 'New in the repository.'
                                            : 'Related to the studies you saved or opened.'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CScholarColors.primaryGreenLight,
                                      borderRadius: BorderRadius.circular(
                                        CScholarRadius.full,
                                      ),
                                      border: Border.all(
                                        color: CScholarColors.primaryGreen
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 11,
                                          color: CScholarColors.primaryGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasPct
                                              ? '${(score * 100).round()}%'
                                              : (r.reason == 'new'
                                                    ? 'New'
                                                    : 'Related'),
                                          style: CScholarTextStyles.body(
                                            11,
                                            FontWeight.w700,
                                            CScholarColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Recommendations unavailable',
                  style: CScholarTextStyles.body(
                    12,
                    FontWeight.w500,
                    CScholarColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(String? username) {
    final parts = (username ?? '').split(' ').where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'there' : parts.first;
  }

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

/// Research-orbit wrapper reused by the dashboard hero.
///
/// The orbit is 128px at desktop widths and scales down with [size] when the
/// hero enters its narrow composition. Either way it is pinned to the hero's
/// trailing edge — the mobile composition anchors it to the right too. Centring
/// it inside the flex column left a wide dead gutter on the right and made the
/// hero's outer margins (28px left vs ~168px right) visibly asymmetric.
class _DesktopOrbit extends StatelessWidget {
  const _DesktopOrbit({this.size = 128});

  /// Rendered edge length of the orbit square.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox.square(
          dimension: size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: const MobileResearchOrbit(),
          ),
        ),
      ),
    );
  }
}
