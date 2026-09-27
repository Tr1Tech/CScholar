import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/inset_shadow.dart';

/// Identity objects — the claymorphism half of the system: the "made" objects
/// (avatars, icon tiles, badges) that make the app feel physical without
/// turning data-dense screens into a toy.
///
/// Rule of thirds applied to material: keep clay/gel objects under ~25% of a
/// viewport, and never use them for long-form reading or table cells.

/// Gel tag. Selected = gel fill; unselected = raised clay **with a rim**, so
/// the unselected state never relies on shadow alone.
class ClayChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CScholarRadius.full);
    final chip = AnimatedContainer(
      duration: motionEnabled(context) ? CScholarDurations.fast : Duration.zero,
      curve: CScholarCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: selected
          ? BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [CScholarMaterial.gelTop, CScholarMaterial.gelBottom],
              ),
              boxShadow: CScholarMaterial.gelDrop(depth: 0.6),
            )
          : BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CScholarMaterial.clayHigh, CScholarMaterial.clay],
              ),
              border: Border.all(color: CScholarMaterial.rim),
              boxShadow: CScholarMaterial.clayDrop(depth: 0.5),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : CScholarMaterial.textMuted),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: CScholarTextStyles.inter(
              12,
              FontWeight.w600,
              selected ? Colors.white : CScholarMaterial.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: chip),
    );
  }
}

/// Moulded tile that holds an icon — KPI cards, list leads, nav affordances.
/// The inner top-light is what makes it look pressed out of the canvas.
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
    final radius = BorderRadius.circular(size * 0.3);
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
                    : CScholarMaterial.clayDrop(depth: 0.5),
      ),
      child: InsetShadow(
        borderRadius: radius,
        shadows: [
          BoxShadow(
            // gold gets a stronger inner shine so the halo has a source
            color: Colors.white.withValues(alpha: gold ? 0.55 : 0.35),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
        child: Center(
          child: Icon(icon, size: size * 0.46, color: glyph),
        ),
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
    final radius = BorderRadius.circular(size / 2);
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
      child: InsetShadow(
        borderRadius: radius,
        shadows: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.40),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
        child: Center(
          child: Text(
            _initials,
            style: CScholarTextStyles.inter(
                size * 0.32, FontWeight.w700, Colors.white),
          ),
        ),
      ),
    );
  }
}

