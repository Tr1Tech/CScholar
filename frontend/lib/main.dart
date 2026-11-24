import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The saved mode is resolved BEFORE the first frame: the app never paints
  // light and then jumps to dark, and start-up never replays the transition.
  await CScholarModeStore.load();
  runApp(const ProviderScope(child: CScholarApp()));
}

class CScholarApp extends ConsumerStatefulWidget {
  const CScholarApp({super.key});

  @override
  ConsumerState<CScholarApp> createState() => _CScholarAppState();
}

class _CScholarAppState extends ConsumerState<CScholarApp>
    with SingleTickerProviderStateMixin {
  /// The palette transition: ONE one-shot motion with two halves.
  ///
  ///   0 → [_coverShare]  a disc of the DESTINATION canvas grows out of the
  ///                      top-right corner (where the button lives) until it
  ///                      covers the viewport;
  /// [_coverShare]      the palette flips under full cover — no half-painted
  ///                      frame is ever visible;
  ///   [_coverShare] → 1  the disc dissolves, revealing the new palette.
  ///
  /// Only the curtain repaints while this runs: the page below rebuilds exactly
  /// once, at the flip. That is what keeps a full-screen theme change inside
  /// the frame budget.
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: CScholarMotion.themeSwap,
  )..addListener(_onTransitionTick)..addStatusListener(_onTransitionStatus);

  static const double _coverShare = 0.62;

  /// The mode currently PAINTED. It trails [themeModeProvider] by one flip:
  /// the provider changes on tap, this changes when the curtain is closed.
  late bool _paintedDark = CScholarModeStore.initialDark;

  /// The mode the curtain is travelling toward.
  late bool _targetDark = CScholarModeStore.initialDark;

  bool _swapped = false;

  @override
  void initState() {
    super.initState();
    // Load saved token on startup
    ref.read(authProvider.notifier).loadToken();
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  void _onTransitionTick() {
    if (_swapped || _transition.value < _coverShare) return;
    _swapped = true;
    // Fully covered: swap the palette. Every mounted route is wrapped in
    // CScholarPaletteRebuild, so the page repaints once, hidden.
    setState(() => _paintedDark = _targetDark);
  }

  void _onTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    // Unmount the curtain. It absorbs pointers, so leaving it parked at value 1
    // would make the whole app dead to taps.
    setState(() {
      _transition.value = 0;
      _swapped = false;
    });
  }

  void _startTransition(bool next) {
    // The root sits above MediaQuery, so read the accessibility flag from the
    // engine directly: reduced motion gets the swap with no curtain at all.
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion || !CScholarMotion.ambientEnabled) {
      _transition.value = 0;
      setState(() {
        _targetDark = next;
        _paintedDark = next;
      });
      return;
    }
    // The curtain's existence is decided in build(), so the state that decides
    // it has to notify now — the controller's own ticks only repaint it.
    setState(() {
      _targetDark = next;
      _swapped = false;
    });
    _transition.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(themeModeProvider, (previous, next) {
      if (next != _targetDark) _startTransition(next);
    });

    final router = ref.watch(appRouter);

    // Point every token getter at the mode this frame paints. This happens
    // BEFORE the subtree builds, so what the page reads is what it draws.
    CScholarPalette.activate(_paintedDark);

    final app = CScholarMobileThemeScope(
      isDark: _paintedDark,
      child: MaterialApp.router(
        title: 'CScholar — CEIT Thesis Repository',
        debugShowCheckedModeBanner: false,
        theme: cscholarThemeData(isDark: false),
        darkTheme: cscholarThemeData(isDark: true),
        themeMode: _paintedDark ? ThemeMode.dark : ThemeMode.light,
        // The curtain owns the transition; Material's own 200ms theme lerp
        // would keep repainting framework widgets *after* the swap, which
        // shows as a ghost of the old palette through the dissolve.
        themeAnimationDuration: Duration.zero,
        routerConfig: router,
      ),
    );

    return CScholarPaletteScope(
      isDark: _paintedDark,
      onToggle: () => ref.read(themeModeProvider.notifier).toggle(),
      child: Stack(
        fit: StackFit.expand,
        // Non-directional so the stack is legal above MaterialApp, where no
        // Directionality exists yet.
        alignment: Alignment.topLeft,
        children: [
          app,
          if (_transition.value > 0)
            Positioned.fill(
              child: AbsorbPointer(
                key: themeCurtainKey,
                child: ListenableBuilder(
                  listenable: _transition,
                  builder: (context, _) => _ThemeCurtain(
                    progress: _transition.value,
                    coverShare: _coverShare,
                    color: (_targetDark
                            ? CScholarPalette.dark
                            : CScholarPalette.light)
                        .paper,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen disc that carries the theme swap.
///
/// Cheap by construction: one `drawCircle` with a radial-gradient shader, no
/// blur, no clip, no backdrop. The leading edge is softened over the last 8% of
/// the radius so the wipe reads as a swell rather than a hard iris.
class _ThemeCurtain extends StatelessWidget {
  const _ThemeCurtain({
    required this.progress,
    required this.coverShare,
    required this.color,
  });

  final double progress;
  final double coverShare;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final covering = (progress / coverShare).clamp(0.0, 1.0);
    // The disc keeps growing slightly through the dissolve, so it never looks
    // parked while it fades.
    final revealing = progress <= coverShare
        ? 0.0
        : ((progress - coverShare) / (1 - coverShare)).clamp(0.0, 1.0);
    final grow = CScholarCurves.settle.transform(covering);
    final alpha = 1 - CScholarCurves.entrance.transform(revealing);

    return CustomPaint(
      painter: _ThemeCurtainPainter(
        grow: grow,
        fade: alpha,
        drift: revealing,
        color: color,
      ),
    );
  }
}

class _ThemeCurtainPainter extends CustomPainter {
  const _ThemeCurtainPainter({
    required this.grow,
    required this.fade,
    required this.drift,
    required this.color,
  });

  final double grow;
  final double fade;
  final double drift;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (grow <= 0 || fade <= 0) return;
    // Origin: the top-right corner, where every shell keeps the switch.
    final center = Offset(size.width - 32, 32);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * grow * (1 + drift * 0.06);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: fade),
          color.withValues(alpha: fade * 0.98),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.92, 1],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_ThemeCurtainPainter old) =>
      old.grow != grow ||
      old.fade != fade ||
      old.drift != drift ||
      old.color != color;
}

/// Identifies the theme-transition curtain, so tests can prove it unmounts
/// (it absorbs pointers while it is up).
const Key themeCurtainKey = ValueKey<String>('cscholar-theme-curtain');

/// ONE theme builder for both modes.
///
/// The tokens resolve from [CScholarPalette.active], so this must be called
/// while the mode it names is active (the root sets it immediately before).
ThemeData cscholarThemeData({required bool isDark}) {
  final brightness = isDark ? Brightness.dark : Brightness.light;
  final snackbarFill = isDark
      ? CScholarMaterial.clayDeep
      : CScholarColors.textPrimary;
  final snackbarInk = isDark ? CScholarColors.textPrimary : CScholarColors.white;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CScholarColors.primaryGreen,
      brightness: brightness,
      primary: CScholarColors.primaryGreen,
      surface: CScholarColors.surfaceWhite,
      error: CScholarColors.error,
    ),
    scaffoldBackgroundColor: CScholarColors.backgroundLight,
    // One transition for every route: fade + slight rise (motion plan).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CScholarTransitionBuilder(),
        TargetPlatform.iOS: CScholarTransitionBuilder(),
        TargetPlatform.linux: CScholarTransitionBuilder(),
        TargetPlatform.macOS: CScholarTransitionBuilder(),
        TargetPlatform.windows: CScholarTransitionBuilder(),
        TargetPlatform.fuchsia: CScholarTransitionBuilder(),
      },
    ),
    textTheme: GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: brightness).textTheme.copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: CScholarColors.textPrimary,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: CScholarColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: CScholarColors.textPrimary,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: CScholarColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: CScholarColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: CScholarColors.textPrimary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: CScholarColors.textSecondary,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CScholarColors.textPrimary,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CScholarColors.textSecondary,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CScholarColors.textSecondary,
          height: 1.4,
        ),
      ),
    ),
    // Soft wells draw NO rim at rest — the tonal fill is the affordance.
    // Only focus (and error, per-field) rings 1.5px. NeumorphField owns its
    // own InputDecoration; this global recipe is the fallback for the
    // allow-listed bespoke wells (hero search, topbar).
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CScholarMaterial.clayDeep,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide(
          color: CScholarMaterial.rimStrong,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide(
          color: CScholarColors.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide(
          color: CScholarColors.error,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      hintStyle: GoogleFonts.dmSans(
        color: CScholarColors.textHint,
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CScholarColors.primaryFill,
        foregroundColor: CScholarColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CScholarRadius.cta),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CScholarColors.primaryFill,
        foregroundColor: CScholarColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CScholarRadius.cta),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CScholarColors.primaryGreen,
        disabledForegroundColor: CScholarColors.textHint,
        side: BorderSide(
          color: CScholarColors.primaryGreen,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CScholarRadius.cta),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CScholarColors.primaryGreen,
        disabledForegroundColor: CScholarColors.textHint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CScholarRadius.full),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),

    // ---- Material system v3: control themes -------------------------
    // Without these, dialogs, menus, chips, snackbars, checkboxes and
    // progress bars fall back to stock Material and break the material
    // language. This is the ONE source of control theming: the old
    // `core/theme/app_theme.dart` was never imported by anything and has
    // been deleted, so there is no second definition to drift against.
    dividerTheme: DividerThemeData(
      color: CScholarColors.dividerLight,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: CScholarColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CScholarColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
      ),
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: CScholarColors.textPrimary,
      ),
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textSecondary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: CScholarColors.surface,
      modalBackgroundColor: CScholarColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CScholarRadius.xxl),
        ),
      ),
    ),
    // The toast is a raised neutral, not an ink block: in dark mode an ink
    // background would be a near-white pill with white copy on it.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: snackbarFill,
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: snackbarInk,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CScholarColors.surfaceLight,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: CScholarColors.white,
      ),
      selectedColor: CScholarColors.primaryFill,
      checkmarkColor: CScholarColors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.full),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? CScholarColors.primaryFill
            // An unchecked box is a tonal well, not an outlined square —
            // the fill IS the affordance, same law as every other control.
            : CScholarMaterial.clayDeep,
      ),
      checkColor: WidgetStateProperty.all(CScholarColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? CScholarColors.white
            : CScholarColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? CScholarColors.primaryFill
            : CScholarMaterial.clayDeep,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: CScholarColors.primaryGreen,
      linearTrackColor: CScholarColors.surfaceLight,
      circularTrackColor: CScholarColors.surfaceLight,
    ),
    // Tooltips are raised neutral chrome in both modes, like the snackbar.
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: snackbarFill,
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
      ),
      textStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: snackbarInk,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: CScholarColors.textSecondary,
      textColor: CScholarColors.textPrimary,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
      ),
      subtitleTextStyle: GoogleFonts.dmSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textMuted,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
      selectedTileColor: CScholarColors.primaryGreenVeryLight,
      selectedColor: CScholarColors.primaryGreen,
    ),
    iconTheme: IconThemeData(color: CScholarColors.textSecondary),
  );
}
