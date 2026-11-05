import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Identity objects — the claymorphism half of the system: the "made" objects
/// (avatars, icon tiles, badges) that make the app feel physical without
/// turning data-dense screens into a toy.
///
/// Rule of thirds applied to material: keep clay/gel objects under ~25% of a
/// viewport, and never use them for long-form reading or table cells.

/// Gel tag. Selected = gel fill; unselected = raised clay **with a rim**, so
/// the unselected state never relies on shadow alone.
///
/// Press sinks to 0.96 and springs back on [CScholarCurves.overshoot]; a
/// selectable chip that is selected pops a check glyph in through
/// [AnimatedSwap]. The check slot is always reserved (even unselected), so
/// toggling never animates width — a width tween would reflow the whole
/// [Wrap] the chips sit in. Display chips (`onTap: null`) are untouched: no
/// press state, no check.
class ClayChip extends StatefulWidget {
  const ClayChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  State<ClayChip> createState() => _ClayChipState();
}

class _ClayChipState extends State<ClayChip> {
  bool _down = false;

  void _setDown(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CScholarRadius.full);
    final animate = motionEnabled(context);
    final selectable = widget.onTap != null;
    final chip = AnimatedScale(
      // Sink only, never layout: a scale keeps the Wrap's line breaks fixed
      // while the press still reads. Reduced motion holds 1.0 exactly.
      scale: animate && _down ? 0.96 : 1.0,
      duration: animate ? CScholarMotion.swap : Duration.zero,
      curve: CScholarCurves.overshoot,
      child: AnimatedContainer(
        duration: animate ? CScholarDurations.fast : Duration.zero,
        curve: CScholarCurves.standard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: widget.selected
            ? BoxDecoration(
                borderRadius: radius,
                color: CScholarMaterial.gelTop.withValues(alpha: 0.12),
                border: Border.all(
                  color: CScholarMaterial.gelTop.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: CScholarMaterial.softShadow(depth: 0.35),
              )
            : BoxDecoration(
                borderRadius: radius,
                color: CScholarMaterial.clay,
                border: Border.all(color: CScholarMaterial.rim),
                boxShadow: CScholarMaterial.softShadow(depth: 0.4),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectable) ...[
              // Reserved slot: the box is always 14px, so the pop never moves
              // the label. Reduced motion swaps instantly with no scale.
              SizedBox(
                width: 14,
                child: AnimatedSwap(
                  style: SwapStyle.pop,
                  child: widget.selected
                      ? Icon(Icons.check_rounded,
                          key: const ValueKey('check'),
                          size: 14,
                          color: CScholarMaterial.gelTop)
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  size: 14,
                  color: widget.selected
                      ? CScholarMaterial.gelTop
                      : CScholarMaterial.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: CScholarTextStyles.body(
                12,
                FontWeight.w600,
                widget.selected
                    ? CScholarMaterial.gelTop
                    : CScholarMaterial.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    if (!selectable) return chip;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: widget.onTap,
        child: chip,
      ),
    );
  }
}

/// Moulded tile that holds an icon — KPI cards, list leads, nav affordances.
/// The gradient fill and its soft shadow give it the clay read; the glyph sits
/// straight on the tile (the old inner white shine belonged to the neumorphic
/// layer and is gone).
///
/// [gold] turns it into the prestige mark: gold gradient, DARK glyph (white on
/// gold is 1.38:1) and the system's only coloured shadow. Use it on two or
/// three elements per screen at most.
class ClayIconTile extends StatelessWidget {
  const ClayIconTile({
    super.key,
    required this.icon,
    this.size = 40,
    this.gel = true,
    this.gold = false,
    this.tint = CScholarMaterial.textGreen,
    this.background = CScholarMaterial.clay,
    this.glowStrength = 1,
  });

  final IconData icon;
  final double size;
  final bool gel;
  final bool gold;
  final Color tint;
  final Color background;

  /// Multiplier on [CScholarMaterial.goldGlow] — 0.6 is a hint, 1.5 is a lamp.
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    final radius = BorderRadius.circular(14);
    final glyph = gold
        ? CScholarMaterial.textPrimary // 12.98:1 on gold top, 6.08:1 on bottom
        : (gel ? Colors.white : tint);
    final rimmed = flat || !(gel || gold);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gold
            ? CScholarMaterial.goldGradient
            : gel
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CScholarMaterial.gelTop,
                      CScholarMaterial.gelBottom,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CScholarMaterial.clayHigh, background],
                  ),
        border: rimmed
            ? Border.all(
                color: flat ? CScholarMaterial.rimStrong : CScholarMaterial.rim,
              )
            : null,
        boxShadow: flat
            ? null
            : gold
                ? CScholarMaterial.goldGlow(strength: glowStrength)
                : gel
                    ? CScholarMaterial.gelDrop(depth: 0.7)
                    : CScholarMaterial.softShadow(depth: 0.5),
      ),
      child: Center(
        child: Icon(icon, size: size * 0.46, color: glyph),
      ),
    );
  }
}

/// Gel avatar. Initials are WHITE, never gold — gold on green measures 2.75:1.
class GelAvatar extends StatelessWidget {
  const GelAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CScholarMaterial.gelTop, CScholarMaterial.gelBottom],
        ),
        boxShadow: CScholarMaterial.gelDrop(depth: 0.7),
      ),
      child: Center(
        child: Text(
          _initials,
          style: CScholarTextStyles.body(
              size * 0.34, FontWeight.w800, Colors.white),
        ),
      ),
    );
  }
}

