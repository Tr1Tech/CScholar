import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Shared topbar chrome for every role shell (admin / faculty / student).
///
/// The bar itself stays TRANSPARENT — the shell lays it above a flat canvas, so
/// a bar fill would only add a second surface with nothing behind it. The
/// controls carry the material instead:
///
///   * search  -> a recessed clay well  ("input fields are wells", never white)
///   * identity-> a raised clay pill + gel avatar
///
/// It also stays transparent once content scrolls under it: seating it would
/// stretch a clay plate across the whole page width, which on a bar holding a
/// single pill is an empty white band, and on the search bars frames one well
/// and one pill with a strip of nothing. The controls keep their own material,
/// so they stay legible with rows passing beneath them.
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
    final radius = BorderRadius.circular(CScholarRadius.well);

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: CScholarTextStyles.body(
        13.5,
        FontWeight.w400,
        CScholarColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: CScholarTextStyles.body(
          13.5,
          FontWeight.w400,
          CScholarColors.textHint,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: CScholarColors.textSecondary,
        ),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(
                  Icons.clear,
                  size: 18,
                  color: CScholarColors.textSecondary,
                ),
                onPressed: onClear,
              ),
        // The well's fill and rim are painted by the Container below.
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
      ),
    );

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: CScholarMaterial.well,
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
    this.heroAvatar = false,
  });

  final String? name;
  final String role;

  /// Shown when [name] is null or blank.
  final String fallbackName;

  /// Wrap the avatar in a [Hero] tagged [userAvatarHeroTag].
  ///
  /// Off by default: only the student shell has a route whose body shows the
  /// same avatar as a target (the profile card), and a hero with no target —
  /// or worse, a second hero sharing the tag — is an assertion, not a nicety.
  final bool heroAvatar;

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
        boxShadow: flat ? null : CScholarMaterial.softShadow(depth: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          heroAvatar
              ? Hero(
                  tag: userAvatarHeroTag,
                  child: CScholarHeaderAvatar(name: label, size: 32),
                )
              : CScholarHeaderAvatar(name: label, size: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CScholarTextStyles.body(
                  12.5,
                  FontWeight.w700,
                  CScholarMaterial.textPrimary,
                ),
              ),
              Text(
                role,
                style: CScholarTextStyles.body(
                  10.5,
                  FontWeight.w500,
                  CScholarMaterial.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Topbar identity avatar: soft coral circle with green initials.
class CScholarHeaderAvatar extends StatelessWidget {
  const CScholarHeaderAvatar({
    super.key,
    required this.name,
    required this.size,
  });

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
      decoration: const BoxDecoration(
        color: CScholarColors.goldSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: CScholarTextStyles.body(
          size * 0.32,
          FontWeight.w800,
          CScholarColors.primaryGreen,
        ),
      ),
    );
  }
}
