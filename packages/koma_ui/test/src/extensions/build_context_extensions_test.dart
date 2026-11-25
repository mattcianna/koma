import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaThemeX', () {
    testWidgets('provides correct accessors under light theme', (tester) async {
      late ColorScheme colorScheme;
      late TextTheme textTheme;
      late KomaColors colors;
      late KomaSpacing spacing;
      late bool isDark;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            colorScheme = context.colorScheme;
            textTheme = context.textTheme;
            colors = context.komaColors;
            spacing = context.komaSpacing;
            isDark = context.isDarkMode;
            return const SizedBox();
          },
        ),
        theme: KomaTheme.light,
      );

      expect(colorScheme.brightness, equals(Brightness.light));
      expect(textTheme.displayLarge, isNotNull);
      expect(colors.reading, equals(KomaColors.light.reading));
      expect(spacing.md, equals(16.0));
      expect(isDark, isFalse);
    });

    testWidgets('provides correct accessors under dark theme', (tester) async {
      late bool isDark;
      late KomaColors colors;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            isDark = context.isDarkMode;
            colors = context.komaColors;
            return const SizedBox();
          },
        ),
        theme: KomaTheme.dark,
      );

      expect(isDark, isTrue);
      expect(colors.reading, equals(KomaColors.dark.reading));
    });

    testWidgets('falls back to default tokens when extensions are absent', (
      tester,
    ) async {
      late KomaColors colors;
      late KomaSpacing spacing;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            colors = context.komaColors;
            spacing = context.komaSpacing;
            return const SizedBox();
          },
        ),
        theme: ThemeData.light(),
      );

      expect(colors.reading, equals(KomaColors.light.reading));
      expect(spacing.md, equals(16.0));
    });
  });
}
