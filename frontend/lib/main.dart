import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
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

    return MaterialApp.router(
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
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.copyWith(
            displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: CScholarColors.textPrimary),
            displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: CScholarColors.textPrimary),
            headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary),
            titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary),
            bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: CScholarColors.textPrimary),
            bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: CScholarColors.textPrimary),
            bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: CScholarColors.textSecondary),
            labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: CScholarColors.textPrimary),
            labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary),
            labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: CScholarColors.textSecondary, height: 1.4),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CScholarColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.lg),
            borderSide: const BorderSide(color: CScholarColors.dividerLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.lg),
            borderSide: const BorderSide(color: CScholarColors.dividerLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.lg),
            borderSide: const BorderSide(color: CScholarColors.primaryGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: GoogleFonts.inter(color: CScholarColors.textHint, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CScholarColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: CScholarColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CScholarRadius.md),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
              borderRadius: BorderRadius.circular(CScholarRadius.md),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
            side: const BorderSide(color: CScholarColors.borderLight),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: CScholarColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.xl),
            side: const BorderSide(color: CScholarColors.borderLight),
          ),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CScholarColors.textPrimary,
          ),
          contentTextStyle: GoogleFonts.inter(
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
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(CScholarRadius.xxl)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: CScholarColors.textPrimary,
          contentTextStyle: GoogleFonts.inter(
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
          side: const BorderSide(color: CScholarColors.borderLight),
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CScholarColors.textPrimary,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
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
                : Colors.transparent,
          ),
          checkColor: WidgetStateProperty.all(CScholarColors.white),
          side: const BorderSide(color: CScholarColors.borderLight, width: 1.5),
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
                : CScholarColors.surfaceLight,
          ),
          trackOutlineColor:
              WidgetStateProperty.all(CScholarColors.borderLight),
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
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CScholarColors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: CScholarColors.textSecondary,
          textColor: CScholarColors.textPrimary,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CScholarColors.textPrimary,
          ),
          subtitleTextStyle: GoogleFonts.inter(
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
    );
  }
}
