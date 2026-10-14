import 'package:flutter/material.dart';

class AppTheme {
  // Quickopia Core Brand Palette
  // Primary Base: Vibrant Quickopia Orange (matches Onboarding & Floating Pill Footer)
  static const Color primaryOrange = Color(0xFFFF5200);
  static const Color primaryOrangeDark = Color(0xFFE04800);
  static const Color primaryOrangeLight = Color(0xFFFF6A00);

  // Signature brand gradient for AppBars and Headers
  static const List<Color> brandOrangeGradient = [
    Color(0xFFFF5200),
    Color(0xFFFF6600),
    Color(0xFFFF4800),
  ];

  static const LinearGradient brandOrangeLinearGradient = LinearGradient(
    colors: brandOrangeGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary & High-Contrast Anchors
  static const Color primaryNavy = Color(0xFF0B2545);
  static const Color primaryDark = Color(0xFF07192E);

  // Accent: Warm Amber & Accent Green for positive actions
  static const Color accentAmber = Color(0xFFF5A623);
  static const Color accentOrange = Color(0xFFFF5200);
  static const Color accentGreen = Color(0xFF2E7D32);

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
          seedColor: primaryOrange,
          primary: primaryOrange,
          secondary: accentAmber,
          surface: neutralLight,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        scaffoldBackgroundColor: neutralLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
        ),
      );
}
