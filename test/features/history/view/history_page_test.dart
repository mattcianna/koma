import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/history/history.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository;

void main() {
  group('HistoryPage & HistoryView', () {
    late LibraryRepository libraryRepository;
    late StreamController<List<ReadingHistoryEvent>> historyController;

    setUp(() {
      libraryRepository = _MockLibraryRepository();
      historyController =
          StreamController<List<ReadingHistoryEvent>>.broadcast();
      when(
        () => libraryRepository.watchReadingHistory(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => historyController.stream);
    });

    tearDown(() async {
      await historyController.close();
    });

    Widget buildSubject({
      ValueChanged<String>? onMangaTap,
      double textScaleFactor = 1.0,
      Size surfaceSize = const Size(800, 1200),
      ThemeData? theme,
    }) {
      return RepositoryProvider<LibraryRepository>.value(
        value: libraryRepository,
        child: MaterialApp(
          theme: theme ?? KomaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: surfaceSize,
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: HistoryPage(uid: 'user-123', onMangaTap: onMangaTap),
          ),
        ),
      );
    }

    testWidgets('renders loading indicator initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when history list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      historyController.add([]);
      await tester.pumpAndSettle();

      expect(find.byType(KomaEmptyState), findsOneWidget);
      expect(find.text('No reading history yet'), findsOneWidget);
    });

    testWidgets('renders error state when stream emits error', (tester) async {
      await tester.pumpWidget(buildSubject());
      historyController.addError(Exception('Failed to load history'));
      await tester.pumpAndSettle();

      expect(find.byType(KomaEmptyState), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders history event cards and handles manga tap', (
      tester,
    ) async {
      String? tappedMangaId;
      final now = DateTime.now();
      final events = [
        ReadingHistoryEvent(
          eventId: 'evt-1',
          uid: 'user-123',
          mangaId: 'manga-csm',
          mangaTitle: 'Chainsaw Man',
          actionType: ReadingHistoryActionType.chapterRead,
          chapterNumbers: const ['140'],
          chaptersCount: 1,
          timestamp: now,
        ),
        ReadingHistoryEvent(
          eventId: 'evt-2',
          uid: 'user-123',
          mangaId: 'manga-frieren',
          mangaTitle: "Frieren: Beyond Journey's End",
          actionType: ReadingHistoryActionType.volumeRead,
          volumeNumber: '5',
          chapterNumbers: const ['38', '39', '40'],
          chaptersCount: 3,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        ReadingHistoryEvent(
          eventId: 'evt-3',
          uid: 'user-123',
          mangaId: 'manga-meshi',
          mangaTitle: 'Delicious in Dungeon',
          actionType: ReadingHistoryActionType.bulkPreviousRead,
          chapterNumbers: const ['1', '2', '3', '4', '5'],
          chaptersCount: 5,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        buildSubject(onMangaTap: (id) => tappedMangaId = id),
      );
      historyController.add(events);
      await tester.pumpAndSettle();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      expect(find.text("Frieren: Beyond Journey's End"), findsOneWidget);
      expect(find.text('Delicious in Dungeon'), findsOneWidget);

      await tester.tap(find.text('Chainsaw Man'));
      await tester.pumpAndSettle();

      expect(tappedMangaId, equals('manga-csm'));
    });

    testWidgets('renders cleanly at 200% font scale without overflow', (
      tester,
    ) async {
      final now = DateTime.now();
      final events = [
        ReadingHistoryEvent(
          eventId: 'evt-1',
          uid: 'user-123',
          mangaId: 'manga-csm',
          mangaTitle:
              'Chainsaw Man Extra Long Title That Stretches Beyond Boundaries',
          actionType: ReadingHistoryActionType.volumeRead,
          volumeNumber: '12',
          chapterNumbers: const ['100', '101', '102', '103'],
          chaptersCount: 4,
          timestamp: now,
        ),
      ];

      await tester.pumpWidget(buildSubject(textScaleFactor: 2));
      historyController.add(events);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Chainsaw Man Extra Long Title That Stretches Beyond Boundaries',
        ),
        findsOneWidget,
      );
    });

    testWidgets('meets accessibility guidelines in light and dark themes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        final now = DateTime.now();
        final events = [
          ReadingHistoryEvent(
            eventId: 'evt-1',
            uid: 'user-123',
            mangaId: 'manga-csm',
            mangaTitle: 'Chainsaw Man',
            actionType: ReadingHistoryActionType.chapterRead,
            chapterNumbers: const ['140'],
            chaptersCount: 1,
            timestamp: now,
          ),
        ];

        for (final theme in [KomaTheme.light, KomaTheme.dark]) {
          await tester.pumpWidget(buildSubject(theme: theme));
          historyController.add(events);
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
        final now = DateTime.now();
        final events = [
          ReadingHistoryEvent(
            eventId: 'evt-1',
            uid: 'user-123',
            mangaId: 'manga-csm',
            mangaTitle:
                'Chainsaw Man Extra Long Title '
                'That Stretches Beyond Boundaries',
            actionType: ReadingHistoryActionType.volumeRead,
            volumeNumber: '12',
            chapterNumbers: const ['100', '101', '102', '103'],
            chaptersCount: 4,
            timestamp: now,
          ),
        ];

        for (final size in const [Size(320, 568), Size(360, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildSubject(textScaleFactor: 2, surfaceSize: size),
          );
          historyController.add(events);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(Card), findsOneWidget);
        }
      },
    );
  });
}
