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
      child: Row(
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
            action!,
          ],
        ],
      ),
    );
  }
}
