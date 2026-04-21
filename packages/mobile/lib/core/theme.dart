import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF161616);
  static const Color sidebar = Color(0xFF111111);
  static const Color border = Color(0xFF252525);
  static const Color accent = Color(0xFFC9A84C);
  
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF6B6B6B);
  
  static const Color statusGreen = Color(0xFF22C55E);
  static const Color statusAmber = Color(0xFFF59E0B);
  static const Color statusRed = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.sidebar,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.statusRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimary,
          fontSize: 56,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimary,
          fontSize: 28,
        ),
        titleMedium: GoogleFonts.ibmPlexMono(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.ibmPlexMono(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
