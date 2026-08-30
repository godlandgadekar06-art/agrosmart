import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgroSmart design system.
/// Palette: deep leaf green (primary/trust), warm earth (secondary/action),
/// sky blue (rain/water data), soft cream background (easy on the eyes in
/// bright outdoor sunlight — high contrast matters more than "modern dark UI"
/// for this audience).
class AppColors {
  static const primaryGreen = Color(0xFF2E7D32); // leaf green
  static const primaryGreenDark = Color(0xFF1B5E20);
  static const accentEarth = Color(0xFFB35A1F); // soil/earth tone
  static const rainBlue = Color(0xFF1976D2);
  static const alertRed = Color(0xFFC62828);
  static const warningAmber = Color(0xFFF9A825);
  static const background = Color(0xFFF8F6EF); // warm off-white, sunlight-friendly
  static const cardWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1F2A1F);
  static const textMuted = Color(0xFF5B6B5B);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.notoSansTextTheme(base.textTheme).copyWith(
      // Marathi needs Noto Sans Devanagari coverage — Noto Sans falls back
      // correctly for Devanagari glyphs, keeping one font family app-wide.
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      titleLarge: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      bodyLarge: GoogleFonts.notoSans(
        fontSize: 17, // deliberately large for readability
        color: AppColors.textDark,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 15,
        color: AppColors.textMuted,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryGreen,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentEarth,
        error: AppColors.alertRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56), // large tap target
          textStyle: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDD8C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }
}
