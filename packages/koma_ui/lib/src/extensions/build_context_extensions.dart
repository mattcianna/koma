import 'package:flutter/material.dart';
import 'package:koma_ui/src/theme/koma_colors.dart';
import 'package:koma_ui/src/theme/koma_spacing.dart';

/// Extension methods on [BuildContext] providing streamlined access to
/// Koma theme tokens and Material 3 schemes.
extension KomaThemeX on BuildContext {
  /// Quick accessor to active Material [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick accessor to active Material [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Domain-specific Koma semantic colors.
  ///
  /// Falls back to [KomaColors.light] if the extension is not registered.
  KomaColors get komaColors =>
      Theme.of(this).extension<KomaColors>() ?? KomaColors.light;

  /// RTL-safe spacing and padding tokens.
  ///
  /// Falls back to standard [KomaSpacing] if the extension is not registered.
  KomaSpacing get komaSpacing =>
      Theme.of(this).extension<KomaSpacing>() ?? const KomaSpacing();

  /// Whether the current theme is in dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
