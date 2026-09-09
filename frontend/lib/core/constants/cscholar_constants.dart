import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CScholarColors {
  // Primary brand palette from Stitch
  static const Color primaryGreen = Color(0xFF009900);
  static const Color primaryGreenHover = Color(0xFF008000);
  static const Color primaryGreenDark = Color(0xFF007300);
  static const Color primaryGreenLight = Color(0xFFE6F5E6);
  static const Color primaryGreenVeryLight = Color(0xFFF0FDF4);

  // Deep sidebars
  static const Color sidebarDeep = Color(0xFF033F15);
  static const Color sidebarHover = Color(0xFF05541C);
  static const Color sidebarActive = Color(0xFF0A6423);
  static const Color adminSidebar = Color(0xFF004D00);
  static const Color adminSidebarHover = Color(0xFF005F00);
  static const Color repoSidebar = Color(0xFF014421);
  static const Color repoActive = Color(0xFF0A5C30);
  static const Color savedSidebarActive = Color(0xFF14833B);
  static const Color forest = Color(0xFF043E18);

  // Accents
  static const Color gold = Color(0xFFF9DC07);
  static const Color goldLight = Color(0xFFFEF9C3);
  static const Color orange = Color(0xFFFF9900);
  static const Color orangeLight = Color(0xFFFFEDD5);

  // Backgrounds & Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundSoft = Color(0xFFF8FAF9);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE5E7EB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF8FAFC);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color shadowColor = Color(0x1A000000);

  // Status
  static const Color success = Color(0xFF009900);
  static const Color warning = Color(0xFFF9DC07);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Roles
  static const Color studentColor = Color(0xFF2563EB);
  static const Color facultyColor = Color(0xFF9333EA);
  static const Color adminColor = Color(0xFFFF9900);
}

class CScholarTextStyles {
  // GoogleFonts Poppins for headings
  static TextStyle poppins(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // GoogleFonts Inter for body, labels, metadata
  static TextStyle inter(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.5,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get h1 => poppins(32, FontWeight.w800, CScholarColors.textPrimary, height: 1.2);
  static TextStyle get h2 => poppins(24, FontWeight.w700, CScholarColors.textPrimary, height: 1.3);
  static TextStyle get h3 => poppins(20, FontWeight.w600, CScholarColors.textPrimary, height: 1.4);
  static TextStyle get h4 => poppins(16, FontWeight.w600, CScholarColors.textPrimary, height: 1.4);

  static TextStyle get bodyLarge => inter(16, FontWeight.w400, CScholarColors.textPrimary);
  static TextStyle get bodyMedium => inter(14, FontWeight.w400, CScholarColors.textPrimary);
  static TextStyle get bodySmall => inter(12, FontWeight.w400, CScholarColors.textSecondary);

  static TextStyle get label => inter(11, FontWeight.w600, CScholarColors.textSecondary, height: 1.4);
  static TextStyle get labelUppercase => inter(11, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 0.5);
}

class CScholarRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double full = 999;
}

class CScholarSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class CScholarDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

class CScholarShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
}

class CScholarSimilarity {
  static const double high = 0.90;
  static const double medium = 0.75;
  static const double low = 0.60;

  static String labelFor(double score) {
    if (score >= high) return 'Highly Relevant';
    if (score >= medium) return 'Relevant';
    if (score >= low) return 'Somewhat Related';
    return 'Related';
  }

  static Color colorFor(double score) {
    if (score >= high) return CScholarColors.success;
    if (score >= medium) return CScholarColors.warning;
    if (score >= low) return CScholarColors.info;
    return CScholarColors.textHint;
  }
}
