import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/models/thesis.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/thesis/${thesis.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CScholarRadius.xl),
          border: Border.all(color: CScholarColors.borderLight),
          boxShadow: CScholarShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image banner / header
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: _headerColor,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    bottom: 4,
                    child: Icon(
                      Icons.article_outlined,
                      color: Colors.white.withValues(alpha: 0.25),
                      size: 48,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(CScholarRadius.sm),
                          ),
                          child: Text(
                            thesis.researchType.toUpperCase(),
                            style: CScholarTextStyles.inter(
                              10,
                              FontWeight.w700,
                              Colors.white,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _semanticBadge(double score) {
    final pct = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
              Colors.white,
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
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

  Color get _headerColor {
    const colors = [
      CScholarColors.primaryGreen,
      Color(0xFF0D9488),
      CScholarColors.orange,
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ];
    return colors[thesis.id % colors.length];
  }
}
