import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';

class ThesisCard extends StatelessWidget {
  final Thesis thesis;
  final double? similarityScore;
  final VoidCallback? onTap;

  const ThesisCard({
    super.key,
    required this.thesis,
    this.similarityScore,
    this.onTap,
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/thesis/${thesis.id}'),
      child: CScholarCard(
        padding: EdgeInsets.zero,
        lift: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CScholarRadius.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _banner(),
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
    );
  }
  Widget _banner() {
    return Container(
      height: 76,
      color: _headerColor,
      child: Stack(
        children: [
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
                    thesis.researchType.toUpperCase(),
                    style: CScholarTextStyles.inter(
                      10,
                      FontWeight.w700,
                      CScholarMaterial.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (similarityScore != null) _semanticBadge(similarityScore!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    Text(
                      thesis.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.poppins(
                        14.5,
                        FontWeight.w700,
                        CScholarColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (thesis.authors != null && thesis.authors!.isNotEmpty)
                      Text(
                        thesis.authors!.map((a) => '${a.firstName} ${a.lastName}').join(', '),
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
                        if ((thesis.program?.code ?? '').isNotEmpty)
                          Flexible(
                            child: _tag(thesis.program!.code),
                          ),
                        if ((thesis.program?.code ?? '').isNotEmpty &&
                            (thesis.academicYear?.label ?? '').isNotEmpty)
                          const SizedBox(width: 8),
                        if ((thesis.academicYear?.label ?? '').isNotEmpty)
                          Text(
                            thesis.academicYear!.label,
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

  Color get _headerColor => bannerPalette[thesis.id % bannerPalette.length];
}
