import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ───────────────────────────────────────────────────
  // Primary: Vibrant, rich Teal
  static const Color primary = Color(0xFF0D9488);        // Teal 600
  static const Color primaryLight = Color(0xFF14B8A6);   // Teal 500
  static const Color primaryDark = Color(0xFF0F766E);    // Teal 700
  static const Color primaryDeep = Color(0xFF115E59);    // Teal 800

  // Accent: Warm Golden Orange
  static const Color accentGold = Color(0xFFF59E0B);     // Amber / Golden Orange
  static const Color accentOrange = Color(0xFFEA580C);   // Deep golden orange
  static const Color goldLight = Color(0xFFFDE68A);      // Soft golden highlight
  static const Color goldDark = Color(0xFFD97706);       // Rich amber orange

  // ── Light Mode Palette (Default Brand Experience) ───────────────────
  static const Color backgroundLight = Color(0xFFFBF9F5); // Warm cream / off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Pure white for cards/sheets
  static const Color cardColorLight = Color(0xFFF3EFEA);  // Subtle warm tinted container

  // Text: Deep Navy
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Deep navy slate
  static const Color textSecondaryLight = Color(0xFF334155); // Navy slate medium
  static const Color textMutedLight = Color(0xFF64748B);     // Muted slate navy

  // ── Dark Mode Palette ────────────────────────────────────────────────
  static const Color background = Color(0xFF0B131E);      // Deep navy night
  static const Color surface = Color(0xFF132032);         // Rich navy surface
  static const Color cardColor = Color(0xFF1C2C42);       // Navy container
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Material 3 Spacing Tokens ────────────────────────────────────────
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // ── Material 3 Shape / Corner Radius Tokens ─────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;
  static const double radiusFull = 999.0;

  // ── Light Theme (Warm Off-White + Deep Navy + Teal + Golden Orange) ──
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCCFBF1),
      onPrimaryContainer: Color(0xFF115E59),
      secondary: accentGold,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFEF3C7),
      onSecondaryContainer: Color(0xFF92400E),
      surface: surfaceLight,
      onSurface: textPrimaryLight,
      surfaceContainerHighest: cardColorLight,
      surfaceContainer: Color(0xFFF5F2EC),
      surfaceContainerLow: Color(0xFFFAF7F3),
      outline: Color(0xFFE2DCD5),
      outlineVariant: Color(0xFFECE7E1),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      side: const BorderSide(color: Color(0xFFE2DCD5)),
      selectedColor: primaryLight,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: Color(0xFFE2DCD5), width: 1),
      ),
      color: surfaceLight,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: textPrimaryLight,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimaryLight,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textPrimaryLight,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textPrimaryLight,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textSecondaryLight,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textMutedLight,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimaryLight,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textMutedLight,
      ),
    ),
  );

  // ── Dark Theme (Deep Navy + Teal + Golden Orange) ────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF134E4A),
      onPrimaryContainer: Color(0xFF99F6E4),
      secondary: accentGold,
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF78350F),
      onSecondaryContainer: Color(0xFFFDE68A),
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: cardColor,
      surfaceContainer: Color(0xFF16253A),
      surfaceContainerLow: Color(0xFF0F1A2A),
      outline: Color(0xFF23364E),
      outlineVariant: Color(0xFF1E2E42),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      side: const BorderSide(color: Color(0xFF23364E)),
      selectedColor: primaryLight,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: Color(0xFF23364E), width: 1),
      ),
      color: surface,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textMuted,
      ),
    ),
  );
}
