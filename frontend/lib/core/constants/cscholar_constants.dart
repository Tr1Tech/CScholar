import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Design tokens for the whole app.
///
/// MATERIAL SYSTEM v3 — see `core/material/material_tokens.dart`, which is the
/// single source of truth for the material layer. Two things changed here:
///
///  1. The canvas moved from near-white to a sage **clay** tone, and the shadow
///     language became tinted instead of black. Clay and canvas must share a hue
///     family or a tinted shadow reads as mud, so surfaces, borders and dividers
///     were retargeted together.
///  2. The greens were darkened so they pass WCAG AA on that canvas. The old
///     #009900 was 3.78:1 in BOTH directions (as text on white, and white text
///     on it); #007A14 is 5.54:1 / 5.06:1 / 4.73:1.
///
/// Measured ratios are recorded next to each token. Do not change one of these
/// values without re-measuring against the canvas (#E8EFE7) and the clay panel
/// (#F1F6F0).
class CScholarColors {
  // ---- Brand green: ONE green for fills and for text --------------------
  static const Color primaryGreen = Color(0xFF007A14);
  static const Color primaryGreenHover = CScholarMaterial.gelBottom;
  static const Color primaryGreenDark = CScholarMaterial.gelDeep;
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
  static const Color gold = CScholarMaterial.goldTop;
  static const Color goldLight = Color(0xFFFEF9C3);
  static const Color goldDeep = CScholarMaterial.goldBottom;
  static const Color goldSoft = Color(0xFFFEF3C7);
  /// Bright orange: fills/tints only — 2.2:1 as text on clay. Use [warningFg]
  /// for warning copy.
  static const Color orange = Color(0xFFFF9900);
  static const Color orangeLight = Color(0xFFFFEDD5);

  // Light shell: clay canvas, floating clay sidebar, gel active pill.
  static const Color shellWash = CScholarMaterial.canvas;
  static const Color sidebarLight = CScholarMaterial.clay;
  static const Color sidebarLightBorder = CScholarMaterial.rim;
  static const Color navActiveBg = primaryGreen;
  static const Color heroDeep = Color(0xFF003800);
  static const Color heroMid = Color(0xFF005A1E);
  static const Color heroGlow = Color(0xFF008000);
  /// Mid stops of the auth brand panel gradient ([heroMid] -> [heroBase] ->
  /// [heroFloor]); all three are dark enough that white and [heroText] clear
  /// the 4.5:1 body floor on every stop.
  static const Color heroBase = Color(0xFF00471B);
  static const Color heroFloor = Color(0xFF043313);
  /// Mint copy on the dark hero panels. Measured 7.46:1 on [heroMid] and
  /// 12.44:1 on [heroFloor] — comfortably AA for the 13.5px body text.
  static const Color heroText = Color(0xFFD1FAE5);
  /// Badge pill on the dark hero: translucent black fill + translucent gold rim.
  /// Both are decoration over a dark gradient — no text sits on them.
  static const Color heroBadgeFill = Color(0x33000000);
  static const Color heroBadgeRim = Color(0x4DF9DC07);

  // ---- Thesis cover art: eight measured two-stop gradients -----------------
  // Decoration only — identity art on a cover, never text backgrounds. Every
  // stop is dark enough that the white cover glyph clears 4.5:1 against the
  // lighter stop of its own pair (worst case #0B6B3A at 6.61:1).
  static const List<List<Color>> coverGradients = [
    [Color(0xFF04331A), Color(0xFF0B6B3A)],
    [Color(0xFF0B1E3A), Color(0xFF1D4ED8)],
    [Color(0xFF1E1B4B), Color(0xFF6D28D9)],
    [Color(0xFF042F2E), Color(0xFF0D9488)],
    [Color(0xFF3B0764), Color(0xFFA21CAF)],
    [Color(0xFF451A03), Color(0xFFC2410C)],
    [Color(0xFF111827), Color(0xFF374151)],
    [Color(0xFF064E3B), Color(0xFFCA8A04)],
  ];

  // Research-type chips (v2 card language)
  static const Color thesisChipBg = Color(0xFFDCFCE7);
  static const Color thesisChipFg = Color(0xFF047857);
  static const Color capstoneChipBg = Color(0xFFFEF3C7);
  static const Color capstoneChipFg = Color(0xFFB45309);

  // ---- Metric tile tints ----
  // Icon-tile backgrounds for KPI / metric rows. Each INK must clear 3:1
  // against its own TINT (WCAG 1.4.11) — sky #0369A1 is 5.17:1 on #E0F2FE and
  // violet #6D28D9 is 5.98:1 on #EDE9FE. The green/amber tiles reuse the
  // research-type tints above.
  static const Color skyTint = Color(0xFFE0F2FE);
  static const Color skyInk = Color(0xFF0369A1);
  static const Color violetTint = Color(0xFFEDE9FE);
  static const Color violetInk = Color(0xFF6D28D9);
  /// Teal and cyan tiles are the saved-thesis device leads. Same contract:
  /// teal #0F766E is 4.86:1 on #CCFBF1, cyan #0E7490 is 4.79:1 on #CFFAFE.
  static const Color tealTint = Color(0xFFCCFBF1);
  static const Color tealInk = Color(0xFF0F766E);
  static const Color cyanTint = Color(0xFFCFFAFE);
  static const Color cyanInk = Color(0xFF0E7490);

  // ---- Canvas & neutral surfaces (sage-clay family) ----
  /// Literal white. For ink on green and for surfaces that must stay paper —
  /// never for the app canvas anymore.
  static const Color white = Color(0xFFFFFFFF);
  /// Page canvas: #E8EFE7.
  static const Color backgroundLight = CScholarMaterial.canvas;
  static const Color backgroundSoft = CScholarMaterial.canvas;
  static const Color backgroundDark = Color(0xFF0F172A);
  /// Clay panel surface (#F1F6F0). Name is historical — this is no longer
  /// pure white, because clay panels must share a hue with the canvas.
  static const Color surfaceWhite = CScholarMaterial.clay;
  /// Recessed wells, inset panels and skeleton bases (#E3EBE1).
  static const Color surfaceLight = CScholarMaterial.clayDeep;
  static const Color cardBg = CScholarMaterial.clay;
  /// Row separators: soft sage, deliberately quieter than [borderLight].
  static const Color dividerLight = Color(0xFFD5E0D3);
  /// Component rim / affordance backstop: 1.46:1 on clay by design.
  static const Color borderLight = CScholarMaterial.rim;
  static const Color inputBg = CScholarMaterial.clayDeep;
  /// Preferred alias for new code: the panel surface.
  static const Color surface = CScholarMaterial.clay;

  // ---- Text ----
  static const Color textPrimary = Color(0xFF0F172A); // 16.31:1 on clay
  static const Color textSecondary = CScholarMaterial.textMuted; // 6.92:1
  /// #556377: 5.22:1 on canvas, 5.58:1 on clay. The old #64748B dropped to
  /// 4.06:1 once the canvas darkened.
  static const Color textMuted = Color(0xFF556377);
  /// Placeholders only — 2.56:1 on clay, never for content.
  static const Color textHint = Color(0xFF94A3B8);
  static const Color shadowColor = Color(0x1A000000);

  // ---- Status ----
  static const Color success = primaryGreen;
  /// Decorative amber (gold). Never text.
  static const Color warning = CScholarMaterial.goldTop;
  /// Warning copy: 5.06:1 on canvas, 5.42:1 on clay.
  static const Color warningFg = Color(0xFFA34A08);
  /// #B91C1C: 5.52:1 on canvas, 5.91:1 on clay, 5.30:1 on [errorLight].
  /// The old #EF4444 was 3.44:1 on clay.
  static const Color error = Color(0xFFB91C1C);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoLight = Color(0xFFDBEAFE);
  /// "Semantic index unavailable" note: amber paper fill, 1.22:1 rim (a hairline
  /// seated on its own fill), 2.49:1 icon and 5.89:1 copy #7A5C00. The copy and
  /// icon both clear their floors on [noteBg] (the icon is 18px, so 3:1 is the
  /// target and 2.49:1 is decoration-adjacent — the copy carries the meaning).
  static const Color noteBg = Color(0xFFFFF8E1);
  static const Color noteRim = Color(0xFFFFE082);
  static const Color noteIcon = Color(0xFFF57F17);
  static const Color noteInk = Color(0xFF7A5C00);

  // Roles
  static const Color studentColor = Color(0xFF1D4ED8);
  static const Color facultyColor = Color(0xFF7E22CE);
  static const Color facultyLight = Color(0xFFF3E8FF);
  static const Color adminColor = Color(0xFFA34A08);
  static const Color adminLight = goldSoft;

  // ---- Chart / progress fills ----
  /// Status fills for bars and charts. A bar is a graphical object, so every
  /// stop must clear 3:1 against the [CScholarMaterial.clayDeep] track
  /// (WCAG 1.4.11). Measured on that track: published 4.54:1, approved 5.50:1,
  /// draft 4.87:1, archived 5.01:1.
  ///
  /// `draft` is [warningFg], never [orange]: #FF9900 is only 1.76:1 there, so
  /// it reads as a gap in the bar rather than a low value.
  static const Map<String, Color> statusFill = {
    'published': primaryGreen,
    'approved': info,
    'draft': warningFg,
    'archived': textSecondary,
  };
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

  // Canonical page/card/section styles — prefer these over ad-hoc sizes so
  // every screen shares one scale (design plan, item 1).
  static TextStyle get pageTitle => poppins(24, FontWeight.w800, CScholarColors.textPrimary, height: 1.25);
  static TextStyle get pageSubtitle => inter(13, FontWeight.w400, CScholarColors.textMuted);
  static TextStyle get cardTitle => poppins(16, FontWeight.w700, CScholarColors.textPrimary);
  static TextStyle get sectionLabel =>
      inter(12, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 1.0);
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
  // Nothing animates longer than 300ms (motion plan, item 8).
  static const Duration slow = Duration(milliseconds: 300);

  /// Input debounce. Not an animation — it never renders — so it sits outside
  /// the 300ms motion ceiling, but it is still named here so no screen hand-
  /// rolls a timer.
  static const Duration debounce = Duration(milliseconds: 400);
}

class CScholarCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOut;
}

/// Elevation recipes — now sourced from the material system, so shadows are
/// TINTED (#C9D6C6) rather than black. A black-alpha shadow on a tinted canvas
/// stops clay from reading as a lit surface.
class CScholarShadows {
  /// Resting panel.
  static List<BoxShadow> get card => CScholarMaterial.clayDrop(depth: 0.8);

  /// Hover / raised.
  static List<BoxShadow> get elevated => CScholarMaterial.clayDrop(depth: 1.2);

  /// Hairline elevation (inline rows, chips).
  static List<BoxShadow> get subtle => CScholarMaterial.clayDrop(depth: 0.4);

  /// Gold halo — the only coloured shadow in the system. Prestige / AI marks
  /// only: max 2-3 per screen, never behind text.
  static List<BoxShadow> get goldGlow => CScholarMaterial.goldGlow();

  /// Green halo for the active nav pill and selected states.
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: CScholarColors.primaryGreen.withValues(alpha: 0.28),
          blurRadius: 14,
          offset: const Offset(0, 4),
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

  /// Colour for a similarity LABEL — must stay text-safe on clay.
  static Color colorFor(double score) {
    if (score >= high) return CScholarColors.success;
    if (score >= medium) return CScholarColors.warningFg;
    if (score >= low) return CScholarColors.info;
    return CScholarColors.textMuted;
  }
}
