import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

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
        rim = const Color(0xFFB8E2B8);
        break;
      case 'approved':
        bg = CScholarColors.infoLight;
        fg = CScholarColors.info;
        rim = const Color(0xFFBFDBFE);
        break;
      case 'draft':
        bg = CScholarColors.adminLight;
        fg = CScholarColors.adminColor;
        rim = const Color(0xFFFDE68A);
        break;
      default:
        bg = const Color(0xFFE2EAE1);
        fg = CScholarColors.textMuted;
        rim = CScholarColors.borderLight;
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
        rim = const Color(0xFFFDE68A);
        break;
      case 'faculty':
        bg = CScholarColors.facultyLight;
        fg = CScholarColors.facultyColor;
        rim = const Color(0xFFE9D5FF);
        break;
      default:
        bg = CScholarColors.infoLight;
        fg = CScholarColors.studentColor;
        rim = const Color(0xFFBFDBFE);
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
    final bg = isActive
        ? CScholarColors.primaryGreenLight
        : const Color(0xFFE2EAE1);
    final fg =
        isActive ? CScholarColors.primaryGreen : CScholarColors.textMuted;
    final rim = isActive ? const Color(0xFFB8E2B8) : CScholarColors.borderLight;

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
        boxShadow: highContrast
            ? null
            : const [
                BoxShadow(
                  color: Color(0x18000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: isPill ? 0.2 : 0.4,
          color: highContrast ? CScholarColors.textPrimary : fg,
        ),
      ),
    );
  }
}

