import 'package:flutter/material.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';

/// CScholar Material System — Soft UI v4.
///
/// The mobile shell is the single source of truth. Every value here resolves
/// through [CScholarPalette], so the web and mobile can never drift: warm paper
/// canvas (green-black at night), floating cards, soft diffuse shadows,
/// extra-rounded geometry.
///
/// THE FUSION LAW stays: one style per structural role.
///   canvas + content panels -> surface card (fill + hairline + soft shadow)
///   anything pressable      -> green pill (press sinks to 0.96)
///   identity objects        -> mint / coral / lilac tinted tiles
///   floating chrome         -> surface + overlay shadow (no blur)
///
/// These are GETTERS, not constants: the palette moves under them when the
/// light/dark mode flips. Read them at paint time; never cache them in a
/// `const` or a long-lived field.
///
/// Contrast values in [ratios] were measured on the light palette (WCAG 2.1).
/// Dark pairs are measured next to their tokens in [CScholarPalette].
class CScholarMaterial {
  CScholarMaterial._();

  static CScholarPalette get _p => CScholarPalette.active;

  // ---------------------------------------------------------------- canvas
  /// Page base: warm paper, `#17201C` at night.
  static Color get canvas => _p.paper;

  /// Content panels: `#FFFEFA` by day, `#202A25` by night.
  static Color get clay => _p.surface;

  /// Legacy alias — surfaces are flat now.
  static Color get clayHigh => _p.surface;

  /// The house fill for recessed controls: segmented tracks, text fields,
  /// selects, search bars, checkbox/switch wells, and skeleton bases.
  static Color get clayDeep => _p.surfaceSoft;

  /// Deeper well, kept for places where [clayDeep] would disappear against
  /// paper: the off-state toggle track and the loading skeleton base.
  ///
  /// One full step deeper than [clayDeep], which sits ~1.04:1 against the paper
  /// canvas: at that distance the control has no edge. With no rim at rest the
  /// fill IS the affordance, so it has to clear the distance on its own —
  /// ~1.21:1 on paper, ~1.29:1 on a card, while hint ink still measures 4.6:1
  /// on it. Inputs and selects intentionally use [clayDeep] now.
  static Color get well => _p.isDark
      ? CScholarMobileColors.surfaceSoftDark
      : const Color(0xFFDDE3D6);

  /// Loading skeletons: the block tone and the shimmer highlight that travels
  /// over it.
  ///
  /// The light pair is a step BELOW the surface; on dark paper that step would
  /// become a glowing white block, so the dark pair sits a step ABOVE the dark
  /// canvas instead — ~1.37:1 on `paperDark`, ~1.21:1 inside a dark card.
  static Color get skeletonBase => _p.skeletonBase;
  static Color get skeletonHighlight => _p.skeletonHighlight;

  /// Legacy aliases kept for the hand-tuned dark pair.
  static const Color skeletonBaseDark = Color(0xFF2C3833);
  static const Color skeletonHighlightDark = Color(0xFF3C4A43);

  /// Shadows are TINTED green-black, never pure black.
  static Color get shadowDark => _p.accentDeep;

  /// Pure white — a FILL, not a shadow.
  static Color get shadowLight => _p.specular;

  /// Soft UI hairline. Opaque so contrast audits measure what the eye sees
  /// (`ink @ 9%` composited on the surface). Fields and buttons carry no rim at
  /// rest; focus and error rings mark state. High contrast swaps this for
  /// [rimStrong].
  static Color get rim => _p.hairline;

  /// Rim used when high contrast is on, and the focus ring in both modes.
  static Color get rimStrong => _p.accent;

  // ------------------------------------------------------- status-chip rims
  static Color get rimPublished => _p.rimSuccess;
  static Color get rimApproved => _p.rimLilac;
  static Color get rimDraft => _p.rimCoral;
  static Color get rimFaculty => _p.rimLilac;

  /// Neutral chip fill used by the "other / inactive" badge.
  static Color get chipNeutral => _p.surfaceSoft;

  // ------------------------------------------------------------------- gel
  /// Text-safe green — the ink used by selected chips, links and focus rings.
  static Color get gelTop => _p.accent;
  static Color get gelBottom => _p.accentBright;
  static Color get gelDeep => _p.accentDeep;
  static Color get gelHigh => _p.accentBright;

  /// Solid green FILL that carries white text (buttons, avatars, icon tiles).
  /// Split from [gelTop] because a fill must stay deep on dark paper while ink
  /// must go light — one green cannot do both.
  static Color get actionFill => _p.action;
  static Color get actionFillPressed => _p.actionPressed;
  static Color get actionFillDeep => _p.actionDeep;

  /// Bottom stop of the RESTING green fill (the gel gradients on pills, tiles,
  /// avatars and covers).
  ///
  /// Light is the mobile shell's flat `#174F3D`: a light fill that ended on the
  /// pressed green made every web control read one step darker than the same
  /// control in the app. Dark keeps [actionFillPressed] — the dark gel was
  /// already matched to the app and is unchanged.
  static Color get actionFillRest => _p.isDark ? _p.actionPressed : _p.action;

  /// Solid destructive fill (white text) and its pressed step.
  static Color get dangerFill => _p.dangerFill;
  static Color get dangerFillPressed => _p.dangerFillPressed;

  /// Attention / AI accent. Gold retired; coral carries prestige marks now.
  static Color get goldTop => _p.coral;
  static Color get goldBottom =>
      _p.isDark ? const Color(0xFF7A2E1C) : _p.danger;
  static Color get goldCore => _p.coralSoft;

  /// Glyph ink for the prestige tile (dark on the light coral gradient, warm
  /// white on the deep dark one).
  static Color get prestigeInk => _p.prestigeInk;

  static LinearGradient get goldGradient => _p.prestigeGradient;

  // ------------------------------------------------------------------ text
  static Color get textPrimary => _p.ink;
  static Color get textMuted => _p.mutedInk;
  static Color get textGreen => _p.accent;
  static Color get textFaint => _p.mutedInk;
  static Color get textBody => _p.ink;

  // ----------------------------------------------------------------- glass
  // Glass retires: the Soft UI brief is flat surfaces with diffuse shadows.
  // The API stays so callers compile; panels render solid.
  static Color get glassChrome => _p.surface;
  static Color get glassOverlay => _p.surface;
  static Color get glassRim => _p.hairline;
  static const Color glassSpecular = Color(0x00FFFFFF);
  static Color get scrim => _p.scrim;

  static const double blurChrome = 0;
  static const double blurOverlay = 0;

  /// Kept for compatibility; the surface treatment ignores it.
  static bool glassEnabled = false;

  // ------------------------------------------------------------- recipes
  /// The card recipe: two diffuse layers on the canvas.
  static List<BoxShadow> cardShadow({double depth = 1}) =>
      _p.cardShadow(depth: depth);

  /// Legacy name — same card recipe.
  static List<BoxShadow> softShadow({double depth = 1}) =>
      cardShadow(depth: depth);

  static List<BoxShadow> clayDrop({double depth = 1}) =>
      cardShadow(depth: depth);

  /// Green shadow for identity objects.
  static List<BoxShadow> gelDrop({double depth = 1}) => [
    BoxShadow(
      color: actionFillDeep.withValues(alpha: (0.22 * depth).clamp(0.0, 1.0)),
      blurRadius: 18 * depth,
      offset: Offset(0, 8 * depth),
    ),
  ];

  /// Soft coral halo — AI / attention marks only.
  static List<BoxShadow> goldGlow({double strength = 1}) => [
    BoxShadow(
      color: _p.coral.withValues(alpha: (0.28 * strength).clamp(0.0, 1.0)),
      blurRadius: 18,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: _p.coral.withValues(alpha: (0.14 * strength).clamp(0.0, 1.0)),
      blurRadius: 40,
      offset: const Offset(0, 6),
    ),
  ];

  /// Floating chrome / dialogs.
  static List<BoxShadow> get overlay => CScholarMobileShadows.overlay;

  /// Measured WCAG 2.1 ratios — the audit trail for this system (light mode).
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
    // ---- dark ----
    'ink #EDF5EF on paperDark #17201C': 14.6,
    'muted ink #A9B5AE on surfaceDark #202A25': 7.5,
    'accent #80C4A6 on surfaceDark #202A25': 8.4,
    'accent #80C4A6 on mintDark #203C31': 6.6,
    'white on action #174F3D (dark fills)': 9.45,
    'danger #FF8F7A on surfaceDark #202A25': 7.3,
    'lilac ink #B7AEE8 on surfaceDark #202A25': 7.9,
    'hint #7F8C85 on paperDark (placeholders only)': 4.3,
  };
}
