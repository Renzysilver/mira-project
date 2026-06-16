import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Dreamy anime palette ──────────────────────────────────────────────
  // Deep cosmic background
  static const Color midnightBlue   = Color(0xFF080B18);
  static const Color deepViolet     = Color(0xFF12082A);
  static const Color deepNavy       = Color(0xFF0A0A1A);

  // Pink-magenta accent system (primary brand accent in the new design)
  static const Color sakuraPink     = Color(0xFFFFD4E8); // soft highlight
  static const Color moonRose       = Color(0xFFFFB7C5); // mid-pink
  static const Color magentaAccent  = Color(0xFFE83E8C); // primary CTA pink
  static const Color magentaDeep    = Color(0xFFC2185B); // pressed state

  // Purple companions
  static const Color softLavender   = Color(0xFFC9A7FF);
  static const Color primaryPurple  = Color(0xFF9B6DFF);
  static const Color deepPurple     = Color(0xFF5A189A);

  // Neutrals
  static const Color moonWhite      = Color(0xFFF0E6FF);
  static const Color auroraBlue     = Color(0xFFA7C4FF);
  static const Color mistGray       = Color(0xFF4A4A6A);
  static const Color textSecondary  = Color(0xFFB8B8C8);

  // Glass
  static const Color glassWhite     = Color(0x1AFFFFFF);
  static const Color glassBorder    = Color(0x33FFFFFF);
  static const Color glassDark      = Color(0xF00F0F2A);

  // Status
  static const Color errorRed       = Color(0xFFFF6B8A);
  static const Color successGreen   = Color(0xFF98F5C4);

  // Legacy aliases so existing code compiles unchanged
  static const Color primaryPink    = moonRose;
  static const Color accentCyan     = auroraBlue;
  static const Color accentGold     = Color(0xFFFFE4A0);
  static const Color backgroundDark = midnightBlue;
  static const Color surfaceDark    = Color(0xFF1A1035);
  static const Color surfaceLight   = Color(0xFF2A1F50);
  static const Color textPrimary    = moonWhite;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: magentaAccent,
      scaffoldBackgroundColor: midnightBlue,
      fontFamily: 'serif',
      colorScheme: const ColorScheme.dark(
        primary: magentaAccent,
        secondary: moonRose,
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
          color: moonWhite, fontSize: 20,
          fontWeight: FontWeight.w300, letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: moonWhite),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w300, color: moonWhite, letterSpacing: 1.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: moonWhite, letterSpacing: 1.2),
        displaySmall:  TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: moonWhite, letterSpacing: 1),
        headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: moonWhite, letterSpacing: 0.8),
        titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: moonWhite),
        bodyLarge:     TextStyle(fontSize: 15, color: moonWhite, height: 1.6),
        bodyMedium:    TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: moonWhite, letterSpacing: 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: magentaAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        hintStyle: const TextStyle(color: mistGray, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
    );
  }

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [midnightBlue, deepViolet, Color(0xFF1A0A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Cosmic aurora gradient — purple-to-pink, used for splash and feature
  /// backgrounds. Matches the mockup's signature look.
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [deepPurple, magentaAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [softLavender, moonRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Pink CTA gradient — primary buttons in the new design.
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [magentaAccent, magentaDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient callGradient = LinearGradient(
    colors: [Color(0xFF0D0820), Color(0xFF1A0A35), Color(0xFF0A0E20)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
