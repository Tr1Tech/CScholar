import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';

/// Minimum height the KPI card column needs: 20px padding, the 36px label row,
/// the 24px value line and the 11.5px trend line.
const double kpiCardIntrinsicHeight = 152;

/// The compact metric variant (icon tile beside label + value) needs less room:
/// 18px padding plus a 46px content row.
const double metricCardIntrinsicHeight = 104;

/// Grid geometry for a KPI strip — ONE source of truth for the admin, faculty
/// and student dashboards.
///
/// The card's height does not depend on the cell width, so an aspect ratio
/// crushes it: a 4-up `childAspectRatio: 2.0` strip at a 1000px window handed
/// the cards 113px cells for 138px of content and overflowed. A fixed
/// [SliverGridDelegateWithFixedCrossAxisCount.mainAxisExtent] is width-proof,
/// and scaling it by the text scale keeps the strip usable at 200% text.
SliverGridDelegate kpiGridDelegate(
  BuildContext context,
  int crossAxisCount, {
  double extent = kpiCardIntrinsicHeight,
  double spacing = 16,
}) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
    mainAxisExtent: extent * (textScale < 1 ? 1 : textScale),
  );
}

/// Standard KPI card: uppercase label, big value, muted trend + tactile icon tile.
///
/// Wrapped in [CScholarCard] (which delegates to [ClaySurface]) and using
/// [ClayIconTile] for physical depth, so a KPI reads as a moulded object rather
/// than a flat div. The tile stays in the clay variant (not gel) because four
/// solid-green tiles would erase the per-metric colour coding.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;

  /// Tint behind the icon tile. Defaults to the canvas so the tile still shares
  /// a hue with the clay panel.
  final Color? iconBg;

  /// Glyph colour. Must clear 3:1 against [iconBg] — pass a `...Color` token
  /// (for example [CScholarColors.info], not the raw brand blue).
  final Color? iconColor;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    this.iconBg,
    this.iconColor,
  });

  /// The value as a number when the string is a plain integer, so the count-up
  /// can run. Anything else — `12,480`, `—`, `92%` — stays literal text:
  /// [CountUpText] formats with its own digits and would drop the separator.
  int? get _countable => int.tryParse(value.trim());

  @override
  Widget build(BuildContext context) {
    return CScholarCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: CScholarTextStyles.inter(
                      11, FontWeight.w700, CScholarColors.textMuted,
                      letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 36 is the tile size the KPI strip was designed around; keeping it
              // means [kpiCardIntrinsicHeight] stays a valid budget.
              ClayIconTile(
                icon: icon,
                size: 36,
                gel: false,
                background: iconBg ?? CScholarMaterial.canvas,
                tint: iconColor ?? CScholarColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // The value counts up on first paint and tweens when it changes;
          // reduced motion snaps it straight to the number.
          if (_countable != null)
            CountUpText(
              value: _countable!,
              style: CScholarTextStyles.poppins(
                  24, FontWeight.w800, CScholarColors.textPrimary),
            )
          else
            Text(value,
                style: CScholarTextStyles.poppins(
                    24, FontWeight.w800, CScholarColors.textPrimary)),
          const SizedBox(height: 4),
          Text(trend,
              style: CScholarTextStyles.inter(11.5, FontWeight.w500, CScholarColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
