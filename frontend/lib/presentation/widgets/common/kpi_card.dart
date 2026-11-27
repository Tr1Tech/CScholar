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
///
/// The value is tabular ([FontFeature.tabularFigures]) so a counting number
/// never reflows its row, and a value that CHANGES (not first paint) flashes a
/// one-shot highlight behind itself over [CScholarMotion.swap] — number and
/// attention land together. The flash is skipped entirely under reduced motion.
class KpiCard extends StatefulWidget {
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

  /// Optional destination. A tappable KPI reads as a control: hover lift,
  /// pointer cursor, and a button semantic node.
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    this.iconBg,
    this.iconColor,
    this.onTap,
  });

  /// The value as a number when the string is a plain integer, so the count-up
  /// can run. Anything else — `12,480`, `—`, `92%` — stays literal text:
  /// [CountUpText] formats with its own digits and would drop the separator.
  int? get _countable => int.tryParse(value.trim());

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard>
    with SingleTickerProviderStateMixin {
  /// One-shot change flash, and it STOPS. A repeating highlight here would
  /// make `pumpAndSettle()` hang and read as a live indicator — a KPI is not
  /// live, it just occasionally changes.
  late final AnimationController _flash =
      AnimationController(vsync: this, duration: CScholarMotion.swap);

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant KpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Changes only, never first paint: a number that flashes on arrival looks
    // like a bug, while one that flashes on CHANGE reads as "this just moved".
    // Reduced motion gets no flash at all — the new number alone is the update.
    if (oldWidget.value != widget.value && motionEnabled(context)) {
      _flash.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tabular figures: the count-up must not widen the row as it runs, and a
    // changed value must not reflow its neighbours either.
    final valueStyle = CScholarTextStyles.heading(
            26, FontWeight.w800, CScholarColors.textPrimary)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final value = widget._countable != null
        ? CountUpText(value: widget._countable!, style: valueStyle)
        : Text(widget.value, style: valueStyle);
    // The flash hugs the number (tight Stack, not the full row): a full-width
    // band would read as a selection, and at 200% text it could clip. Only the
    // fill alpha animates, over the exit curve — transform/opacity only, and
    // the controller is parked at 0 whenever nothing changed, so a settled
    // tree holds no ticker.
    final animate = motionEnabled(context);
    final valued = !animate
        ? value
        : Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _flash,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreenLight.withValues(
                          alpha: (1 - _flash.value) * 0.35),
                      borderRadius:
                          BorderRadius.circular(CScholarRadius.sm),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              value,
            ],
          );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: CScholarTextStyles.body(
                    11, FontWeight.w700, CScholarColors.textMuted,
                    letterSpacing: 0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 36 is the tile size the KPI strip was designed around; keeping it
            // means [kpiCardIntrinsicHeight] stays a valid budget.
            ClayIconTile(
              icon: widget.icon,
              size: 36,
              gel: false,
              background: widget.iconBg ?? CScholarMaterial.canvas,
              tint: widget.iconColor ?? CScholarColors.primaryGreen,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // The value counts up on first paint and tweens when it changes;
        // reduced motion snaps it straight to the number.
        valued,
        const SizedBox(height: 4),
        Text(widget.trend,
            style: CScholarTextStyles.body(
                11.5, FontWeight.w500, CScholarColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
    final card = CScholarCard(
      padding: widget.onTap == null
          ? const EdgeInsets.all(20)
          : EdgeInsets.zero,
      lift: widget.onTap != null,
      child: widget.onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(CScholarRadius.softCard),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
            ),
    );
    return Semantics(
      button: widget.onTap != null,
      label: widget.onTap == null
          ? null
          : '${widget.label}: ${widget.value}. ${widget.trend}',
      child: card,
    );
  }
}
