import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T>;

void main() {
  group('LibraryRecord', () {
    final addedAt = DateTime(2026, 10, 1, 14, 20);
    final updatedAt = DateTime(2026, 11, 13, 10, 30);

    test('supports value equality', () {
      final a = LibraryRecord(
        mangaId: 'manga-1',
        uid: 'uid-1',
        title: 'Chainsaw Man',
        status: 'Reading',
        addedAt: addedAt,
        updatedAt: updatedAt,
      );
      final b = LibraryRecord(
        mangaId: 'manga-1',
        uid: 'uid-1',
        title: 'Chainsaw Man',
        status: 'Reading',
        addedAt: addedAt,
        updatedAt: updatedAt,
      );

      expect(a, equals(b));
      expect(a.props, equals(b.props));
    });

    test('deserializes from map with Timestamp and full fields', () {
      final map = <String, dynamic>{
        'mangaId': 'manga-123',
        'uid': 'uid-456',
        'title': 'Chainsaw Man',
        'coverFileName': 'cover.jpg',
        'status': 'Reading',
        'preferredLanguages': ['en', 'it'],
        'readChapters': ['1', '2', '3'],
        'readVolumes': ['1'],
        'lastReadChapter': '3',
        'lastReadChapterId': 'ch-uuid-3',
        'latestKnownChapterId': 'ch-uuid-180',
        'latestKnownChapterNumber': '180',
        'addedAt': Timestamp.fromDate(addedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

      final record = LibraryRecord.fromMap(map);

      expect(record.mangaId, equals('manga-123'));
      expect(record.uid, equals('uid-456'));
      expect(record.title, equals('Chainsaw Man'));
      expect(record.coverFileName, equals('cover.jpg'));
      expect(record.status, equals('Reading'));
      expect(record.readingStatus, equals(ReadingStatus.reading));
      expect(record.preferredLanguages, equals(['en', 'it']));
      expect(record.readChapters, equals(['1', '2', '3']));
      expect(record.readVolumes, equals(['1']));
      expect(record.lastReadChapter, equals('3'));
      expect(record.lastReadChapterId, equals('ch-uuid-3'));
      expect(record.latestKnownChapterId, equals('ch-uuid-180'));
      expect(record.latestKnownChapterNumber, equals('180'));
      expect(record.addedAt, equals(addedAt));
      expect(record.updatedAt, equals(updatedAt));
    });

    test('deserializes from map with missing fields and non-list dynamics', () {
      final record = LibraryRecord.fromMap(
        <String, dynamic>{
          'preferredLanguages': 'not-a-list',
          'readChapters': null,
          'readVolumes': 123,
          'addedAt': '2026-10-01T14:20:00.000',
          'updatedAt': updatedAt.millisecondsSinceEpoch,
        },
        mangaId: 'fallback-manga-id',
        uid: 'fallback-uid',
      );

      expect(record.mangaId, equals('fallback-manga-id'));
      expect(record.uid, equals('fallback-uid'));
      expect(record.status, equals(ReadingStatus.planToRead.firestoreValue));
      expect(record.readingStatus, equals(ReadingStatus.planToRead));
      expect(record.preferredLanguages, isEmpty);
      expect(record.readChapters, isEmpty);
      expect(record.readVolumes, isEmpty);
      expect(record.addedAt, equals(addedAt));
      expect(record.updatedAt, equals(updatedAt));

      final recordFallbackDates = LibraryRecord.fromMap(const <String, dynamic>{
        'addedAt': false,
        'updatedAt': false,
      });
      expect(recordFallbackDates.addedAt, isA<DateTime>());
      expect(recordFallbackDates.updatedAt, isA<DateTime>());
    });

    test('deserializes from DocumentSnapshot', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('snapshot-manga-id');
      when(snapshot.data).thenReturn(<String, dynamic>{
        'uid': 'user-1',
        'title': 'Berserk',
        'status': 'Completed',
        'addedAt': Timestamp.fromDate(addedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      final record = LibraryRecord.fromDocument(snapshot);

      expect(record.mangaId, equals('snapshot-manga-id'));
      expect(record.title, equals('Berserk'));
      expect(record.readingStatus, equals(ReadingStatus.completed));
    });

    test('deserializes from DocumentSnapshot with null data', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('null-manga-id');
      when(snapshot.data).thenReturn(null);

      final record = LibraryRecord.fromDocument(snapshot);
      expect(record.mangaId, equals('null-manga-id'));
      expect(record.title, isEmpty);
      expect(record.readingStatus, equals(ReadingStatus.planToRead));
    });

    test('serializes to map with Timestamp', () {
      final record = LibraryRecord(
        mangaId: 'manga-1',
        uid: 'uid-1',
        title: 'Chainsaw Man',
        coverFileName: 'cover.jpg',
        status: 'Reading',
        preferredLanguages: const ['en'],
        readChapters: const ['1', '2'],
        readVolumes: const ['1'],
        lastReadChapter: '2',
        lastReadChapterId: 'ch-2',
        latestKnownChapterId: 'ch-100',
        latestKnownChapterNumber: '100',
        addedAt: addedAt,
        updatedAt: updatedAt,
      );

      final map = record.toMap();

      expect(map['mangaId'], equals('manga-1'));
      expect(map['uid'], equals('uid-1'));
      expect(map['title'], equals('Chainsaw Man'));
      expect(map['coverFileName'], equals('cover.jpg'));
      expect(map['status'], equals('Reading'));
      expect(map['preferredLanguages'], equals(['en']));
      expect(map['readChapters'], equals(['1', '2']));
      expect(map['readVolumes'], equals(['1']));
      expect(map['lastReadChapter'], equals('2'));
      expect(map['lastReadChapterId'], equals('ch-2'));
      expect(map['latestKnownChapterId'], equals('ch-100'));
      expect(map['latestKnownChapterNumber'], equals('100'));
      expect(map['addedAt'], equals(Timestamp.fromDate(addedAt)));
      expect(map['updatedAt'], equals(Timestamp.fromDate(updatedAt)));
    });

    test('copyWith updates specified fields', () {
      final initial = LibraryRecord(
        mangaId: 'manga-1',
        uid: 'uid-1',
        title: 'Initial Title',
        status: 'Plan to Read',
        addedAt: addedAt,
        updatedAt: updatedAt,
      );

      final updated = initial.copyWith(
        mangaId: 'manga-2',
        uid: 'uid-2',
        title: 'Updated Title',
        coverFileName: 'new_cover.jpg',
        status: 'Reading',
        preferredLanguages: ['it'],
        readChapters: ['1'],
        readVolumes: ['1'],
        lastReadChapter: '1',
        lastReadChapterId: 'ch-1',
        latestKnownChapterId: 'ch-20',
        latestKnownChapterNumber: '20',
        addedAt: DateTime(2026),
        updatedAt: DateTime(2026, 2),
      );

      expect(updated.mangaId, equals('manga-2'));
      expect(updated.uid, equals('uid-2'));
      expect(updated.title, equals('Updated Title'));
      expect(updated.coverFileName, equals('new_cover.jpg'));
      expect(updated.status, equals('Reading'));
      expect(updated.preferredLanguages, equals(['it']));
      expect(updated.readChapters, equals(['1']));
      expect(updated.readVolumes, equals(['1']));
      expect(updated.lastReadChapter, equals('1'));
      expect(updated.lastReadChapterId, equals('ch-1'));
      expect(updated.latestKnownChapterId, equals('ch-20'));
      expect(updated.latestKnownChapterNumber, equals('20'));
      expect(updated.addedAt, equals(DateTime(2026)));
      expect(updated.updatedAt, equals(DateTime(2026, 2)));

      final unchanged = initial.copyWith();
      expect(unchanged, equals(initial));
    });
  });
}
