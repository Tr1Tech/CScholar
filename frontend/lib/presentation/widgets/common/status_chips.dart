import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// The status palette, exposed on its own so a control that wraps the chip —
/// the admin status menu — cannot drift from the read-only badge.
///
/// Published = mint, Approved = lilac, Draft = coral, Archived / other = slate.
///
/// All foreground / background pairs are verified WCAG AA (>= 4.5:1):
/// - Published: green #174F3D on mint (7.26:1)
/// - Approved:  lilac ink #5B5194 on lilac soft (5.53:1)
/// - Draft:     coral ink #A63E25 on coral soft (5.17:1)
/// - Other:     muted ink #5A665F on surfaceSoft (5.55:1)
class ThesisStatusStyle {
  const ThesisStatusStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.rim,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color rim;

  /// Sentence-case name used in spoken/compound labels ("Status: Published")
  /// and anywhere a status is referred to in help copy. The chip itself keeps
  /// the uppercase micro-label.
  String get displayLabel {
    final lower = label.toLowerCase();
    return lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
  }

  /// The shape that pairs with the colour for this status (A11Y-3). Reserve
  /// the icon for surfaces that have room; the chip's text label already
  /// carries the meaning on its own.
  IconData get icon {
    switch (label.toLowerCase()) {
      case 'published':
        return Icons.check_circle_outline;
      case 'approved':
        return Icons.verified_outlined;
      case 'draft':
        return Icons.edit_note;
      case 'archived':
        return Icons.inventory_2_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  factory ThesisStatusStyle.of(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return ThesisStatusStyle(
          label: status.toUpperCase(),
          bg: CScholarColors.primaryGreenLight,
          fg: CScholarColors.primaryGreen,
          rim: CScholarMaterial.rimPublished,
        );
      case 'approved':
        return ThesisStatusStyle(
          label: status.toUpperCase(),
          bg: CScholarColors.facultyLight,
          fg: CScholarColors.facultyColor,
          rim: CScholarMaterial.rimApproved,
        );
      case 'draft':
        return ThesisStatusStyle(
          label: status.toUpperCase(),
          bg: CScholarColors.adminLight,
          fg: CScholarColors.adminColor,
          rim: CScholarMaterial.rimDraft,
        );
      default:
        return ThesisStatusStyle(
          label: status.toUpperCase(),
          bg: CScholarMaterial.chipNeutral,
          fg: CScholarColors.textMuted,
          rim: CScholarMaterial.rim,
        );
    }
  }
}

/// The lifecycle edges, mirroring the API's `THESIS_STATUS_SOURCES` and the
/// database's `fn_can_transition_status`. Keyed by current status, the set of
/// targets the server will accept — so a control can hide transitions it knows
/// would come back as a 409 instead of offering a dead option.
///
/// Archiving is reversible: `archived -> draft/published`.
class ThesisStatusTransitions {
  ThesisStatusTransitions._();

  static const Map<String, Set<String>> _targets = {
    'draft': {'approved', 'archived'},
    'approved': {'draft', 'published'},
    'published': {'archived'},
    'archived': {'draft', 'published'},
  };

  static bool allows(String from, String to) =>
      _targets[from.toLowerCase()]?.contains(to.toLowerCase()) ?? false;

  static Set<String> targetsFrom(String from) =>
      _targets[from.toLowerCase()] ?? const <String>{};
}

class ThesisStatusChip extends StatelessWidget {
  final String status;
  const ThesisStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = ThesisStatusStyle.of(status);
    return _TactileChip(
      text: style.label,
      bg: style.bg,
      fg: style.fg,
      rim: style.rim,
      // One semantic unit, and the colour is never the only carrier of
      // meaning: the status name is spoken (A11Y-3, A11Y-6).
      semanticLabel: 'Status: ${style.displayLabel}',
    );
  }
}

/// Tactile role badge. Student = green, Faculty = lilac, Admin = coral.
class RoleChip extends StatelessWidget {
  final String role;
  const RoleChip(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color rim;

    switch (role.toLowerCase()) {
      case 'admin':
        bg = CScholarColors.adminLight;
        fg = CScholarColors.adminColor;
        rim = CScholarMaterial.rimDraft;
        break;
      case 'faculty':
        bg = CScholarColors.facultyLight;
        fg = CScholarColors.facultyColor;
        rim = CScholarMaterial.rimFaculty;
        break;
      default:
        bg = CScholarColors.primaryGreenLight;
        fg = CScholarColors.studentColor;
        rim = CScholarMaterial.rimPublished;
    }
    return _TactileChip(
      text: role.toLowerCase(),
      bg: bg,
      fg: fg,
      rim: rim,
      isPill: true,
      semanticLabel: 'Role: ${role.toLowerCase()}',
    );
  }
}

class ActiveChip extends StatelessWidget {
  final bool isActive;
  const ActiveChip(this.isActive, {super.key});

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? CScholarColors.primaryGreenLight
        : CScholarMaterial.chipNeutral;
    final fg = isActive
        ? CScholarColors.primaryGreen
        : CScholarColors.textMuted;
    final rim = isActive ? CScholarMaterial.rimPublished : CScholarMaterial.rim;

    return _TactileChip(
      text: isActive ? 'ACTIVE' : 'INACTIVE',
      bg: bg,
      fg: fg,
      rim: rim,
      semanticLabel: 'Account status: ${isActive ? 'Active' : 'Inactive'}',
    );
  }
}

class _TactileChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final Color rim;
  final bool isPill;
  final String? semanticLabel;

  const _TactileChip({
    required this.text,
    required this.bg,
    required this.fg,
    required this.rim,
    this.isPill = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeOf(context)?.highContrast == true;

    return Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPill ? 10 : 8,
          vertical: isPill ? 3.5 : 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            isPill ? CScholarRadius.full : CScholarRadius.sm,
          ),
          border: Border.all(
            color: highContrast ? CScholarColors.textPrimary : rim,
            width: highContrast ? 1.5 : 1,
          ),
          // The shadow is the tinted clay token, never black. A 20px badge is too
          // small for the shadow to define it, hence the hairline rim alongside.
          boxShadow: highContrast
              ? null
              : CScholarMaterial.softShadow(depth: 0.3),
        ),
        child: Text(
          text,
          style: CScholarTextStyles.body(
            11,
            FontWeight.w700,
            highContrast ? CScholarMaterial.textPrimary : fg,
            letterSpacing: isPill ? 0.2 : 0.4,
          ),
        ),
      ),
    );
  }
}
