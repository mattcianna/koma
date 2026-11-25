import 'package:flutter/material.dart';

/// Clean Material 3 typography scale for Koma.
///
/// Designed to scale fluidly with iOS Dynamic Type and Android Font Scaling
/// up to 200% without layout overflow.
abstract class KomaTypography {
  /// Font family fallback list for Latin and Japanese kanji/kana titles.
  static const List<String> fontFallbacks = <String>[
    'Roboto',
    'SF Pro Text',
    'SF Pro Display',
    'Noto Sans JP',
  ];

  /// Assembles the canonical Material 3 [TextTheme] for Koma.
  static TextTheme createTextTheme({Color? color}) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        height: 64 / 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        height: 52 / 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.10,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.50,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.40,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.10,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.50,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.50,
        color: color,
        fontFamilyFallback: fontFallbacks,
      ),
    );
  }

  /// Default text theme without explicit color overrides.
  static final TextTheme textTheme = createTextTheme();
}
