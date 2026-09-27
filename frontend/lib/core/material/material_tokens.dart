import 'package:flutter/material.dart';

/// CScholar Material System — clay + neumorphism + glass (design lab v3).
///
/// THE FUSION LAW: one style per structural role, never two on one element.
///   canvas + content panels -> clay        (matte, tinted, same hue family)
///   anything pressable      -> neumorphism (raised <-> pressed inset)
///   identity objects        -> clay + gel  (avatars, tiles, covers, badges)
///   floating chrome/overlay -> glass       (topbar, rail, search, dialogs)
///
/// Clay and canvas MUST share a hue family. Neumorphism only reads as light +
/// shadow when the surface and its background are the same colour — this is
/// why the canvas moved off the old near-white (#F8FAFC / #F2F7F1).
///
/// Contrast values in [ratios] were measured (WCAG 2.1). Keep them in sync.
class CScholarMaterial {
  CScholarMaterial._();

  // ---------------------------------------------------------------- canvas
  /// Page base. Deeper than the clay surface so highlights can read.
  static const Color canvas = Color(0xFFE8EFE7);

  /// Content panels: same hue as [canvas], ~4% lighter.
  static const Color clay = Color(0xFFF1F6F0);

  /// Top-left stop of the clay "inflate" gradient.
  static const Color clayHigh = Color(0xFFFAFCF9);

  /// Recessed wells: input fields, tracks, table stripes.
  static const Color clayDeep = Color(0xFFE3EBE1);

  /// Shadows are TINTED, never black. Black-alpha shadows on white are what
  /// stop neumorphism from reading correctly.
  static const Color shadowDark = Color(0xFFC9D6C6);
  static const Color shadowLight = Color(0xFFFFFFFF);

  /// 1px affordance backstop (subtle by design: 1.46:1 on clay).
  /// Neumorphic controls always carry this — shadows alone are not an
  /// affordance (high contrast, cheap panels, low vision).
  static const Color rim = Color(0xFFC3D0C0);

  /// Rim used when high contrast is on: 6.92:1 on clay.
  static const Color rimStrong = Color(0xFF475569);

  // ------------------------------------------------------------------- gel
  /// Gel accent (clay-styled fills). White text is safe at/below [gelTop].
  static const Color gelTop = Color(0xFF007A14);
  static const Color gelBottom = Color(0xFF00610F);
  static const Color gelDeep = Color(0xFF004A0B);

  /// NON-TEXT surfaces only (3.36:1 with white text).
  static const Color gelHigh = Color(0xFF00A31B);

  /// Decoration only — 1.17:1 on clay, 8.46:1+ on dark green.
  static const Color goldTop = Color(0xFFF9DC07);
  static const Color goldBottom = Color(0xFFCA8A04);

  /// Hot centre of the gold halo — paler than [goldTop] so the glow reads as
  /// emitted light rather than a flat gold pill.
  static const Color goldCore = Color(0xFFFFE066);

  /// Gradient for gold "gel" objects (prestige / AI marks).
  /// Dark glyphs only: #0F172A measures 12.98:1 on [goldTop] and 6.08:1 on
  /// [goldBottom]. White on gold is 1.38:1 — never do it.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldTop, goldBottom],
  );

  // ------------------------------------------------------------------ text
  /// 16.31:1 on clay.
  static const Color textPrimary = Color(0xFF0F172A);

  /// 6.92:1 on clay. The lightest text token allowed on clay or glass.
  static const Color textMuted = Color(0xFF475569);

  /// 5.06:1 on clay. Use instead of #009900 whenever green carries text.
  static const Color textGreen = Color(0xFF007A14);

  /// 4.35:1 on clay — white surfaces only, never clay/glass.
  static const Color textFaint = Color(0xFF64748B);

  // ----------------------------------------------------------------- glass
  static const Color glassChrome = Color(0x9EFFFFFF); // ~.62 white
  static const Color glassOverlay = Color(0xB8FFFFFF); // ~.72 white
  static const Color glassRim = Color(0x8CFFFFFF);
  static const Color glassSpecular = Color(0x47FFFFFF);
  static const Color scrim = Color(0x470F172A);

  static const double blurChrome = 18;
  static const double blurOverlay = 28;

  /// Global kill switch (low-power mode, blur-heavy screens, list items).
  /// High contrast disables blur per-panel via `MediaQuery.highContrastOf`.
  static bool glassEnabled = true;

  // ------------------------------------------------------------- recipes
  /// Raised clay shadow pair: tinted dark bottom-right + white top-left.
  static List<BoxShadow> clayDrop({double depth = 1}) => [
        BoxShadow(
          color: shadowDark.withValues(alpha: (0.55 * depth).clamp(0.0, 1.0)),
          blurRadius: 18 * depth,
          offset: Offset(0, 10 * depth),
          spreadRadius: -6 * depth,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: (0.85 * depth).clamp(0.0, 1.0)),
          blurRadius: 10 * depth,
          offset: const Offset(-6, -6),
        ),
      ];

  /// Inner bottom shadow — this is what makes clay look inflated rather
  /// than merely dropped. Painted by `InsetShadow`.
  static List<BoxShadow> clayInset({double strength = 1}) => [
        BoxShadow(
          color: shadowDark.withValues(alpha: (0.28 * strength).clamp(0.0, 1.0)),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  /// Inner shadow for pressed neumorphic controls (top-left, like a well).
  static List<BoxShadow> pressInset({double strength = 1}) => [
        BoxShadow(
          color: const Color(0xFF003F09).withValues(alpha: (0.42 * strength).clamp(0.0, 1.0)),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  /// Gel shadow for identity objects.
  static List<BoxShadow> gelDrop({double depth = 1}) => [
        BoxShadow(
          color: gelDeep.withValues(alpha: (0.30 * depth).clamp(0.0, 1.0)),
          blurRadius: 16 * depth,
          offset: Offset(0, 8 * depth),
          spreadRadius: -4,
        ),
      ];

  /// Gold halo — the ONLY coloured shadow in the system.
  ///
  /// Three layers: a tight hot core, a mid bloom, and a wide warm falloff. One
  /// shadow alone reads as a coloured drop shadow; the layered falloff is what
  /// makes it read as light being emitted.
  ///
  /// Rules: gold objects take [goldGradient] with a DARK glyph (white on gold
  /// is 1.38:1), put it on <= 2-3 elements per screen, never behind text, and
  /// let high contrast drop it entirely (it is decoration).
  static List<BoxShadow> goldGlow({double strength = 1}) => [
        BoxShadow(
          color: goldCore.withValues(alpha: (0.70 * strength).clamp(0.0, 1.0)),
          blurRadius: 8,
        ),
        BoxShadow(
          color: goldTop.withValues(alpha: (0.40 * strength).clamp(0.0, 1.0)),
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: goldBottom.withValues(alpha: (0.22 * strength).clamp(0.0, 1.0)),
          blurRadius: 44,
          spreadRadius: 4,
          offset: const Offset(0, 4),
        ),
      ];

  /// Measured WCAG 2.1 ratios — the audit trail for this system.
  static const Map<String, double> ratios = {
    'white on gel dark stop #007A14': 5.54,
    'text primary on clay': 16.31,
    'text muted #475569 on clay': 6.92,
    'green text #007A14 on clay': 5.06,
    'glass composite (white .62 over canvas)': 16.83,
    'white on dark forest #033F15': 12.17,
    'brand #009900 as text on clay (graphics only)': 3.23,
    'gold #F9DC07 on clay (decoration only)': 1.26,
    'dark glyph #0F172A on gold top': 12.98,
    'dark glyph #0F172A on gold bottom': 6.08,
    'white glyph on gold (never)': 1.38,
    'text faint #64748B on clay (avoid)': 4.35,
  };
}
