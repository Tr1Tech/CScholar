import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/animate_x.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

/// V2 search result card (new design): generative cover, title, authors,
/// program/year, keyword chips, and the card's state/actions on the right —
///
///   type badge   (top-right)
///   match        (directly under the type badge, only on semantic results)
///   save         (bottom-right corner)
///
/// The match lives in the right rail under the type badge instead of sharing
/// the author line: a two-line badge on that line pushed the authors, program
/// and keyword rows down and left visible gaps between them. In the rail it is
/// beside that text, so a semantic card keeps the exact same vertical rhythm
/// as a keyword card.
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
              // A card is content-sized; without this the column fills any
              // bounded height it is handed and the save stops hugging the
              // bottom edge of the card.
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
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
                          const SizedBox(height: 4),
                          if (thesis.authorsString.isNotEmpty)
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
                                        // A recessed well, not
                                        // `backgroundSoft`: the canvas
                                        // (#E8EFE7) is DARKER than the clay
                                        // card (#F1F6F0), so those chips read
                                        // as holes punched in the panel rather
                                        // than tokens on it.
                                        color: CScholarMaterial.clayDeep,
                                        borderRadius: BorderRadius.circular(
                                          CScholarRadius.full,
                                        ),
                                        border: Border.all(
                                          color: CScholarMaterial.rim,
                                        ),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right rail: type badge on top, the semantic score
                    // directly underneath it. Keeping it here means the two
                    // badges never change the height of the title, author or
                    // program lines on the left.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _typeChip(),
                        if (similarity != null) ...[
                          const SizedBox(height: 8),
                          _matchBadge(context, similarity!),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // OverflowBar, not Row+Spacer: the two actions are pinned to
                // opposite ends while there is room, and stack (still
                // right-aligned) at 200% text instead of overflowing.
                OverflowBar(
                  spacing: 8,
                  overflowSpacing: 8,
                  alignment: MainAxisAlignment.spaceBetween,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: [_relatedPill(context), _saveButton()],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The left-hand action: leave the list for the study's related work.
  Widget _relatedPill(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/thesis/${thesis.id}', extra: similarity),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CScholarColors.primaryGreenLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CScholarMaterial.rimPublished),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible: at 200% text "Related Research" is wider than the
            // card's action column. Ellipsising the wording keeps the pill
            // inside the card; the arrow still names the direction.
            Flexible(
              child: Text(
                'Related Research',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w600,
                  CScholarColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: CScholarColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  /// Save action as a named pill, pinned to the card's bottom-right corner.
  ///
  /// The old icon-only circle was a 36px mystery target; this states its
  /// purpose and shows the saved state.
  Widget _saveButton() {
    final bg = isSaved
        ? CScholarColors.primaryGreenLight
        : CScholarMaterial.clayDeep;
    final fg = isSaved
        ? CScholarColors.primaryGreen
        : CScholarColors.textPrimary;
    final rim = isSaved ? CScholarMaterial.rimPublished : CScholarMaterial.rim;
    return Semantics(
      button: true,
      toggled: isSaved,
      label: isSaved ? 'Saved — tap to remove' : 'Save study',
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggleSave,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // 12+12 padding around a 12px label = the 44px interaction floor
          // (A11Y-1), without forcing the pill to fill the row.
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rim),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_outline,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 5),
              Text(
                isSaved ? 'Saved' : 'Save',
                style: CScholarTextStyles.body(12, FontWeight.w700, fg),
              ),
            ],
          ),
        ),
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
    final rim = CScholarMaterial.rimPublished;
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

  /// Match score, stacked as the sparkle/number line and `MATCH` underneath.
  ///
  /// It sits in the card's right rail, directly under the type badge. Keeping
  /// it out of the author line is what preserves the keyword card's vertical
  /// rhythm: the badge no longer stretches the authors or program rows.
  Widget _matchBadge(BuildContext context, double score) {
    final pct = (score * 100).round().clamp(0, 100);
    final badge = Tooltip(
      message:
          'Match $pct% — ranked by meaning. Open the study to see related work.',
      child: Semantics(
        label: 'Match $pct% — ranked by meaning',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CScholarColors.primaryGreenLight,
            borderRadius: BorderRadius.circular(CScholarRadius.full),
            border: Border.all(
              color: CScholarColors.primaryGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: CScholarColors.primaryGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$pct%',
                    style: CScholarTextStyles.body(
                      12.5,
                      FontWeight.w800,
                      CScholarColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                'MATCH',
                style: CScholarTextStyles.body(
                  9,
                  FontWeight.w700,
                  CScholarColors.textMuted,
                ).copyWith(letterSpacing: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
    return badge.scalePop(context);
  }
}
