import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestoreLibraryClient extends Mock
    implements FirestoreLibraryClient;

class _FakeLibraryRecord extends Fake implements LibraryRecord;

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeLibraryRecord());
  });

  group('LibraryRepository', () {
    late FirestoreLibraryClient client;
    late LibraryRepository repository;

    final testDate = DateTime(2026, 11, 13, 12);

    setUp(() {
      client = _MockFirestoreLibraryClient();
      repository = LibraryRepository(firestoreLibraryClient: client);
    });

    test('can be instantiated with default client', () {
      expect(LibraryRepository.new, returnsNormally);
    });

    group('ensureUserProfile', () {
      test('delegates to client and returns mapped profile', () async {
        final record = UserProfileRecord(
          uid: 'uid-1',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/pic.jpg',
          uiLocale: 'it',
          preferredLanguages: const ['it'],
          contentRatings: const ['safe'],
          notificationsEnabled: false,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(
          () => client.ensureUserProfile(
            uid: any(named: 'uid'),
            email: any(named: 'email'),
            displayName: any(named: 'displayName'),
            photoUrl: any(named: 'photoUrl'),
            uiLocale: any(named: 'uiLocale'),
            preferredLanguages: any(named: 'preferredLanguages'),
            contentRatings: any(named: 'contentRatings'),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        ).thenAnswer((_) async => record);

        final result = await repository.ensureUserProfile(
          uid: 'uid-1',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/pic.jpg',
          uiLocale: 'it',
          preferredLanguages: const ['it'],
          contentRatings: const ['safe'],
          notificationsEnabled: false,
        );

        expect(result.uid, equals('uid-1'));
        expect(result.email, equals('test@example.com'));
        expect(result.displayName, equals('Test User'));
        expect(result.photoUrl, equals('https://example.com/pic.jpg'));
        expect(result.uiLocale, equals('it'));
        expect(result.preferredLanguages, equals(const ['it']));
        expect(result.contentRatings, equals(const ['safe']));
        expect(result.notificationsEnabled, isFalse);

        verify(
          () => client.ensureUserProfile(
            uid: 'uid-1',
            email: 'test@example.com',
            displayName: 'Test User',
            photoUrl: 'https://example.com/pic.jpg',
            uiLocale: 'it',
            preferredLanguages: const ['it'],
            contentRatings: const ['safe'],
            notificationsEnabled: false,
          ),
        ).called(1);
      });
    });

    group('watchUserSettings', () {
      test('emits mapped UserSettingsProfile when record exists', () {
        final record = UserProfileRecord(
          uid: 'uid-1',
          email: 'test@example.com',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.watchUserProfile('uid-1'))
            .thenAnswer((_) => Stream.value(record));

        expect(
          repository.watchUserSettings('uid-1'),
          emits(
            UserSettingsProfile(
              uid: 'uid-1',
              email: 'test@example.com',
              createdAt: testDate,
              updatedAt: testDate,
            ),
          ),
        );
      });

      test('emits null when client emits null', () {
        when(() => client.watchUserProfile('uid-1'))
            .thenAnswer((_) => Stream.value(null));

        expect(repository.watchUserSettings('uid-1'), emits(isNull));
      });
    });

    group('getUserSettings', () {
      test('returns mapped UserSettingsProfile when record exists', () async {
        final record = UserProfileRecord(
          uid: 'uid-1',
          email: 'test@example.com',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.getUserProfile('uid-1'))
            .thenAnswer((_) async => record);

        final result = await repository.getUserSettings('uid-1');
        expect(result?.uid, equals('uid-1'));
        expect(result?.email, equals('test@example.com'));
      });

      test('returns null when record is null', () async {
        when(() => client.getUserProfile('uid-1'))
            .thenAnswer((_) async => null);

        final result = await repository.getUserSettings('uid-1');
        expect(result, isNull);
      });
    });

    group('updateUserSettings', () {
      test('delegates to client with all parameters', () async {
        when(
          () => client.updateUserSettings(
            uid: any(named: 'uid'),
            displayName: any(named: 'displayName'),
            photoUrl: any(named: 'photoUrl'),
            uiLocale: any(named: 'uiLocale'),
            preferredLanguages: any(named: 'preferredLanguages'),
            contentRatings: any(named: 'contentRatings'),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        ).thenAnswer((_) async {});

        await repository.updateUserSettings(
          uid: 'uid-1',
          displayName: 'New Name',
          photoUrl: 'https://new.png',
          uiLocale: 'it',
          preferredLanguages: const ['it'],
          contentRatings: const ['safe'],
          notificationsEnabled: false,
        );

        verify(
          () => client.updateUserSettings(
            uid: 'uid-1',
            displayName: 'New Name',
            photoUrl: 'https://new.png',
            uiLocale: 'it',
            preferredLanguages: const ['it'],
            contentRatings: const ['safe'],
            notificationsEnabled: false,
          ),
        ).called(1);
      });
    });

    group('watchLibrary', () {
      test('emits mapped LibraryEntry list filtered by status', () {
        final record = LibraryRecord(
          mangaId: 'manga-1',
          uid: 'uid-1',
          title: 'Chainsaw Man',
          status: 'Reading',
          addedAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.watchLibrary('uid-1', status: 'Reading'))
            .thenAnswer((_) => Stream.value([record]));

        expect(
          repository.watchLibrary('uid-1', status: ReadingStatus.reading),
          emits([
            LibraryEntry(
              mangaId: 'manga-1',
              uid: 'uid-1',
              title: 'Chainsaw Man',
              status: ReadingStatus.reading,
              addedAt: testDate,
              updatedAt: testDate,
            ),
          ]),
        );
      });

      test('passes null status when status is omitted', () {
        when(() => client.watchLibrary('uid-1'))
            .thenAnswer((_) => Stream.value([]));

        expect(repository.watchLibrary('uid-1'), emits(isEmpty));
      });
    });

    group('watchLibraryEntry', () {
      test('emits mapped LibraryEntry when doc exists', () {
        final record = LibraryRecord(
          mangaId: 'manga-1',
          uid: 'uid-1',
          title: 'Chainsaw Man',
          status: 'Reading',
          addedAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.watchLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) => Stream.value(record));

        expect(
          repository.watchLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'),
          emits(
            LibraryEntry(
              mangaId: 'manga-1',
              uid: 'uid-1',
              title: 'Chainsaw Man',
              status: ReadingStatus.reading,
              addedAt: testDate,
              updatedAt: testDate,
            ),
          ),
        );
      });

      test('emits null when doc does not exist', () {
        when(() => client.watchLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) => Stream.value(null));

        expect(
          repository.watchLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'),
          emits(isNull),
        );
      });
    });

    group('getLibraryEntry', () {
      test('returns mapped entry when doc exists', () async {
        final record = LibraryRecord(
          mangaId: 'manga-1',
          uid: 'uid-1',
          title: 'Chainsaw Man',
          status: 'Reading',
          addedAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.getLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) async => record);

        final result = await repository.getLibraryEntry(
          uid: 'uid-1',
          mangaId: 'manga-1',
        );

        expect(result?.mangaId, equals('manga-1'));
        expect(result?.title, equals('Chainsaw Man'));
      });

      test('returns null when doc does not exist', () async {
        when(() => client.getLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) async => null);

        final result = await repository.getLibraryEntry(
          uid: 'uid-1',
          mangaId: 'manga-1',
        );

        expect(result, isNull);
      });
    });

    group('addOrUpdateLibraryEntry', () {
      test('delegates upsert to client with matching uid', () async {
        when(
          () => client.upsertLibraryEntry(
            uid: any(named: 'uid'),
            entry: any(named: 'entry'),
          ),
        ).thenAnswer((_) async {});

        final entry = LibraryEntry(
          mangaId: 'manga-1',
          uid: 'diff-uid',
          title: 'Dungeon Meshi',
          status: ReadingStatus.planToRead,
          addedAt: testDate,
          updatedAt: testDate,
        );

        await repository.addOrUpdateLibraryEntry(uid: 'uid-1', entry: entry);

        verify(
          () => client.upsertLibraryEntry(
            uid: 'uid-1',
            entry: any(
              named: 'entry',
              that: isA<LibraryRecord>()
                  .having((r) => r.uid, 'uid', 'uid-1')
                  .having((r) => r.title, 'title', 'Dungeon Meshi'),
            ),
          ),
        ).called(1);
      });
    });

    group('updateStatus', () {
      test('delegates to client with firestore status string', () async {
        when(
          () => client.updateReadingStatus(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async {});

        await repository.updateStatus(
          uid: 'uid-1',
          mangaId: 'manga-1',
          status: ReadingStatus.completed,
        );

        verify(
          () => client.updateReadingStatus(
            uid: 'uid-1',
            mangaId: 'manga-1',
            status: 'Completed',
          ),
        ).called(1);
      });
    });

    group('removeFromLibrary', () {
      test('delegates to client', () async {
        when(
          () => client.removeFromLibrary(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
          ),
        ).thenAnswer((_) async {});

        await repository.removeFromLibrary(uid: 'uid-1', mangaId: 'manga-1');

        verify(() => client.removeFromLibrary(uid: 'uid-1', mangaId: 'manga-1'))
            .called(1);
      });
    });

    group('toggleChapterRead and markChapterRead', () {
      test('delegates to client with provided title and cover', () async {
        when(
          () => client.toggleChapterRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            chapterNumber: any(named: 'chapterNumber'),
            isRead: any(named: 'isRead'),
            chapterId: any(named: 'chapterId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
          ),
        ).thenAnswer((_) async {});

        await repository.toggleChapterRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          chapterNumber: '10',
          isRead: true,
          chapterId: 'cid-10',
          mangaTitle: 'Chainsaw Man',
          coverFileName: 'cover.jpg',
        );

        verify(
          () => client.toggleChapterRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            chapterNumber: '10',
            isRead: true,
            chapterId: 'cid-10',
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
          ),
        ).called(1);
      });

      test(
        'falls back to Untitled Manga when mangaTitle is null or blank',
        () async {
          when(
            () => client.toggleChapterRead(
              uid: any(named: 'uid'),
              mangaId: any(named: 'mangaId'),
              chapterNumber: any(named: 'chapterNumber'),
              isRead: any(named: 'isRead'),
              chapterId: any(named: 'chapterId'),
              mangaTitle: any(named: 'mangaTitle'),
              coverFileName: any(named: 'coverFileName'),
            ),
          ).thenAnswer((_) async {});

          await repository.toggleChapterRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            chapterNumber: '1',
            isRead: true,
          );

          await repository.toggleChapterRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            chapterNumber: '2',
            isRead: true,
            mangaTitle: '   ',
          );

          verify(
            () => client.toggleChapterRead(
              uid: 'uid-1',
              mangaId: 'manga-1',
              chapterNumber: '1',
              isRead: true,
              mangaTitle: 'Untitled Manga',
            ),
          ).called(1);

          verify(
            () => client.toggleChapterRead(
              uid: 'uid-1',
              mangaId: 'manga-1',
              chapterNumber: '2',
              isRead: true,
              mangaTitle: 'Untitled Manga',
            ),
          ).called(1);
        },
      );

      test('calls toggleChapterRead with isRead false', () async {
        when(
          () => client.toggleChapterRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            chapterNumber: any(named: 'chapterNumber'),
            isRead: any(named: 'isRead'),
            chapterId: any(named: 'chapterId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
          ),
        ).thenAnswer((_) async {});

        await repository.toggleChapterRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          chapterNumber: '10',
          isRead: false,
        );

        verify(
          () => client.toggleChapterRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            chapterNumber: '10',
            isRead: false,
            mangaTitle: 'Untitled Manga',
          ),
        ).called(1);
      });

      test(
        'markChapterRead calls toggleChapterRead with isRead: true',
        () async {
          when(
            () => client.toggleChapterRead(
              uid: any(named: 'uid'),
              mangaId: any(named: 'mangaId'),
              chapterNumber: any(named: 'chapterNumber'),
              isRead: any(named: 'isRead'),
              chapterId: any(named: 'chapterId'),
              mangaTitle: any(named: 'mangaTitle'),
              coverFileName: any(named: 'coverFileName'),
            ),
          ).thenAnswer((_) async {});

          await repository.markChapterRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            chapterNumber: '5',
            chapterId: 'cid-5',
            mangaTitle: 'Berserk',
            coverFileName: 'berserk.jpg',
          );

          verify(
            () => client.toggleChapterRead(
              uid: 'uid-1',
              mangaId: 'manga-1',
              chapterNumber: '5',
              isRead: true,
              chapterId: 'cid-5',
              mangaTitle: 'Berserk',
              coverFileName: 'berserk.jpg',
            ),
          ).called(1);
        },
      );
    });

    group('markVolumeRead', () {
      test(
        'delegates to client when volumeChapterNumbers is not empty',
        () async {
          when(
            () => client.markVolumeRead(
              uid: any(named: 'uid'),
              mangaId: any(named: 'mangaId'),
              mangaTitle: any(named: 'mangaTitle'),
              coverFileName: any(named: 'coverFileName'),
              volumeNumber: any(named: 'volumeNumber'),
              volumeChapterNumbers: any(named: 'volumeChapterNumbers'),
              lastChapterNumberInVolume: any(
                named: 'lastChapterNumberInVolume',
              ),
              lastChapterIdInVolume: any(named: 'lastChapterIdInVolume'),
            ),
          ).thenAnswer((_) async {});

          await repository.markVolumeRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            volumeNumber: '1',
            volumeChapterNumbers: const ['1', '2', '3'],
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'csm.jpg',
            lastChapterNumberInVolume: '3',
            lastChapterIdInVolume: 'cid-3',
          );

          verify(
            () => client.markVolumeRead(
              uid: 'uid-1',
              mangaId: 'manga-1',
              mangaTitle: 'Chainsaw Man',
              coverFileName: 'csm.jpg',
              volumeNumber: '1',
              volumeChapterNumbers: const ['1', '2', '3'],
              lastChapterNumberInVolume: '3',
              lastChapterIdInVolume: 'cid-3',
            ),
          ).called(1);
        },
      );

      test('falls back to Untitled Manga when mangaTitle is blank', () async {
        when(
          () => client.markVolumeRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
            volumeNumber: any(named: 'volumeNumber'),
            volumeChapterNumbers: any(named: 'volumeChapterNumbers'),
            lastChapterNumberInVolume: any(named: 'lastChapterNumberInVolume'),
            lastChapterIdInVolume: any(named: 'lastChapterIdInVolume'),
          ),
        ).thenAnswer((_) async {});

        await repository.markVolumeRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          volumeNumber: '1',
          volumeChapterNumbers: const ['1'],
          mangaTitle: '   ',
        );

        verify(
          () => client.markVolumeRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            mangaTitle: 'Untitled Manga',
            coverFileName: null,
            volumeNumber: '1',
            volumeChapterNumbers: const ['1'],
          ),
        ).called(1);
      });

      test('guards empty volumeChapterNumbers and updates existing entry '
          'without calling client markVolumeRead', () async {
        final existingRecord = LibraryRecord(
          mangaId: 'manga-1',
          uid: 'uid-1',
          title: 'Existing Title',
          status: 'Reading',
          readVolumes: const ['1'],
          lastReadChapter: '10',
          addedAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.getLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) async => existingRecord);
        when(
          () => client.upsertLibraryEntry(
            uid: any(named: 'uid'),
            entry: any(named: 'entry'),
          ),
        ).thenAnswer((_) async {});

        await repository.markVolumeRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          volumeNumber: '2',
          volumeChapterNumbers: const [],
          lastChapterNumberInVolume: '20',
          lastChapterIdInVolume: 'cid-20',
        );

        verifyNever(
          () => client.markVolumeRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
            volumeNumber: any(named: 'volumeNumber'),
            volumeChapterNumbers: any(named: 'volumeChapterNumbers'),
            lastChapterNumberInVolume: any(named: 'lastChapterNumberInVolume'),
            lastChapterIdInVolume: any(named: 'lastChapterIdInVolume'),
          ),
        );

        verify(
          () => client.upsertLibraryEntry(
            uid: 'uid-1',
            entry: any(
              named: 'entry',
              that: isA<LibraryRecord>()
                  .having((r) => r.readVolumes, 'readVolumes', ['1', '2'])
                  .having((r) => r.lastReadChapter, 'lastReadChapter', '20')
                  .having(
                    (r) => r.lastReadChapterId,
                    'lastReadChapterId',
                    'cid-20',
                  ),
            ),
          ),
        ).called(1);
      });

      test('guards empty volumeChapterNumbers and preserves existing lastRead '
          'when chapter info is omitted', () async {
        final existingRecord = LibraryRecord(
          mangaId: 'manga-1',
          uid: 'uid-1',
          title: 'Existing Title',
          status: 'Reading',
          readVolumes: const ['1'],
          lastReadChapter: '10',
          lastReadChapterId: 'cid-10',
          addedAt: testDate,
          updatedAt: testDate,
        );

        when(() => client.getLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) async => existingRecord);
        when(
          () => client.upsertLibraryEntry(
            uid: any(named: 'uid'),
            entry: any(named: 'entry'),
          ),
        ).thenAnswer((_) async {});

        await repository.markVolumeRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          volumeNumber: '2',
          volumeChapterNumbers: const [],
        );

        verify(
          () => client.upsertLibraryEntry(
            uid: 'uid-1',
            entry: any(
              named: 'entry',
              that: isA<LibraryRecord>()
                  .having((r) => r.readVolumes, 'readVolumes', ['1', '2'])
                  .having((r) => r.lastReadChapter, 'lastReadChapter', '10')
                  .having(
                    (r) => r.lastReadChapterId,
                    'lastReadChapterId',
                    'cid-10',
                  ),
            ),
          ),
        ).called(1);
      });

      test('guards empty volumeChapterNumbers and creates new entry when '
          'no existing entry found', () async {
        when(() => client.getLibraryEntry(uid: 'uid-1', mangaId: 'manga-1'))
            .thenAnswer((_) async => null);
        when(
          () => client.upsertLibraryEntry(
            uid: any(named: 'uid'),
            entry: any(named: 'entry'),
          ),
        ).thenAnswer((_) async {});

        await repository.markVolumeRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          volumeNumber: '1',
          volumeChapterNumbers: const [],
          coverFileName: 'cover.jpg',
          lastChapterNumberInVolume: '10',
          lastChapterIdInVolume: 'cid-10',
        );

        verifyNever(
          () => client.markVolumeRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
            volumeNumber: any(named: 'volumeNumber'),
            volumeChapterNumbers: any(named: 'volumeChapterNumbers'),
            lastChapterNumberInVolume: any(named: 'lastChapterNumberInVolume'),
            lastChapterIdInVolume: any(named: 'lastChapterIdInVolume'),
          ),
        );

        verify(
          () => client.upsertLibraryEntry(
            uid: 'uid-1',
            entry: any(
              named: 'entry',
              that: isA<LibraryRecord>()
                  .having((r) => r.title, 'title', 'Untitled Manga')
                  .having((r) => r.readVolumes, 'readVolumes', ['1'])
                  .having((r) => r.status, 'status', 'Reading')
                  .having((r) => r.lastReadChapter, 'lastReadChapter', '10')
                  .having(
                    (r) => r.lastReadChapterId,
                    'lastReadChapterId',
                    'cid-10',
                  ),
            ),
          ),
        ).called(1);
      });
    });

    group('markPreviousAsRead', () {
      test(
        'returns early when previousChapterNumbersToMark is empty',
        () async {
          await repository.markPreviousAsRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            targetChapterNumber: '10',
            targetChapterId: 'cid-10',
            previousChapterNumbersToMark: const [],
          );

          verifyNever(
            () => client.markPreviousChaptersRead(
              uid: any(named: 'uid'),
              mangaId: any(named: 'mangaId'),
              mangaTitle: any(named: 'mangaTitle'),
              coverFileName: any(named: 'coverFileName'),
              targetChapterNumber: any(named: 'targetChapterNumber'),
              targetChapterId: any(named: 'targetChapterId'),
              previousChapterNumbersToMark: any(
                named: 'previousChapterNumbersToMark',
              ),
            ),
          );
        },
      );

      test('delegates to client with safe title and parameters', () async {
        when(
          () => client.markPreviousChaptersRead(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            mangaTitle: any(named: 'mangaTitle'),
            coverFileName: any(named: 'coverFileName'),
            targetChapterNumber: any(named: 'targetChapterNumber'),
            targetChapterId: any(named: 'targetChapterId'),
            previousChapterNumbersToMark: any(
              named: 'previousChapterNumbersToMark',
            ),
          ),
        ).thenAnswer((_) async {});

        await repository.markPreviousAsRead(
          uid: 'uid-1',
          mangaId: 'manga-1',
          targetChapterNumber: '10',
          targetChapterId: 'cid-10',
          previousChapterNumbersToMark: const ['1', '2', '3'],
          mangaTitle: 'Chainsaw Man',
          coverFileName: 'csm.jpg',
        );

        verify(
          () => client.markPreviousChaptersRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'csm.jpg',
            targetChapterNumber: '10',
            targetChapterId: 'cid-10',
            previousChapterNumbersToMark: const ['1', '2', '3'],
          ),
        ).called(1);
      });

      test(
        'falls back to Untitled Manga when mangaTitle is null or blank',
        () async {
          when(
            () => client.markPreviousChaptersRead(
              uid: any(named: 'uid'),
              mangaId: any(named: 'mangaId'),
              mangaTitle: any(named: 'mangaTitle'),
              coverFileName: any(named: 'coverFileName'),
              targetChapterNumber: any(named: 'targetChapterNumber'),
              targetChapterId: any(named: 'targetChapterId'),
              previousChapterNumbersToMark: any(
                named: 'previousChapterNumbersToMark',
              ),
            ),
          ).thenAnswer((_) async {});

          await repository.markPreviousAsRead(
            uid: 'uid-1',
            mangaId: 'manga-1',
            targetChapterNumber: '10',
            targetChapterId: 'cid-10',
            previousChapterNumbersToMark: const ['1'],
          );

          verify(
            () => client.markPreviousChaptersRead(
              uid: 'uid-1',
              mangaId: 'manga-1',
              mangaTitle: 'Untitled Manga',
              coverFileName: null,
              targetChapterNumber: '10',
              targetChapterId: 'cid-10',
              previousChapterNumbersToMark: const ['1'],
            ),
          ).called(1);
        },
      );
    });

    group('watchReadingHistory', () {
      test('emits mapped ReadingHistoryEvent list with limit', () {
        final record = ReadingHistoryRecord(
          eventId: 'ev-1',
          uid: 'uid-1',
          mangaId: 'manga-1',
          mangaTitle: 'Chainsaw Man',
          actionType: 'chapter_read',
          chapterNumbers: const ['1'],
          chaptersCount: 1,
          timestamp: testDate,
        );

        when(() => client.watchReadingHistory('uid-1', limit: 25))
            .thenAnswer((_) => Stream.value([record]));

        expect(
          repository.watchReadingHistory('uid-1', limit: 25),
          emits([
            ReadingHistoryEvent(
              eventId: 'ev-1',
              uid: 'uid-1',
              mangaId: 'manga-1',
              mangaTitle: 'Chainsaw Man',
              actionType: ReadingHistoryActionType.chapterRead,
              chapterNumbers: const ['1'],
              chaptersCount: 1,
              timestamp: testDate,
            ),
          ]),
        );
      });
    });

    group('getReadingHistory', () {
      test('returns mapped ReadingHistoryEvent list with limit', () async {
        final record = ReadingHistoryRecord(
          eventId: 'ev-1',
          uid: 'uid-1',
          mangaId: 'manga-1',
          mangaTitle: 'Chainsaw Man',
          actionType: 'chapter_read',
          chapterNumbers: const ['1'],
          chaptersCount: 1,
          timestamp: testDate,
        );

        when(() => client.getReadingHistory('uid-1', limit: 25))
            .thenAnswer((_) async => [record]);

        final result = await repository.getReadingHistory('uid-1', limit: 25);

        expect(result.length, equals(1));
        expect(result.first.eventId, equals('ev-1'));
        expect(result.first.mangaTitle, equals('Chainsaw Man'));
      });
    });

    group('updateLatestKnownChapter', () {
      test('delegates updateLatestKnownChapter to client', () async {
        when(
          () => client.updateLatestKnownChapter(
            uid: any(named: 'uid'),
            mangaId: any(named: 'mangaId'),
            latestKnownChapterNumber: any(named: 'latestKnownChapterNumber'),
            latestKnownChapterId: any(named: 'latestKnownChapterId'),
          ),
        ).thenAnswer((_) async {});

        await repository.updateLatestKnownChapter(
          uid: 'uid-1',
          mangaId: 'manga-1',
          latestKnownChapterNumber: '449',
          latestKnownChapterId: 'ext:449999',
        );

        verify(
          () => client.updateLatestKnownChapter(
            uid: 'uid-1',
            mangaId: 'manga-1',
            latestKnownChapterNumber: '449',
            latestKnownChapterId: 'ext:449999',
          ),
        ).called(1);
      });
    });
  });
}
