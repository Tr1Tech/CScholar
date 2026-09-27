import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String term) {
    final query = term.trim();
    if (query.isNotEmpty) {
      context.go('/repository?q=${Uri.encodeComponent(query)}');
    } else {
      context.go('/repository');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentTheses = ref.watch(recentThesesProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isMobile = size.width < 640;

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // 1. Sticky Navigation Header
          SliverToBoxAdapter(
            child: Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: CScholarColors.borderLight)),
              ),
              child: Row(
                children: [
                  const CScholarLogo(iconSize: 36, subtitle: 'CEIT REPOSITORY'),
                  if (isWide) ...[
                    const SizedBox(width: 36),
                    Row(
                      children: [
                        _headerNavLink('Home', isActive: true, onTap: () => context.go('/')),
                        const SizedBox(width: 8),
                        _headerNavLink('Browse', onTap: () => context.go('/repository')),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Search quick icon
                  IconButton(
                    tooltip: 'Search repository',
                    icon: const Icon(Icons.search, size: 22, color: CScholarColors.textSecondary),
                    onPressed: () => context.go('/repository'),
                  ),
                  const SizedBox(width: 8),
                  // Login & Register CTA Buttons
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CScholarColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                    ),
                    child: Text(
                      'Login',
                      style: CScholarTextStyles.inter(14, FontWeight.w600, Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isMobile)
                    OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CScholarColors.textPrimary,
                        side: const BorderSide(color: CScholarColors.borderLight),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                      ),
                      child: Text(
                        'Register',
                        style: CScholarTextStyles.inter(14, FontWeight.w600, CScholarColors.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Hero Section with Gradient and Search
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 64 : 24,
                vertical: isWide ? 84 : 48,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CScholarColors.heroDeep,
                    CScholarColors.heroMid,
                    CScholarColors.heroGlow,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Ambient glows: gold prestige + soft light (static layers,
                  // no animation — the one glass moment lives in the search box).
                  Positioned(
                    top: -90,
                    right: -70,
                    child: _glow(240, CScholarColors.gold.withValues(alpha: 0.22)),
                  ),
                  Positioned(
                    bottom: -110,
                    left: -50,
                    child: _glow(280, Colors.white.withValues(alpha: 0.08)),
                  ),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: CScholarColors.heroBadgeFill,
                          borderRadius: BorderRadius.circular(CScholarRadius.full),
                          border: Border.all(color: CScholarColors.heroBadgeRim, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: CScholarColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CEIT THESIS & CAPSTONE REPOSITORY',
                              style: CScholarTextStyles.inter(
                                11,
                                FontWeight.w700,
                                CScholarColors.gold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Display Headline
                      Text(
                        'Find research that\nmatches your ideas.',
                        style: CScholarTextStyles.poppins(
                          isWide ? 46 : 32,
                          FontWeight.w800,
                          Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          'Search CEIT thesis and capstone projects with keywords or plain-language questions, ranked by semantic similarity.',
                          style: CScholarTextStyles.inter(
                            isWide ? 17 : 14.5,
                            FontWeight.w400,
                            CScholarMaterial.shadowDark,
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Big Hero Search Box — frosted glass over the gradient.
                      // A single static GlassPanel (never inside scrolling or
                      // animated content) so it holds frame rate.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: GlassPanel(
                          radius: CScholarRadius.lg,
                          // Deliberate overrides of the chrome recipe — .62
                          // fill / 18 blur. The hero's copy sits behind this
                          // box, so it needs a more opaque, sharper pane.
                          fill: Colors.white.withValues(alpha: 0.88),
                          blur: 14,
                          padding: const EdgeInsets.all(6),
                          // Glass over the dark hero: a dark shadow is correct
                          // here (the no-black rule covers shadows cast on the
                          // sage canvas). Tinted to the hero's own deep green so
                          // it reads as the hero's shadow, not as soot.
                          shadows: [
                            BoxShadow(
                              color: CScholarColors.heroDeep
                                  .withValues(alpha: 0.42),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Icon(Icons.search, color: CScholarColors.textHint, size: 24),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onSubmitted: _handleSearch,
                                  style: CScholarTextStyles.inter(15, FontWeight.w400, CScholarColors.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Search thesis, capstone, topic, author, keyword...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: () => _handleSearch(_searchController.text),
                                style: FilledButton.styleFrom(
                                  backgroundColor: CScholarColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                ),
                                child: const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Popular Search Pills — live keywords from the database.
                      Consumer(
                        builder: (context, ref, _) {
                          final keywordsAsync = ref.watch(keywordsProvider);
                          return keywordsAsync.maybeWhen(
                            data: (keywords) {
                              if (keywords.isEmpty) return const SizedBox.shrink();
                              return Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    'Popular searches:',
                                    style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.heroText),
                                  ),
                                  ...keywords
                                      .take(4)
                                      .map((k) => _popularSearchTag(k.term)),
                                ],
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ),
          ),

          // 3. Live repository stats (public endpoint + catalog sizes)
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: CScholarColors.borderLight)),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 28),
                  child: _statsStrip(),
                ),
              ),
            ),
          ),

          // 4. Latest Studies Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 64 : 20,
                vertical: 48,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latest Studies',
                                  style: CScholarTextStyles.poppins(24, FontWeight.w700, CScholarColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recently published thesis and capstone works from CEIT students',
                                  style: CScholarTextStyles.inter(14, FontWeight.w400, CScholarColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () => context.go('/repository'),
                            label: Text(
                              'View All',
                              style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.primaryGreen),
                            ),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward, size: 16, color: CScholarColors.primaryGreen),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Studies Grid
                      recentTheses.when(
                        data: (theses) {
                          if (theses.isEmpty) {
                            return const Center(child: Text('No featured studies available'));
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 960
                                  ? 3
                                  : constraints.maxWidth > 620
                                      ? 2
                                      : 1;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: theses.take(6).length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.15,
                                ),
                                itemBuilder: (context, index) {
                                  return ThesisCard(
                                    thesis: theses[index],
                                  );
                                },
                              );
                            },
                          );
                        },
                        loading: () =>
                            const SkeletonList(count: 3, cardHeight: 150),
                        error: (_, _) => const Center(child: Text('Error loading featured studies')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Institutional Footer
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: CScholarColors.borderLight)),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Text(
                        '© 2026 CScholar — CEIT Thesis & Capstone Repository. All rights reserved.',
                        style: CScholarTextStyles.inter(12, FontWeight.w400, CScholarColors.textMuted),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (ctx) => GlassDialog(
                                title: const Text('Help Desk'),
                                content: const Text(
                                    'For account issues, contact your administrator or '
                                    'email the CEIT office at ceit@csu.edu.ph.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Close')),
                                ],
                              ),
                            ),
                            child: Text('Help Desk', style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Live counts row under the hero: published studies, programs,
  /// academic years. All from public endpoints — no login needed.
  Widget _statsStrip() {
    return Consumer(
      builder: (context, ref, _) {
        final stats = ref.watch(publicStatsProvider);
        final years = ref.watch(academicYearsProvider);
        final studies = stats.value?['studies']?.toString() ?? '—';
        final programs = stats.value?['programs']?.toString() ?? '—';
        final yearCount = years.value?.length.toString() ?? '—';
        return Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 32,
          runSpacing: 16,
          children: [
            _statItem(studies, 'Published Studies', Icons.article_outlined),
            _statItem(programs, 'CEIT Programs', Icons.school_outlined),
            _statItem(yearCount, 'Academic Years',
                Icons.calendar_today_outlined),
          ],
        );
      },
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClayIconTile(
          icon: icon,
          size: 44,
          gel: false,
          background: CScholarColors.primaryGreenLight,
          tint: CScholarColors.primaryGreen,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: CScholarTextStyles.poppins(
                    22, FontWeight.w800, CScholarColors.textPrimary)),
            Text(label,
                style: CScholarTextStyles.inter(
                    12, FontWeight.w500, CScholarColors.textMuted)),
          ],
        ),
      ],
    );
  }

  /// Soft radial glow orb for the hero (static decoration, no blur cost).
  Widget _glow(double size, Color color) {    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  Widget _headerNavLink(String title,
      {bool isActive = false, required VoidCallback onTap}) {    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isActive ? CScholarColors.primaryGreenVeryLight : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
      ),
      child: Text(
        title,
        style: CScholarTextStyles.inter(
          14,
          isActive ? FontWeight.w600 : FontWeight.w500,
          isActive ? CScholarColors.primaryGreen : CScholarColors.textSecondary,
        ),
      ),
    );
  }

  Widget _popularSearchTag(String term) {
    return InkWell(
      borderRadius: BorderRadius.circular(CScholarRadius.full),
      onTap: () {
        _searchController.text = term;
        _handleSearch(term);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: CScholarMaterial.scrim,
          borderRadius: BorderRadius.circular(CScholarRadius.full),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          term,
          style: CScholarTextStyles.inter(12, FontWeight.w500, Colors.white),
        ),
      ),
    );
  }
}
