import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaEmptyState', () {
    testWidgets('renders headline, description, and fallback icon', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaEmptyState(
          title: 'Empty Library',
          description: 'You have not added any manga yet.',
        ),
      );

      expect(find.text('Empty Library'), findsOneWidget);
      expect(find.text('You have not added any manga yet.'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('renders custom fallback icon when specified', (tester) async {
      await tester.pumpApp(
        const KomaEmptyState(
          title: 'No Search Results',
          description: 'Try adjusting your search terms.',
          fallbackIcon: Icons.search_off_rounded,
        ),
      );

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('renders image asset and exercises error builder', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaEmptyState(
          title: 'Asset Empty State',
          description: 'Testing asset image fallback',
          imageAssetPath: 'assets/illustrations/empty_library.png',
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      await tester.pumpApp(
        Builder(
          builder: (context) => imageWidget.errorBuilder!(
            context,
            Exception('asset load failed'),
            null,
          ),
        ),
      );

      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('renders action button and triggers callback', (tester) async {
      var pressed = false;

      await tester.pumpApp(
        KomaEmptyState(
          title: 'Empty State',
          description: 'Actionable empty state.',
          actionLabel: 'Discover Manga',
          onActionPressed: () => pressed = true,
        ),
      );

      expect(find.text('Discover Manga'), findsOneWidget);
      await tester.tap(find.text('Discover Manga'));
      expect(pressed, isTrue);
    });

    testWidgets('action button meets >= 48dp touch target threshold', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaEmptyState(
          title: 'Empty State',
          description: 'Actionable empty state.',
          actionLabel: 'Explore',
          onActionPressed: () {},
        ),
      );

      final buttonFinder = find.byType(FilledButton);
      expect(buttonFinder, findsOneWidget);

      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(kKomaMinTouchTarget));
    });

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpApp(
          KomaEmptyState(
            title: 'Empty State Light',
            description: 'Description text.',
            actionLabel: 'Action',
            onActionPressed: () {},
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpApp(
          KomaEmptyState(
            title: 'Empty State Dark',
            description: 'Description text dark.',
            actionLabel: 'Action Dark',
            onActionPressed: () {},
          ),
          theme: KomaTheme.dark,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      },
    );

    testWidgets('renders cleanly on 320x568 and 360x800 at 200% font scaling', (
      tester,
    ) async {
      for (final size in const [Size(320, 568), Size(360, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpApp(
          KomaEmptyState(
            title: 'Your Reading History Timeline Is Currently Empty',
            description:
                'Chapters marked as read or completed will '
                'automatically appear here ordered chronologically by '
                'read date.',
            actionLabel: 'Explore MangaDex Directory',
            onActionPressed: () {},
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      }
    });
  });
}
