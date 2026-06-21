import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Dark navy system (design reference) ──────────────────────────
  static const Color background = Color(0xFF0A0B14);
  static const Color surfaceDark = Color(0xFF12131F);
  static const Color surfaceLight = Color(0xFF1A1B2E);
  static const Color cardGlass = Color(0xFF16172A);

  // Accent purple
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleDeep = Color(0xFF6D28D9);

  // Accent pink
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFF472B6);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Glass
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Status
  static const Color successGreen = Color(0xFF34D399);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color gold = Color(0xFFFBBF24);

  // ── Legacy aliases (back-compat) ─────────────────────────────────
  static const Color midnightBlue = background;
  static const Color deepViolet = surfaceDark;
  static const Color softLavender = purpleLight;
  static const Color moonRose = pinkLight;
  static const Color sakuraPink = pinkLight;
  static const Color moonWhite = textPrimary;
  static const Color auroraBlue = Color(0xFF60A5FA);
  static const Color mistGray = textMuted;
  static const Color magentaAccent = pink;
  static const Color magentaDeep = Color(0xFFBE185D);
  static const Color deepPurple = purpleDeep;
  static const Color deepNavy = background;
  static const Color primaryPurple = purple;
  static const Color primaryPink = pink;
  static const Color accentCyan = Color(0xFF60A5FA);
  static const Color accentGold = gold;
  static const Color backgroundDark = background;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: purple,
      scaffoldBackgroundColor: background,
      fontFamily: 'serif',
      colorScheme: const ColorScheme.dark(
        primary: purple,
        secondary: pink,
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
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 20,
            fontWeight: FontWeight.w300, letterSpacing: 2),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w200, color: textPrimary, letterSpacing: 1.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w200, color: textPrimary, letterSpacing: 1.2),
        displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: 1),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: textPrimary, letterSpacing: 0.8),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 15, color: textPrimary, height: 1.6),
        bodyMedium: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, letterSpacing: 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: cardGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? pink : Colors.white70),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? pink.withOpacity(0.4)
                : Colors.white.withOpacity(0.08)),
      ),
    );
  }

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceDark, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purpleLight, pinkLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [pink, Color(0xFFBE185D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient callGradient = LinearGradient(
    colors: [background, surfaceDark, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
