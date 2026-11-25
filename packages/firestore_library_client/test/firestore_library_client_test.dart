import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore;

class _MockWriteBatch extends Mock implements WriteBatch;

class _MockCollectionReference<T> extends Mock
    implements CollectionReference<T>;

class _MockDocumentReference<T> extends Mock implements DocumentReference<T>;

class _MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T>;

class _MockQuery<T> extends Mock implements Query<T>;

class _MockQuerySnapshot<T> extends Mock implements QuerySnapshot<T>;

class _MockQueryDocumentSnapshot<T> extends Mock
    implements QueryDocumentSnapshot<T>;

class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>>;

class _FakeSetOptions extends Fake implements SetOptions;

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDocumentReference());
    registerFallbackValue(_FakeSetOptions());
    registerFallbackValue(<String, dynamic>{});
  });

  group('FirestoreLibraryClient', () {
    late _MockFirebaseFirestore firestore;
    late _MockWriteBatch batch;
    late _MockCollectionReference<Map<String, dynamic>> usersCollection;
    late _MockDocumentReference<Map<String, dynamic>> userDoc;
    late _MockCollectionReference<Map<String, dynamic>> devicesCollection;
    late _MockDocumentReference<Map<String, dynamic>> deviceDoc;
    late _MockCollectionReference<Map<String, dynamic>> libraryCollection;
    late _MockDocumentReference<Map<String, dynamic>> libraryDoc;
    late _MockCollectionReference<Map<String, dynamic>> historyCollection;
    late _MockDocumentReference<Map<String, dynamic>> historyDoc;

    late FirestoreLibraryClient client;

    const uid = 'test-uid-001';
    const mangaId = 'manga-dex-uuid-1';
    const deviceId = 'device-hardware-id-1';

    setUp(() {
      firestore = _MockFirebaseFirestore();
      batch = _MockWriteBatch();
      usersCollection = _MockCollectionReference<Map<String, dynamic>>();
      userDoc = _MockDocumentReference<Map<String, dynamic>>();
      devicesCollection = _MockCollectionReference<Map<String, dynamic>>();
      deviceDoc = _MockDocumentReference<Map<String, dynamic>>();
      libraryCollection = _MockCollectionReference<Map<String, dynamic>>();
      libraryDoc = _MockDocumentReference<Map<String, dynamic>>();
      historyCollection = _MockCollectionReference<Map<String, dynamic>>();
      historyDoc = _MockDocumentReference<Map<String, dynamic>>();

      when(() => firestore.collection('users')).thenReturn(usersCollection);
      when(firestore.batch).thenReturn(batch);
      when(batch.commit).thenAnswer((_) async {});

      when(() => usersCollection.doc(uid)).thenReturn(userDoc);
      when(() => userDoc.collection('devices')).thenReturn(devicesCollection);
      when(() => userDoc.collection('library')).thenReturn(libraryCollection);
      when(() => userDoc.collection('reading_history'))
          .thenReturn(historyCollection);

      when(() => devicesCollection.doc(deviceId)).thenReturn(deviceDoc);
      when(() => libraryCollection.doc(mangaId)).thenReturn(libraryDoc);
      when(() => historyCollection.doc(any<String>())).thenReturn(historyDoc);
      when(historyCollection.doc).thenReturn(historyDoc);
      when(() => historyDoc.id).thenReturn('mock-hist-event-id');

      client = FirestoreLibraryClient(firestore: firestore);
    });

    group('constructor', () {
      test('uses custom firestore instance when provided', () {
        final customClient = FirestoreLibraryClient(firestore: firestore);
        expect(customClient, isNotNull);
      });
    });

    group('ensureUserProfile', () {
      test('returns existing profile without setting if doc exists', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.id).thenReturn(uid);
        when(snapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'email': 'existing@ciannavei.dev',
          'displayName': 'Existing User',
          'uiLocale': 'en',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        when(userDoc.get).thenAnswer((_) async => snapshot);

        final profile = await client.ensureUserProfile(
          uid: uid,
          email: 'new@ciannavei.dev',
        );

        expect(profile.email, equals('existing@ciannavei.dev'));
        expect(profile.displayName, equals('Existing User'));
        verify(userDoc.get).called(1);
        verifyNever(() => userDoc.set(any<Map<String, dynamic>>()));
      });

      test(
        'creates default profile with server timestamps if doc does not exist',
        () async {
          final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
          when(() => snapshot.exists).thenReturn(false);
          when(snapshot.data).thenReturn(null);
          when(userDoc.get).thenAnswer((_) async => snapshot);
          when(() => userDoc.set(any<Map<String, dynamic>>()))
              .thenAnswer((_) async {});

          final profile = await client.ensureUserProfile(
            uid: uid,
            email: 'reader@ciannavei.dev',
            displayName: 'New Reader',
            photoUrl: 'https://example.com/avatar.jpg',
          );

          expect(profile.uid, equals(uid));
          expect(profile.email, equals('reader@ciannavei.dev'));
          expect(profile.displayName, equals('New Reader'));
          expect(profile.photoUrl, equals('https://example.com/avatar.jpg'));
          expect(profile.uiLocale, equals('en'));
          expect(profile.preferredLanguages, equals(['en', 'it']));
          expect(profile.contentRatings, equals(['safe', 'suggestive']));
          expect(profile.notificationsEnabled, isTrue);

          verify(
            () => userDoc.set(
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having((m) => m['uid'], 'uid', uid)
                    .having((m) => m['email'], 'email', 'reader@ciannavei.dev')
                    .having(
                      (m) => m['displayName'],
                      'displayName',
                      'New Reader',
                    )
                    .having((m) => m['createdAt'], 'createdAt', isNotNull)
                    .having((m) => m['updatedAt'], 'updatedAt', isNotNull),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('getUserProfile', () {
      test('returns record when doc exists', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.id).thenReturn(uid);
        when(snapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'email': 'reader@ciannavei.dev',
          'uiLocale': 'it',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        when(userDoc.get).thenAnswer((_) async => snapshot);

        final profile = await client.getUserProfile(uid);

        expect(profile, isNotNull);
        expect(profile?.email, equals('reader@ciannavei.dev'));
        expect(profile?.uiLocale, equals('it'));
      });

      test('returns null when doc does not exist', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(false);
        when(snapshot.data).thenReturn(null);
        when(userDoc.get).thenAnswer((_) async => snapshot);

        final profile = await client.getUserProfile(uid);
        expect(profile, isNull);
      });

      test('returns null when data is null', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(true);
        when(snapshot.data).thenReturn(null);
        when(userDoc.get).thenAnswer((_) async => snapshot);

        final profile = await client.getUserProfile(uid);
        expect(profile, isNull);
      });
    });

    group('watchUserProfile', () {
      test('emits record when doc exists', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.id).thenReturn(uid);
        when(snapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'email': 'stream@example.com',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        when(userDoc.snapshots).thenAnswer((_) => Stream.value(snapshot));

        expect(
          client.watchUserProfile(uid),
          emits(
            isA<UserProfileRecord>().having(
              (p) => p.email,
              'email',
              'stream@example.com',
            ),
          ),
        );
      });

      test('emits null when doc does not exist', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(false);
        when(snapshot.data).thenReturn(null);
        when(userDoc.snapshots).thenAnswer((_) => Stream.value(snapshot));

        expect(client.watchUserProfile(uid), emits(isNull));
      });
    });

    group('updateUserSettings', () {
      test('updates mutable settings and updatedAt', () async {
        when(() => userDoc.update(any<Map<String, dynamic>>()))
            .thenAnswer((_) async {});

        await client.updateUserSettings(
          uid: uid,
          displayName: 'Updated Name',
          photoUrl: 'https://avatar.png',
          uiLocale: 'it',
          preferredLanguages: ['it'],
          contentRatings: ['safe'],
          notificationsEnabled: false,
        );

        verify(
          () => userDoc.update(
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>()
                  .having(
                    (m) => m['displayName'],
                    'displayName',
                    'Updated Name',
                  )
                  .having(
                    (m) => m['photoUrl'],
                    'photoUrl',
                    'https://avatar.png',
                  )
                  .having((m) => m['uiLocale'], 'uiLocale', 'it')
                  .having(
                    (m) => m['preferredLanguages'],
                    'preferredLanguages',
                    ['it'],
                  )
                  .having((m) => m['contentRatings'], 'contentRatings', [
                    'safe',
                  ])
                  .having(
                    (m) => m['notificationsEnabled'],
                    'notificationsEnabled',
                    false,
                  )
                  .having((m) => m['updatedAt'], 'updatedAt', isNotNull),
            ),
          ),
        ).called(1);
      });
    });

    group('device token operations', () {
      test('upsertDeviceToken merges token and updatedAt', () async {
        when(
          () => deviceDoc.set(any<Map<String, dynamic>>(), any<SetOptions>()),
        ).thenAnswer((_) async {});

        await client.upsertDeviceToken(
          uid: uid,
          deviceId: deviceId,
          token: 'fcm-token-12345678901234567890123456789012',
          platform: 'android',
        );

        verify(
          () => deviceDoc.set(
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>()
                  .having(
                    (m) => m['token'],
                    'token',
                    'fcm-token-12345678901234567890123456789012',
                  )
                  .having((m) => m['platform'], 'platform', 'android')
                  .having((m) => m['updatedAt'], 'updatedAt', isNotNull),
            ),
            any<SetOptions>(that: isA<SetOptions>()),
          ),
        ).called(1);
      });

      test('deleteDeviceToken deletes device document', () async {
        when(deviceDoc.delete).thenAnswer((_) async {});

        await client.deleteDeviceToken(uid: uid, deviceId: deviceId);

        verify(deviceDoc.delete).called(1);
      });
    });

    group('library operations', () {
      test('watchLibrary without status filter emits records', () async {
        final querySnapshot = _MockQuerySnapshot<Map<String, dynamic>>();
        final docSnapshot = _MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(() => docSnapshot.id).thenReturn(mangaId);
        when(docSnapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'title': 'Chainsaw Man',
          'status': 'Reading',
          'addedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        when(() => querySnapshot.docs).thenReturn([docSnapshot]);
        when(libraryCollection.snapshots)
            .thenAnswer((_) => Stream.value(querySnapshot));

        expect(
          client.watchLibrary(uid),
          emits(
            isA<List<LibraryRecord>>()
                .having((l) => l.length, 'length', 1)
                .having((l) => l.first.title, 'title', 'Chainsaw Man'),
          ),
        );
      });

      test(
        'watchLibrary with status filter queries with where clause',
        () async {
          final query = _MockQuery<Map<String, dynamic>>();
          final querySnapshot = _MockQuerySnapshot<Map<String, dynamic>>();
          when(() => libraryCollection.where('status', isEqualTo: 'Reading'))
              .thenReturn(query);
          when(query.snapshots).thenAnswer((_) => Stream.value(querySnapshot));
          when(() => querySnapshot.docs).thenReturn([]);

          expect(client.watchLibrary(uid, status: 'Reading'), emits(isEmpty));

          verify(() => libraryCollection.where('status', isEqualTo: 'Reading'))
              .called(1);
        },
      );

      test('watchLibraryEntry emits record when doc exists', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.id).thenReturn(mangaId);
        when(snapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'title': 'Frieren',
          'status': 'Completed',
          'addedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        when(libraryDoc.snapshots).thenAnswer((_) => Stream.value(snapshot));

        expect(
          client.watchLibraryEntry(uid: uid, mangaId: mangaId),
          emits(
            isA<LibraryRecord>().having((l) => l.title, 'title', 'Frieren'),
          ),
        );
      });

      test('watchLibraryEntry emits null when doc does not exist', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(false);
        when(snapshot.data).thenReturn(null);
        when(libraryDoc.snapshots).thenAnswer((_) => Stream.value(snapshot));

        expect(
          client.watchLibraryEntry(uid: uid, mangaId: mangaId),
          emits(isNull),
        );
      });

      test('getLibraryEntry returns record when doc exists', () async {
        final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.id).thenReturn(mangaId);
        when(snapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'title': 'Berserk',
          'status': 'Reading',
          'addedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        when(libraryDoc.get).thenAnswer((_) async => snapshot);

        final entry = await client.getLibraryEntry(uid: uid, mangaId: mangaId);

        expect(entry, isNotNull);
        expect(entry?.title, equals('Berserk'));
      });

      test(
        'getLibraryEntry returns null when doc does not exist or data null',
        () async {
          final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
          when(() => snapshot.exists).thenReturn(false);
          when(snapshot.data).thenReturn(null);
          when(libraryDoc.get).thenAnswer((_) async => snapshot);

          final entry = await client.getLibraryEntry(
            uid: uid,
            mangaId: mangaId,
          );

          expect(entry, isNull);
        },
      );

      test(
        'upsertLibraryEntry sets initial entry when doc does not exist',
        () async {
          final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
          when(() => snapshot.exists).thenReturn(false);
          when(libraryDoc.get).thenAnswer((_) async => snapshot);
          when(() => libraryDoc.set(any<Map<String, dynamic>>()))
              .thenAnswer((_) async {});

          final entry = LibraryRecord(
            mangaId: mangaId,
            uid: uid,
            title: 'Dungeon Meshi',
            status: 'Plan to Read',
            addedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await client.upsertLibraryEntry(uid: uid, entry: entry);

          verify(
            () => libraryDoc.set(
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having((m) => m['mangaId'], 'mangaId', mangaId)
                    .having((m) => m['uid'], 'uid', uid)
                    .having((m) => m['title'], 'title', 'Dungeon Meshi')
                    .having((m) => m['addedAt'], 'addedAt', isNotNull)
                    .having((m) => m['updatedAt'], 'updatedAt', isNotNull),
              ),
            ),
          ).called(1);
        },
      );

      test(
        'upsertLibraryEntry updates only mutable fields when doc exists',
        () async {
          final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
          when(() => snapshot.exists).thenReturn(true);
          when(libraryDoc.get).thenAnswer((_) async => snapshot);
          when(() => libraryDoc.update(any<Map<String, dynamic>>()))
              .thenAnswer((_) async {});

          final entry = LibraryRecord(
            mangaId: mangaId,
            uid: uid,
            title: 'Dungeon Meshi',
            coverFileName: 'new_cover.jpg',
            status: 'Reading',
            readChapters: const ['1', '2'],
            addedAt: DateTime(2026),
            updatedAt: DateTime(2026, 2),
          );

          await client.upsertLibraryEntry(uid: uid, entry: entry);

          verify(
            () => libraryDoc.update(
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having((m) => m['title'], 'title', 'Dungeon Meshi')
                    .having((m) => m['status'], 'status', 'Reading')
                    .having(
                      (m) => m.containsKey('addedAt'),
                      'has addedAt',
                      false,
                    )
                    .having((m) => m.containsKey('uid'), 'has uid', false)
                    .having(
                      (m) => m.containsKey('mangaId'),
                      'has mangaId',
                      false,
                    ),
              ),
            ),
          ).called(1);
        },
      );

      test('updateReadingStatus updates status and updatedAt', () async {
        when(() => libraryDoc.update(any<Map<String, dynamic>>()))
            .thenAnswer((_) async {});

        await client.updateReadingStatus(
          uid: uid,
          mangaId: mangaId,
          status: 'Completed',
        );

        verify(
          () => libraryDoc.update(
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>()
                  .having((m) => m['status'], 'status', 'Completed')
                  .having((m) => m['updatedAt'], 'updatedAt', isNotNull),
            ),
          ),
        ).called(1);
      });

      test(
        'updateLatestKnownChapter updates chapter fields & timestamp',
        () async {
          when(() => libraryDoc.update(any<Map<String, dynamic>>()))
              .thenAnswer((_) async {});

          await client.updateLatestKnownChapter(
            uid: uid,
            mangaId: mangaId,
            latestKnownChapterNumber: '449',
            latestKnownChapterId: 'ext:449999',
          );

          verify(
            () => libraryDoc.update(
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having(
                      (m) => m['latestKnownChapterNumber'],
                      'latestKnownChapterNumber',
                      '449',
                    )
                    .having(
                      (m) => m['latestKnownChapterId'],
                      'latestKnownChapterId',
                      'ext:449999',
                    )
                    .having((m) => m['updatedAt'], 'updatedAt', isNotNull),
              ),
            ),
          ).called(1);
        },
      );

      test('removeFromLibrary deletes library document', () async {
        when(libraryDoc.delete).thenAnswer((_) async {});

        await client.removeFromLibrary(uid: uid, mangaId: mangaId);

        verify(libraryDoc.delete).called(1);
      });
    });

    group('atomic progress and history operations', () {
      test('toggleChapterRead marks chapter read in 1 WriteBatch', () async {
        await client.toggleChapterRead(
          uid: uid,
          mangaId: mangaId,
          chapterNumber: '11',
          isRead: true,
          chapterId: 'ch-uuid-11',
          mangaTitle: 'Chainsaw Man',
          coverFileName: 'cover.jpg',
        );

        verify(
          () => batch.update(
            libraryDoc,
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>()
                  .having((m) => m['lastReadChapter'], 'lastReadChapter', '11')
                  .having(
                    (m) => m['lastReadChapterId'],
                    'lastReadChapterId',
                    'ch-uuid-11',
                  ),
            ),
          ),
        ).called(1);

        verify(
          () => batch.set<Map<String, dynamic>>(
            historyDoc,
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>()
                  .having((m) => m['actionType'], 'actionType', 'chapter_read')
                  .having((m) => m['chapterNumbers'], 'chapterNumbers', ['11'])
                  .having((m) => m['chaptersCount'], 'chaptersCount', 1)
                  .having((m) => m['mangaTitle'], 'mangaTitle', 'Chainsaw Man')
                  .having(
                    (m) => m['coverFileName'],
                    'coverFileName',
                    'cover.jpg',
                  ),
            ),
          ),
        ).called(1);

        verify(batch.commit).called(1);
      });

      test(
        'toggleChapterRead unmarks chapter read without writing history',
        () async {
          await client.toggleChapterRead(
            uid: uid,
            mangaId: mangaId,
            chapterNumber: '11',
            isRead: false,
          );

          verify(
            () => batch.update(
              libraryDoc,
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>().having(
                  (m) => m.containsKey('readChapters'),
                  'readChapters',
                  true,
                ),
              ),
            ),
          ).called(1);

          verifyNever(
            () => batch.set<Map<String, dynamic>>(
              any<DocumentReference<Map<String, dynamic>>>(),
              any<Map<String, dynamic>>(),
            ),
          );
          verify(batch.commit).called(1);
        },
      );

      test(
        'markChapterRead delegates to toggleChapterRead with isRead true',
        () async {
          await client.markChapterRead(
            uid: uid,
            mangaId: mangaId,
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
            chapterNumber: '12',
            chapterId: 'ch-12',
          );

          verify(() => batch.update(libraryDoc, any<Map<String, dynamic>>()))
              .called(1);
          verify(
            () => batch.set<Map<String, dynamic>>(
              historyDoc,
              any<Map<String, dynamic>>(),
            ),
          ).called(1);
          verify(batch.commit).called(1);
        },
      );

      test(
        'markVolumeRead commits library update and history in 1 WriteBatch',
        () async {
          await client.markVolumeRead(
            uid: uid,
            mangaId: mangaId,
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
            volumeNumber: '2',
            volumeChapterNumbers: const ['12', '13', '14'],
            lastChapterNumberInVolume: '14',
            lastChapterIdInVolume: 'ch-14',
          );

          verify(
            () => batch.update(
              libraryDoc,
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having(
                      (m) => m['lastReadChapter'],
                      'lastReadChapter',
                      '14',
                    )
                    .having(
                      (m) => m['lastReadChapterId'],
                      'lastReadChapterId',
                      'ch-14',
                    ),
              ),
            ),
          ).called(1);

          verify(
            () => batch.set<Map<String, dynamic>>(
              historyDoc,
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having((m) => m['actionType'], 'actionType', 'volume_read')
                    .having((m) => m['volumeNumber'], 'volumeNumber', '2')
                    .having((m) => m['chapterNumbers'], 'chapterNumbers', [
                      '12',
                      '13',
                      '14',
                    ])
                    .having((m) => m['chaptersCount'], 'chaptersCount', 3),
              ),
            ),
          ).called(1);

          verify(batch.commit).called(1);
        },
      );

      test(
        'markVolumeRead handles empty volumeChapterNumbers gracefully',
        () async {
          await client.markVolumeRead(
            uid: uid,
            mangaId: mangaId,
            mangaTitle: 'Chainsaw Man',
            coverFileName: null,
            volumeNumber: '3',
            volumeChapterNumbers: const [],
          );

          verify(() => batch.update(libraryDoc, any<Map<String, dynamic>>()))
              .called(1);
          verify(
            () => batch.set<Map<String, dynamic>>(
              historyDoc,
              any<Map<String, dynamic>>(
                that: isA<Map<String, dynamic>>()
                    .having((m) => m['chaptersCount'], 'chaptersCount', 1)
                    .having(
                      (m) => m['chapterNumbers'],
                      'chapterNumbers',
                      isEmpty,
                    ),
              ),
            ),
          ).called(1);
          verify(batch.commit).called(1);
        },
      );

      test('markVolumeRead chunks > 450 chapters in 1 WriteBatch', () async {
        final chapters500 = List.generate(500, (i) => '${i + 1}');

        await client.markVolumeRead(
          uid: uid,
          mangaId: mangaId,
          mangaTitle: 'Mega Volume',
          coverFileName: null,
          volumeNumber: '1',
          volumeChapterNumbers: chapters500,
        );

        verify(() => batch.update(libraryDoc, any<Map<String, dynamic>>()))
            .called(1);
        // 500 chapters chunked at 450 = 2 history docs
        verify(
          () => batch.set<Map<String, dynamic>>(
            historyDoc,
            any<Map<String, dynamic>>(),
          ),
        ).called(2);
        verify(batch.commit).called(1);
      });

      test(
        'markVolumeRead throws AssertionError when batch operations exceed 500',
        () {
          expect(
            () => client.markVolumeRead(
              uid: uid,
              mangaId: mangaId,
              mangaTitle: 'Too Big',
              coverFileName: null,
              volumeNumber: '1',
              volumeChapterNumbers: List.filled(225000, '1'),
            ),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test(
        'markPreviousChaptersRead returns early when list is empty',
        () async {
          await client.markPreviousChaptersRead(
            uid: uid,
            mangaId: mangaId,
            mangaTitle: 'Chainsaw Man',
            coverFileName: 'cover.jpg',
            targetChapterNumber: '1',
            targetChapterId: 'ch-1',
            previousChapterNumbersToMark: const [],
          );

          verifyNever(firestore.batch);
        },
      );

      test('markPreviousChaptersRead chunks 800 chapters into 2 history docs '
          'inside 1 hoisted WriteBatch', () async {
        final chapters800 = List.generate(800, (i) => '${i + 1}');

        await client.markPreviousChaptersRead(
          uid: uid,
          mangaId: mangaId,
          mangaTitle: 'One Piece',
          coverFileName: 'op.jpg',
          targetChapterNumber: '800',
          targetChapterId: 'ch-800',
          previousChapterNumbersToMark: chapters800,
        );

        // 1 library update
        verify(
          () => batch.update(
            libraryDoc,
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>()
                  .having((m) => m['lastReadChapter'], 'lastReadChapter', '800')
                  .having(
                    (m) => m['lastReadChapterId'],
                    'lastReadChapterId',
                    'ch-800',
                  ),
            ),
          ),
        ).called(1);

        // 800 chapters chunked at 450 = 2 history doc sets
        verify(
          () => batch.set<Map<String, dynamic>>(
            historyDoc,
            any<Map<String, dynamic>>(
              that: isA<Map<String, dynamic>>().having(
                (m) => m['actionType'],
                'actionType',
                'bulk_previous_read',
              ),
            ),
          ),
        ).called(2);

        // Committed ONCE atomically (total 3 operations: 1 library + 2 hist)
        verify(batch.commit).called(1);
      });

      test(
        'markPreviousChaptersRead throws AssertionError when ops exceed 500',
        () {
          expect(
            () => client.markPreviousChaptersRead(
              uid: uid,
              mangaId: mangaId,
              mangaTitle: 'Too Big',
              coverFileName: null,
              targetChapterNumber: '225000',
              targetChapterId: 'ch-big',
              previousChapterNumbersToMark: List.filled(225000, '1'),
            ),
            throwsA(isA<AssertionError>()),
          );
        },
      );
    });

    group('reading history queries', () {
      test('watchReadingHistory emits ordered history records', () async {
        final query = _MockQuery<Map<String, dynamic>>();
        final queryLimit = _MockQuery<Map<String, dynamic>>();
        final querySnapshot = _MockQuerySnapshot<Map<String, dynamic>>();
        final docSnapshot = _MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(() => historyCollection.orderBy('timestamp', descending: true))
            .thenReturn(query);
        when(() => query.limit(50)).thenReturn(queryLimit);
        when(queryLimit.snapshots)
            .thenAnswer((_) => Stream.value(querySnapshot));

        when(() => docSnapshot.id).thenReturn('hist-1');
        when(docSnapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'mangaId': mangaId,
          'mangaTitle': 'Chainsaw Man',
          'actionType': 'chapter_read',
          'chapterNumbers': ['1'],
          'chaptersCount': 1,
          'timestamp': Timestamp.now(),
        });
        when(() => querySnapshot.docs).thenReturn([docSnapshot]);

        expect(
          client.watchReadingHistory(uid),
          emits(
            isA<List<ReadingHistoryRecord>>()
                .having((h) => h.length, 'length', 1)
                .having(
                  (h) => h.first.mangaTitle,
                  'mangaTitle',
                  'Chainsaw Man',
                ),
          ),
        );
      });

      test('getReadingHistory returns ordered history records', () async {
        final query = _MockQuery<Map<String, dynamic>>();
        final queryLimit = _MockQuery<Map<String, dynamic>>();
        final querySnapshot = _MockQuerySnapshot<Map<String, dynamic>>();
        final docSnapshot = _MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(() => historyCollection.orderBy('timestamp', descending: true))
            .thenReturn(query);
        when(() => query.limit(25)).thenReturn(queryLimit);
        when(queryLimit.get).thenAnswer((_) async => querySnapshot);

        when(() => docSnapshot.id).thenReturn('hist-2');
        when(docSnapshot.data).thenReturn(<String, dynamic>{
          'uid': uid,
          'mangaId': mangaId,
          'mangaTitle': 'Berserk',
          'actionType': 'volume_read',
          'chapterNumbers': ['1', '2'],
          'volumeNumber': '1',
          'chaptersCount': 2,
          'timestamp': Timestamp.now(),
        });
        when(() => querySnapshot.docs).thenReturn([docSnapshot]);

        final history = await client.getReadingHistory(uid, limit: 25);

        expect(history.length, equals(1));
        expect(history.first.mangaTitle, equals('Berserk'));
      });
    });
  });
}
