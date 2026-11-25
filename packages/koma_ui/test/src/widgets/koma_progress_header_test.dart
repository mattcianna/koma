import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaProgressHeader', () {
    testWidgets('renders title, author, and progress percentage', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(
          title: 'Chainsaw Man',
          author: 'Tatsuki Fujimoto',
          readChapters: 50,
          totalChapters: 100,
        ),
      );

      expect(find.text('Chainsaw Man'), findsOneWidget);
      expect(find.text('Tatsuki Fujimoto'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('50 of 100 Chapters'), findsOneWidget);
    });

    testWidgets('renders custom progressFractionLabel when supplied', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(
          readChapters: 10,
          totalChapters: 20,
          progressFractionLabel: 'Ch. 10 / 20',
        ),
      );

      expect(find.text('Ch. 10 / 20'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('renders custom coverImage widget when supplied', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(
          readChapters: 5,
          totalChapters: 10,
          coverImage: KeyedSubtree(
            key: Key('custom-cover'),
            child: SizedBox(width: 56, height: 80),
          ),
        ),
      );

      expect(find.byKey(const Key('custom-cover')), findsOneWidget);
    });

    testWidgets('renders coverImageUrl and exercises image builders', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(
          title: 'Cover URL Manga',
          coverImageUrl: 'https://example.com/cover.png',
          readChapters: 1,
          totalChapters: 5,
        ),
      );

      final cachedImageFinder = find.byType(CachedNetworkImage);
      expect(cachedImageFinder, findsOneWidget);

      final cachedImage = tester.widget<CachedNetworkImage>(cachedImageFinder);
      await tester.pumpApp(
        Builder(
          builder: (context) => Column(
            children: [
              cachedImage.placeholder!(context, 'url'),
              cachedImage.errorWidget!(context, 'url', Exception('error')),
            ],
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    });

    testWidgets('renders statusChip when provided', (tester) async {
      await tester.pumpApp(
        const KomaProgressHeader(
          readChapters: 5,
          totalChapters: 10,
          statusChip: Text('Reading Status'),
        ),
      );

      expect(find.text('Reading Status'), findsOneWidget);
    });

    testWidgets('handles continue button tap callback', (tester) async {
      var pressed = false;

      await tester.pumpApp(
        KomaProgressHeader(
          readChapters: 5,
          totalChapters: 10,
          continueChapterLabel: 'Continue Ch. 6',
          onContinuePressed: () => pressed = true,
        ),
      );

      expect(find.text('Continue Ch. 6'), findsOneWidget);
      await tester.tap(find.text('Continue Ch. 6'));
      expect(pressed, isTrue);
    });

    testWidgets('handles zero totalChapters without division error', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(readChapters: 0, totalChapters: 0),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 of 0 Chapters'), findsOneWidget);
    });

    testWidgets('includes liveRegion semantics for accessibility', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(readChapters: 25, totalChapters: 100),
      );

      final liveRegionFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label == '25% complete, 25 of 100 chapters read',
      );
      expect(liveRegionFinder, findsOneWidget);
    });

    testWidgets('supports custom progressSummaryText and semantics overrides', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaProgressHeader(
          title: 'Manga di Test',
          readChapters: 10,
          totalChapters: 20,
          progressSummaryText: '10 su 20 Capitoli',
          progressSemanticsLabel: 'Avanzamento: 50% completato, 10 di 20 letti',
          coverSemanticsLabel: 'Copertina di Manga di Test',
        ),
      );

      expect(find.text('10 su 20 Capitoli'), findsOneWidget);

      final liveRegionFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label ==
                'Avanzamento: 50% completato, 10 di 20 letti',
      );
      expect(liveRegionFinder, findsOneWidget);

      final coverSemanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.image == true &&
            widget.properties.label == 'Copertina di Manga di Test',
      );
      expect(coverSemanticsFinder, findsOneWidget);
    });

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpApp(
          KomaProgressHeader(
            readChapters: 5,
            totalChapters: 10,
            continueChapterLabel: 'Continue Ch. 6',
            onContinuePressed: () {},
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpApp(
          KomaProgressHeader(
            readChapters: 5,
            totalChapters: 10,
            continueChapterLabel: 'Continue Ch. 6',
            onContinuePressed: () {},
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
          KomaProgressHeader(
            title: 'Very Long Manga Title With Expansive Subtitles That Wrap',
            author: 'Renowned Manga Author Name',
            readChapters: 78,
            totalChapters: 142,
            continueChapterLabel: 'Continue Reading Chapter 79 Right Now',
            onContinuePressed: () {},
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      }
    });
  });
}
