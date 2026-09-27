import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';

/// Shared topbar chrome for every role shell (admin / faculty / student).
///
/// The bar itself stays TRANSPARENT — the shell lays it above a flat canvas, so
/// a bar fill would only add a second surface with nothing behind it. The
/// controls carry the material instead:
///
///   * search  -> a recessed clay well  ("input fields are wells", never white)
///   * identity-> a raised clay pill + gel avatar
///
/// Glass is deliberately NOT used here. Glass pays for itself when there is
/// content behind it to blur; above a flat canvas it is pure cost and looks
/// identical to clay. See [CScholarMaterial.ratios] for the tokens involved.
class Topbar extends StatelessWidget {
  const Topbar({
    super.key,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(28, 16, 28, 12),
  });

  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          ?leading,
          // A trailing-only bar (faculty, student) must still sit right: the
          // pill is an identity anchor in the top-right corner, not a left item.
          if (trailing != null) const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tonal clay search well — replaces the hardcoded `#F9FAFB` white box that
/// read as a hole punched in the sage canvas.
///
/// Flat fill, no outline at rest: the fill IS the field. A drawn rim on every
/// search box was part of what made the earlier pass look boxed-in.
class TopbarSearchField extends StatelessWidget {
  const TopbarSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search…',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.width = 380,
    this.maxWidth = 420,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Passing null hides the clear affordance entirely.
  final VoidCallback? onClear;

  final double width;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    final radius = BorderRadius.circular(CScholarRadius.full);

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: CScholarTextStyles.inter(
          13.5, FontWeight.w400, CScholarColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textHint),
        prefixIcon: const Icon(Icons.search,
            size: 20, color: CScholarColors.textSecondary),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear,
                    size: 18, color: CScholarColors.textSecondary),
                onPressed: onClear,
              ),
        // The well's fill and rim are painted by the Container below.
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: CScholarMaterial.clayDeep,
            borderRadius: radius,
            // No outline at rest — the tonal fill is the field. High contrast
            // keeps a strong rim as its fallback.
            border: flat
                ? Border.all(color: CScholarMaterial.rimStrong, width: 1.5)
                : null,
          ),
          child: field,
        ),
      ),
    );
  }
}

/// Identity pill: gel avatar + name + role on a raised clay pill.
///
/// Replaces the two near-identical hand-rolled pills that had drifted (the
/// admin one had no shadow, the faculty one used a black-alpha shadow and both
/// painted `Colors.white` over the sage canvas).
class TopbarUserPill extends StatelessWidget {
  const TopbarUserPill({
    super.key,
    required this.name,
    required this.role,
    this.fallbackName = 'User',
  });

  final String? name;
  final String role;

  /// Shown when [name] is null or blank.
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    final label = (name ?? '').trim().isEmpty ? fallbackName : name!.trim();
    final radius = BorderRadius.circular(CScholarRadius.full);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: flat ? CScholarMaterial.clay : CScholarMaterial.clayHigh,
        borderRadius: radius,
        border: Border.all(
          color: flat ? CScholarMaterial.rimStrong : CScholarMaterial.rim,
          width: flat ? 1.5 : 1,
        ),
        boxShadow: flat ? null : CScholarMaterial.clayDrop(depth: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GelAvatar(name: label, size: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CScholarTextStyles.inter(
                    12.5, FontWeight.w700, CScholarMaterial.textPrimary),
              ),
              Text(
                role,
                style: CScholarTextStyles.inter(
                    10.5, FontWeight.w500, CScholarMaterial.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
