import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/animate_x.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

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
                if (similarity != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _matchBadge(context, similarity!),
                  ),
                ],
                const SizedBox(height: 10),
                // Wrap, not Row+Spacer: at 200% text the two action pills
                // exceed a narrow result column. They stack instead of
                // overflowing.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: CScholarColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // A labelled pill, not a bare 36px circle: the icon-only
                    // button read as a floating affordance with no name. Same
                    // geometry as "Related Research" so the row scans as one
                    // set of actions; mint = saved, clay = unsaved.
                    _saveButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Save action as a named pill. The old icon-only circle was a 36px
  /// mystery target; this states its purpose and shows the saved state.
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  /// Semantic match as a readable inline pill.
  ///
  /// It used to be a 52px column with a 10px label that `FittedBox` shrank to
  /// ~6px. A horizontal pill carries the same mint/green identity, stays at a
  /// legible 11.5px, and lives in the content flow so it never squeezes the
  /// title column.
  Widget _matchBadge(BuildContext context, double score) {
    final pct = (score * 100).round().clamp(0, 100);
    final badge = Tooltip(
      message:
          'Semantic match $pct% — ranked by meaning. Open the study to see related work.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CScholarColors.primaryGreenLight,
          borderRadius: BorderRadius.circular(CScholarRadius.full),
          border: Border.all(
            color: CScholarColors.primaryGreen.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
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
            const SizedBox(width: 5),
            Text(
              'Semantic match',
              style: CScholarTextStyles.body(
                11.5,
                FontWeight.w600,
                CScholarColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
    return badge.scalePop(context);
  }
}
