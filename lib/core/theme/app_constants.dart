import 'package:flutter/material.dart';

/// Centralized constants for padding, border radii, durations, and UI values.
class AppConstants {
  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));

  // Spacing & Padding
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationShort = Duration(milliseconds: 250);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationLong = Duration(milliseconds: 600);

  // App Limits & Defaults
  static const double maxTransactionAmount = 100000000.0; // 100 Million
  static const int maxTitleLength = 60;
  static const int maxNotesLength = 200;

  // Brand Colors
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryTealDark = Color(0xFF0F766E);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentEmerald = Color(0xFF10B981);
}
