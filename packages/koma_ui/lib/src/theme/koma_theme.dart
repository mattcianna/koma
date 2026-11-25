import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/theme/koma_colors.dart';
import 'package:koma_ui/src/theme/koma_spacing.dart';
import 'package:koma_ui/src/theme/koma_typography.dart';

/// Factory and assembly for Koma Material 3 themes.
///
/// Implements both Light ("Warm Washi Paper") and Dark ("Sumi Ink OLED")
/// visual styles with WCAG 2.2 AA compliant contrast ratios.
abstract class KomaTheme {
  /// Assembles the complete Light ThemeData ("Warm Washi Paper").
  static ThemeData get light {
    const baseColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFBE123C),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFE4E6),
      onPrimaryContainer: Color(0xFF4C0519),
      secondary: Color(0xFF475569),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE2E8F0),
      onSecondaryContainer: Color(0xFF0F172A),
      tertiary: Color(0xFF0F766E),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFCCFBF1),
      onTertiaryContainer: Color(0xFF115E59),
      error: Color(0xFFB91C1C),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111115),
      onSurfaceVariant: Color(0xFF52525B),
      surfaceContainer: Color(0xFFF3EFE9),
      surfaceContainerHigh: Color(0xFFEAE4DC),
      surfaceContainerHighest: Color(0xFFE1D9CE),
      surfaceContainerLow: Color(0xFFF8F5F0),
      surfaceContainerLowest: Color(0xFFFAF8F5),
      outline: Color(0xFF78716C),
      outlineVariant: Color(0xFFE8E2D9),
    );

    return _buildTheme(
      colorScheme: baseColorScheme,
      komaColors: KomaColors.light,
      systemOverlay: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFFAF8F5),
      ),
    );
  }

  /// Assembles the complete OLED Dark ThemeData ("Sumi Ink").
  static ThemeData get dark {
    const baseColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFB7185),
      onPrimary: Color(0xFF4C0519),
      primaryContainer: Color(0xFF9F1239),
      onPrimaryContainer: Color(0xFFFFE4E6),
      secondary: Color(0xFF94A3B8),
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF334155),
      onSecondaryContainer: Color(0xFFF1F5F9),
      tertiary: Color(0xFF2DD4BF),
      onTertiary: Color(0xFF042F2E),
      tertiaryContainer: Color(0xFF115E59),
      onTertiaryContainer: Color(0xFFCCFBF1),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF991B1B),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF16161B),
      onSurface: Color(0xFFF5F3EF),
      onSurfaceVariant: Color(0xFFA1A1AA),
      surfaceContainer: Color(0xFF1E1E25),
      surfaceContainerHigh: Color(0xFF272730),
      surfaceContainerHighest: Color(0xFF31313C),
      surfaceContainerLow: Color(0xFF121216),
      surfaceContainerLowest: Color(0xFF0D0D10),
      outline: Color(0xFF71717A),
      outlineVariant: Color(0xFF202027),
    );

    return _buildTheme(
      colorScheme: baseColorScheme,
      komaColors: KomaColors.dark,
      systemOverlay: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0D0D10),
      ),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required KomaColors komaColors,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    const spacing = KomaSpacing();
    final textTheme = KomaTypography.createTextTheme(
      color: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: KomaPageTransitionsBuilder(),
          TargetPlatform.iOS: KomaPageTransitionsBuilder(),
          TargetPlatform.macOS: KomaPageTransitionsBuilder(),
          TargetPlatform.windows: KomaPageTransitionsBuilder(),
          TargetPlatform.linux: KomaPageTransitionsBuilder(),
          TargetPlatform.fuchsia: KomaPageTransitionsBuilder(),
        },
      ),
      extensions: [komaColors, spacing],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: colorScheme.primary,
        centerTitle: false,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamilyFallback: KomaTypography.fontFallbacks,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsetsDirectional.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(16),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        disabledColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.primary,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
          fontFamilyFallback: KomaTypography.fontFallbacks,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(8),
          side: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(kKomaMinTouchTarget, kKomaMinTouchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(kKomaMinTouchTarget, kKomaMinTouchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(kKomaMinTouchTarget, kKomaMinTouchTarget),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, kKomaMinTouchTarget),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontFamilyFallback: KomaTypography.fontFallbacks,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontFamilyFallback: KomaTypography.fontFallbacks,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// Page transitions builder that respects reduced motion preferences.
class KomaPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates a [KomaPageTransitionsBuilder].
  const new();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return const ZoomPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
