// Reusable ThesisCard widget

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/models/thesis.dart';

class ThesisCard extends StatelessWidget {
  final Thesis thesis;
  final double? similarityScore; // 0.0–1.0 for recommendation cards
  final VoidCallback? onTap;

  const ThesisCard({
    super.key,
    required this.thesis,
    this.similarityScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/thesis/${thesis.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CScholarColors.dividerLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder / header
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: _headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    bottom: 8,
                    child: Icon(
                      Icons.article_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            thesis.researchType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (similarityScore != null)
                          _semanticBadge(similarityScore!),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thesis.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CScholarColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (thesis.authors != null && thesis.authors!.isNotEmpty)
                      Text(
                        thesis.authors!.map((a) => '${a.firstName} ${a.lastName}').join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CScholarColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        _tag(thesis.program?.name ?? ''),
                        const Spacer(),
                        Text(
                          thesis.academicYear?.label ?? ''.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: CScholarColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prominent semantic match badge shown on AI recommendation cards.
  Widget _semanticBadge(double score) {
    final pct = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 11, color: CScholarColors.primaryGreen),
          const SizedBox(width: 4),
          Text(
            '$pct% match',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CScholarColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CScholarColors.primaryGreenVeryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: CScholarColors.primaryGreen,
        ),
      ),
    );
  }

  Color get _headerColor {
    final colors = [
      CScholarColors.primaryGreen,
      CScholarColors.primaryGreenLight,
      CScholarColors.orange,
      CScholarColors.info,
      CScholarColors.facultyColor,
    ];
    return colors[thesis.id % colors.length];
  }
}
