import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

class AppColors {
  static bool get isDarkMode => appThemeMode.value == ThemeMode.dark;

  static Color get background => isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF9FAFB);
  static Color get surface => isDarkMode ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
  static Color get sidebar => isDarkMode ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get border => isDarkMode ? const Color(0xFF252525) : const Color(0xFFE5E7EB);
  static Color get accent => isDarkMode ? const Color(0xFFC9A84C) : const Color(0xFFB49033);
  
  static Color get textPrimary => isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF111827);
  static Color get textMuted => isDarkMode ? const Color(0xFF6B6B6B) : const Color(0xFF6B7280);
  
  static const Color statusGreen = Color(0xFF22C55E);
  static const Color statusAmber = Color(0xFFF59E0B);
  static const Color statusRed = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FAFB);
    final srf = isDark ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
    final sb = isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final bdr = isDark ? const Color(0xFF252525) : const Color(0xFFE5E7EB);
    final acc = isDark ? const Color(0xFFC9A84C) : const Color(0xFFB49033);
    final textP = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF111827);
    final textM = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF6B7280);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textP,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textP),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: sb,
        selectedItemColor: acc,
        unselectedItemColor: textM,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: srf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: bdr, width: 1),
        ),
        elevation: 0,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: acc,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: acc,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: AppColors.statusRed,
        onError: Colors.white,
        surface: srf,
        onSurface: textP,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: textP,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textP,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textM,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textP,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textM,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.outfit(
          color: textP,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
