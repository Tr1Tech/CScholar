import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Canonical page heading: 24/800 title + 13 muted subtitle + optional action
/// (design plan, item 1 — one scale everywhere). It reveals first in the page
/// entrance stagger, so every screen opens the same way.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const PageHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return EntranceReveal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The action is a plain, non-flex child: `Flexible` alongside an
          // `Expanded` both default to flex 1, so the row handed the trailing
          // slot half the header and the button sat dead centre of the page.
          // Non-flex pins it to the trailing edge, but then its intrinsic width
          // is uncapped — and a labelled clay button at 200% text can be wider
          // than the row. Cap it at two thirds so the title keeps a readable
          // column and the button ellipsizes its own label instead of
          // overflowing the header.
          final maxActionWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth * 2 / 3
              : double.infinity;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CScholarTextStyles.pageTitle),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: CScholarTextStyles.pageSubtitle),
                    ],
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxActionWidth),
                  child: action!,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
