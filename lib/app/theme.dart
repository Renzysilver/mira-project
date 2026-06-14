import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color primaryPink = Color(0xFFE040FB);
  static const Color accentCyan = Color(0xFF18FFFF);
  static const Color accentGold = Color(0xFFFFD740);
  static const Color backgroundDark = Color(0xFF0A0E21);
  static const Color surfaceDark = Color(0xFF1A1E35);
  static const Color surfaceLight = Color(0xFF2A2E45);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3D6);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color successGreen = Color(0xFF69F0AE);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPink,
        surface: surfaceDark,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: errorRed)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark.withValues( alpha : 0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundDark, Color(0xFF1A1040)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
