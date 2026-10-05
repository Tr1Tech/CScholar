import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
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
                          style: CScholarTextStyles.poppins(
                              15, FontWeight.w700, CScholarColors.textPrimary),
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
                  style: CScholarTextStyles.inter(
                      12, FontWeight.w500, CScholarColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${thesis.program?.name ?? '—'}  •  ${thesis.academicYear?.label ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.inter(
                      11.5, FontWeight.w400, CScholarColors.textMuted),
                ),
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: keywords
                        .map((k) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                // A recessed well, not `backgroundSoft`: the
                                // canvas (#E8EFE7) is DARKER than the clay card
                                // (#F1F6F0), so those chips read as holes
                                // punched in the panel rather than tokens on it.
                                color: CScholarMaterial.clayDeep,
                                borderRadius:
                                    BorderRadius.circular(CScholarRadius.full),
                                border:
                                    Border.all(color: CScholarMaterial.rim),
                              ),
                              child: Text(k.term,
                                  style: CScholarTextStyles.inter(11,
                                      FontWeight.w500, CScholarColors.textMuted)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(
                        '/thesis/${thesis.id}',
                        extra: similarity,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CScholarColors.primaryGreenLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CScholarMaterial.rimPublished),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Related Research',
                                style: CScholarTextStyles.inter(12,
                                    FontWeight.w600, CScholarColors.primaryGreen)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward,
                                size: 14, color: CScholarColors.primaryGreen),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    NeumorphIconButton(
                      tooltip: isSaved ? 'Remove from Saved' : 'Save Study',
                      size: 36,
                      icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      onPressed: onToggleSave,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (similarity != null) ...[
            const SizedBox(width: 12),
            _matchBadge(similarity!),
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
    final rim =
        _isThesis ? CScholarMaterial.rimPublished : CScholarMaterial.rimDraft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
        border: Border.all(color: rim),
      ),
      child: Text(_isThesis ? 'Thesis' : 'Capstone',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  /// Real match badge — only rendered when a semantic similarity exists.
  /// The ring is a SOLID token colour: at 35% alpha a 3px ring is a 1.4:1
  /// affordance and disappears in bright light.
  Widget _matchBadge(double score) {
    final pct = (score * 100).round().clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // tile-exempt: this is a circular DATA gauge carrying a percentage, not
        // an icon tile — ClayIconTile would turn a number into a square chip.
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CScholarColors.primaryGreenLight,
            border: Border.all(
                color: CScholarColors.primaryGreen, width: 2.5),
          ),
          child: Center(
            child: Text('$pct%',
                style: CScholarTextStyles.inter(
                    13, FontWeight.w800, CScholarColors.primaryGreen)),
          ),
        ),
        const SizedBox(height: 2),
        Text('Match',
            style: CScholarTextStyles.inter(
                10, FontWeight.w500, CScholarColors.textMuted)),
      ],
    );
  }
}
