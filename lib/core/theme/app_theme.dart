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
  // Background: Warm / Off-White
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

  // ── Light Theme (Warm Off-White + Deep Navy + Teal + Golden Orange) ──
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryLight,
      secondary: accentGold,
      surface: surfaceLight,
      onPrimary: Colors.white,
      onSurface: textPrimaryLight,
      surfaceContainerHighest: cardColorLight,
      outline: Color(0xFFE2DCD5),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 4.0,
        color: textPrimaryLight,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        color: textSecondaryLight,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
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
      secondary: accentGold,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      surfaceContainerHighest: cardColor,
      outline: Color(0xFF23364E),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 4.0,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        color: textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textMuted,
      ),
    ),
  );
}
