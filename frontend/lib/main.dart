import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:frontend/presentation/widgets/common/theme_iris.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The saved mode is resolved BEFORE the first frame: the app never paints
  // light and then jumps to dark, and start-up never replays the transition.
  await CScholarModeStore.load();
  runApp(const ProviderScope(child: CScholarApp()));
}

class CScholarApp extends ConsumerStatefulWidget {
  const CScholarApp({super.key});

  /// Test seam: supplies the "captured" frame instead of the real raster.
  ///
  /// Widget tests run on a fake clock, and the engine's raster future never
  /// completes there — so without this the wipe could not be exercised at all.
  /// Production never sets it.
  @visibleForTesting
  static Future<ui.Image?> Function()? debugFrameCapture;

  @override
  ConsumerState<CScholarApp> createState() => _CScholarAppState();
}

class _CScholarAppState extends ConsumerState<CScholarApp>
    with SingleTickerProviderStateMixin {
  /// The theme transition: ONE one-shot iris wipe.
  ///
  /// The frame on screen is captured, the palette flips, and the captured
  /// (old-theme) frame stays on top with an expanding circular hole cut out of
  /// it — centred on the switch that was tapped. The live app, already painted
  /// in the new palette, shows through that hole. The circle ends once it has
  /// passed the farthest corner, and the frozen frame is dropped.
  ///
  /// Only the clip changes from frame to frame: the app below sits in its own
  /// repaint boundary, so a wipe never re-rasterizes the page underneath.
  late final AnimationController _transition =
      AnimationController(vsync: this, duration: CScholarMotion.themeSwap)
        ..addListener(_onTransitionTick)
        ..addStatusListener(_onTransitionStatus);

  /// Where the disc becomes opaque in the FALLBACK path (capture unavailable).
  static const double _curtainSwapAt = 0.62;

  /// The boundary the transition captures.
  final GlobalKey _boundaryKey = GlobalKey();

  /// The mode currently PAINTED. It trails [themeModeProvider] by one flip:
  /// the provider changes on tap, this changes when the iris opens.
  late bool _paintedDark = CScholarModeStore.initialDark;

  /// The mode the wipe is travelling toward.
  late bool _targetDark = CScholarModeStore.initialDark;

  /// True once this run has committed its palette flip.
  bool _swapped = false;

  /// Whether the wipe overlay is mounted. Set in the same frame as the flip and
  /// cleared when the controller completes — never derived from the controller
  /// value, which is still 0 on the frame the run starts.
  bool _active = false;

  /// The frozen old frame, painted outside the iris. Null on the fallback path.
  ui.Image? _frozen;

  /// Circle centre, in viewport coordinates: the switch's icon.
  Offset _irisOrigin = Offset.zero;

  /// Where the toggle was tapped, until the transition picks it up.
  Offset? _pendingOrigin;

  /// Bumped per transition so a capture that lands after a newer toggle (or
  /// after dispose) is discarded instead of flashing a stale frame.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    // Load saved token on startup
    ref.read(authProvider.notifier).loadToken();
  }

  @override
  void dispose() {
    _transition.dispose();
    _frozen?.dispose();
    super.dispose();
  }

  void _onTransitionTick() {
    if (_swapped || _transition.value < _curtainSwapAt) return;
    _swapped = true;
    // Fully covered: swap the palette. Every mounted route is wrapped in
    // CScholarPaletteRebuild, so the page repaints once, hidden.
    setState(() => _paintedDark = _targetDark);
  }

  void _onTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    // Drop the frozen frame and unmount the overlay. It absorbs pointers, so
    // leaving it parked would make the whole app dead to taps.
    final old = _frozen;
    setState(() {
      _transition.value = 0;
      _swapped = false;
      _active = false;
      _frozen = null;
    });
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  /// Entry point from the switch: remembers where it was tapped, then flips the
  /// provider. The listener in [build] turns that into a wipe.
  void _requestToggle(Offset? origin) {
    _pendingOrigin = origin;
    ref.read(themeModeProvider.notifier).toggle();
  }

  Future<void> _startTransition(bool next) async {
    _targetDark = next;
    final generation = ++_generation;

    // The root sits above MediaQuery, so read the accessibility flag from the
    // engine directly: reduced motion gets the swap with no wipe at all.
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion || !CScholarMotion.ambientEnabled) {
      _discardFrozen();
      _transition.value = 0;
      setState(() {
        _active = false;
        _swapped = false;
        _paintedDark = next;
      });
      return;
    }

    _discardFrozen();
    _transition.value = 0;

    final shot = await _captureFrame();
    if (!mounted || generation != _generation) {
      shot?.dispose();
      return;
    }

    final origin = _localOrigin(_pendingOrigin);
    _pendingOrigin = null;

    if (shot == null) {
      // Nothing to freeze (a renderer that cannot rasterize, or a capture that
      // blew its budget): cover the screen with the destination canvas and
      // dissolve it instead.
      if (kDebugMode) {
        debugPrint(
          'theme wipe: no frame captured — using the dissolving curtain',
        );
      }
      setState(() {
        _swapped = false;
        _active = true;
        _irisOrigin = origin;
      });
      _transition.forward(from: 0);
      return;
    }

    // Both halves of the illusion land in ONE frame: the frozen old theme goes
    // up and the palette flips underneath it, so no half-painted state shows.
    setState(() {
      _frozen = shot;
      _irisOrigin = origin;
      _paintedDark = next;
      _swapped = true;
      _active = true;
    });
    _transition.forward(from: 0);
  }

  /// Rasterizes the app as it is right now.
  ///
  /// Null means the host cannot produce an image (or took too long) and the
  /// caller should fall back to the dissolving curtain. Captured at up to 2x so
  /// the frozen frame stays sharp on a retina screen without paying for a 3-4x
  /// buffer.
  Future<ui.Image?> _captureFrame() async {
    try {
      final seam = CScholarApp.debugFrameCapture;
      if (seam != null) return await seam();

      final boundary = _boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return null;
      final dpr = View.of(context).devicePixelRatio;
      final ratio = dpr.isFinite ? dpr.clamp(1.0, 2.0) : 1.0;
      return await boundary
          .toImage(pixelRatio: ratio)
          .timeout(
            CScholarMotion.themeCapture,
            onTimeout: () => throw const _CaptureMissed(),
          );
    } on Object {
      return null;
    }
  }

  /// Where the toggle was, in this Stack's coordinates.
  ///
  /// A missing origin (keyboard activation, a host with no layout) falls back to
  /// the top-right corner — where every shell keeps the switch anyway.
  Offset _localOrigin(Offset? global) {
    final box = context.findRenderObject();
    if (global != null && box is RenderBox && box.hasSize) {
      return box.globalToLocal(global);
    }
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    return Offset(size.width - 40, 40);
  }

  void _discardFrozen() {
    final old = _frozen;
    if (old == null) return;
    _frozen = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
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
      // Isolated so the per-frame wipe never re-rasterizes the page, and so the
      // transition has exactly one frame to capture.
      child: RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp.router(
          title: 'CScholar — CEIT Thesis Repository',
          debugShowCheckedModeBanner: false,
          theme: cscholarThemeData(isDark: false),
          darkTheme: cscholarThemeData(isDark: true),
          themeMode: _paintedDark ? ThemeMode.dark : ThemeMode.light,
          // The wipe owns the transition; Material's own 200ms theme lerp
          // would keep repainting framework widgets AFTER the flip, which shows
          // as a ghost of the old palette inside the iris.
          themeAnimationDuration: Duration.zero,
          routerConfig: router,
        ),
      ),
    );

    return CScholarPaletteScope(
      isDark: _paintedDark,
      onToggle: _requestToggle,
      child: Stack(
        fit: StackFit.expand,
        // Non-directional so the stack is legal above MaterialApp, where no
        // Directionality exists yet.
        alignment: Alignment.topLeft,
        children: [
          app,
          if (_active)
            Positioned.fill(
              child: AbsorbPointer(
                key: themeCurtainKey,
                // Only this subtree rebuilds per frame. The app below lives in
                // its own repaint boundary, so the wipe never re-rasterizes it.
                child: ListenableBuilder(
                  listenable: _transition,
                  builder: (context, _) {
                    final value = _transition.value;
                    return _frozen != null
                        ? ThemeIris(
                            image: _frozen!,
                            center: _irisOrigin,
                            progress: CScholarCurves.reveal.transform(
                              value.clamp(0.0, 1.0),
                            ),
                          )
                        : _ThemeCurtain(
                            progress: value,
                            coverShare: _curtainSwapAt,
                            color:
                                (_targetDark
                                        ? CScholarPalette.dark
                                        : CScholarPalette.light)
                                    .paper,
                          );
                  },
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
    final grow = CScholarCurves.reveal.transform(covering);
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
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
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

/// Thrown internally when the frame capture exceeds its budget.
class _CaptureMissed implements Exception {
  const _CaptureMissed();
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
  final snackbarInk = isDark
      ? CScholarColors.textPrimary
      : CScholarColors.white;

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
        borderSide: BorderSide(color: CScholarMaterial.rimStrong, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide(color: CScholarColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.well),
        borderSide: BorderSide(color: CScholarColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        side: BorderSide(color: CScholarColors.primaryGreen, width: 1.5),
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
