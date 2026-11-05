import 'package:flutter/material.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';

/// CScholar Material System — Soft UI v4.
///
/// The mobile shell is now the single source of truth. Every value here aliases
/// [CScholarMobileColors] / [CScholarMobileShadows], so the web and mobile can
/// never drift: warm paper canvas, near-white floating cards, soft green-tinted
/// diffuse shadows, extra-rounded geometry.
///
/// THE FUSION LAW stays: one style per structural role.
///   canvas + content panels -> surface card (fill + hairline + soft shadow)
///   anything pressable      -> green pill (press sinks to 0.96)
///   identity objects        -> mint / coral / lilac tinted tiles
///   floating chrome         -> surface + overlay shadow (no blur)
///
/// Contrast values in [ratios] were measured (WCAG 2.1). Keep them in sync.
class CScholarMaterial {
  CScholarMaterial._();

  // ---------------------------------------------------------------- canvas
  /// Page base: warm paper `#F8F6F0`.
  static const Color canvas = CScholarMobileColors.paper;

  /// Content panels: `#FFFEFA` floating on the paper canvas.
  static const Color clay = CScholarMobileColors.surface;

  /// Legacy alias — surfaces are flat now.
  static const Color clayHigh = CScholarMobileColors.surface;

  /// Recessed wells: input fields, tracks, skeleton bases. `#F1F3ED`.
  static const Color clayDeep = CScholarMobileColors.surfaceSoft;

  /// Input wells only — search bars, fields, selects.
  ///
  /// One full step deeper than [clayDeep], which sits ~1.04:1 against the paper
  /// canvas: at that distance the well has no edge and an empty search bar
  /// reads as blank space. With no rim at rest the fill IS the affordance, so
  /// it has to clear the distance on its own — ~1.21:1 on paper, ~1.29:1 on a
  /// card, while hint ink still measures 4.6:1 on it.
  static const Color well = Color(0xFFDDE3D6);

  /// Loading skeletons: the block tone and the shimmer highlight that travels
  /// over it.
  ///
  /// Skeletons used [clayDeep], which measures 1.04:1 on the paper canvas — the
  /// mobile shell loaded onto what looked like a blank page. This is the same
  /// step the well takes, so a skeleton is findable on paper and inside a card,
  /// and the sweep runs up to the card surface.
  static const Color skeletonBase = well;
  static const Color skeletonHighlight = CScholarMobileColors.surface;

  /// The same two tones for the dark shell.
  ///
  /// The light pair is a step BELOW the surface; on dark paper that step turns
  /// into a glowing white block. These sit a step ABOVE the dark canvas
  /// instead — ~1.37:1 on `paperDark`, ~1.21:1 inside a dark card.
  static const Color skeletonBaseDark = Color(0xFF2C3833);
  static const Color skeletonHighlightDark = Color(0xFF3C4A43);

  /// Shadows are TINTED green-black, never pure black.
  static const Color shadowDark = CScholarMobileColors.greenDeep;

  /// Pure white — a FILL, not a shadow.
  static const Color shadowLight = Color(0xFFFFFFFF);

  /// Soft UI hairline. Opaque so contrast audits measure what the eye sees
  /// (`ink @ 9%` composited on the surface). Fields and buttons carry no rim at
  /// rest; focus and error rings mark state. High contrast swaps this for
  /// [rimStrong].
  static const Color rim = Color(0xFFEAEAE6);

  /// Rim used when high contrast is on.
  static const Color rimStrong = CScholarMobileColors.green;

  // ------------------------------------------------------- status-chip rims
  static const Color rimPublished = CScholarMobileColors.mint;
  static const Color rimApproved = CScholarMobileColors.lilacSoft;
  static const Color rimDraft = CScholarMobileColors.coralSoft;
  static const Color rimFaculty = CScholarMobileColors.lilacSoft;

  /// Neutral chip fill used by the "other / inactive" badge.
  static const Color chipNeutral = CScholarMobileColors.surfaceSoft;

  // ------------------------------------------------------------------- gel
  static const Color gelTop = CScholarMobileColors.green;
  static const Color gelBottom = CScholarMobileColors.green2;
  static const Color gelDeep = CScholarMobileColors.greenDeep;
  static const Color gelHigh = CScholarMobileColors.green2;

  /// Attention / AI accent. Gold retired; coral carries prestige marks now.
  static const Color goldTop = CScholarMobileColors.coral;
  static const Color goldBottom = CScholarMobileColors.coralInk;
  static const Color goldCore = CScholarMobileColors.coralSoft;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldTop, goldBottom],
  );

  // ------------------------------------------------------------------ text
  static const Color textPrimary = CScholarMobileColors.ink;
  static const Color textMuted = CScholarMobileColors.mutedInk;
  static const Color textGreen = CScholarMobileColors.green;
  static const Color textFaint = CScholarMobileColors.mutedInk;
  static const Color textBody = Color(0xFF2F3B35);

  // ----------------------------------------------------------------- glass
  // Glass retires: the Soft UI brief is flat surfaces with diffuse shadows.
  // The API stays so callers compile; panels render solid.
  static const Color glassChrome = CScholarMobileColors.surface;
  static const Color glassOverlay = CScholarMobileColors.surface;
  static const Color glassRim = CScholarMobileColors.line;
  static const Color glassSpecular = Color(0x00FFFFFF);
  static const Color scrim = Color(0x59231D18);

  static const double blurChrome = 0;
  static const double blurOverlay = 0;

  /// Kept for compatibility; the surface treatment ignores it.
  static bool glassEnabled = false;

  // ------------------------------------------------------------- recipes
  /// The card recipe: two diffuse green-tinted layers on the paper canvas.
  static List<BoxShadow> cardShadow({double depth = 1}) => [
    BoxShadow(
      color: const Color(0x1323382D)
          .withValues(alpha: (0.075 * depth).clamp(0.0, 1.0)),
      blurRadius: 28 * depth,
      offset: Offset(0, 12 * depth),
    ),
    BoxShadow(
      color: const Color(0x0923382D)
          .withValues(alpha: (0.035 * depth).clamp(0.0, 1.0)),
      blurRadius: 6 * depth,
      offset: Offset(0, 2 * depth),
    ),
  ];

  /// Legacy name — same card recipe.
  static List<BoxShadow> softShadow({double depth = 1}) =>
      cardShadow(depth: depth);

  static List<BoxShadow> clayDrop({double depth = 1}) =>
      cardShadow(depth: depth);

  /// Green shadow for identity objects.
  static List<BoxShadow> gelDrop({double depth = 1}) => [
    BoxShadow(
      color: gelDeep.withValues(alpha: (0.22 * depth).clamp(0.0, 1.0)),
      blurRadius: 18 * depth,
      offset: Offset(0, 8 * depth),
    ),
  ];

  /// Soft coral halo — AI / attention marks only.
  static List<BoxShadow> goldGlow({double strength = 1}) => [
    BoxShadow(
      color: CScholarMobileColors.coral.withValues(
        alpha: (0.28 * strength).clamp(0.0, 1.0),
      ),
      blurRadius: 18,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: CScholarMobileColors.coral.withValues(
        alpha: (0.14 * strength).clamp(0.0, 1.0),
      ),
      blurRadius: 40,
      offset: const Offset(0, 6),
    ),
  ];

  /// Floating chrome / dialogs.
  static List<BoxShadow> get overlay => CScholarMobileShadows.overlay;

  /// Measured WCAG 2.1 ratios — the audit trail for this system.
  static const Map<String, double> ratios = {
    'ink on paper': 15.0,
    'muted ink #5A665F on paper': 5.55,
    'muted ink #5A665F on surface': 5.94,
    'white on green #174F3D': 9.45,
    'green2 #2D7159 on paper': 5.38,
    'green #174F3D on mint': 7.26,
    'coral ink #A63E25 on coral soft': 5.17,
    'lilac ink #5B5194 on lilac soft': 5.53,
    'white on green2 #2D7159': 5.38,
    'hint #748079 on paper (placeholders only)': 3.81,
    'cover white on green #174F3D': 9.45,
  };
}
