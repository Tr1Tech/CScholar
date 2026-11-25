import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';

/// Mobile-only student theme — exact copy of the Figma prototype
/// (`cscholar-mobile-ui/src/index.css:261-280`, dark `:956-972`).
///
/// Isolated from the web clay system on purpose: web keeps
/// `CScholarColors` / `CScholarMaterial` untouched (DESIGN.md palette lock).
///
/// Dark mode resolves through [CScholarMobileTheme]: screens and widgets
/// read `CScholarMobileTheme.of(context)` (or the `ctx.mobile*`
/// extensions) and never branch on the provider themselves, so every
/// surface flips with the header toggle.
class CScholarMobileColors {
  CScholarMobileColors._();

  static const Color ink = Color(0xFF17231E);
  static const Color muted = Color(0xFF748079);
  static const Color green = Color(0xFF174F3D);
  static const Color green2 = Color(0xFF2D7159);
  static const Color mint = Color(0xFFDCEEE5);
  static const Color cream = Color(0xFFF4EFE6);
  static const Color paper = Color(0xFFF8F6F0);
  static const Color surface = Color(0xFFFFFEFA);
  static const Color surfaceSoft = Color(0xFFF1F3ED);
  static const Color line = Color(0x17403E32);
  static const Color coral = Color(0xFFF17B5B);
  static const Color coralSoft = Color(0xFFFFE3DA);
  static const Color lilac = Color(0xFF7369AD);
  static const Color lilacSoft = Color(0xFFE8E4F5);

  /// Text-safe accent inks. The raw accents above are fill colours (coral is
  /// ~2.4:1 on paper); body copy and small labels use these instead.
  static const Color mutedInk = Color(0xFF5A665F);
  static const Color coralInk = Color(0xFFA63E25);

  /// Destructive ink on the dark surfaces. Vivid enough to read as "danger"
  /// (not a pale tint) and 6.2:1 on surfaceDark, so small labels clear AA.
  static const Color coralInkDark = Color(0xFFFF8F7A);
  static const Color lilacInk = Color(0xFF5B5194);
  static const Color greenDeep = Color(0xFF0F3B2E);

  static const Color inkDark = Color(0xFFEDF5EF);
  static const Color mutedDark = Color(0xFFA9B5AE);
  static const Color greenDark = Color(0xFF80C4A6);
  static const Color green2Dark = Color(0xFF93D1B5);
  static const Color mintDark = Color(0xFF203C31);
  static const Color creamDark = Color(0xFF1B2420);
  static const Color paperDark = Color(0xFF17201C);
  static const Color surfaceDark = Color(0xFF202A25);
  static const Color surfaceSoftDark = Color(0xFF26312B);
  static const Color coralSoftDark = Color(0xFF492D27);
  static const Color lilacSoftDark = Color(0xFF302D46);
  static const Color lineDark = Color(0x14E4F3EA);
}

class CScholarMobileRadius {
  static const double card = 23;
  static const double cta = 22;
  static const double pill = 999;
  static const double nav = 24;
  static const double navBar = 31;
  static const double sheet = 26;
}

class CScholarMobileShadows {
  static List<BoxShadow> get soft => const [
    BoxShadow(color: Color(0x1723382D), blurRadius: 42, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x0A23382D), blurRadius: 10, offset: Offset(0, 3)),
  ];

  static List<BoxShadow> get card => const [
    BoxShadow(color: Color(0x1323382D), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0923382D), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> get pressed => const [
    BoxShadow(color: Color(0x1423382D), blurRadius: 12, offset: Offset(0, 5)),
  ];

  /// Floating chrome / dialogs: deeper than a card, still diffuse.
  static List<BoxShadow> get overlay => const [
    BoxShadow(color: Color(0x1F23382D), blurRadius: 54, offset: Offset(0, 22)),
    BoxShadow(color: Color(0x0D23382D), blurRadius: 14, offset: Offset(0, 4)),
  ];
}

class CScholarMobileTextStyles {
  static TextStyle manrope(
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

  static TextStyle dmSans(
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

  static TextStyle get pageTitle => manrope(
    29,
    FontWeight.w700,
    CScholarMobileColors.ink,
    height: 1.15,
    letterSpacing: -0.45,
  );

  static TextStyle get sectionTitle => manrope(
    18,
    FontWeight.w700,
    CScholarMobileColors.ink,
    height: 1.2,
    letterSpacing: -0.36,
  );

  static TextStyle get cardTitle =>
      manrope(14, FontWeight.w700, CScholarMobileColors.ink, height: 1.35);

  static TextStyle get eyebrow => dmSans(
    10,
    FontWeight.w800,
    CScholarMobileColors.green2,
    height: 1.2,
    letterSpacing: 1.15,
  );

  static TextStyle get body =>
      dmSans(13, FontWeight.w400, CScholarMobileColors.ink, height: 1.5);

  static TextStyle get bodyMuted =>
      dmSans(12, FontWeight.w400, CScholarMobileColors.muted, height: 1.6);

  static TextStyle get caption =>
      dmSans(10, FontWeight.w400, CScholarMobileColors.muted, height: 1.4);
}

/// Resolved mobile palette for the current theme mode.
///
/// Screens and widgets read this (via `CScholarMobileTheme.of(context)`,
/// which watches the theme provider) and never branch on light/dark
/// themselves. Static neutrals that do NOT flip (brand green, coral,
/// dividers tuned per-mode) stay on [CScholarMobileColors] directly.
class CScholarMobileTheme {
  final bool isDark;

  const CScholarMobileTheme({required this.isDark});

  static CScholarMobileTheme of(BuildContext context) {
    final scope = CScholarMobileThemeScope.maybeOf(context);
    if (scope != null) {
      return CScholarMobileTheme(isDark: scope.isDark);
    }
    return CScholarMobileTheme(isDark: _isDarkOf(context));
  }

  static bool _isDarkOf(BuildContext context) => ProviderScope.containerOf(
    context,
    listen: false,
  ).read(mobileThemeModeProvider);

  Color get ink =>
      isDark ? CScholarMobileColors.inkDark : CScholarMobileColors.ink;
  Color get muted =>
      isDark ? CScholarMobileColors.mutedDark : CScholarMobileColors.muted;
  Color get green =>
      isDark ? CScholarMobileColors.greenDark : CScholarMobileColors.green;
  Color get green2 =>
      isDark ? CScholarMobileColors.green2Dark : CScholarMobileColors.green2;
  Color get mint =>
      isDark ? CScholarMobileColors.mintDark : CScholarMobileColors.mint;
  Color get cream =>
      isDark ? CScholarMobileColors.creamDark : CScholarMobileColors.cream;
  Color get paper =>
      isDark ? CScholarMobileColors.paperDark : CScholarMobileColors.paper;
  Color get surface =>
      isDark ? CScholarMobileColors.surfaceDark : CScholarMobileColors.surface;
  Color get surfaceSoft => isDark
      ? CScholarMobileColors.surfaceSoftDark
      : CScholarMobileColors.surfaceSoft;
  Color get line =>
      isDark ? CScholarMobileColors.lineDark : CScholarMobileColors.line;
  Color get coralSoft => isDark
      ? CScholarMobileColors.coralSoftDark
      : CScholarMobileColors.coralSoft;

  /// Destructive text/icon ink: deep rust on light, vivid coral on dark.
  Color get dangerInk => isDark
      ? CScholarMobileColors.coralInkDark
      : CScholarMobileColors.coralInk;
  Color get lilacSoft => isDark
      ? CScholarMobileColors.lilacSoftDark
      : CScholarMobileColors.lilacSoft;

  TextStyle manrope(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
    double? letterSpacing,
  }) => CScholarMobileTextStyles.manrope(
    size,
    weight,
    color,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle dmSans(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.5,
    double? letterSpacing,
  }) => CScholarMobileTextStyles.dmSans(
    size,
    weight,
    color,
    height: height,
    letterSpacing: letterSpacing,
  );

  TextStyle get pageTitle =>
      manrope(29, FontWeight.w700, ink, height: 1.15, letterSpacing: -0.45);
  TextStyle get sectionTitle =>
      manrope(18, FontWeight.w700, ink, height: 1.2, letterSpacing: -0.36);
  TextStyle get cardTitle => manrope(14, FontWeight.w700, ink, height: 1.35);
  TextStyle get eyebrow =>
      dmSans(10, FontWeight.w800, green2, height: 1.2, letterSpacing: 1.15);
  TextStyle get body => dmSans(13, FontWeight.w400, ink, height: 1.5);
  TextStyle get bodyMuted => dmSans(12, FontWeight.w400, muted, height: 1.6);
  TextStyle get caption => dmSans(10, FontWeight.w400, muted, height: 1.4);
}

/// Inherited scope carrying the current mobile theme mode down the tree.
///
/// [MobileStudentScaffold] (a [ConsumerWidget]) rebuilds on the toggle and
/// re-provides this scope, so every `CScholarMobileTheme.of(context)` below
/// it resolves the new mode on the next build. Without the scope, `of`
/// falls back to a non-subscribing container read and screens keep the
/// mode they built with — the exact bug where toggling dark left cards
/// and text on light values.
class CScholarMobileThemeScope extends InheritedWidget {
  final bool isDark;

  const CScholarMobileThemeScope({
    super.key,
    required this.isDark,
    required super.child,
  });

  static CScholarMobileThemeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CScholarMobileThemeScope>();

  @override
  bool updateShouldNotify(CScholarMobileThemeScope old) => old.isDark != isDark;
}
