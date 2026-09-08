// CScholar App Theme
// Modern academic technology platform theme

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/cscholar_constants.dart';

/// Light theme for CScholar
ThemeData lightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    // Color scheme
    colorScheme: ColorScheme.light(
      primary: CScholarColors.primaryGreen,
      onPrimary: CScholarColors.white,
      primaryContainer: CScholarColors.primaryGreenVeryLight,
      onPrimaryContainer: CScholarColors.primaryGreenDark,
      secondary: CScholarColors.orange,
      onSecondary: CScholarColors.white,
      secondaryContainer: CScholarColors.yellowLight,
      onSecondaryContainer: CScholarColors.textPrimary,
      tertiary: CScholarColors.yellow,
      onTertiary: CScholarColors.textPrimary,
      error: CScholarColors.error,
      onError: CScholarColors.white,
      surface: CScholarColors.surfaceWhite,
      onSurface: CScholarColors.textPrimary,
      surfaceContainerHighest: CScholarColors.surfaceLight,
      outline: CScholarColors.dividerLight,
      outlineVariant: CScholarColors.dividerLight,
      shadow: CScholarColors.shadowColor,
    ),

    // Scaffold
    scaffoldBackgroundColor: CScholarColors.backgroundLight,

    // App bar
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: CScholarColors.white,
      foregroundColor: CScholarColors.textPrimary,
      surfaceTintColor: CScholarColors.white,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: CScholarColors.textPrimary,
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: CScholarColors.textPrimary,
        size: 24,
      ),
    ),

    // Text theme using Google Fonts (Inter)
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: CScholarColors.textPrimary,
        height: 1.12,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: CScholarColors.textPrimary,
        height: 1.16,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: CScholarColors.textPrimary,
        height: 1.22,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: CScholarColors.textPrimary,
        height: 1.25,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
        height: 1.29,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
        height: 1.33,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
        height: 1.27,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textSecondary,
        height: 1.33,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: CScholarColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CScholarColors.textSecondary,
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: CScholarColors.textHint,
        height: 1.45,
        letterSpacing: 0.5,
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: 0,
      surfaceTintColor: CScholarColors.white,
      color: CScholarColors.surfaceWhite,
      shadowColor: CScholarColors.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.lg),
        side: BorderSide(
          color: CScholarColors.dividerLight,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: CScholarColors.primaryGreen,
        foregroundColor: CScholarColors.white,
        disabledBackgroundColor: CScholarColors.primaryGreen.withOpacity(0.5),
        disabledForegroundColor: CScholarColors.white.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(
          horizontal: CScholarSpacing.lg,
          vertical: CScholarSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CScholarRadius.md),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.pressed)
              ? CScholarColors.primaryGreenDark.withOpacity(0.2)
              : null,
        ),
      ),
    ),

    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CScholarColors.primaryGreen,
        disabledForegroundColor: CScholarColors.textHint,
        side: const BorderSide(
          color: CScholarColors.primaryGreen,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: CScholarSpacing.lg,
          vertical: CScholarSpacing.md,
        ),
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

    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CScholarColors.primaryGreen,
        disabledForegroundColor: CScholarColors.textHint,
        padding: const EdgeInsets.symmetric(
          horizontal: CScholarSpacing.md,
          vertical: CScholarSpacing.sm,
        ),
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

    // Input decoration (form fields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CScholarColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: CScholarSpacing.md,
        vertical: CScholarSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        borderSide: const BorderSide(
          color: CScholarColors.dividerLight,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        borderSide: const BorderSide(
          color: CScholarColors.dividerLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        borderSide: const BorderSide(
          color: CScholarColors.primaryGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        borderSide: const BorderSide(
          color: CScholarColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        borderSide: const BorderSide(
          color: CScholarColors.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        borderSide: BorderSide(
          color: CScholarColors.dividerLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textSecondary,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textHint,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CScholarColors.primaryGreen,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: CScholarColors.error,
      ),
      prefixIconColor: CScholarColors.textHint,
      suffixIconColor: CScholarColors.textHint,
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: CScholarColors.textSecondary,
      size: 24,
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: CScholarColors.dividerLight,
      thickness: 1,
      space: CScholarSpacing.md,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: CScholarColors.primaryGreenVeryLight,
      disabledColor: CScholarColors.surfaceLight,
      selectedColor: CScholarColors.primaryGreen.withOpacity(0.2),
      secondarySelectedColor: CScholarColors.primaryGreen.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(
        horizontal: CScholarSpacing.md,
        vertical: CScholarSpacing.xs,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CScholarColors.textPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CScholarColors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        side: const BorderSide(
          color: CScholarColors.dividerLight,
        ),
      ),
      side: const BorderSide(
        color: CScholarColors.dividerLight,
      ),
      brightness: Brightness.light,
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: CScholarColors.primaryGreen,
      unselectedLabelColor: CScholarColors.textSecondary,
      indicatorColor: CScholarColors.primaryGreen,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.pressed)
            ? CScholarColors.primaryGreen.withOpacity(0.1)
            : null,
      ),
    ),

    // Navigation bar theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CScholarColors.white,
      elevation: 0,
      surfaceTintColor: CScholarColors.white,
      indicatorColor: CScholarColors.primaryGreenVeryLight,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CScholarColors.primaryGreen,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CScholarColors.textSecondary,
          );
        },
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: CScholarColors.primaryGreen,
              size: 24,
            );
          }
          return const IconThemeData(
            color: CScholarColors.textSecondary,
            size: 24,
          );
        },
      ),
    ),

    // Drawer theme
    drawerTheme: DrawerThemeData(
      backgroundColor: CScholarColors.white,
      surfaceTintColor: CScholarColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: CScholarColors.white,
      surfaceTintColor: CScholarColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CScholarRadius.xl),
        ),
      ),
      modalBackgroundColor: CScholarColors.white,
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ),
    ),

    // Snack bar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CScholarColors.textPrimary,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.white,
      ),
      actionTextColor: CScholarColors.yellow,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
      elevation: 4,
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: CScholarColors.white,
      surfaceTintColor: CScholarColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.xl),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: CScholarColors.textPrimary,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textPrimary,
      ),
    ),

    // Progress indicator theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: CScholarColors.primaryGreen,
      linearTrackColor: CScholarColors.primaryGreenVeryLight,
      circularTrackColor: CScholarColors.primaryGreenVeryLight,
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: CScholarColors.primaryGreen,
      inactiveTrackColor: CScholarColors.primaryGreenVeryLight,
      thumbColor: CScholarColors.primaryGreen,
      overlayColor: CScholarColors.primaryGreen.withOpacity(0.2),
      valueIndicatorColor: CScholarColors.primaryGreen,
      valueIndicatorTextStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CScholarColors.white,
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return CScholarColors.primaryGreen;
          }
          return CScholarColors.dividerLight;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return CScholarColors.primaryGreen.withOpacity(0.4);
          }
          return CScholarColors.dividerLight;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.pressed)
            ? CScholarColors.primaryGreen.withOpacity(0.2)
            : null,
      ),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return CScholarColors.primaryGreen;
          }
          return Colors.transparent;
        },
      ),
      checkColor: WidgetStateProperty.all(CScholarColors.white),
      side: const BorderSide(
        color: CScholarColors.dividerLight,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
      ),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return CScholarColors.primaryGreen;
          }
          return CScholarColors.dividerLight;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.pressed)
            ? CScholarColors.primaryGreen.withOpacity(0.2)
            : null,
      ),
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: CScholarSpacing.md,
        vertical: CScholarSpacing.xs,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: CScholarColors.textPrimary,
      ),
      subtitleTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textSecondary,
      ),
      leadingAndTrailingTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CScholarColors.textSecondary,
      ),
      iconColor: CScholarColors.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
      tileColor: Colors.transparent,
      selectedTileColor: CScholarColors.primaryGreenVeryLight,
      selectedColor: CScholarColors.primaryGreen,
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: CScholarColors.textPrimary,
        borderRadius: BorderRadius.circular(CScholarRadius.sm),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: CScholarColors.white,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CScholarSpacing.md,
        vertical: CScholarSpacing.sm,
      ),
      waitDuration: CScholarDurations.fast,
    ),

    // Menu theme
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(CScholarColors.white),
        surfaceTintColor: WidgetStateProperty.all(CScholarColors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.md),
            side: const BorderSide(
              color: CScholarColors.dividerLight,
              width: 1,
            ),
          ),
        ),
      ),
    ),

    // Expansion tile theme
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: CScholarColors.white,
      collapsedBackgroundColor: CScholarColors.white,
      textColor: CScholarColors.textPrimary,
      collapsedTextColor: CScholarColors.textPrimary,
      iconColor: CScholarColors.textSecondary,
      collapsedIconColor: CScholarColors.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        side: const BorderSide(
          color: CScholarColors.dividerLight,
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CScholarRadius.md),
        side: const BorderSide(
          color: CScholarColors.dividerLight,
        ),
      ),
    ),
  );
}