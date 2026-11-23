import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/animate_x.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// V2 search result card (new design): generative cover, title, authors,
/// program/year, keyword chips, real match badge (semantic only), save +
/// related actions.
class ResultCard extends StatelessWidget {
  final Thesis thesis;
  final bool isSaved;
  final double? similarity;
  final VoidCallback onToggleSave;

  const ResultCard({
    super.key,
    required this.thesis,
    required this.isSaved,
    required this.onToggleSave,
    this.similarity,
  });

  bool get _isThesis => thesis.researchType.toLowerCase() == 'thesis';

  @override
  Widget build(BuildContext context) {
    final keywords = (thesis.keywords ?? []).take(3).toList();
    return CScholarCard(
      padding: const EdgeInsets.all(16),
      lift: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThesisCover(seed: thesis.id),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go(
                          '/thesis/${thesis.id}',
                          // Semantic entries hand their score through: the
                          // detail screen meters it, keyword entries meter
                          // nothing. Extra never survives a pasted URL — the
                          // meter then stays off instead of guessing.
                          extra: similarity,
                        ),
                        child: Text(
                          thesis.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CScholarTextStyles.heading(
                            15,
                            FontWeight.w700,
                            CScholarColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _typeChip(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  thesis.authorsString,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    12,
                    FontWeight.w500,
                    CScholarColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${thesis.program?.name ?? '—'}  •  ${thesis.academicYear?.label ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    11.5,
                    FontWeight.w400,
                    CScholarColors.textMuted,
                  ),
                ),
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: keywords
                        .map(
                          (k) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              // A recessed well, not `backgroundSoft`: the
                              // canvas (#E8EFE7) is DARKER than the clay card
                              // (#F1F6F0), so those chips read as holes
                              // punched in the panel rather than tokens on it.
                              color: CScholarMaterial.clayDeep,
                              borderRadius: BorderRadius.circular(
                                CScholarRadius.full,
                              ),
                              border: Border.all(color: CScholarMaterial.rim),
                            ),
                            child: Text(
                              k.term,
                              style: CScholarTextStyles.body(
                                11,
                                FontWeight.w500,
                                CScholarColors.textMuted,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () =>
                          context.go('/thesis/${thesis.id}', extra: similarity),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CScholarColors.primaryGreenLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CScholarMaterial.rimPublished,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Related Research',
                              style: CScholarTextStyles.body(
                                12,
                                FontWeight.w600,
                                CScholarColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: CScholarColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Outline <-> filled morphs through the button's MorphIcon
                    // instead of hard-swapping: the eye reads it as a
                    // response, not a repaint.
                    NeumorphIconButton(
                      tooltip: isSaved ? 'Remove from Saved' : 'Save Study',
                      size: 36,
                      icon: Icons.bookmark_outline,
                      selectedIcon: Icons.bookmark,
                      selected: isSaved,
                      onPressed: onToggleSave,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (similarity != null) ...[
            const SizedBox(width: 12),
            _matchBadge(context, similarity!),
          ],
        ],
      ),
    );
  }

  /// Research-type token. Solid verified pair + rim, matching the tactile
  /// chips in `common/status_chips.dart` (a chip without a rim only reads as a
  /// coloured rectangle on a tinted canvas).
  Widget _typeChip() {
    final bg = _isThesis
        ? CScholarColors.thesisChipBg
        : CScholarColors.capstoneChipBg;
    final fg = _isThesis
        ? CScholarColors.thesisChipFg
        : CScholarColors.capstoneChipFg;
    final rim = _isThesis
        ? CScholarMaterial.rimPublished
        : CScholarMaterial.rimDraft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
        border: Border.all(color: rim),
      ),
      child: Text(
        _isThesis ? 'Thesis' : 'Capstone',
        style: CScholarTextStyles.body(11, FontWeight.w700, fg),
      ),
    );
  }

  /// Real match badge — gold AI identity with explainability tooltip.
  /// Circular data gauge, now gold paper + amber ink so AI rank is distinct
  /// from green status chips. Fixed 52px slot (same as before) so the
  /// repository row never reflows — the label scales down inside it.
  /// Pops in on a springy settle so the rank lands instead of painting.
  Widget _matchBadge(BuildContext context, double score) {
    final pct = (score * 100).round().clamp(0, 100);
    final badge = Tooltip(
      message:
          'Semantic match $pct% — ranked by meaning. Open the study to see related work.',
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // tile-exempt: this is a circular DATA gauge carrying a percentage, not
            // an icon tile — ClayIconTile would turn a number into a square chip.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CScholarColors.goldSoft,
                border: Border.all(color: CScholarColors.warningFg, width: 2.5),
                boxShadow: CScholarShadows.goldGlow,
              ),
              child: Center(
                child: Text(
                  '$pct%',
                  style: CScholarTextStyles.body(
                    13,
                    FontWeight.w800,
                    CScholarColors.warningFg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: CScholarColors.warningFg,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Semantic match',
                    style: CScholarTextStyles.body(
                      10,
                      FontWeight.w700,
                      CScholarColors.warningFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return badge.scalePop(context);
  }
}
