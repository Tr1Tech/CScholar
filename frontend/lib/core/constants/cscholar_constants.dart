import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// Design tokens for the whole app.
///
/// SOFT UI v4 — the mobile shell is the single source of truth. Every value
/// here resolves through [CScholarPalette], so desktop and mobile share one
/// definition and both follow the app-wide light/dark mode: paper canvas,
/// near-white cards (dark green-black at night), soft tinted shadows, Manrope
/// headings and DM Sans body copy.
///
/// The members are GETTERS, not `const`s, precisely so a mode switch can move
/// them. `CScholarPalette.active` is the current resolution; [CScholarApp]
/// clicks it over before anything reads it. Never cache one of these into a
/// `const` or into a long-lived field — read it where you paint.
///
/// Contrast note: raw accents (`coral`, `lilac`, `muted`) are FILL colours. Body
/// copy uses the text-safe inks ([CScholarPalette.danger], [lilacInk],
/// [mutedInk]) which clear 4.5:1 on the canvas and on their own tints in BOTH
/// modes.
class CScholarColors {
  static CScholarPalette get _p => CScholarPalette.active;

  // ---- Brand green -------------------------------------------------------
  /// Text-safe brand green: links, icons, selected ink, small accents.
  static Color get primaryGreen => _p.accent;

  /// Brighter green ink: eyebrows, hover ink, status dots.
  static Color get primaryGreenHover => _p.accentBright;

  /// Pressed / deepest green.
  static Color get primaryGreenDark => _p.accentDeep;

  /// Tint behind green ink (active pill, published chip, metric tile).
  static Color get primaryGreenLight => _p.mint;

  /// Deeper tint: selected rows, hover wash, segmented track.
  static Color get primaryGreenVeryLight => _p.surfaceSoft;

  /// Solid green FILL: white text sits on this. On dark it is a deep green,
  /// never the mint ink — that split is what keeps buttons legible at night.
  static Color get primaryFill => _p.action;

  /// Pressed solid fill.
  static Color get primaryFillPressed => _p.actionPressed;

  /// Deepest solid fill.
  static Color get primaryFillDeep => _p.actionDeep;

  /// Ink that rides on [primaryFill] / [primaryFillPressed].
  static Color get onPrimaryFill => white;

  // Sidebars are light floating cards now. Legacy names are kept so old
  // references compile; they resolve to the brand green for glyphs/active ink.
  static Color get forest => primaryGreen;
  static Color get sidebarDeep => forest;
  static Color get sidebarHover => primaryGreenHover;
  static Color get sidebarActive => forest;
  static Color get adminSidebar => forest;
  static Color get adminSidebarHover => primaryGreenHover;
  static Color get repoSidebar => forest;
  static Color get repoActive => forest;
  static Color get savedSidebarActive => forest;

  /// Role accent dot / chip.
  static Map<String, Color> get roleAccent => {
    'student': CScholarColors.studentColor,
    'faculty': CScholarColors.facultyColor,
    'admin': CScholarColors.adminColor,
  };

  // Accents — gold retires; coral is the attention / AI accent.
  static Color get gold => _p.coral;
  static Color get goldLight => _p.coralSoft;
  static Color get goldDeep => _p.danger;
  static Color get goldSoft => _p.coralSoft;
  static Color get orange => _p.coral;
  static Color get orangeLight => _p.coralSoft;

  // Shell: paper canvas, floating surface sidebar, mint active pill.
  static Color get shellWash => _p.paper;
  static Color get sidebarLight => _p.surface;
  static Color get sidebarLightBorder => _p.line;
  static Color get navActiveBg => primaryFill;
  static Color get heroDeep => _p.accentDeep;
  static Color get heroMid => _p.accent;
  static Color get heroGlow => _p.accentBright;
  static Color get heroBase => _p.accentDeep;
  static Color get heroFloor => _p.accentDeep;
  static Color get heroText => _p.mint;
  static const Color heroBadgeFill = Color(0x3317231E);
  static const Color heroBadgeRim = Color(0x4DF17B5B);

  // ---- Thesis cover art: eight measured two-stop gradients -----------------
  // Identity art, not chrome: every stop is a DARK tone that carries white
  // cover glyphs above 4.5:1, so the set is deliberately mode-STABLE. Flipping
  // it would put white glyphs on a pale banner.
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

  // Research-type chips. Type is identity, never alarm: both Thesis and
  // Capstone use the brand green system. Coral is reserved for
  // destructive/error UI.
  static Color get thesisChipBg => _p.mint;
  static Color get thesisChipFg => _p.accent;
  static Color get capstoneChipBg => _p.mint;
  static Color get capstoneChipFg => _p.accent;

  // ---- Metric tile tints ----
  static Color get skyTint => _p.mint;
  static Color get skyInk => _p.accent;
  static Color get violetTint => _p.lilacSoft;
  static Color get violetInk => _p.lilacInk;
  static Color get tealTint => _p.coralSoft;
  static Color get tealInk => _p.danger;
  static Color get cyanTint => _p.surfaceWarm;
  static Color get cyanInk => _p.mutedInk;

  // ---- Canvas & neutral surfaces ----
  static const Color white = Color(0xFFFFFFFF);
  static Color get backgroundLight => _p.paper;
  static Color get backgroundSoft => _p.paper;

  /// A fixed ink slab (cover art / contrast fixtures) — never flips.
  static const Color backgroundDark = CScholarMobileColors.ink;
  static Color get surfaceWhite => _p.surface;
  static Color get surfaceLight => _p.surfaceSoft;
  static Color get cardBg => _p.surface;
  static Color get dividerLight => CScholarMaterial.rim;
  static Color get borderLight => CScholarMaterial.rim;
  static Color get inputBg => _p.surfaceSoft;
  static Color get surface => _p.surface;

  // ---- Text ----
  static Color get textPrimary => _p.ink;
  static Color get textSecondary => _p.mutedInk;
  static Color get textMuted => _p.mutedInk;
  static Color get textHint => _p.hint;
  static const Color shadowColor = Color(0x1423382D);

  // ---- Status ----
  static Color get success => _p.accent;
  static Color get warning => _p.coral;
  static Color get warningFg => _p.danger;
  static Color get error => _p.danger;
  static Color get errorLight => _p.coralSoft;
  static Color get info => _p.accentBright;
  static Color get infoLight => _p.mint;
  static Color get noteBg => _p.coralSoft;
  static Color get noteRim => _p.coral;
  static Color get noteIcon => _p.danger;
  static Color get noteInk => _p.danger;

  // Roles
  static Color get studentColor => _p.accentBright;
  static Color get facultyColor => _p.lilacInk;
  static Color get facultyLight => _p.lilacSoft;
  static Color get adminColor => _p.danger;
  static Color get adminLight => _p.coralSoft;

  // ---- Chart / progress fills ----
  static Map<String, Color> get statusFill => {
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

/// The interaction floor (A11Y-1).
///
/// Every pressable surface — icon buttons, pagers, filter chips, search-clear
/// buttons, close buttons, inline links — must expose at least
/// [minimum]×[minimum] logical pixels of HIT AREA, not just a glyph that size.
/// [primary] is the minimum height for a primary action.
///
/// Use these instead of re-typing 44/48 at call sites: a raw number is how a
/// target quietly shrinks during a later "tighten the row" pass.
class CScholarTapTarget {
  /// Absolute floor for any interactive target.
  static const double minimum = 44;

  /// Primary actions (submit, sign in, save) should clear this.
  static const double primary = 48;

  /// Small square target used by icon actions in dense rows.
  static const Size square = Size(minimum, minimum);
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

  /// The one light/dark palette swap.
  ///
  /// Deliberately OUTSIDE the interaction budget: this is not a control
  /// answering a tap (the switch pops its glyph immediately), it is the whole
  /// interface changing material. An iris wipe expands from the switch until it
  /// has passed the farthest corner; nothing fades.
  ///
  /// 720 ms is the measured "swell": at 480 ms the circle crossed the viewport
  /// before the eye had read it as a wipe, which is what made the switch feel
  /// like a cut with a flicker on it.
  static const Duration themeSwap = Duration(milliseconds: 720);

  /// How long the theme wipe will wait for the frame it freezes before falling
  /// back to a simpler transition. A capture is normally 5–20 ms; waiting
  /// longer leaves the tap with no visible answer for longer than it takes the
  /// eye to notice.
  static const Duration themeCapture = Duration(milliseconds: 90);

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

  /// Iris-wipe expansion: a swell, not a swipe.
  ///
  /// [settle] front-loads — it is built for a control that must answer
  /// immediately — which on a full-viewport wipe covers half the screen before
  /// the eye has read it as a wipe. This curve spends its time in the middle,
  /// where the circle is crossing actual content, and lands slowly.
  static const Curve reveal = Cubic(0.32, 0.0, 0.18, 1.0);

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
