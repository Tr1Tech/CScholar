import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/csu_mark.dart';

/// CScholar Brand Logo: unified CSU mark + wordmark.
/// The emblem is always the green rounded square with white mortarboard.
class CScholarLogo extends StatelessWidget {
  final double iconSize;
  final bool showText;
  final bool isDark;
  final String? subtitle;

  const CScholarLogo({
    super.key,
    this.iconSize = 36,
    this.showText = true,
    this.isDark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CSUMark(size: iconSize),
        if (showText) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CScholar',
                style: CScholarTextStyles.poppins(
                  iconSize * 0.52,
                  FontWeight.w800,
                  isDark ? Colors.white : CScholarColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              Text(
                (subtitle ?? 'CEIT REPOSITORY').toUpperCase(),
                style: CScholarTextStyles.inter(
                  iconSize * 0.26,
                  FontWeight.w700,
                  isDark
                      ? CScholarColors.gold.withValues(alpha: 0.9)
                      : CScholarColors.textMuted,
                  letterSpacing: 1.1,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    // The wordmark is text, so 200% text makes it wider than a narrow host (a
    // topbar leading slot, a sidebar card). Scale the whole mark down instead
    // of overflowing: a brand must not ellipsize, and a logo is not body copy,
    // so this is the one place where scaling beats growing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: mark,
    );
  }
}
