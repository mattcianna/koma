import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaMangaCard', () {
    testWidgets('renders title, author, and handles tap callback', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpApp(
        KomaMangaCard(
          title: 'Chainsaw Man',
          author: 'Tatsuki Fujimoto',
          onTap: () => tapped = true,
          imageBuilder: (context) => const SizedBox(),
        ),
      );

      expect(find.text('Chainsaw Man'), findsOneWidget);
      expect(find.text('Tatsuki Fujimoto'), findsOneWidget);

      await tester.tap(find.text('Chainsaw Man'));
      expect(tapped, isTrue);
    });

    testWidgets('renders unread badge when unreadCount > 0', (tester) async {
      await tester.pumpApp(
        KomaMangaCard(
          title: 'Frieren',
          unreadCount: 5,
          onTap: () {},
          imageBuilder: (context) => const SizedBox(),
        ),
      );

      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('renders reading progress indicator when progress provided', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaMangaCard(
          title: 'Dungeon Meshi',
          progress: 0.75,
          onTap: () {},
          imageBuilder: (context) => const SizedBox(),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders statusChip when provided', (tester) async {
      await tester.pumpApp(
        KomaMangaCard(
          title: 'Berserk',
          statusChip: const Text('Reading Badge'),
          onTap: () {},
          imageBuilder: (context) => const SizedBox(),
        ),
      );

      expect(find.text('Reading Badge'), findsOneWidget);
    });

    testWidgets('constructs CachedNetworkImage with kKomaUserAgentHeaders', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaMangaCard(
          title: 'Oshi no Ko',
          imageUrl: 'https://uploads.mangadex.org/covers/123/cover.jpg',
          onTap: () {},
        ),
      );

      final cachedImageFinder = find.byType(CachedNetworkImage);
      expect(cachedImageFinder, findsOneWidget);

      final cachedImage = tester.widget<CachedNetworkImage>(cachedImageFinder);
      expect(cachedImage.httpHeaders, equals(kKomaUserAgentHeaders));
      expect(cachedImage.httpHeaders?['User-Agent'], equals(kKomaUserAgent));

      // Test placeholder and errorWidget builders
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

    testWidgets('fallback placeholder is shown when imageUrl is null', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaMangaCard(title: 'No Image Manga', onTap: () {}),
      );

      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets(
      'semantics label contains title, author, unread count, progress',
      (tester) async {
        await tester.pumpApp(
          KomaMangaCard(
            title: 'Chainsaw Man',
            author: 'Tatsuki Fujimoto',
            unreadCount: 3,
            progress: 0.5,
            onTap: () {},
            imageBuilder: (context) => const SizedBox(),
          ),
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Chainsaw Man, by Tatsuki Fujimoto, 3 unread chapters, '
                      '50% completed',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets('interactive hit target meets >= 48x48dp threshold', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaMangaCard(
          title: 'Hit Target Manga',
          width: 180,
          onTap: () {},
          imageBuilder: (context) => const SizedBox(),
        ),
      );

      final cardSize = tester.getSize(find.byType(KomaMangaCard));
      expect(cardSize.width, greaterThanOrEqualTo(kKomaMinTouchTarget));
      expect(cardSize.height, greaterThanOrEqualTo(kKomaMinTouchTarget));
    });

    testWidgets('uses custom semanticsLabel verbatim when provided', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaMangaCard(
          title: 'Berserk',
          author: 'Kentaro Miura',
          unreadCount: 10,
          semanticsLabel: 'Berserk di Kentaro Miura, 10 capitoli non letti',
          onTap: () {},
          imageBuilder: (context) => const SizedBox(),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Berserk di Kentaro Miura, 10 capitoli non letti' &&
            widget.properties.button == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpApp(
          KomaMangaCard(
            title: 'Accessible Manga',
            author: 'Author Name',
            onTap: () {},
            imageBuilder: (context) => const SizedBox(),
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpApp(
          KomaMangaCard(
            title: 'Accessible Manga Dark',
            author: 'Author Name',
            unreadCount: 3,
            onTap: () {},
            imageBuilder: (context) => const SizedBox(),
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
          KomaMangaCard(
            title: 'A Very Long Manga Title That Might Wrap Across Lines',
            author: 'Detailed Author And Artist Name',
            unreadCount: 42,
            progress: 0.85,
            onTap: () {},
            imageBuilder: (context) => const SizedBox(),
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('renders footerAction independently outside card tap target', (
      tester,
    ) async {
      var cardTapped = false;
      var footerTapped = false;

      await tester.pumpApp(
        KomaMangaCard(
          title: 'I Want to End This Love Game',
          unreadCount: 1,
          onTap: () => cardTapped = true,
          imageBuilder: (context) => const SizedBox(),
          footerAction: FilledButton(
            onPressed: () => footerTapped = true,
            child: const Text('Read Ch. 73'),
          ),
        ),
      );

      await tester.tap(find.text('Read Ch. 73'));
      await tester.pump();
      expect(footerTapped, isTrue);
      expect(cardTapped, isFalse);

      await tester.tap(find.text('I Want to End This Love Game'));
      await tester.pump();
      expect(cardTapped, isTrue);
    });

    testWidgets(
      'passes a11y guidelines with footerAction in light and dark themes',
      (tester) async {
        final handle = tester.ensureSemantics();

        for (final theme in [KomaTheme.light, KomaTheme.dark]) {
          await tester.pumpApp(
            KomaMangaCard(
              title: 'Accessible With Footer',
              unreadCount: 2,
              onTap: () {},
              imageBuilder: (context) => const SizedBox(),
              footerAction: Builder(
                builder: (context) => FilledButton.tonalIcon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colorScheme.primaryContainer,
                    foregroundColor: context.colorScheme.onPrimaryContainer,
                    minimumSize: const Size(
                      double.infinity,
                      kKomaMinTouchTarget,
                    ),
                  ),
                  icon: const ExcludeSemantics(
                    child: Icon(Icons.check_circle_outline_rounded, size: 18),
                  ),
                  label: const Text(
                    'Read Ch. 73',
                    semanticsLabel: 'Mark chapter 73 as read',
                  ),
                ),
              ),
            ),
            theme: theme,
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }

        handle.dispose();
      },
    );

    testWidgets(
      'renders footerAction cleanly on 320x568 and 360x800 at 200% font '
      'scaling',
      (tester) async {
        for (final size in const [Size(320, 568), Size(360, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpApp(
            KomaMangaCard(
              title: 'A Very Long Manga Title That Might Wrap Across Lines',
              unreadCount: 4,
              onTap: () {},
              imageBuilder: (context) => const SizedBox(),
              footerAction: FilledButton(
                onPressed: () {},
                child: const Text(
                  'Read Ch. 73',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            textScaler: const TextScaler.linear(2),
          );

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'exposes card and footerAction as separate semantic button nodes',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpApp(
          KomaMangaCard(
            title: 'Rent-A-Girlfriend',
            unreadCount: 1,
            semanticsLabel: 'Rent-A-Girlfriend, Reading, 1 unread chapter',
            onTap: () {},
            imageBuilder: (context) => const SizedBox(),
            footerAction: FilledButton(
              onPressed: () {},
              child: const Text(
                'Read Ch. 450',
                semanticsLabel:
                    'Read Ch. 450, mark Rent-A-Girlfriend chapter 450 as read',
              ),
            ),
          ),
        );

        final cardSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Rent-A-Girlfriend, Reading, 1 unread chapter' &&
              widget.properties.button == true,
        );
        final actionSemantics = find.bySemanticsLabel(
          'Read Ch. 450, mark Rent-A-Girlfriend chapter 450 as read',
        );
        expect(cardSemantics, findsOneWidget);
        expect(actionSemantics, findsOneWidget);
        expect(
          tester.getSemantics(cardSemantics).id,
          isNot(equals(tester.getSemantics(actionSemantics).id)),
        );
        handle.dispose();
      },
    );
  });
}
