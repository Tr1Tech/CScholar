import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Design tokens for the whole app.
///
/// SOFT UI v4 — the mobile shell is now the single source of truth. Every
/// surface value here aliases [CScholarMobileColors] so desktop and mobile can
/// never drift: paper canvas, near-white cards, soft green-tinted shadows,
/// Manrope headings and DM Sans body copy.
///
/// Contrast note: raw accents (`coral`, `lilac`, `muted`) are FILL colours. Body
/// copy uses the text-safe inks ([CScholarMobileColors.coralInk], [lilacInk],
/// [mutedInk]) which clear 4.5:1 on paper and on their own tints.
class CScholarColors {
  // ---- Brand green: ONE green for fills and for text --------------------
  static const Color primaryGreen = CScholarMobileColors.green;
  static const Color primaryGreenHover = CScholarMobileColors.green2;
  static const Color primaryGreenDark = CScholarMobileColors.greenDeep;
  static const Color primaryGreenLight = CScholarMobileColors.mint;
  static const Color primaryGreenVeryLight = CScholarMobileColors.surfaceSoft;

  // Sidebars are light floating cards now. Legacy names are kept so old
  // references compile; they resolve to the brand green for glyphs/active ink.
  static const Color forest = CScholarMobileColors.green;
  static const Color sidebarDeep = forest;
  static const Color sidebarHover = CScholarMobileColors.green2;
  static const Color sidebarActive = forest;
  static const Color adminSidebar = forest;
  static const Color adminSidebarHover = CScholarMobileColors.green2;
  static const Color repoSidebar = forest;
  static const Color repoActive = forest;
  static const Color savedSidebarActive = forest;

  /// Role accent dot / chip.
  static const Map<String, Color> roleAccent = {
    'student': CScholarMobileColors.green2,
    'faculty': CScholarMobileColors.lilacInk,
    'admin': CScholarMobileColors.coralInk,
  };

  // Accents — gold retires; coral is the attention / AI accent.
  static const Color gold = CScholarMobileColors.coral;
  static const Color goldLight = CScholarMobileColors.coralSoft;
  static const Color goldDeep = CScholarMobileColors.coralInk;
  static const Color goldSoft = CScholarMobileColors.coralSoft;
  static const Color orange = CScholarMobileColors.coral;
  static const Color orangeLight = CScholarMobileColors.coralSoft;

  // Light shell: paper canvas, floating surface sidebar, mint active pill.
  static const Color shellWash = CScholarMobileColors.paper;
  static const Color sidebarLight = CScholarMobileColors.surface;
  static const Color sidebarLightBorder = CScholarMobileColors.line;
  static const Color navActiveBg = CScholarMobileColors.green;
  static const Color heroDeep = CScholarMobileColors.greenDeep;
  static const Color heroMid = CScholarMobileColors.green;
  static const Color heroGlow = CScholarMobileColors.green2;
  static const Color heroBase = CScholarMobileColors.greenDeep;
  static const Color heroFloor = CScholarMobileColors.greenDeep;
  static const Color heroText = CScholarMobileColors.mint;
  static const Color heroBadgeFill = Color(0x3317231E);
  static const Color heroBadgeRim = Color(0x4DF17B5B);

  // ---- Thesis cover art: eight measured two-stop gradients -----------------
  // Decoration only — identity art on a cover, never text backgrounds. Every
  // stop keeps white cover glyphs above 4.5:1.
  static const List<List<Color>> coverGradients = [
    [CScholarMobileColors.greenDeep, CScholarMobileColors.green],
    [CScholarMobileColors.ink, CScholarMobileColors.green2],
    [Color(0xFF1B2330), CScholarMobileColors.lilacInk],
    [Color(0xFF231A17), CScholarMobileColors.coralInk],
    [Color(0xFF14211C), Color(0xFF3E7A63)],
    [Color(0xFF221C2E), Color(0xFF6A5FA8)],
    [Color(0xFF26211A), Color(0xFF8A6A3A)],
    [Color(0xFF102A22), Color(0xFF2F6B55)],
  ];

  // Research-type chips
  static const Color thesisChipBg = CScholarMobileColors.mint;
  static const Color thesisChipFg = CScholarMobileColors.green;
  static const Color capstoneChipBg = CScholarMobileColors.coralSoft;
  static const Color capstoneChipFg = CScholarMobileColors.coralInk;

  // ---- Metric tile tints ----
  static const Color skyTint = CScholarMobileColors.mint;
  static const Color skyInk = CScholarMobileColors.green;
  static const Color violetTint = CScholarMobileColors.lilacSoft;
  static const Color violetInk = CScholarMobileColors.lilacInk;
  static const Color tealTint = CScholarMobileColors.coralSoft;
  static const Color tealInk = CScholarMobileColors.coralInk;
  static const Color cyanTint = CScholarMobileColors.cream;
  static const Color cyanInk = CScholarMobileColors.mutedInk;

  // ---- Canvas & neutral surfaces ----
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = CScholarMobileColors.paper;
  static const Color backgroundSoft = CScholarMobileColors.paper;
  static const Color backgroundDark = CScholarMobileColors.ink;
  static const Color surfaceWhite = CScholarMobileColors.surface;
  static const Color surfaceLight = CScholarMobileColors.surfaceSoft;
  static const Color cardBg = CScholarMobileColors.surface;
  static const Color dividerLight = CScholarMaterial.rim;
  static const Color borderLight = CScholarMaterial.rim;
  static const Color inputBg = CScholarMobileColors.surfaceSoft;
  static const Color surface = CScholarMobileColors.surface;

  // ---- Text ----
  static const Color textPrimary = CScholarMobileColors.ink;
  static const Color textSecondary = CScholarMobileColors.mutedInk;
  static const Color textMuted = CScholarMobileColors.mutedInk;
  static const Color textHint = CScholarMobileColors.muted;
  static const Color shadowColor = Color(0x1423382D);

  // ---- Status ----
  static const Color success = primaryGreen;
  static const Color warning = CScholarMobileColors.coral;
  static const Color warningFg = CScholarMobileColors.coralInk;
  static const Color error = CScholarMobileColors.coralInk;
  static const Color errorLight = CScholarMobileColors.coralSoft;
  static const Color info = CScholarMobileColors.green2;
  static const Color infoLight = CScholarMobileColors.mint;
  static const Color noteBg = CScholarMobileColors.coralSoft;
  static const Color noteRim = CScholarMobileColors.coral;
  static const Color noteIcon = CScholarMobileColors.coralInk;
  static const Color noteInk = CScholarMobileColors.coralInk;

  // Roles
  static const Color studentColor = CScholarMobileColors.green2;
  static const Color facultyColor = CScholarMobileColors.lilacInk;
  static const Color facultyLight = CScholarMobileColors.lilacSoft;
  static const Color adminColor = CScholarMobileColors.coralInk;
  static const Color adminLight = CScholarMobileColors.coralSoft;

  // ---- Chart / progress fills ----
  static const Map<String, Color> statusFill = {
    'published': primaryGreen,
    'approved': info,
    'draft': warningFg,
    'archived': textSecondary,
  };
}

class CScholarTextStyles {
  // Manrope for headings, titles and metric values.
  static TextStyle heading(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  // DM Sans for body, labels, metadata.
  static TextStyle body(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.5,
    double? letterSpacing,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Legacy aliases — both now render the Soft UI pairing. New code should use
  /// [heading] / [body].
  @Deprecated('Use CScholarTextStyles.heading')
  static TextStyle poppins(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
    double? letterSpacing,
  }) => heading(
    size,
    weight,
    color,
    height: height,
    letterSpacing: letterSpacing,
  );

  @Deprecated('Use CScholarTextStyles.body')
  static TextStyle inter(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.5,
    double? letterSpacing,
  }) => body(size, weight, color, height: height, letterSpacing: letterSpacing);

  static TextStyle get h1 =>
      heading(32, FontWeight.w800, CScholarColors.textPrimary, height: 1.2);
  static TextStyle get h2 =>
      heading(24, FontWeight.w700, CScholarColors.textPrimary, height: 1.3);
  static TextStyle get h3 =>
      heading(20, FontWeight.w600, CScholarColors.textPrimary, height: 1.4);
  static TextStyle get h4 =>
      heading(16, FontWeight.w600, CScholarColors.textPrimary, height: 1.4);

  static TextStyle get bodyLarge =>
      body(16, FontWeight.w400, CScholarColors.textPrimary);
  static TextStyle get bodyMedium =>
      body(14, FontWeight.w400, CScholarColors.textPrimary);
  static TextStyle get bodySmall =>
      body(12, FontWeight.w400, CScholarColors.textSecondary);

  static TextStyle get label =>
      body(11, FontWeight.w600, CScholarColors.textSecondary, height: 1.4);
  static TextStyle get labelUppercase => body(
    11,
    FontWeight.w700,
    CScholarColors.textSecondary,
    letterSpacing: 0.5,
  );

  // Canonical page/card/section styles — prefer these over ad-hoc sizes so
  // every screen shares one scale (design plan, item 1).
  static TextStyle get pageTitle => heading(
    26,
    FontWeight.w800,
    CScholarColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static TextStyle get pageSubtitle =>
      body(13, FontWeight.w400, CScholarColors.textMuted);
  static TextStyle get cardTitle =>
      heading(16, FontWeight.w700, CScholarColors.textPrimary);
  static TextStyle get sectionLabel => body(
    12,
    FontWeight.w700,
    CScholarColors.textSecondary,
    letterSpacing: 1.0,
  );
}

class CScholarRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 23;
  static const double full = 999;

  /// Soft UI card + sheet geometry (brief 20–30px rounded-3xl).
  static const double softCard = 23;
  static const double softSheet = 26;

  /// Pill action and input well.
  static const double cta = 22;
  static const double well = 18;

  /// Sidebar / bottom-nav active pill.
  static const double navPill = 17;
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

/// Motion budget v2 — the layer above [CScholarDurations].
///
/// [CScholarDurations] remains the *interaction* budget and keeps its 300ms
/// ceiling (`motion_test.dart` pins `slow == 300ms`): a control that reacts to
/// a tap must answer inside 300ms or it feels laggy. What was missing was
/// anywhere for a *page-level* or *ambient* gesture to live, so every
/// long-running motion in the app ended up crammed into 300ms and nothing
/// could breathe.
///
/// Hence two named budgets, and the rule that decides which one you use:
///
///   * TRANSITION ([micro] .. [page]) — a response to a user action or a route
///     change. Bounded, interruptible, one-shot. Must never exceed [page].
///   * AMBIENT ([breathe], [drift], [shimmer], [pulse]) — a loop that runs
///     while a state holds (idle, live, syncing, loading). Gated by
///     [ambientEnabled], so tests and low-power users never see one.
///
/// Nothing else: if you need a duration that is not here, you are animating
/// the wrong thing.
class CScholarMotion {
  // ------------------------------------------------------------- transition
  /// Press, hover, focus — the twitch a control makes under the pointer.
  static const Duration micro = Duration(milliseconds: 120);

  /// State swap: chip selects, icon morph, error text replaces hint.
  static const Duration swap = Duration(milliseconds: 200);

  /// Entrance for a block: one reveal, or one step of a cascade.
  static const Duration enter = Duration(milliseconds: 280);

  /// Page-level: route transitions, hero flights, the outgoing page's retreat.
  /// This is the ceiling for any one-shot motion in the app.
  static const Duration page = Duration(milliseconds: 360);

  /// Soft UI entrance: brief 300-500ms fade + rise.
  static const Duration softEnter = Duration(milliseconds: 350);

  // ---------------------------------------------------------------- ambient
  /// Slow breath: a halo deepening, an icon tile floating ±2px.
  static const Duration breathe = Duration(milliseconds: 2400);

  /// Very slow wash behind a hero panel. Long enough to be noticed only in
  /// peripheral vision — the point is that it is never seen to loop.
  static const Duration drift = Duration(milliseconds: 16000);

  /// Skeleton shimmer sweep. One full pass.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// How long a load may run before a skeleton is worth painting.
  ///
  /// Anything faster than this is a "loader flash": the placeholder appears and
  /// is replaced before the eye can read it, which is a flicker, not feedback.
  /// Deferred, a fast response lands as content with no placeholder ever
  /// interstitial, and a slow one gets its skeleton at 250ms — the point where
  /// a blank frame starts to feel like a hang.
  static const Duration skeletonDelay = Duration(milliseconds: 250);

  /// Live / syncing indicator pulse.
  static const Duration pulse = Duration(milliseconds: 1200);

  // ------------------------------------------------------------- global gate
  /// Kill switch for ALL looping motion.
  ///
  /// A repeating [AnimationController] makes `pumpAndSettle()` never terminate,
  /// and `screens_render_test.dart` already had to work around this for
  /// `ClayLoader` with a hand-rolled frame budget. That workaround stays, but
  /// the gate makes it explicit and lets a test (or a low-power mode) turn
  /// every loop off in one line. Tests must set
  /// `CScholarMotion.ambientEnabled = false` in `setUp` and restore it in
  /// `tearDown`.
  static bool ambientEnabled = true;
}

/// Named entrance rhythms. A page's delay map is a design decision, so it is
/// named and shared rather than re-invented with magic numbers per screen.
///
/// [step] is the gap between siblings; [max] clamps the last sibling's delay so
/// a long list can never crawl in; [rise] is how far each block travels.
enum MotionPitch {
  /// Dense lists, table rows, chips. Barely a stagger — it reads as one
  /// gesture.
  tight(
    step: Duration(milliseconds: 24),
    max: Duration(milliseconds: 160),
    rise: 8,
  ),

  /// The default for page blocks below a header.
  page(
    step: Duration(milliseconds: 48),
    max: Duration(milliseconds: 240),
    rise: 12,
  ),

  /// Feature cards and KPI strips: a slower, more deliberate walk.
  feature(
    step: Duration(milliseconds: 72),
    max: Duration(milliseconds: 320),
    rise: 16,
  ),

  /// Thesis results, saved studies. Long enough to be seen, clamped hard.
  result(
    step: Duration(milliseconds: 56),
    max: Duration(milliseconds: 280),
    rise: 14,
  );

  const MotionPitch({
    required this.step,
    required this.max,
    required this.rise,
  });
  final Duration step;
  final Duration max;
  final double rise;
}

class CScholarCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOut;

  /// Soft UI entrance: brief `cubic-bezier(0.16, 1, 0.3, 1)` fade + rise.
  static const Curve softEnter = Cubic(0.16, 1, 0.3, 1);

  /// Material 3 "emphasised": fast out, soft landing. Default for anything
  /// that MOVES TO a new place — sliding pill, drawer, hero flight, page push.
  static const Curve settle = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Springy settle for micro-interactions: a save icon, a checkmark, a badge.
  /// The tiny overshoot is what makes a toggle read as physical. Do NOT use it
  /// on anything larger than ~80px — a big surface that overshoots reads as
  /// broken.
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Mirrored exit. Leaving must be faster and less fussy than arriving, so
  /// entrances use [settle] while exits use this.
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Ease-in-out for something that LOOPS (breathe, drift, pulse): the two
  /// halves must be symmetric or the loop visibly hitches at the turnaround.
  static const Curve anticipate = Cubic(0.4, 0.0, 0.6, 1.0);

  /// Only for continuous, constant-rate motion (shimmer sweep, spinner).
  static const Curve steady = Curves.linear;
}

/// Elevation recipes — Soft UI diffuse green-tinted shadows on paper.
class CScholarShadows {
  /// Resting panel.
  static List<BoxShadow> get card => CScholarMaterial.cardShadow();

  /// Hover / raised.
  static List<BoxShadow> get elevated =>
      CScholarMaterial.cardShadow(depth: 1.25);

  /// Hairline elevation (inline rows, chips).
  static List<BoxShadow> get subtle => CScholarMaterial.cardShadow(depth: 0.5);

  /// Coral halo — AI / attention marks only.
  static List<BoxShadow> get goldGlow => CScholarMaterial.goldGlow();

  /// Green halo for the active nav pill and selected states.
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: CScholarColors.primaryGreen.withValues(alpha: 0.22),
      blurRadius: 16,
      offset: const Offset(0, 6),
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
