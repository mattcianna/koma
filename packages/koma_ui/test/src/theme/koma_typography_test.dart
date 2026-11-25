import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

void main() {
  group('KomaTypography', () {
    test('font fallbacks include Japanese support', () {
      expect(KomaTypography.fontFallbacks, contains('Noto Sans JP'));
    });

    test('createTextTheme provides expected scales', () {
      final theme = KomaTypography.createTextTheme(color: Colors.black);

      expect(theme.displayLarge?.fontSize, equals(57));
      expect(theme.displayLarge?.fontWeight, equals(FontWeight.w400));

      expect(theme.headlineLarge?.fontSize, equals(32));
      expect(theme.headlineLarge?.fontWeight, equals(FontWeight.w700));

      expect(theme.titleLarge?.fontSize, equals(22));
      expect(theme.titleLarge?.fontWeight, equals(FontWeight.w600));

      expect(theme.bodyMedium?.fontSize, equals(14));
      expect(theme.bodyMedium?.fontWeight, equals(FontWeight.w400));

      expect(theme.labelLarge?.fontSize, equals(14));
      expect(theme.labelLarge?.fontWeight, equals(FontWeight.w600));
    });

    test('default textTheme instance is populated', () {
      expect(KomaTypography.textTheme.displayLarge, isNotNull);
      expect(KomaTypography.textTheme.bodyMedium, isNotNull);
    });
  });
}
