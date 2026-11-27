import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Plain-language explanation of the embedding AI behind search and
/// recommendations. Opened from the recommendation surfaces so the claim is
/// inspectable without opening the source code.
Future<void> showAiExplainer(BuildContext context) {
  return showClayDialog<void>(
    context: context,
    builder: (ctx) => GlassDialog(
      title: const Text('How the AI works'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CScholar uses sentence embeddings, not a chatbot.',
              style: CScholarTextStyles.body(
                13,
                FontWeight.w700,
                CScholarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _step(
              '1',
              'Each study becomes a vector',
              'The title, abstract, and PDF text are converted by '
                  'all-MiniLM-L6-v2 into 384 numbers that represent meaning.',
            ),
            _step(
              '2',
              'Your query becomes a vector too',
              'Semantic search embeds the query the same way and ranks '
                  'published studies by cosine similarity.',
            ),
            _step(
              '3',
              'Recommendations add an anchor',
              'The last study you viewed or saved becomes the anchor. The '
                  'server returns the published studies closest to it.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CScholarMaterial.clayDeep,
                borderRadius: BorderRadius.circular(CScholarRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What it is not',
                    style: CScholarTextStyles.body(
                      12,
                      FontWeight.w700,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No generated answers, no invented citations, and no '
                    'learned profile of you. The percentage is similarity to '
                    'the anchor, not a probability. Recommendations are '
                    'content-based and seeded by your last action.',
                    style: CScholarTextStyles.body(
                      11.5,
                      FontWeight.w400,
                      CScholarColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        NeumorphButton(
          onPressed: () => Navigator.pop(ctx),
          label: 'Got it',
          gel: false,
        ),
      ],
    ),
  );
}

Widget _step(String number, String title, String body) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CScholarColors.primaryGreenVeryLight,
            borderRadius: BorderRadius.circular(CScholarRadius.full),
          ),
          child: Text(
            number,
            style: CScholarTextStyles.body(
              11,
              FontWeight.w800,
              CScholarColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CScholarTextStyles.body(
                  12.5,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: CScholarTextStyles.body(
                  11.5,
                  FontWeight.w400,
                  CScholarColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
