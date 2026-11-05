import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

void main() {
  runApp(const ProviderScope(child: CScholarApp()));
}

class CScholarApp extends ConsumerStatefulWidget {
  const CScholarApp({super.key});

  @override
  ConsumerState<CScholarApp> createState() => _CScholarAppState();
}

class _CScholarAppState extends ConsumerState<CScholarApp> {
  @override
  void initState() {
    super.initState();
    // Load saved token on startup
    ref.read(authProvider.notifier).loadToken();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouter);
    final isDark = ref.watch(mobileThemeModeProvider);

    return CScholarMobileThemeScope(
      isDark: isDark,
      child: MaterialApp.router(
        title: 'CScholar — CEIT Thesis Repository',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: CScholarColors.primaryGreen,
            brightness: Brightness.light,
            primary: CScholarColors.primaryGreen,
            surface: CScholarColors.surfaceWhite,
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
            ThemeData.light().textTheme.copyWith(
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
            fillColor: CScholarMaterial.well,
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
              borderSide: const BorderSide(
                color: CScholarMaterial.gelTop,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CScholarRadius.well),
              borderSide: const BorderSide(
                color: CScholarColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CScholarRadius.well),
              borderSide: const BorderSide(
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
              backgroundColor: CScholarColors.primaryGreen,
              foregroundColor: Colors.white,
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
              backgroundColor: CScholarColors.primaryGreen,
              foregroundColor: Colors.white,
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
              side: const BorderSide(
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
          dividerTheme: const DividerThemeData(
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
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: CScholarColors.surface,
            modalBackgroundColor: CScholarColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(CScholarRadius.xxl),
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: CScholarColors.textPrimary,
            contentTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CScholarColors.white,
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
            selectedColor: CScholarColors.primaryGreen,
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
                  ? CScholarColors.primaryGreen
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
                  ? CScholarColors.primaryGreen
                  : CScholarMaterial.clayDeep,
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: CScholarColors.primaryGreen,
            linearTrackColor: CScholarColors.surfaceLight,
            circularTrackColor: CScholarColors.surfaceLight,
          ),
          tooltipTheme: TooltipThemeData(
            decoration: BoxDecoration(
              color: CScholarColors.textPrimary,
              borderRadius: BorderRadius.circular(CScholarRadius.sm),
            ),
            textStyle: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CScholarColors.white,
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
          iconTheme: const IconThemeData(color: CScholarColors.textSecondary),
        ),
        routerConfig: router,
      ),
    );
  }
}
