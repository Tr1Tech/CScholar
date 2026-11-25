import 'package:flutter/material.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';

/// The app-wide palette — light and dark resolved from ONE definition.
///
/// ## Why this exists
///
/// The web/desktop UI was built on `static const` colour tokens
/// ([CScholarColors], [CScholarMaterial]) that alias the mobile shell's
/// [CScholarMobileColors]. A `const` cannot flip, so desktop was light-only.
///
/// Those two token classes now resolve through [CScholarPalette.active]: every
/// member became a getter, so all ~650 existing call sites (`CScholarColors.textPrimary`,
/// `CScholarMaterial.clay`, …) follow the mode without being rewritten.
///
/// ## The two rules that keep it honest
///
/// 1. **[CScholarApp] owns the mode.** It calls [activate] before its subtree
///    builds, so the palette that is read is always the palette that was just
///    painted. Nothing else may call [activate].
/// 2. **A palette change must reach the pages.** The Navigator caches the page
///    widget it was handed, so rebuilding `MaterialApp` with a new theme never
///    rebuilds a route (probe: `test/theme_mode_test.dart`). Routes are
///    therefore wrapped in [CScholarPaletteRebuild], which depends on
///    [CScholarPaletteScope]; flipping `isDark` rebuilds every mounted page.
///
/// ## Dark accents
///
/// Light reuses one green (`#174F3D`) for both ink and solid fill. That cannot
/// work on a dark canvas: a fill that carries white text must stay dark, while
/// ink that sits on a dark surface must become light. The palette therefore
/// splits the two roles:
///
///   * [accent] / [accentBright] — text-safe greens, light on dark.
///   * [action] / [actionPressed] — solid fills that carry white text.
///
/// Everything else keeps its role and only moves value, so a screen written
/// against the tokens reads correctly in both modes.
class CScholarPalette {
  const CScholarPalette({
    required this.isDark,
    required this.paper,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceWarm,
    required this.mint,
    required this.ink,
    required this.mutedInk,
    required this.hint,
    required this.hairline,
    required this.line,
    required this.accent,
    required this.accentBright,
    required this.accentDeep,
    required this.action,
    required this.actionPressed,
    required this.actionDeep,
    required this.coral,
    required this.coralSoft,
    required this.danger,
    required this.dangerFill,
    required this.dangerFillPressed,
    required this.lilac,
    required this.lilacSoft,
    required this.lilacInk,
    required this.rimSuccess,
    required this.rimLilac,
    required this.rimCoral,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.scrim,
  });

  /// True for the dark resolution.
  final bool isDark;

  // ---------------------------------------------------------------- surfaces
  /// Page base.
  final Color paper;

  /// Cards, panels, floating sidebar, dialogs.
  final Color surface;

  /// Recessed fills: text fields, selects, tracks, skeletons.
  final Color surfaceSoft;

  /// Alternate warm wash (metric tiles).
  final Color surfaceWarm;

  /// Active pill / success tint / role tint.
  final Color mint;

  // -------------------------------------------------------------------- text
  /// Headings and body copy.
  final Color ink;

  /// Secondary copy: labels, metadata.
  final Color mutedInk;

  /// Placeholders only.
  final Color hint;

  // ------------------------------------------------------------------- edges
  /// Opaque hairline (card rims, dividers).
  final Color hairline;

  /// Alpha hairline (the shell's own edges).
  final Color line;

  // ----------------------------------------------------------------- accents
  /// Text-safe brand green: links, icons, selected ink.
  final Color accent;

  /// Brighter green ink: eyebrows, status dots, hover ink.
  final Color accentBright;

  /// Pressed / deepest green.
  final Color accentDeep;

  /// Solid green FILL. White text on it clears AA in both modes.
  final Color action;

  /// Pressed solid fill.
  final Color actionPressed;

  /// Deepest solid fill.
  final Color actionDeep;

  /// Attention / AI accent (raw fill).
  final Color coral;
  final Color coralSoft;

  /// Text-safe destructive ink.
  final Color danger;

  /// Solid destructive FILL (white text on it) and its pressed step.
  final Color dangerFill;
  final Color dangerFillPressed;

  /// Faculty identity accent.
  final Color lilac;
  final Color lilacSoft;
  final Color lilacInk;

  // ------------------------------------------------------------ status rims
  final Color rimSuccess;
  final Color rimLilac;
  final Color rimCoral;

  // -------------------------------------------------------------- skeleton
  final Color skeletonBase;
  final Color skeletonHighlight;

  /// Modal scrim.
  final Color scrim;

  /// Specular white — a FILL on cover art, never a shadow.
  Color get specular => const Color(0xFFFFFFFF);

  // ---------------------------------------------------------------- recipes
  /// Two diffuse layers, tinted green-black on paper and a soft black lift on
  /// dark. Dark needs more alpha than light to register at all, but a heavy
  /// black halo reads as a smudge on the near-black canvas — the dark recipe
  /// stops at roughly three times the light alphas, never the old 42%.
  List<BoxShadow> cardShadow({double depth = 1}) {
    if (isDark) {
      return [
        BoxShadow(
          color: const Color(0xFF000000)
              .withValues(alpha: (0.22 * depth).clamp(0.0, 1.0)),
          blurRadius: 28 * depth,
          offset: Offset(0, 12 * depth),
        ),
        BoxShadow(
          color: const Color(0xFF000000)
              .withValues(alpha: (0.10 * depth).clamp(0.0, 1.0)),
          blurRadius: 6 * depth,
          offset: Offset(0, 2 * depth),
        ),
      ];
    }
    return [
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
  }

  /// Prestige / attention mark gradient. Stays a DEEP fill in both modes so
  /// the dark ink glyph keeps its measured contrast (12.98:1 light).
  LinearGradient get prestigeGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA8432A), Color(0xFF7A2E1C)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CScholarMobileColors.coral, CScholarMobileColors.coralInk],
        );

  /// Glyph ink for the prestige tile.
  Color get prestigeInk =>
      isDark ? const Color(0xFFFFF3EF) : const Color(0xFF17231E);

  // ---------------------------------------------------------------- instances
  /// The light resolution — every value is the locked Soft UI v4 token.
  static const CScholarPalette light = CScholarPalette(
    isDark: false,
    paper: CScholarMobileColors.paper,
    surface: CScholarMobileColors.surface,
    surfaceSoft: CScholarMobileColors.surfaceSoft,
    surfaceWarm: CScholarMobileColors.cream,
    mint: CScholarMobileColors.mint,
    ink: CScholarMobileColors.ink,
    mutedInk: CScholarMobileColors.mutedInk,
    hint: CScholarMobileColors.muted,
    hairline: Color(0xFFEAEAE6),
    line: CScholarMobileColors.line,
    accent: CScholarMobileColors.green,
    accentBright: CScholarMobileColors.green2,
    accentDeep: CScholarMobileColors.greenDeep,
    action: CScholarMobileColors.green,
    actionPressed: CScholarMobileColors.greenDeep,
    actionDeep: Color(0xFF0A2C22),
    coral: CScholarMobileColors.coral,
    coralSoft: CScholarMobileColors.coralSoft,
    danger: CScholarMobileColors.coralInk,
    dangerFill: Color(0xFFA63E25),
    dangerFillPressed: Color(0xFF7E2C18),
    lilac: CScholarMobileColors.lilac,
    lilacSoft: CScholarMobileColors.lilacSoft,
    lilacInk: CScholarMobileColors.lilacInk,
    rimSuccess: CScholarMobileColors.mint,
    rimLilac: CScholarMobileColors.lilacSoft,
    rimCoral: CScholarMobileColors.coralSoft,
    skeletonBase: Color(0xFFDDE3D6),
    skeletonHighlight: CScholarMobileColors.surface,
    scrim: Color(0x59231D18),
  );

  /// The dark resolution. Same roles, tuned values: paper and cards stay in the
  /// green family, inks invert, and every accent keeps a text-safe variant.
  static const CScholarPalette dark = CScholarPalette(
    isDark: true,
    paper: CScholarMobileColors.paperDark,
    surface: CScholarMobileColors.surfaceDark,
    surfaceSoft: CScholarMobileColors.surfaceSoftDark,
    surfaceWarm: CScholarMobileColors.creamDark,
    mint: CScholarMobileColors.mintDark,
    ink: CScholarMobileColors.inkDark,
    mutedInk: CScholarMobileColors.mutedDark,
    hint: Color(0xFF7F8C85),
    hairline: Color(0xFF2E3A34),
    line: CScholarMobileColors.lineDark,
    accent: CScholarMobileColors.greenDark,
    accentBright: CScholarMobileColors.green2Dark,
    accentDeep: Color(0xFF0B2A21),
    // Solid fills match the mobile shell's forest green. The lighter #2E7D63
    // this used to carry made every web fill (search CTA, primary buttons,
    // active nav pill, cover gel) read a step brighter than the same control
    // in the app — dark mode is one brand fill on both, white copy rides it.
    action: CScholarMobileColors.green,
    actionPressed: CScholarMobileColors.greenDeep,
    actionDeep: Color(0xFF0A2C22),
    coral: CScholarMobileColors.coral,
    coralSoft: CScholarMobileColors.coralSoftDark,
    danger: CScholarMobileColors.coralInkDark,
    dangerFill: Color(0xFF8F3521),
    dangerFillPressed: Color(0xFF6E2718),
    lilac: Color(0xFF8C82C6),
    lilacSoft: CScholarMobileColors.lilacSoftDark,
    lilacInk: Color(0xFFB7AEE8),
    rimSuccess: Color(0xFF2F6B55),
    rimLilac: Color(0xFF4A4470),
    rimCoral: Color(0xFF6B3A2E),
    skeletonBase: Color(0xFF2C3833),
    skeletonHighlight: Color(0xFF3C4A43),
    scrim: Color(0x99060B08),
  );

  // ------------------------------------------------------------------ active
  static CScholarPalette _active = light;

  /// The palette the token getters currently resolve against.
  static CScholarPalette get active => _active;

  /// Click [isDark] into the token layer. Called by [CScholarApp] (and the
  /// tests' theme host) immediately before the subtree that reads it builds.
  static void activate(bool isDark) => _active = isDark ? dark : light;

  /// The painted mode for this subtree. Depend on THIS (not the provider) to
  /// rebuild alongside the colours — the provider flips as soon as the button
  /// is tapped, while the painting flips mid-transition.
  static CScholarPalette of(BuildContext context) {
    final scope = CScholarPaletteScope.maybeOf(context);
    if (scope != null) {
      return scope.isDark ? dark : light;
    }
    return _active;
  }
}

/// Carries the painted mode down the tree.
///
/// Lives above `MaterialApp`, so an overlay or a dialog can read it too. Its
/// only job is notification: the colours themselves are read from
/// [CScholarPalette.active] by every token getter.
class CScholarPaletteScope extends InheritedWidget {
  const CScholarPaletteScope({
    super.key,
    required this.isDark,
    this.onToggle,
    required super.child,
  });

  final bool isDark;

  /// Flips the app-wide mode, optionally reporting WHERE the switch was tapped
  /// (global logical pixels) so the iris can open from the icon itself. Null in
  /// hosts that render chrome without an app (tests, the design lab), where the
  /// switch is visible but inert instead of crashing.
  final void Function(Offset? origin)? onToggle;

  static CScholarPaletteScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CScholarPaletteScope>();

  @override
  bool updateShouldNotify(CScholarPaletteScope old) =>
      old.isDark != isDark || old.onToggle != onToggle;
}

/// Re-builds the page under it when the painted mode flips.
///
/// Every route body is wrapped in one (see `app_router.dart`). The Navigator
/// keeps the widget it was handed for a route, so a root-level rebuild does not
/// reach it; this widget is mounted INSIDE the route and subscribes to
/// [CScholarPaletteScope], which is the one signal that the colours moved.
///
/// ## Why the whole subtree is marked dirty
///
/// Rebuilding this widget alone is not enough. Route builders hand back a
/// `const` page (`const AdminDashboardScreen()`), and Flutter short-circuits a
/// child whose widget instance is `identical` to the one it already has — so
/// the page (and every const widget inside it) kept painting the old palette
/// until the next navigation remounted the route. Marking the descendant
/// elements dirty rebuilds them in place: no `State` is disposed, scroll
/// offsets and form input survive, and every const token read runs again
/// against the palette that was just activated. The framework explicitly
/// allows this during build because the marked elements are descendants of the
/// element that is building.
class CScholarPaletteRebuild extends StatefulWidget {
  const CScholarPaletteRebuild({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<CScholarPaletteRebuild> createState() => _CScholarPaletteRebuildState();
}

class _CScholarPaletteRebuildState extends State<CScholarPaletteRebuild> {
  /// The mode the current subtree was built for. Null until the first build.
  bool? _paintedDark;

  @override
  Widget build(BuildContext context) {
    final isDark =
        CScholarPaletteScope.maybeOf(context)?.isDark ??
        CScholarPalette.active.isDark;
    final flipped = _paintedDark != null && _paintedDark != isDark;
    _paintedDark = isDark;

    final page = widget.builder(context);
    if (flipped) _rebuildSubtree(context as Element);
    return page;
  }

  /// Marks every mounted element below [root] dirty, keeping their widgets and
  /// states. Elements that are already dirty — or no longer active — are left
  /// to the framework.
  static void _rebuildSubtree(Element root) {
    root.visitChildren(_markDirty);
  }

  static void _markDirty(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markDirty);
  }
}
