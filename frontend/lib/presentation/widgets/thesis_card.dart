import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

class ThesisCard extends StatefulWidget {
  final Thesis thesis;
  final double? similarityScore;
  final VoidCallback? onTap;

  /// Saved state for the banner bookmark toggle. Null (with [onToggleSave]
  /// null) means display-only: no toggle, exactly the old card.
  final bool? isSaved;

  /// Save handler. When set, a [TactileToggle] rides top-right on the banner.
  final VoidCallback? onToggleSave;

  /// Hero sources on/off. A hero needs exactly one source and one target per
  /// route change: the route rendering the detail target passes false here,
  /// the same opt-out `student_layout.dart` takes with `heroAvatar: false`
  /// for the route owning the avatar target.
  final bool heroBanner;

  const ThesisCard({
    super.key,
    required this.thesis,
    this.similarityScore,
    this.onTap,
    this.isSaved,
    this.onToggleSave,
    this.heroBanner = true,
  });

  /// Banner palette. Every stop is a DARK tone that carries the 10px w700 white
  /// type label at >= 4.5:1 — the previous set included `#FF9900` (2.14:1) and
  /// `#0D9488` (3.74:1), so one card in five had an unreadable label.
  ///
  /// Public so the contrast contract is testable (see
  /// `test/tier2_surface_test.dart`). Ratios with white text: #007A14 5.54,
  /// #1D4ED8 6.70, #0F766E 5.47, #7E22CE 6.98, #B45309 5.02.
  static const List<Color> bannerPalette = [
    CScholarColors.primaryGreen,
    Color(0xFF1D4ED8),
    Color(0xFF0F766E),
    Color(0xFF7E22CE),
    Color(0xFFB45309),
  ];

  @override
  State<ThesisCard> createState() => _ThesisCardState();
}

/// Hover state for the banner zoom. The card keeps its `CScholarCard` lift;
/// this owns only whether the pointer is over the card, so the banner can
/// answer separately from the lift.
class _ThesisCardState extends State<ThesisCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // Reduced motion (and touch, which never hovers) holds the banner at 1.0
    // exactly — never a snapped zoom.
    final animate = motionEnabled(context);
    // The save toggle overlays the card as a Stack SIBLING, never a
    // descendant of the card's own GestureDetector: nested tap recognizers
    // BOTH fire, so a toggle inside the card would also navigate. Siblings
    // are exclusive — the topmost opaque hit wins and the card never hears
    // the toggle's tap.
    return Stack(
      children: [
        GestureDetector(
          // Semantic landings hand their score through (see ResultCard): the
          // detail screen meters it, plain taps meter nothing.
          onTap: widget.onTap ??
              () => context.go(
                    '/thesis/${widget.thesis.id}',
                    extra: widget.similarityScore,
                  ),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: CScholarCard(
              padding: EdgeInsets.zero,
              lift: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CScholarRadius.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The banner zooms to 1.03 inside its OWN clip (top corners
                    // match the card, bottom stays square into the body), so the
                    // zoom crops instead of overflowing. Transform only, over the
                    // swap budget — the most premium micro-interaction available
                    // for one transform.
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(CScholarRadius.xl),
                      ),
                      child: AnimatedScale(
                        scale: animate && _hover ? 1.03 : 1.0,
                        duration:
                            animate ? CScholarMotion.swap : Duration.zero,
                        curve: CScholarCurves.settle,
                        child: _banner(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: _body(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Save toggle rides top-right on the banner when the card is
        // save-aware. White glyphs: every banner stop is dark (5.0:1 or
        // better with white). Same coordinates the in-banner toggle had —
        // only the hit-test relationship changed, not the look.
        if (widget.onToggleSave != null)
          Positioned(
            top: 2,
            right: 2,
            child: TactileToggle(
              selected: widget.isSaved ?? false,
              onChanged: widget.onToggleSave!,
              icon: Icons.bookmark_outline,
              selectedIcon: Icons.bookmark,
              size: 18,
              color: CScholarMaterial.shadowLight,
              selectedColor: CScholarMaterial.shadowLight,
              semanticLabel:
                  (widget.isSaved ?? false) ? 'Saved' : 'Save study',
            ),
          ),
      ],
    );
  }

  Widget _banner() {
    final flat = MediaQuery.highContrastOf(context);
    final banner = Container(
      height: 76,
      color: _headerColor,
      child: Stack(
        children: [
          // Soft radial glow bleeding off the top-right corner, WayFinder
          // NextClassCard-style: light on the dark banner, never behind the
          // title pill (top-left) or the badge. Decoration only — dropped
          // under high contrast with every other glow — and STATIC: a
          // breathing loop on every card in a forty-result grid would blow
          // the three-loop viewport budget, so the halo does not tick.
          if (!flat)
            Positioned(
              right: -36,
              top: -44,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CScholarMaterial.shadowLight.withValues(alpha: 0.20),
                      CScholarMaterial.shadowLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 4,
            child: Icon(
              Icons.article_outlined,
              color: CScholarMaterial.shadowLight.withValues(alpha: 0.22),
              size: 48,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOLID white pill, dark ink (17.85:1). The old 25%-white pill
                // composited to #409B4F over the green banner, which dropped
                // white label text to 3.49:1 on every single card.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CScholarMaterial.shadowLight,
                    borderRadius: BorderRadius.circular(CScholarRadius.sm),
                    boxShadow: CScholarMaterial.clayDrop(depth: 0.3),
                  ),
                  child: Text(
                    widget.thesis.researchType.toUpperCase(),
                    style: CScholarTextStyles.inter(
                      10,
                      FontWeight.w700,
                      CScholarMaterial.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.similarityScore != null)
                  _semanticBadge(widget.similarityScore!),
              ],
            ),
          ),
        ],
      ),
    );
    // Banner Hero SOURCE: the slab flies into the detail header. Only the
    // colour travels (flightShuttleBuilder) — text mid-flight smears. Off on
    // the target route via [heroBanner], so source and target can never share
    // a tag in one subtree.
    if (!widget.heroBanner) return banner;
    return Hero(
      tag: thesisBannerTag(widget.thesis.id),
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) =>
              ColoredBox(color: _headerColor),
      child: banner,
    );
  }

  Widget _body() {
    final title = Text(
      widget.thesis.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: CScholarTextStyles.poppins(
        14.5,
        FontWeight.w700,
        CScholarColors.textPrimary,
        height: 1.3,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    // Title Hero SOURCE: flies into the detail title. Text may
                    // fly (unlike the slab, it stays legible mid-flight).
                    widget.heroBanner
                        ? Hero(
                            tag: thesisTitleTag(widget.thesis.id),
                            child: title,
                          )
                        : title,
                    const SizedBox(height: 4),
                    if (widget.thesis.authors != null && widget.thesis.authors!.isNotEmpty)
                      Text(
                        widget.thesis.authors!.map((a) => '${a.firstName} ${a.lastName}').join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.inter(
                          11.5,
                          FontWeight.w400,
                          CScholarColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        if ((widget.thesis.program?.code ?? '').isNotEmpty)
                          Flexible(
                            child: _tag(widget.thesis.program!.code),
                          ),
                        if ((widget.thesis.program?.code ?? '').isNotEmpty &&
                            (widget.thesis.academicYear?.label ?? '').isNotEmpty)
                          const SizedBox(width: 8),
                        if ((widget.thesis.academicYear?.label ?? '').isNotEmpty)
                          Text(
                            widget.thesis.academicYear!.label,
                            style: CScholarTextStyles.inter(
                              11,
                              FontWeight.w500,
                              CScholarColors.textHint,
                            ),
                          ),
                      ],
                    ),
      ],
    );
  }

  /// Match badge. The fill is the system scrim (slate-tinted, not a black
  /// alpha) so it belongs to the palette; white ink stays legible on every
  /// banner stop in [_bannerPalette].
  Widget _semanticBadge(double score) {
    final pct = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CScholarMaterial.scrim,
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        border: Border.all(
          color: CScholarMaterial.shadowLight.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 11, color: CScholarColors.gold),
          const SizedBox(width: 4),
          Text(
            '$pct% match',
            style: CScholarTextStyles.inter(
              10.5,
              FontWeight.w700,
              CScholarMaterial.shadowLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Program-code tag. Was `#F1F5F9` — a cool slate that belonged to no hue
  /// family in this palette; now a recessed clay well with a rim.
  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
        border: Border.all(color: CScholarMaterial.rim),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CScholarTextStyles.inter(
          10.5,
          FontWeight.w700,
          CScholarColors.textSecondary,
        ),
      ),
    );
  }

  Color get _headerColor =>
      ThesisCard.bannerPalette[widget.thesis.id % ThesisCard.bannerPalette.length];
}
