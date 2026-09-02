import 'package:flutter/material.dart';

class AppTheme {
  // Quickopia Starter Brand Palette
  // Primary Base: Deep Navy (Trust, Security, Tech-Forward)
  static const Color primaryNavy = Color(0xFF0B2545);
  static const Color primaryDark = Color(0xFF07192E);

  // Accent: Warm Amber (Strictly for high-impact CTAs)
  static const Color accentAmber = Color(0xFFF5A623);
  static const Color accentOrange = Color(0xFFE89415);

  // Neutrals: Clean Grays & Whites (WCAG-compliant readability)
  static const Color neutralLight = Color(0xFFF7F8FA);
  static const Color neutralDark = Color(0xFF1C1C1E);
  static const Color neutralGray = Color(0xFF8E8E93);
  static const Color cardSurface = Colors.white;

  // Spacing & Border Radius Tokens
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          primary: primaryNavy,
          secondary: accentAmber,
          surface: neutralLight,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        scaffoldBackgroundColor: neutralLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentAmber,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
        ),
      );
}
