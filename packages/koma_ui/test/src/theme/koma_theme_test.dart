import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

void main() {
  group('KomaTheme', () {
    test('light theme has expected Material 3 and Koma configurations', () {
      final theme = KomaTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(const Color(0xFFBE123C)));
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFAF8F5)));
      expect(theme.materialTapTargetSize, equals(MaterialTapTargetSize.padded));

      final komaColors = theme.extension<KomaColors>();
      expect(komaColors, isNotNull);
      expect(komaColors?.reading, equals(const Color(0xFFBE123C)));

      final komaSpacing = theme.extension<KomaSpacing>();
      expect(komaSpacing, isNotNull);

      expect(theme.appBarTheme.elevation, equals(0));
      expect(theme.cardTheme.elevation, equals(0));
      expect(
        theme.filledButtonTheme.style?.minimumSize?.resolve({}),
        equals(const Size(double.infinity, 48)),
      );
      expect(
        theme.iconButtonTheme.style?.minimumSize?.resolve({}),
        equals(const Size(48, 48)),
      );
      expect(
        theme.outlinedButtonTheme.style?.minimumSize?.resolve({}),
        equals(const Size(48, 48)),
      );
      expect(
        theme.textButtonTheme.style?.minimumSize?.resolve({}),
        equals(const Size(48, 48)),
      );
    });

    test('dark theme has expected Material 3 and Koma configurations', () {
      final theme = KomaTheme.dark;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(const Color(0xFFFB7185)));
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF0D0D10)));

      final komaColors = theme.extension<KomaColors>();
      expect(komaColors, isNotNull);
      expect(komaColors?.reading, equals(const Color(0xFFFB7185)));

      final komaSpacing = theme.extension<KomaSpacing>();
      expect(komaSpacing, isNotNull);

      expect(theme.cardTheme.color, equals(const Color(0xFF16161B)));
    });

    test('navigationBarTheme iconTheme resolves selection state', () {
      final theme = KomaTheme.light;
      final navTheme = theme.navigationBarTheme;

      final selectedIcon = navTheme.iconTheme?.resolve({WidgetState.selected});
      expect(selectedIcon?.color, equals(theme.colorScheme.primary));

      final unselectedIcon = navTheme.iconTheme?.resolve({});
      expect(unselectedIcon?.color, equals(theme.colorScheme.onSurfaceVariant));
    });

    testWidgets('KomaPageTransitionsBuilder returns child without motion when '
        'disableAnimations is true', (tester) async {
      const builder = KomaPageTransitionsBuilder();
      const testChild = Text('Child');
      Widget? builtWidget;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                final route = MaterialPageRoute<void>(
                  builder: (_) => const SizedBox(),
                );
                return builtWidget = builder.buildTransitions<void>(
                  route,
                  context,
                  kAlwaysCompleteAnimation,
                  kAlwaysDismissedAnimation,
                  testChild,
                );
              },
            ),
          ),
        ),
      );

      expect(builtWidget, same(testChild));
    });

    testWidgets(
      'KomaPageTransitionsBuilder animates when disableAnimations is false',
      (tester) async {
        const builder = KomaPageTransitionsBuilder();
        const testChild = Text('Child');
        Widget? builtWidget;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  final route = MaterialPageRoute<void>(
                    builder: (_) => const SizedBox(),
                  );
                  return builtWidget = builder.buildTransitions<void>(
                    route,
                    context,
                    kAlwaysCompleteAnimation,
                    kAlwaysDismissedAnimation,
                    testChild,
                  );
                },
              ),
            ),
          ),
        );

        expect(builtWidget, isNot(same(testChild)));
      },
    );
  });
}
