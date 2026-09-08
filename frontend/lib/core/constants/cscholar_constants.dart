// CScholar Design System Constants
// Caraga State University inspired palette

import 'package:flutter/material.dart';

/// CScholar brand colors — Stitch design v2
class CScholarColors {
  // Primary brand green
  static const Color primaryGreen = Color(0xFF009900);
  static const Color primaryGreenHover = Color(0xFF007A00);
  static const Color primaryGreenDark = Color(0xFF005A00);
  static const Color primaryGreenVeryLight = Color(0xFFDCF5DC); // Gold-tinted very light
  static const Color primaryGreenLight = Color(0xFF33AA33);

  // Sidebar deep greens
  static const Color sidebarDeep = Color(0xFF033F15);
  static const Color sidebarHover = Color(0xFF05541C);
  static const Color sidebarActive = Color(0xFF0A6423);
  static const Color adminSidebar = Color(0xFF004D00);

  // Accents — gold and orange
  static const Color gold = Color(0xFFF9DC07);
  static const Color goldLight = Color(0xFFFBE674);
  static const Color orange = Color(0xFFFF9900);
  static const Color orangeLight = Color(0xFFFFB34D);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color shadowColor = Color(0x1A000000);

  // Semantic colors
  static const Color success = Color(0xFF009900);
  static const Color warning = Color(0xFFF9DC07);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF2196F3);

  // Role colors
  static const Color studentColor = Color(0xFF2196F3);
  static const Color facultyColor = Color(0xFF9C27B0);
  static const Color adminColor = Color(0xFFFF9800);
}

/// Text styles using Google Fonts
class CScholarTextStyles {
  static const String fontFamily = 'Inter';

  static TextStyle get headlineLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: CScholarColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: CScholarColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.25,
  );

  static TextStyle get headlineSmall => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: CScholarColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: CScholarColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CScholarColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get titleSmall => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CScholarColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: CScholarColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CScholarColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CScholarColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CScholarColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: CScholarColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: CScholarColors.textHint,
    height: 1.4,
  );

  // Semantic text styles
  static TextStyle get success => bodyMedium.copyWith(
    color: CScholarColors.success,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get warning => bodyMedium.copyWith(
    color: CScholarColors.warning,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get error => bodyMedium.copyWith(
    color: CScholarColors.error,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get semanticMatch => bodyMedium.copyWith(
    color: CScholarColors.primaryGreen,
    fontWeight: FontWeight.w700,
  );
}

/// Spacing constants
class CScholarSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Border radius constants
class CScholarRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999;
}

/// Shadow definitions
class CScholarShadows {
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: CScholarColors.shadowColor,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: CScholarColors.shadowColor,
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: CScholarColors.shadowColor,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: CScholarColors.shadowColor,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: CScholarColors.shadowColor,
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}

/// Animation durations
class CScholarDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

/// Breakpoints for responsive design
class CScholarBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Semantic similarity thresholds for UI
class CScholarSimilarity {
  static const double highThreshold = 0.90;
  static const double mediumThreshold = 0.75;
  static const double lowThreshold = 0.60;

  static String labelFor(double score) {
    if (score >= highThreshold) return 'Highly Relevant';
    if (score >= mediumThreshold) return 'Relevant';
    if (score >= lowThreshold) return 'Somewhat Related';
    return 'Related';
  }

  static Color colorFor(double score) {
    if (score >= highThreshold) return CScholarColors.success;
    if (score >= mediumThreshold) return CScholarColors.warning;
    if (score >= lowThreshold) return CScholarColors.info;
    return CScholarColors.textHint;
  }
}