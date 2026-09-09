import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: CScholarApp()));
}

class CScholarApp extends ConsumerWidget {
  const CScholarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          surface: CScholarColors.cardBg,
        ),
        scaffoldBackgroundColor: CScholarColors.backgroundLight,
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
          fillColor: CScholarColors.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.lg),
            borderSide: const BorderSide(color: CScholarColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CScholarRadius.lg),
            borderSide: const BorderSide(color: CScholarColors.borderLight),
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
      ),
      routerConfig: router,
    );
  }
}
