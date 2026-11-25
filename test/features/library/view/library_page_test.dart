import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/library/library.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository;

void main() {
  group('LibraryPage & LibraryView', () {
    late LibraryRepository libraryRepository;
    late StreamController<List<LibraryEntry>> entriesController;

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '.',
          );
    });

    final entry1 = LibraryEntry(
      mangaId: 'manga-1',
      uid: 'user-123',
      title: 'Chainsaw Man',
      status: ReadingStatus.reading,
      lastReadChapter: '10',
      latestKnownChapterNumber: '15',
      addedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final entry2 = LibraryEntry(
      mangaId: 'manga-2',
      uid: 'user-123',
      title: "Frieren: Beyond Journey's End",
      status: ReadingStatus.completed,
      lastReadChapter: '120',
      latestKnownChapterNumber: '120',
      addedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUp(() {
      libraryRepository = _MockLibraryRepository();
      entriesController = StreamController<List<LibraryEntry>>.broadcast();

      when(() => libraryRepository.watchLibrary(any()))
          .thenAnswer((_) => entriesController.stream);
      when(
        () => libraryRepository.toggleChapterRead(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
          chapterNumber: any(named: 'chapterNumber'),
          isRead: any(named: 'isRead'),
          chapterId: any(named: 'chapterId'),
          mangaTitle: any(named: 'mangaTitle'),
          coverFileName: any(named: 'coverFileName'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await entriesController.close();
    });

    Widget buildSubject({
      ThemeData? theme,
      ValueChanged<String>? onMangaTap,
      VoidCallback? onDiscoverTap,
      TextScaler textScaler = TextScaler.noScaling,
    }) {
      return MaterialApp(
        theme: theme ?? KomaTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: LibraryPage(
            uid: 'user-123',
            onMangaTap: onMangaTap,
            onDiscoverTap: onDiscoverTap,
            libraryRepository: libraryRepository,
          ),
        ),
      );
    }

    for (final themeEntry in [
      ('light', KomaTheme.light),
      ('dark', KomaTheme.dark),
    ]) {
      testWidgets('meets a11y guidelines under ${themeEntry.$1} theme', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(buildSubject(theme: themeEntry.$2));
        entriesController.add([entry1, entry2]);
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    for (final size in [const Size(320, 568), const Size(360, 800)]) {
      testWidgets(
        'renders cleanly on ${size.width}x${size.height} at 200% scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildSubject(textScaler: const TextScaler.linear(2)),
          );
          entriesController.add([entry1, entry2]);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Chainsaw Man'), findsOneWidget);
        },
      );
    }

    testWidgets('renders empty state when library has zero entries', (
      tester,
    ) async {
      var discoverTapped = false;

      await tester.pumpWidget(
        buildSubject(onDiscoverTap: () => discoverTapped = true),
      );
      entriesController.add([]);
      await tester.pump();

      expect(find.byType(KomaEmptyState), findsOneWidget);
      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Discover Manga'), findsOneWidget);

      await tester.tap(find.text('Discover Manga'));
      await tester.pump();

      expect(discoverTapped, isTrue);
    });

    testWidgets('renders manga cards and triggers onMangaTap', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? tappedMangaId;

      await tester.pumpWidget(
        buildSubject(onMangaTap: (id) => tappedMangaId = id),
      );
      entriesController.add([entry1, entry2]);
      await tester.pump();

      expect(find.byKey(const Key('home_section_to_read')), findsOneWidget);
      expect(find.byKey(const Key('home_section_finished')), findsOneWidget);
      expect(find.text('Chainsaw Man'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text("Frieren: Beyond Journey's End"),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);

      await tester.ensureVisible(find.text('Chainsaw Man'));
      await tester.tap(find.text('Chainsaw Man'));
      await tester.pump();

      expect(tappedMangaId, equals('manga-1'));
    });

    testWidgets('filters entries by status chip', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      entriesController.add([entry1, entry2]);
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text("Frieren: Beyond Journey's End"),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);

      // Tap Reading status chip
      final readingChip = find.byKey(const Key('library_filter_reading'));
      await tester.ensureVisible(readingChip);
      await tester.tap(readingChip);
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      expect(find.text("Frieren: Beyond Journey's End"), findsNothing);

      // Tap Completed status chip
      final completedChip = find.byKey(const Key('library_filter_completed'));
      await tester.ensureVisible(completedChip);
      await tester.tap(completedChip);
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsNothing);
      expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);

      // Tap All filter chip
      final allChip = find.byKey(const Key('library_filter_all'));
      await tester.ensureVisible(allChip);
      await tester.tap(allChip);
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text("Frieren: Beyond Journey's End"),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);
    });

    testWidgets('filters entries by inline search and clears filter', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      entriesController.add([entry1, entry2]);
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('library_search_field')),
        'Chainsaw',
      );
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      expect(find.text("Frieren: Beyond Journey's End"), findsNothing);

      // Enter search that yields no results
      await tester.enterText(
        find.byKey(const Key('library_search_field')),
        'Unknown Title',
      );
      await tester.pump();

      expect(find.text('No titles match this filter'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text("Frieren: Beyond Journey's End"),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);
    });

    testWidgets(
      'renders up-to-date banner when all Reading entries are caught up '
      'and toggles On Hold / Finished section',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var discoverTapped = false;
        final caughtUpEntry = LibraryEntry(
          mangaId: 'manga-rag',
          uid: 'user-123',
          title: 'Rent-A-Girlfriend',
          status: ReadingStatus.reading,
          lastReadChapter: '448',
          latestKnownChapterNumber: '448',
          addedAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

        await tester.pumpWidget(
          buildSubject(onDiscoverTap: () => discoverTapped = true),
        );
        entriesController.add([caughtUpEntry, entry2]);
        await tester.pump();

        expect(find.byKey(const Key('home_section_to_read')), findsOneWidget);
        expect(find.byKey(const Key('home_caught_up_banner')), findsOneWidget);
        expect(find.text('Wow!'), findsOneWidget);
        expect(find.text("You're up to date with everything"), findsOneWidget);
        expect(find.byKey(const Key('home_section_caught_up')), findsOneWidget);
        expect(find.text('Rent-A-Girlfriend'), findsOneWidget);
        expect(find.byKey(const Key('home_section_finished')), findsOneWidget);

        await tester.tap(find.text('Discover new Manga'));
        await tester.pump();
        expect(discoverTapped, isTrue);

        // Collapse On Hold / Finished section
        final finishedHeader = find.byKey(const Key('home_section_finished'));
        await tester.scrollUntilVisible(
          finishedHeader,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(finishedHeader);
        await tester.pump();
        await tester.tap(finishedHeader);
        await tester.pump();
        expect(find.text("Frieren: Beyond Journey's End"), findsNothing);

        // Re-expand On Hold / Finished section
        await tester.ensureVisible(finishedHeader);
        await tester.tap(finishedHeader);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text("Frieren: Beyond Journey's End"),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);
      },
    );

    for (final themeEntry in [
      ('light', KomaTheme.light),
      ('dark', KomaTheme.dark),
    ]) {
      testWidgets(
        'up-to-date Home banner meets a11y guidelines under ${themeEntry.$1}',
        (tester) async {
          tester.view.physicalSize = const Size(430, 932);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final handle = tester.ensureSemantics();
          final caughtUpEntry = LibraryEntry(
            mangaId: 'manga-rag',
            uid: 'user-123',
            title: 'Rent-A-Girlfriend',
            status: ReadingStatus.reading,
            lastReadChapter: '448',
            latestKnownChapterNumber: '448',
            addedAt: DateTime(2026),
            updatedAt: DateTime(2026),
          );

          await tester.pumpWidget(buildSubject(theme: themeEntry.$2));
          entriesController.add([caughtUpEntry, entry2]);
          await tester.pumpAndSettle();

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        },
      );
    }

    testWidgets('renders cleanly under 200% font scaling without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildSubject(textScaler: const TextScaler.linear(2)),
      );
      entriesController.add([entry1, entry2]);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Chainsaw Man'), findsOneWidget);
    });

    testWidgets(
      'renders Read Ch. quick action only on Reading entries with unread '
      'chapters and marks read on tap',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        String? tappedMangaId;
        final caughtUpEntry = LibraryEntry(
          mangaId: 'manga-rag',
          uid: 'user-123',
          title: 'Rent-A-Girlfriend',
          status: ReadingStatus.reading,
          lastReadChapter: '449',
          latestKnownChapterNumber: '449',
          addedAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
        final planEntry = LibraryEntry(
          mangaId: 'manga-plan',
          uid: 'user-123',
          title: 'Plan Series',
          status: ReadingStatus.planToRead,
          latestKnownChapterNumber: '12',
          addedAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

        await tester.pumpWidget(
          buildSubject(onMangaTap: (id) => tappedMangaId = id),
        );
        entriesController.add([entry1, caughtUpEntry, planEntry, entry2]);
        await tester.pump();

        final quickReadButton = find.byKey(
          const Key('library_quick_mark_read_manga-1'),
        );
        expect(quickReadButton, findsOneWidget);
        expect(find.text('Read Ch. 15'), findsOneWidget);
        expect(
          find.byKey(const Key('library_quick_mark_read_manga-rag')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('library_quick_mark_read_manga-plan')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('library_quick_mark_read_manga-2')),
          findsNothing,
        );

        await tester.ensureVisible(quickReadButton);
        await tester.tap(quickReadButton);
        await tester.pump();

        expect(tappedMangaId, isNull);
        verify(
          () => libraryRepository.toggleChapterRead(
            uid: 'user-123',
            mangaId: 'manga-1',
            chapterNumber: '15',
            isRead: true,
            mangaTitle: 'Chainsaw Man',
          ),
        ).called(1);
        expect(find.text('Marked Chainsaw Man Ch. 15 as read'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Read Ch. 15, mark Chainsaw Man chapter 15 as read',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders cleanly on 640x800 at 200% scale and passes disabled '
        'spinner a11y guidelines', (tester) async {
      tester.view.physicalSize = const Size(640, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<void>();
      when(
        () => libraryRepository.toggleChapterRead(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
          chapterNumber: any(named: 'chapterNumber'),
          isRead: any(named: 'isRead'),
          chapterId: any(named: 'chapterId'),
          mangaTitle: any(named: 'mangaTitle'),
          coverFileName: any(named: 'coverFileName'),
        ),
      ).thenAnswer((_) => completer.future);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildSubject(textScaler: const TextScaler.linear(2)),
      );
      entriesController.add([entry1, entry2]);
      await tester.pump();
      expect(tester.takeException(), isNull);

      final quickReadButton = find.byKey(
        const Key('library_quick_mark_read_manga-1'),
      );
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -250));
      await tester.pump();
      await tester.ensureVisible(quickReadButton);
      await tester.pump();
      await tester.tap(quickReadButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      completer.complete();
      await tester.pump();
      handle.dispose();
    });
  });
}
