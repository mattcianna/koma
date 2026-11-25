import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/library/library.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository;

class _MockMangaRepository extends Mock implements MangaRepository;

void main() {
  group('LibraryBloc', () {
    late LibraryRepository libraryRepository;
    late StreamController<List<LibraryEntry>> entriesController;

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

    test('initial state has LibraryStatus.initial', () {
      final bloc = LibraryBloc(libraryRepository: libraryRepository);
      expect(bloc.state.status, equals(LibraryStatus.initial));
      expect(bloc.state.allEntries, isEmpty);
      expect(bloc.state.selectedStatus, isNull);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.isLibraryEmpty, isTrue);
      expect(bloc.state.isFilterEmpty, isFalse);
    });

    blocTest<LibraryBloc, LibraryState>(
      'emits [loading, success] when LibraryStarted added and entries arrive',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      act: (bloc) async {
        bloc.add(const LibraryStarted(uid: 'user-123'));
        await Future<void>.delayed(Duration.zero);
        entriesController.add([entry1, entry2]);
      },
      expect: () => [
        const LibraryState(status: LibraryStatus.loading),
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1, entry2],
        ),
      ],
      verify: (_) {
        verify(() => libraryRepository.watchLibrary('user-123')).called(1);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'emits [loading, failure] when LibraryStarted stream emits error',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      act: (bloc) async {
        bloc.add(const LibraryStarted(uid: 'user-123'));
        await Future<void>.delayed(Duration.zero);
        entriesController.addError(Exception('Firestore error'));
      },
      expect: () => [
        const LibraryState(status: LibraryStatus.loading),
        predicate<LibraryState>((state) {
          return state.status == LibraryStatus.failure &&
              state.errorMessage!.contains('Firestore error');
        }),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'updates selectedStatus on LibraryStatusFilterChanged',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      seed: () => LibraryState(
        status: LibraryStatus.success,
        allEntries: [entry1, entry2],
      ),
      act: (bloc) =>
          bloc.add(const LibraryStatusFilterChanged(ReadingStatus.reading)),
      expect: () => [
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1, entry2],
          selectedStatus: ReadingStatus.reading,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.filteredEntries, equals([entry1]));
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'updates searchQuery on LibrarySearchQueryChanged',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      seed: () => LibraryState(
        status: LibraryStatus.success,
        allEntries: [entry1, entry2],
      ),
      act: (bloc) => bloc.add(const LibrarySearchQueryChanged('frieren')),
      expect: () => [
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1, entry2],
          searchQuery: 'frieren',
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.filteredEntries, equals([entry2]));
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'isFilterEmpty is true when search query yields 0 results',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      seed: () => LibraryState(
        status: LibraryStatus.success,
        allEntries: [entry1, entry2],
      ),
      act: (bloc) =>
          bloc.add(const LibrarySearchQueryChanged('nonexistent title')),
      expect: () => [
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1, entry2],
          searchQuery: 'nonexistent title',
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.filteredEntries, isEmpty);
        expect(bloc.state.isFilterEmpty, isTrue);
      },
    );

    test('calculateUnreadHint calculates diff correctly', () {
      expect(calculateUnreadHint(entry1), equals(5));
      expect(calculateUnreadHint(entry2), equals(0));

      final unreadEntry = LibraryEntry(
        mangaId: 'manga-3',
        uid: 'user-123',
        title: 'Unread Manga',
        status: ReadingStatus.reading,
        readChapters: const {'1', '2', '3'},
        latestKnownChapterNumber: '10',
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(calculateUnreadHint(unreadEntry), equals(7));

      final noLatestEntry = LibraryEntry(
        mangaId: 'manga-4',
        uid: 'user-123',
        title: 'No Latest Manga',
        status: ReadingStatus.reading,
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(calculateUnreadHint(noLatestEntry), equals(0));

      final caughtUpEntry = LibraryEntry(
        mangaId: 'manga-5',
        uid: 'user-123',
        title: 'Caught Up Manga',
        status: ReadingStatus.reading,
        lastReadChapter: '448',
        latestKnownChapterNumber: '448',
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(calculateUnreadHint(caughtUpEntry), equals(0));
    });

    test('Home section getters partition entries into 3 sections', () {
      final caughtUp = LibraryEntry(
        mangaId: 'rag',
        uid: 'user-123',
        title: 'Rent-A-Girlfriend',
        status: ReadingStatus.reading,
        lastReadChapter: '448',
        latestKnownChapterNumber: '448',
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final planToRead = LibraryEntry(
        mangaId: 'plan',
        uid: 'user-123',
        title: 'Plan Series',
        status: ReadingStatus.planToRead,
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final state = LibraryState(
        status: LibraryStatus.success,
        allEntries: [entry1, caughtUp, planToRead, entry2],
      );

      expect(state.isHomeSectionsView, isTrue);
      expect(state.toReadEntries, equals([entry1, planToRead]));
      expect(state.caughtUpEntries, equals([caughtUp]));
      expect(state.finishedOrPausedEntries, equals([entry2]));
    });

    blocTest<LibraryBloc, LibraryState>(
      'LibraryRefreshRequested syncs latest released chapters via '
      'MangaRepository',
      build: () {
        final mangaRepo = _MockMangaRepository();
        when(() => mangaRepo.getLatestReleasedChapter('rag')).thenAnswer(
          (_) async => const MangaChapter(chapterNumber: '449', id: 'ext:449'),
        );
        when(
          () => libraryRepository.updateLatestKnownChapter(
            uid: 'user-123',
            mangaId: 'rag',
            latestKnownChapterNumber: '449',
            latestKnownChapterId: 'ext:449',
          ),
        ).thenAnswer((_) async {});

        return LibraryBloc(
          libraryRepository: libraryRepository,
          mangaRepository: mangaRepo,
        );
      },
      act: (bloc) async {
        final caughtUp = LibraryEntry(
          mangaId: 'rag',
          uid: 'user-123',
          title: 'Rent-A-Girlfriend',
          status: ReadingStatus.reading,
          lastReadChapter: '448',
          latestKnownChapterNumber: '448',
          addedAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
        bloc.add(const LibraryStarted(uid: 'user-123'));
        await Future<void>.delayed(Duration.zero);
        entriesController.add([caughtUp]);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const LibraryRefreshRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (_) {
        verify(
          () => libraryRepository.updateLatestKnownChapter(
            uid: 'user-123',
            mangaId: 'rag',
            latestKnownChapterNumber: '449',
            latestKnownChapterId: 'ext:449',
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'LibraryQuickMarkLatestReadRequested marks latest chapter read and emits '
      'feedback',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      seed: () => LibraryState(
        status: LibraryStatus.success,
        allEntries: [entry1.copyWith(latestKnownChapterId: 'ext:ch-15')],
      ),
      act: (bloc) async {
        final target = entry1.copyWith(latestKnownChapterId: 'ext:ch-15');
        bloc.add(LibraryQuickMarkLatestReadRequested(target));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1.copyWith(latestKnownChapterId: 'ext:ch-15')],
          markingReadMangaIds: const {'manga-1'},
        ),
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1.copyWith(latestKnownChapterId: 'ext:ch-15')],
          quickMarkFeedback: const LibraryQuickMarkFeedback(
            mangaId: 'manga-1',
            mangaTitle: 'Chainsaw Man',
            chapterNumber: '15',
          ),
        ),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.toggleChapterRead(
            uid: 'user-123',
            mangaId: 'manga-1',
            chapterNumber: '15',
            isRead: true,
            chapterId: 'ext:ch-15',
            mangaTitle: 'Chainsaw Man',
          ),
        ).called(1);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'LibraryQuickMarkLatestReadRequested coerces empty chapterId to null '
      'and emits error feedback on failure',
      build: () {
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
        ).thenThrow(Exception('Write failed'));
        return LibraryBloc(libraryRepository: libraryRepository);
      },
      seed: () => LibraryState(
        status: LibraryStatus.success,
        allEntries: [entry1.copyWith(latestKnownChapterId: '')],
      ),
      act: (bloc) async {
        final target = entry1.copyWith(latestKnownChapterId: '');
        bloc.add(LibraryQuickMarkLatestReadRequested(target));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1.copyWith(latestKnownChapterId: '')],
          markingReadMangaIds: const {'manga-1'},
        ),
        LibraryState(
          status: LibraryStatus.success,
          allEntries: [entry1.copyWith(latestKnownChapterId: '')],
          quickMarkFeedback: const LibraryQuickMarkFeedback(
            mangaId: 'manga-1',
            mangaTitle: 'Chainsaw Man',
            chapterNumber: '15',
            isError: true,
          ),
        ),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.toggleChapterRead(
            uid: 'user-123',
            mangaId: 'manga-1',
            chapterNumber: '15',
            isRead: true,
            mangaTitle: 'Chainsaw Man',
          ),
        ).called(1);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'LibraryQuickMarkLatestReadRequested ignores entries without valid '
      'latest chapter',
      build: () => LibraryBloc(libraryRepository: libraryRepository),
      act: (bloc) {
        bloc.add(
          LibraryQuickMarkLatestReadRequested(
            LibraryEntry(
              mangaId: 'manga-no-latest',
              uid: 'user-123',
              title: 'No Latest',
              status: ReadingStatus.reading,
              addedAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ),
        );
      },
      expect: () => <LibraryState>[],
      verify: (_) {
        verifyNever(
          () => libraryRepository.toggleChapterRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            chapterNumber: any(named: 'chapterNumber'),
            isRead: any(named: 'isRead'),
            chapterId: any(named: 'chapterId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
          ),
        );
      },
    );

    test('resolveLibraryCoverUrl builds valid URLs', () {
      expect(resolveLibraryCoverUrl('123', null), isNull);
      expect(resolveLibraryCoverUrl('123', ''), isNull);
      expect(
        resolveLibraryCoverUrl('manga-1', 'cover.jpg'),
        equals('https://uploads.mangadex.org/covers/manga-1/cover.jpg.256.jpg'),
      );
      expect(
        resolveLibraryCoverUrl('manga-1', 'cover.jpg', size: 512),
        equals('https://uploads.mangadex.org/covers/manga-1/cover.jpg.512.jpg'),
      );
    });
  });
}
