import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/search/search.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockMangaRepository extends Mock implements MangaRepository;

void main() {
  group('SearchPage & SearchView', () {
    late MangaRepository mangaRepository;

    const testManga1 = Manga(
      id: 'manga-csm',
      title: 'Chainsaw Man',
      authorName: 'Tatsuki Fujimoto',
      coverUrl256: 'https://uploads.mangadex.org/covers/csm/256.jpg',
    );
    const testManga2 = Manga(
      id: 'manga-frieren',
      title: "Frieren: Beyond Journey's End",
      authorName: 'Kanehito Yamada',
      coverUrl256: 'https://uploads.mangadex.org/covers/frieren/256.jpg',
    );

    setUp(() {
      mangaRepository = _MockMangaRepository();
      when(
        () => mangaRepository.searchManga(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          translatedLanguages: any(named: 'translatedLanguages'),
          contentRatings: any(named: 'contentRatings'),
          preferredLocales: any(named: 'preferredLocales'),
        ),
      ).thenAnswer((_) async => [testManga1, testManga2]);
    });

    Widget buildSubject({
      ValueChanged<String>? onMangaTap,
      TextScaler textScaler = TextScaler.noScaling,
      Size surfaceSize = const Size(800, 1200),
      ThemeData? theme,
    }) {
      return RepositoryProvider<MangaRepository>.value(
        value: mangaRepository,
        child: MaterialApp(
          theme: theme ?? KomaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: surfaceSize, textScaler: textScaler),
            child: SearchPage(
              onMangaTap: onMangaTap,
              cardImageBuilder: (context) =>
                  const SizedBox(width: 100, height: 150),
            ),
          ),
        ),
      );
    }

    testWidgets('renders search bar, popular header, and manga cards', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discover_search_bar')), findsOneWidget);
      expect(find.byKey(const Key('manga_card_manga-csm')), findsOneWidget);
      expect(find.byKey(const Key('manga_card_manga-frieren')), findsOneWidget);
    });

    testWidgets(
      'tapping manga card invokes onMangaTap callback with manga ID',
      (tester) async {
        String? tappedId;
        await tester.pumpWidget(
          buildSubject(onMangaTap: (id) => tappedId = id),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('manga_card_manga-csm')));
        await tester.pump();

        expect(tappedId, equals('manga-csm'));
      },
    );

    testWidgets(
      'typing query in search bar triggers search and shows clear button',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('discover_search_bar')),
          'berserk',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('discover_search_clear_button')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('discover_search_clear_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('discover_search_clear_button')),
          findsNothing,
        );
      },
    );

    testWidgets('renders empty state when search returns zero results', (
      tester,
    ) async {
      when(
        () => mangaRepository.searchManga(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          translatedLanguages: any(named: 'translatedLanguages'),
          contentRatings: any(named: 'contentRatings'),
          preferredLocales: any(named: 'preferredLocales'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discover_empty_state')), findsOneWidget);
    });

    testWidgets('renders error state and retries on failure', (tester) async {
      when(
        () => mangaRepository.searchManga(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          translatedLanguages: any(named: 'translatedLanguages'),
          contentRatings: any(named: 'contentRatings'),
          preferredLocales: any(named: 'preferredLocales'),
        ),
      ).thenThrow(const MangaRateLimitException('Rate limited'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discover_error_state')), findsOneWidget);

      when(
        () => mangaRepository.searchManga(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          translatedLanguages: any(named: 'translatedLanguages'),
          contentRatings: any(named: 'contentRatings'),
          preferredLocales: any(named: 'preferredLocales'),
        ),
      ).thenAnswer((_) async => [testManga1]);

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manga_card_manga-csm')), findsOneWidget);
    });

    testWidgets('renders manga cards with localized author semantics', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('manga_card_manga-csm'));
      expect(cardFinder, findsOneWidget);
      final card = tester.widget<KomaMangaCard>(cardFinder);
      expect(card.semanticsLabel, 'Chainsaw Man, by Tatsuki Fujimoto');
    });

    testWidgets('meets accessibility guidelines in light and dark themes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        for (final theme in [KomaTheme.light, KomaTheme.dark]) {
          await tester.pumpWidget(buildSubject(theme: theme));
          await tester.pumpAndSettle();

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'renders without overflow on narrow 320x568 and 360x800 screens at 2.0x',
      (tester) async {
        for (final size in const [Size(320, 568), Size(360, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildSubject(
              textScaler: const TextScaler.linear(2),
              surfaceSize: size,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('discover_search_bar')), findsOneWidget);
          expect(find.byKey(const Key('manga_card_manga-csm')), findsOneWidget);
        }
      },
    );
  });
}
