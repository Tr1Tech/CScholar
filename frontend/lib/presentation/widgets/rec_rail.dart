import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';

/// "AI Recommendations" rail for the repository page (new design).
/// Honest by construction: recommendations are the live semantic matches
/// for the current query — never fabricated, never interest-tracked.
class RecRail extends ConsumerWidget {
  final String query;
  const RecRail({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Recommendations',
              style: CScholarTextStyles.poppins(
                  16, FontWeight.w700, CScholarColors.textPrimary)),
          const SizedBox(height: 2),
          Text('Related to your current search',
              style: CScholarTextStyles.inter(
                  12, FontWeight.w400, CScholarColors.textMuted)),
          const SizedBox(height: 14),
          if (query.trim().isEmpty)
            _placeholder()
          else
            _results(context, ref),
          const SizedBox(height: 14),
          _aiNote(),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        // Recessed well: `backgroundSoft` is the canvas, which is darker than
        // the clay card, so it read as a hole rather than an empty state.
        color: CScholarMaterial.clayDeep,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        border: Border.all(color: CScholarMaterial.rim),
      ),
      child: Center(
        child: Text(
          'Type a query to see AI picks',
          textAlign: TextAlign.center,
          style: CScholarTextStyles.inter(
              12, FontWeight.w500, CScholarColors.textMuted),
        ),
      ),
    );
  }

  Widget _results(BuildContext context, WidgetRef ref) {
    final async = ref.watch(semanticSearchProvider(query.trim()));
    return asyncSlot(
      async,
      // The rail is a card body, not a page: the loader stays exactly as it
      // was, it is simply cross-faded instead of swapped.
      skeleton: const ClayLoader(height: 8),
      data: (results) {
        final top = results.take(4).toList();
        if (top.isEmpty) {
          return Text('No AI matches for this query yet',
              style: CScholarTextStyles.inter(
                  12, FontWeight.w500, CScholarColors.textMuted));
        }
        return Column(
          // Rail rows step dense on tight inside the rail gliding in from
          // the right — one gesture per row, never competing with the page.
          children: [
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              Stagger(
                index: i,
                step: MotionPitch.tight.step,
                max: MotionPitch.tight.max,
                rise: MotionPitch.tight.rise,
                child: _recRow(context, top[i].thesis, top[i].similarity),
              ),
            ],
          ],
        );
      },
      error: (_, _) => Text('Recommendations unavailable right now',
          style: CScholarTextStyles.inter(
              12, FontWeight.w500, CScholarColors.textMuted)),
    );
  }

  Widget _recRow(BuildContext context, Thesis t, double similarity) {
    final isThesis = t.researchType.toLowerCase() == 'thesis';
    final pct = (similarity * 100).round().clamp(0, 100);
    // A rail row is a custom surface, not a button — so it presses like every
    // other non-button surface in the system: clay's press is a sink, and the
    // ripple is deliberately gone.
    return PressableSurface(
      radius: CScholarRadius.md,
      onTap: () => context.go('/thesis/${t.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThesisCover(
                seed: t.id, width: 52, height: 64, borderRadius: 8, iconSize: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.inter(
                          12.5, FontWeight.w600, CScholarColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isThesis
                              ? CScholarColors.thesisChipBg
                              : CScholarColors.capstoneChipBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(isThesis ? 'Thesis' : 'Capstone',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isThesis
                                    ? CScholarColors.thesisChipFg
                                    : CScholarColors.capstoneChipFg)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            '${t.program?.name ?? ''} • ${t.academicYear?.label ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.inter(11,
                                FontWeight.w400, CScholarColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$pct% match',
                      style: CScholarTextStyles.inter(11, FontWeight.w700,
                          CScholarColors.primaryGreen)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: CScholarColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _aiNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CScholarColors.goldSoft,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        // Solid rim, not a 40% alpha gold: an alpha rim on a light tint is a
        // ~1.2:1 edge and reads as a rendering artefact.
        border: Border.all(color: CScholarMaterial.rimDraft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome,
              size: 18, color: CScholarColors.goldDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ranked by meaning, not keywords',
                    style: CScholarTextStyles.inter(
                        12, FontWeight.w700, CScholarColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                    'Semantic search compares the meaning of your query against every study.',
                    style: CScholarTextStyles.inter(
                        11.5, FontWeight.w400, CScholarColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
