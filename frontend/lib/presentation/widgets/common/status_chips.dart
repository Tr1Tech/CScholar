import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Tactile status chip for the thesis system.
///
/// Published = emerald, Approved = cobalt, Draft = warm amber,
/// Archived / other = clay slate.
///
/// All foreground / background pairs are verified WCAG AA (>= 4.5:1):
/// - Published: #007A14 on #E6F5E6 (4.89:1)
/// - Approved:  #1D4ED8 on #DBEAFE (5.49:1)
/// - Draft:     #A34A08 on #FEF3C7 (5.33:1)
/// - Other:     #556377 on #E2EAE1 (4.97:1)
///
/// Every colour comes from the token layer: the fills are CScholarColors
/// tokens and the hairline rims are CScholarMaterial tokens, so the palette
/// law scan has no literal to flag.
class ThesisStatusChip extends StatelessWidget {
  final String status;
  const ThesisStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color rim;

    switch (status.toLowerCase()) {
      case 'published':
        bg = CScholarColors.primaryGreenLight;
        fg = CScholarColors.primaryGreen;
        rim = CScholarMaterial.rimPublished;
        break;
      case 'approved':
        bg = CScholarColors.infoLight;
        fg = CScholarColors.info;
        rim = CScholarMaterial.rimApproved;
        break;
      case 'draft':
        bg = CScholarColors.adminLight;
        fg = CScholarColors.adminColor;
        rim = CScholarMaterial.rimDraft;
        break;
      default:
        bg = CScholarMaterial.chipNeutral;
        fg = CScholarColors.textMuted;
        rim = CScholarMaterial.rim;
    }
    return _TactileChip(text: status.toUpperCase(), bg: bg, fg: fg, rim: rim);
  }
}

/// Tactile role badge. Student = cobalt, Faculty = violet, Admin = amber.
/// All foreground / background pairs are verified WCAG AA (>= 4.5:1).
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
        bg = CScholarColors.infoLight;
        fg = CScholarColors.studentColor;
        rim = CScholarMaterial.rimApproved;
    }
    return _TactileChip(
      text: role.toLowerCase(),
      bg: bg,
      fg: fg,
      rim: rim,
      isPill: true,
    );
  }
}

class ActiveChip extends StatelessWidget {
  final bool isActive;
  const ActiveChip(this.isActive, {super.key});

  @override
  Widget build(BuildContext context) {
    final bg =
        isActive ? CScholarColors.primaryGreenLight : CScholarMaterial.chipNeutral;
    final fg =
        isActive ? CScholarColors.primaryGreen : CScholarColors.textMuted;
    final rim = isActive ? CScholarMaterial.rimPublished : CScholarMaterial.rim;

    return _TactileChip(
      text: isActive ? 'ACTIVE' : 'INACTIVE',
      bg: bg,
      fg: fg,
      rim: rim,
    );
  }
}

class _TactileChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final Color rim;
  final bool isPill;

  const _TactileChip({
    required this.text,
    required this.bg,
    required this.fg,
    required this.rim,
    this.isPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast =
        MediaQuery.maybeOf(context)?.highContrast == true;

    return Container(
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
        boxShadow: highContrast ? null : CScholarMaterial.clayDrop(depth: 0.18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: isPill ? 0.2 : 0.4,
          color: highContrast ? CScholarMaterial.textPrimary : fg,
        ),
      ),
    );
  }
}