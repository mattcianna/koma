import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/reader_progress/reader_progress.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockMangaRepository extends Mock implements MangaRepository;

class _MockLibraryRepository extends Mock implements LibraryRepository;

void main() {
  group('MangaDetailBloc', () {
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
      description: 'Denji is a teenage boy living with a Chainsaw Devil.',
    );

    const chapter1 = MangaChapter(chapterNumber: '1', id: 'ch-id-1');
    const chapter2 = MangaChapter(chapterNumber: '2', id: 'ch-id-2');
    const chapter3 = MangaChapter(chapterNumber: '3', id: 'ch-id-3');

    const volume1 = MangaVolume(
      volumeNumber: '1',
      count: 3,
      chapters: [chapter1, chapter2, chapter3],
    );

    const testAggregate = ChapterAggregate(
      mangaId: testMangaId,
      volumes: [volume1],
      orderedChapters: [chapter1, chapter2, chapter3],
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
      ).thenReturn(['2', '3']);

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

    test('initial state has MangaDetailStatus.initial', () {
      final bloc = MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      );
      expect(bloc.state.status, equals(MangaDetailStatus.initial));
      expect(bloc.state.isInLibrary, isFalse);
      expect(bloc.state.readChaptersCount, equals(0));
      expect(bloc.state.totalChaptersCount, equals(0));
    });

    blocTest<MangaDetailBloc, MangaDetailState>(
      'emits [loading, success] when MangaDetailStarted succeeds',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      act: (bloc) => bloc.add(
        const MangaDetailStarted(mangaId: testMangaId, uid: testUid),
      ),
      expect: () => [
        const MangaDetailState(
          status: MangaDetailStatus.loading,
          mangaId: testMangaId,
          uid: testUid,
        ),
        const MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
        ),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.watchLibraryEntry(
            uid: testUid,
            mangaId: testMangaId,
          ),
        ).called(1);
        verify(() => mangaRepository.getMangaDetails(testMangaId)).called(1);
        verify(() => mangaRepository.getMangaAggregate(testMangaId)).called(1);
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'emits [loading, failure] when getMangaDetails fails',
      setUp: () {
        when(
          () => mangaRepository.getMangaDetails(
            any(),
            preferredLocales: any(named: 'preferredLocales'),
          ),
        ).thenThrow(Exception('API error'));
      },
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      act: (bloc) => bloc.add(
        const MangaDetailStarted(mangaId: testMangaId, uid: testUid),
      ),
      expect: () => [
        const MangaDetailState(
          status: MangaDetailStatus.loading,
          mangaId: testMangaId,
          uid: testUid,
        ),
        predicate<MangaDetailState>((state) {
          return state.status == MangaDetailStatus.failure &&
              state.errorMessage!.contains('API error');
        }),
      ],
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'updates libraryEntry when stream emits',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      act: (bloc) async {
        bloc.add(const MangaDetailStarted(mangaId: testMangaId, uid: testUid));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        libraryEntryController.add(testLibraryEntry);
      },
      expect: () => [
        const MangaDetailState(
          status: MangaDetailStatus.loading,
          mangaId: testMangaId,
          uid: testUid,
        ),
        const MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
        ),
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
        ),
      ],
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'calls addOrUpdateLibraryEntry on MangaDetailAddedToLibrary',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => const MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
      ),
      act: (bloc) =>
          bloc.add(const MangaDetailAddedToLibrary(ReadingStatus.planToRead)),
      verify: (_) {
        verify(
          () => libraryRepository.addOrUpdateLibraryEntry(
            uid: testUid,
            entry: any(named: 'entry'),
          ),
        ).called(1);
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'calls updateStatus on MangaDetailStatusChanged when in library',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
      ),
      act: (bloc) =>
          bloc.add(const MangaDetailStatusChanged(ReadingStatus.completed)),
      verify: (_) {
        verify(
          () => libraryRepository.updateStatus(
            uid: testUid,
            mangaId: testMangaId,
            status: ReadingStatus.completed,
          ),
        ).called(1);
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'calls removeFromLibrary on MangaDetailRemovedFromLibrary',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
      ),
      act: (bloc) => bloc.add(const MangaDetailRemovedFromLibrary()),
      verify: (_) {
        verify(
          () => libraryRepository.removeFromLibrary(
            uid: testUid,
            mangaId: testMangaId,
          ),
        ).called(1);
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'calls toggleChapterRead on MangaDetailChapterToggled',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
      ),
      act: (bloc) => bloc.add(
        const MangaDetailChapterToggled(chapter: chapter2, isRead: true),
      ),
      verify: (_) {
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
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'calls markVolumeRead on MangaDetailVolumeMarkedRead',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
      ),
      act: (bloc) => bloc.add(const MangaDetailVolumeMarkedRead(volume1)),
      verify: (_) {
        verify(
          () => libraryRepository.markVolumeRead(
            uid: testUid,
            mangaId: testMangaId,
            volumeNumber: '1',
            volumeChapterNumbers: ['1', '2', '3'],
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
            lastChapterNumberInVolume: '3',
            lastChapterIdInVolume: 'ch-id-3',
          ),
        ).called(1);
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'computes previous unread chapters on MangaDetailBulkPreviousRequested',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
      ),
      act: (bloc) => bloc.add(const MangaDetailBulkPreviousRequested(chapter3)),
      expect: () => [
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
          pendingBulkChapter: chapter3,
          pendingBulkUnreadChapters: const ['2', '3'],
        ),
      ],
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'calls markPreviousAsRead on MangaDetailBulkPreviousConfirmed',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
        pendingBulkChapter: chapter3,
        pendingBulkUnreadChapters: const ['2', '3'],
      ),
      act: (bloc) => bloc.add(const MangaDetailBulkPreviousConfirmed()),
      expect: () => [
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
          pendingBulkChapter: chapter3,
          pendingBulkUnreadChapters: const ['2', '3'],
          isBulkActionLoading: true,
        ),
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
        ),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.markPreviousAsRead(
            uid: testUid,
            mangaId: testMangaId,
            targetChapterNumber: '3',
            targetChapterId: 'ch-id-3',
            previousChapterNumbersToMark: ['2', '3'],
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
          ),
        ).called(1);
      },
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'clears pending bulk state on MangaDetailBulkPreviousDismissed',
      build: () => MangaDetailBloc(
        mangaRepository: mangaRepository,
        libraryRepository: libraryRepository,
      ),
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
        pendingBulkChapter: chapter3,
        pendingBulkUnreadChapters: const ['2', '3'],
      ),
      act: (bloc) => bloc.add(const MangaDetailBulkPreviousDismissed()),
      expect: () => [
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
        ),
      ],
    );

    blocTest<MangaDetailBloc, MangaDetailState>(
      'marks all unread chapters read and updates latest on '
      'MangaDetailCatchUpRequested',
      build: () {
        when(
          () => mangaRepository.computePreviousUnreadChapters(
            aggregate: testAggregate,
            upToChapterNumber: '3',
            alreadyReadChapters: const {'1'},
          ),
        ).thenReturn(const ['2', '3']);
        when(
          () => libraryRepository.markPreviousAsRead(
            uid: testUid,
            mangaId: testMangaId,
            targetChapterNumber: '3',
            targetChapterId: 'ch-id-3',
            previousChapterNumbersToMark: const ['2', '3'],
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
          ),
        ).thenAnswer((_) async {});
        when(
          () => libraryRepository.updateLatestKnownChapter(
            uid: testUid,
            mangaId: testMangaId,
            latestKnownChapterNumber: '3',
            latestKnownChapterId: 'ch-id-3',
          ),
        ).thenAnswer((_) async {});

        return MangaDetailBloc(
          mangaRepository: mangaRepository,
          libraryRepository: libraryRepository,
        );
      },
      seed: () => MangaDetailState(
        status: MangaDetailStatus.success,
        mangaId: testMangaId,
        uid: testUid,
        manga: testManga,
        aggregate: testAggregate,
        libraryEntry: testLibraryEntry,
      ),
      act: (bloc) => bloc.add(const MangaDetailCatchUpRequested()),
      expect: () => [
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
          isBulkActionLoading: true,
        ),
        MangaDetailState(
          status: MangaDetailStatus.success,
          mangaId: testMangaId,
          uid: testUid,
          manga: testManga,
          aggregate: testAggregate,
          libraryEntry: testLibraryEntry,
        ),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.markPreviousAsRead(
            uid: testUid,
            mangaId: testMangaId,
            targetChapterNumber: '3',
            targetChapterId: 'ch-id-3',
            previousChapterNumbersToMark: const ['2', '3'],
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
          ),
        ).called(1);
        verify(
          () => libraryRepository.updateLatestKnownChapter(
            uid: testUid,
            mangaId: testMangaId,
            latestKnownChapterNumber: '3',
            latestKnownChapterId: 'ch-id-3',
          ),
        ).called(1);
      },
    );
  });
}
