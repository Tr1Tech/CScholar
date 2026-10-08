import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/motion_ambient.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final recentTheses = ref.watch(recentThesesProvider);
    final stats = ref.watch(publicStatsProvider);
    final savedIds = ref.watch(savedThesisIdsProvider);
    final academicYears = ref.watch(academicYearsProvider);

    // Recommendations are generated from the most recent database record.
    final recentList = recentTheses.value;
    final recommendationSourceId =
        (recentList != null && recentList.isNotEmpty) ? recentList.first.id : null;
    final recommendedTheses = recommendationSourceId == null
        ? AsyncValue.data(<SemanticResult>[])
        : ref.watch(recommendedThesesProvider(recommendationSourceId));

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
                    // 1. Greeting banner (display only — no actions).
                    // Minimal by design: badge, greeting, date. Browsing
                    // and searching live on the Repository page.
                    EntranceReveal(
                      scaleFrom: 0.98,
                      rise: 0,
                      child: ClaySurface(
                        radius: CScholarRadius.xl,
                        padding: const EdgeInsets.all(24),
                        // The screen's one ambient gesture, living on the hero
                        // panel's own surface (never behind glass or a list).
                        // Gated and bounded inside DriftingWash itself.
                        child: DriftingWash(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow =
                                  constraints.maxWidth < 760;
                              final left = Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Eyebrow badge — institutional scope at a glance.
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: CScholarColors
                                          .primaryGreenVeryLight,
                                      borderRadius: BorderRadius.circular(
                                          CScholarRadius.full),
                                      border: Border.all(
                                          color: CScholarMaterial
                                              .rimPublished),
                                    ),
                                    child: Text(
                                      'CEIT • 2025–2026 REPOSITORY',
                                      style: CScholarTextStyles.inter(
                                        10.5,
                                        FontWeight.w700,
                                        CScholarColors.primaryGreen,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Good ${_timeOfDay()}${(user?.username ?? '').isEmpty ? '' : ', ${user!.username}'}!',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: CScholarTextStyles.poppins(
                                      24,
                                      FontWeight.w800,
                                      CScholarColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _greetingSubtitle(),
                                    style: CScholarTextStyles.inter(
                                      13.5,
                                      FontWeight.w400,
                                      CScholarColors.textMuted,
                                    ),
                                  ),
                                ],
                              );
                              if (isNarrow) return left;
                              // Wide: a quiet decorative trio fills the
                              // right side — static art, nothing to tap.
                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 7, child: left),
                                  const SizedBox(width: 24),
                                  const Expanded(
                                    flex: 4,
                                    child: _HeroArt(),
                                  ),
                                ],
                              );
                            },
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
                          physics:
                              const NeverScrollableScrollPhysics(),
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
                                    value:
                                        '${stats.value?['studies'] ?? 0}',
                                    icon: Icons.article_outlined,
                                    iconBg:
                                        CScholarColors.thesisChipBg,
                                    iconColor:
                                        CScholarColors.primaryGreen,
                                  ),
                                  _metricCard(
                                    title: 'CEIT Programs',
                                    value:
                                        '${stats.value?['programs'] ?? 0}',
                                    icon: Icons
                                        .account_balance_outlined,
                                    iconBg: CScholarColors.skyTint,
                                    iconColor: CScholarColors.skyInk,
                                  ),
                                  _metricCard(
                                    title: 'Academic Years',
                                    value:
                                        '${academicYears.value?.length ?? 0}',
                                    icon: Icons
                                        .calendar_today_outlined,
                                    iconBg:
                                        CScholarColors.violetTint,
                                    iconColor:
                                        CScholarColors.violetInk,
                                  ),
                                  _metricCard(
                                    title: 'Your Saved',
                                    value: '${savedIds.length}',
                                    icon: Icons.bookmark_outline,
                                    iconBg: CScholarColors
                                        .capstoneChipBg,
                                    iconColor:
                                        CScholarColors.warningFg,
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
                      origin: const Offset(0.06, 0),
                      child: _recommendedStudiesCard(recommendedTheses),
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

  String _greetingSubtitle() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
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
      'December'
    ];
    final day = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$day, $month ${now.day}, ${now.year} • Browse and discover CEIT research below.';
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
                  style: CScholarTextStyles.inter(
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
                  style: CScholarTextStyles.poppins(
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
                  style: CScholarTextStyles.poppins(
                      16, FontWeight.w700, CScholarColors.textPrimary),
                ),
              ),
              NeumorphButton(
                onPressed: () => context.go('/repository'),
                label: 'View All',
                gel: false,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
          const Divider(color: CScholarMaterial.rim, height: 16),
          const SizedBox(height: 6),
          asyncSlot(
            recentTheses,
            skeleton: const SkeletonList(count: 4, cardHeight: 64),
            data: (theses) {
              if (theses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent studies available'),
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
                            borderRadius:
                                BorderRadius.circular(CScholarRadius.md),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClayIconTile(
                                icon: Icons.article_outlined,
                                size: 36,
                                gel: false,
                                background:
                                    CScholarColors.primaryGreenLight,
                                tint: CScholarColors.primaryGreen,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CScholarTextStyles.inter(
                                          13.5,
                                          FontWeight.w600,
                                          CScholarColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if ((t.program?.name ?? '')
                                            .isNotEmpty)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  CScholarColors.skyTint,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      4),
                                            ),
                                            child: Text(
                                              t.program!.name,
                                              style:
                                                  CScholarTextStyles.inter(
                                                      10.5,
                                                      FontWeight.w700,
                                                      CScholarColors
                                                          .skyInk),
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
                                            style:
                                                CScholarTextStyles.inter(
                                                    11.5,
                                                    FontWeight.w400,
                                                    CScholarColors
                                                        .textMuted),
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

  Widget _recommendedStudiesCard(AsyncValue<List<SemanticResult>> recommended) {
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
                  style: CScholarTextStyles.poppins(
                      16, FontWeight.w700, CScholarColors.textPrimary),
                ),
              ),
              NeumorphButton(
                onPressed: () => context.go('/repository'),
                label: 'View All',
                gel: false,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
          const Divider(color: CScholarMaterial.rim, height: 16),
          const SizedBox(height: 6),
          asyncSlot(
            recommended,
            skeleton: const SkeletonList(count: 4, cardHeight: 64),
            data: (recs) {
              if (recs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No recommendations yet',
                      style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                    ),
                  ),
                );
              }
              return Column(
                // Same result rhythm for the rail's own rows, inside the rail
                // block gliding in from the right at +220.
                children: recs.take(4).toList().asMap().entries.map((entry) {
                  final r = entry.value;
                  return Stagger(
                    index: entry.key,
                    step: MotionPitch.result.step,
                    max: MotionPitch.result.max,
                    rise: MotionPitch.result.rise,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(CScholarRadius.md),
                        onTap: () => context.go(
                          '/thesis/${r.thesis.id}',
                          extra: r.similarity,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CScholarMaterial.clayDeep,
                            borderRadius:
                                BorderRadius.circular(CScholarRadius.md),
                          ),
                          child: Row(
                            children: [
                              ClayIconTile(
                                icon: Icons.auto_awesome,
                                size: 36,
                                gel: false,
                                background: CScholarColors.goldSoft,
                                tint: CScholarColors.warningFg,
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
                                      style: CScholarTextStyles.inter(
                                          13.5,
                                          FontWeight.w600,
                                          CScholarColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r.thesis.program?.name ?? ''}${(r.thesis.program?.name ?? '').isEmpty ? '' : ' • '}${(r.similarity * 100).round()}% match',
                                      style: CScholarTextStyles.inter(
                                          11.5,
                                          FontWeight.w400,
                                          CScholarColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Tooltip(
                                message:
                                    'AI recommendation — ${(r.similarity * 100).round()}% semantically similar to your recent views. Open to see why.',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: CScholarColors.goldSoft,
                                    borderRadius: BorderRadius.circular(
                                        CScholarRadius.full),
                                    border: Border.all(
                                        color:
                                            CScholarMaterial.rimDraft),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome,
                                          size: 11,
                                          color:
                                              CScholarColors.warningFg),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(r.similarity * 100).round()}%',
                                        style: CScholarTextStyles.inter(
                                            11,
                                            FontWeight.w700,
                                            CScholarColors.warningFg),
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
                }).toList(),
              );
            },
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Recommendations unavailable',
                  style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

/// Static decorative trio for the greeting banner — pure display, no taps,
/// no counts, no buttons. Kept compact so the banner stays a greeting.
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            top: 12,
            child: _TiltedCover(seed: 3, angle: -0.12),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _TiltedCover(seed: 5, angle: 0.12),
          ),
          ThesisCover(seed: 1, width: 96, height: 120, iconSize: 40),
        ],
      ),
    );
  }
}

class _TiltedCover extends StatelessWidget {
  final int seed;
  final double angle;
  const _TiltedCover({required this.seed, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ThesisCover(
          seed: seed, width: 84, height: 104, iconSize: 32),
    );
  }
}
