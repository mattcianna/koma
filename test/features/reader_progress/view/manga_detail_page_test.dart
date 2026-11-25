import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/reader_progress/reader_progress.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockMangaRepository extends Mock implements MangaRepository;

class _MockLibraryRepository extends Mock implements LibraryRepository;

void main() {
  group('MangaDetailPage & MangaDetailView', () {
    late MangaRepository mangaRepository;
    late LibraryRepository libraryRepository;
    late StreamController<LibraryEntry?> libraryEntryController;

    const testMangaId = 'manga-uuid-123';
    const testUid = 'user-uid-456';

    const testManga = Manga(
      id: testMangaId,
      title: 'Chainsaw Man',
      authorName: 'Tatsuki Fujimoto',
      coverFileName: 'cover.jpg',
      description: 'Denji is a young man living a life of extreme poverty.',
    );

    const chapter1 = MangaChapter(chapterNumber: '1', id: 'ch-id-1');
    const chapter2 = MangaChapter(chapterNumber: '2', id: 'ch-id-2');
    const unavailableChapter = MangaChapter(
      chapterNumber: '3',
      id: '',
      isUnavailable: true,
    );

    const volume1 = MangaVolume(
      volumeNumber: '1',
      count: 3,
      chapters: [chapter1, chapter2, unavailableChapter],
    );

    const testAggregate = ChapterAggregate(
      mangaId: testMangaId,
      volumes: [volume1],
      orderedChapters: [chapter1, chapter2, unavailableChapter],
    );

    final testLibraryEntry = LibraryEntry(
      mangaId: testMangaId,
      uid: testUid,
      title: 'Chainsaw Man',
      status: ReadingStatus.reading,
      readChapters: const {'1'},
      lastReadChapter: '1',
      lastReadChapterId: 'ch-id-1',
      addedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '.',
          );
      registerFallbackValue(const ChapterAggregate(mangaId: 'dummy'));
      registerFallbackValue(
        LibraryEntry(
          mangaId: 'dummy',
          uid: 'dummy',
          title: 'dummy',
          status: ReadingStatus.reading,
          addedAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      registerFallbackValue(const MangaChapter(chapterNumber: '1', id: '1'));
      registerFallbackValue(const MangaVolume(volumeNumber: '1'));
      registerFallbackValue(ReadingStatus.reading);
    });

    setUp(() {
      mangaRepository = _MockMangaRepository();
      libraryRepository = _MockLibraryRepository();
      libraryEntryController = StreamController<LibraryEntry?>.broadcast();

      when(
        () => libraryRepository.watchLibraryEntry(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
        ),
      ).thenAnswer((_) => libraryEntryController.stream);

      when(
        () => mangaRepository.getMangaDetails(
          any(),
          preferredLocales: any(named: 'preferredLocales'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => testManga);

      when(
        () => mangaRepository.getMangaAggregate(
          any(),
          translatedLanguages: any(named: 'translatedLanguages'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => testAggregate);

      when(
        () => mangaRepository.computePreviousUnreadChapters(
          aggregate: any(named: 'aggregate'),
          upToChapterNumber: any(named: 'upToChapterNumber'),
          alreadyReadChapters: any(named: 'alreadyReadChapters'),
        ),
      ).thenReturn(['2']);

      when(
        () => libraryRepository.addOrUpdateLibraryEntry(
          uid: any(named: 'uid'),
          entry: any(named: 'entry'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => libraryRepository.updateStatus(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => libraryRepository.removeFromLibrary(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
        ),
      ).thenAnswer((_) async {});

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

      when(
        () => libraryRepository.markVolumeRead(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
          volumeNumber: any(named: 'volumeNumber'),
          volumeChapterNumbers: any(named: 'volumeChapterNumbers'),
          mangaTitle: any(named: 'mangaTitle'),
          coverFileName: any(named: 'coverFileName'),
          lastChapterNumberInVolume: any(named: 'lastChapterNumberInVolume'),
          lastChapterIdInVolume: any(named: 'lastChapterIdInVolume'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => libraryRepository.markPreviousAsRead(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
          targetChapterNumber: any(named: 'targetChapterNumber'),
          targetChapterId: any(named: 'targetChapterId'),
          previousChapterNumbersToMark: any(
            named: 'previousChapterNumbersToMark',
          ),
          mangaTitle: any(named: 'mangaTitle'),
          coverFileName: any(named: 'coverFileName'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await libraryEntryController.close();
    });

    Widget buildSubject({
      ThemeData? theme,
      Future<bool> Function(Uri uri)? urlLauncher,
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
          child: MangaDetailPage(
            mangaId: testMangaId,
            uid: testUid,
            mangaRepository: mangaRepository,
            libraryRepository: libraryRepository,
            urlLauncher: urlLauncher,
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
        libraryEntryController.add(testLibraryEntry);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

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
          libraryEntryController.add(testLibraryEntry);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Chainsaw Man'), findsWidgets);
        },
      );
    }

    testWidgets('renders progress header, synopsis, and volume accordion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chainsaw Man'), findsWidgets);
      expect(find.text('Tatsuki Fujimoto'), findsOneWidget);
      expect(find.text('Synopsis'), findsOneWidget);
      expect(find.text('Volume 1'), findsOneWidget);
      expect(find.text('Ch. 1'), findsWidgets);
    });

    testWidgets('toggles chapter read state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find toggle for Chapter 2
      final ch2ToggleFinder = find.byTooltip('Mark Chapter 2 as read');
      expect(ch2ToggleFinder, findsOneWidget);

      await tester.tap(ch2ToggleFinder);
      await tester.pump();

      verify(
        () => libraryRepository.toggleChapterRead(
          uid: testUid,
          mangaId: testMangaId,
          chapterNumber: '2',
          isRead: true,
          chapterId: 'ch-id-2',
          mangaTitle: 'Chainsaw Man',
          coverFileName: 'cover.jpg',
        ),
      ).called(1);
    });

    testWidgets('marks entire volume as read', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final markVolumeButton = find.byTooltip('Mark volume as read: Volume 1');
      expect(markVolumeButton, findsOneWidget);

      await tester.tap(markVolumeButton);
      await tester.pump();

      verify(
        () => libraryRepository.markVolumeRead(
          uid: testUid,
          mangaId: testMangaId,
          volumeNumber: '1',
          volumeChapterNumbers: ['1', '2', '3'],
          mangaTitle: 'Chainsaw Man',
          coverFileName: 'cover.jpg',
          lastChapterNumberInVolume: '3',
          lastChapterIdInVolume: '',
        ),
      ).called(1);
    });

    testWidgets('triggers bulk previous read sheet and confirms', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final bulkButtonFinder = find.byTooltip(
        'Mark previous chapters as read up to Chapter 2',
      );
      expect(bulkButtonFinder, findsOneWidget);

      await tester.tap(bulkButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(KomaBulkReadSheet), findsOneWidget);
      expect(find.text('Mark previous chapters as read?'), findsOneWidget);

      await tester.tap(find.text('Mark 1 Chapters (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => libraryRepository.markPreviousAsRead(
          uid: testUid,
          mangaId: testMangaId,
          targetChapterNumber: '2',
          targetChapterId: 'ch-id-2',
          previousChapterNumbersToMark: ['2'],
          mangaTitle: 'Chainsaw Man',
          coverFileName: 'cover.jpg',
        ),
      ).called(1);
    });

    testWidgets('launches external MangaDex URL on external link tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Uri? launchedUri;

      await tester.pumpWidget(
        buildSubject(
          urlLauncher: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      );
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final openFinder = find.byTooltip('Open Chapter 1 on MangaDex');
      expect(openFinder, findsOneWidget);

      await tester.tap(openFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        launchedUri,
        equals(Uri.parse('https://mangadex.org/chapter/ch-id-1')),
      );
    });

    testWidgets('shows notice when chapter is unavailable', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final openFinder = find.byTooltip('Open Chapter 3 on MangaDex');
      expect(openFinder, findsOneWidget);

      await tester.tap(openFinder);
      await tester.pump();

      expect(
        find.text('This chapter is currently unavailable on MangaDex.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'opens status picker and removes from library with confirmation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject());
        libraryEntryController.add(testLibraryEntry);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap on status chip in progress header
        final readingChip = find.byWidgetPredicate(
          (widget) =>
              widget is KomaStatusChip &&
              widget.status == KomaStatusType.reading &&
              widget.onTap != null,
        );
        expect(readingChip, findsOneWidget);

        await tester.tap(readingChip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Change status'), findsOneWidget);
        expect(find.text('Remove from library'), findsOneWidget);

        // Tap Remove from library
        await tester.tap(find.text('Remove from library'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Remove from library?'), findsOneWidget);

        // Tap Remove confirm
        await tester.tap(find.text('Remove'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => libraryRepository.removeFromLibrary(
            uid: testUid,
            mangaId: testMangaId,
          ),
        ).called(1);
      },
    );

    testWidgets('renders cleanly under 200% font scaling with zero overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildSubject(textScaler: const TextScaler.linear(2)),
      );
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Chainsaw Man'), findsWidgets);
    });

    testWidgets(
      'auto-expands first volume with unread chapters and supports quick '
      'mark latest unread button',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ch1 = MangaChapter(chapterNumber: '1', id: 'ch-id-1');
        const ch2 = MangaChapter(chapterNumber: '2', id: 'ch-id-2');
        const ch3 = MangaChapter(chapterNumber: '3', id: 'ch-id-3');
        const vol1Read = MangaVolume(
          volumeNumber: '1',
          count: 1,
          chapters: [ch1],
        );
        const vol2Unread = MangaVolume(
          volumeNumber: '2',
          count: 2,
          chapters: [ch2, ch3],
        );
        const multiVolumeAggregate = ChapterAggregate(
          mangaId: testMangaId,
          volumes: [vol1Read, vol2Unread],
          orderedChapters: [ch1, ch2, ch3],
        );

        when(
          () => mangaRepository.getMangaAggregate(
            any(),
            translatedLanguages: any(named: 'translatedLanguages'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => multiVolumeAggregate);

        await tester.pumpWidget(buildSubject());
        libraryEntryController.add(testLibraryEntry);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Volume 1 is all read so Ch. 1 starts collapsed; Volume 2 is unread
        // so Ch. 2 and Ch. 3 are expanded immediately.
        expect(find.text('Ch. 1'), findsNothing);
        expect(find.text('Ch. 2'), findsOneWidget);
        expect(find.text('Ch. 3'), findsOneWidget);

        final quickLatestBtn = find.byKey(
          const Key('manga_detail_quick_mark_latest_button'),
        );
        expect(quickLatestBtn, findsOneWidget);
        expect(find.text('Mark Ch. 3 as read'), findsOneWidget);

        await tester.ensureVisible(quickLatestBtn);
        await tester.tap(quickLatestBtn);
        await tester.pump();

        verify(
          () => libraryRepository.toggleChapterRead(
            uid: testUid,
            mangaId: testMangaId,
            chapterNumber: '3',
            isRead: true,
            chapterId: 'ch-id-3',
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
          ),
        ).called(1);
      },
    );

    testWidgets('renders cleanly on 320x568 at 300% Dynamic Type scale with '
        'Label in Name', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildSubject(textScaler: const TextScaler.linear(3)),
      );
      libraryEntryController.add(testLibraryEntry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      final markButton = find.byKey(
        const Key('manga_detail_quick_mark_latest_button'),
      );
      await tester.scrollUntilVisible(
        markButton,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      expect(find.text('Mark Ch. 3 as read'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Mark Ch. 3 as read, latest unread chapter of Chainsaw Man',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
