import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Canonical page heading: 24/800 title + 13 muted subtitle + optional action
/// (design plan, item 1 — one scale everywhere). It reveals first in the page
/// entrance stagger, so every screen opens the same way.
///
/// [actions] is for a small cluster of related controls (for example a primary
/// "Add" beside a secondary "Bulk Import"). On a narrow window the cluster
/// moves below the title instead of squeezing it into a one-word column.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return EntranceReveal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CScholarTextStyles.pageTitle),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: CScholarTextStyles.pageSubtitle),
              ],
            ],
          );

          if (actions.isNotEmpty) {
            // Two clay buttons plus the title need roughly 620px before the
            // title starts wrapping. Below that, give the buttons their own
            // row rather than a 2/3-wide slot in a crowded one.
            if (!constraints.maxWidth.isFinite || constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: actions,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ],
            );
          }

          if (action == null) return heading;

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
              Expanded(child: heading),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxActionWidth),
                child: action!,
              ),
            ],
          );
        },
      ),
    );
  }
}
