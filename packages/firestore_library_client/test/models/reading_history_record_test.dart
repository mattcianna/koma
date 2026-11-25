import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T>;

void main() {
  group('ReadingHistoryRecord', () {
    final now = DateTime(2026, 11, 13, 11, 15);

    test('supports value equality', () {
      final a = ReadingHistoryRecord(
        eventId: 'event-1',
        uid: 'uid-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        actionType: 'chapter_read',
        chapterNumbers: const ['1'],
        chaptersCount: 1,
        timestamp: now,
      );
      final b = ReadingHistoryRecord(
        eventId: 'event-1',
        uid: 'uid-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        actionType: 'chapter_read',
        chapterNumbers: const ['1'],
        chaptersCount: 1,
        timestamp: now,
      );

      expect(a, equals(b));
      expect(a.props, equals(b.props));
    });

    test('deserializes from map with Timestamp and full fields', () {
      final map = <String, dynamic>{
        'eventId': 'event-123',
        'uid': 'uid-456',
        'mangaId': 'manga-789',
        'mangaTitle': 'Chainsaw Man',
        'coverFileName': 'cover.jpg',
        'actionType': 'volume_read',
        'chapterNumbers': ['1', '2', '3', '4'],
        'volumeNumber': '1',
        'chaptersCount': 4,
        'timestamp': Timestamp.fromDate(now),
      };

      final record = ReadingHistoryRecord.fromMap(map);

      expect(record.eventId, equals('event-123'));
      expect(record.uid, equals('uid-456'));
      expect(record.mangaId, equals('manga-789'));
      expect(record.mangaTitle, equals('Chainsaw Man'));
      expect(record.coverFileName, equals('cover.jpg'));
      expect(record.actionType, equals('volume_read'));
      expect(record.chapterNumbers, equals(['1', '2', '3', '4']));
      expect(record.volumeNumber, equals('1'));
      expect(record.chaptersCount, equals(4));
      expect(record.timestamp, equals(now));
    });

    test(
      'deserializes from map with fallback count and multiple date formats',
      () {
        final record = ReadingHistoryRecord.fromMap(
          const <String, dynamic>{
            'chapterNumbers': ['10', '11'],
            'timestamp': '2026-11-13T11:15:00.000',
          },
          eventId: 'fallback-event',
          uid: 'fallback-uid',
        );

        expect(record.eventId, equals('fallback-event'));
        expect(record.uid, equals('fallback-uid'));
        expect(record.actionType, equals('chapter_read'));
        expect(record.chapterNumbers, equals(['10', '11']));
        expect(record.chaptersCount, equals(2));
        expect(record.timestamp, equals(now));

        final recordFromInt = ReadingHistoryRecord.fromMap(<String, dynamic>{
          'timestamp': now.millisecondsSinceEpoch,
          'chapterNumbers': 'not-a-list',
        });
        expect(recordFromInt.timestamp, equals(now));
        expect(recordFromInt.chapterNumbers, isEmpty);
        expect(recordFromInt.chaptersCount, equals(0));

        final recordFallbackDate = ReadingHistoryRecord.fromMap(
          const <String, dynamic>{'timestamp': false},
        );
        expect(recordFallbackDate.timestamp, isA<DateTime>());
      },
    );

    test('deserializes from DocumentSnapshot', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('snapshot-hist-id');
      when(snapshot.data).thenReturn(<String, dynamic>{
        'uid': 'user-1',
        'mangaId': 'manga-1',
        'mangaTitle': 'Frieren',
        'actionType': 'chapter_read',
        'chapterNumbers': ['1'],
        'chaptersCount': 1,
        'timestamp': Timestamp.fromDate(now),
      });

      final record = ReadingHistoryRecord.fromDocument(snapshot);

      expect(record.eventId, equals('snapshot-hist-id'));
      expect(record.mangaTitle, equals('Frieren'));
      expect(record.chaptersCount, equals(1));
    });

    test('deserializes from DocumentSnapshot with null data', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('null-hist-id');
      when(snapshot.data).thenReturn(null);

      final record = ReadingHistoryRecord.fromDocument(snapshot);
      expect(record.eventId, equals('null-hist-id'));
      expect(record.mangaTitle, isEmpty);
      expect(record.chapterNumbers, isEmpty);
      expect(record.chaptersCount, equals(0));
    });

    test('serializes to map with Timestamp', () {
      final record = ReadingHistoryRecord(
        eventId: 'event-1',
        uid: 'uid-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        coverFileName: 'cover.jpg',
        actionType: 'chapter_read',
        chapterNumbers: const ['1'],
        chaptersCount: 1,
        timestamp: now,
      );

      final map = record.toMap();

      expect(map['eventId'], equals('event-1'));
      expect(map['uid'], equals('uid-1'));
      expect(map['mangaId'], equals('manga-1'));
      expect(map['mangaTitle'], equals('Chainsaw Man'));
      expect(map['coverFileName'], equals('cover.jpg'));
      expect(map['actionType'], equals('chapter_read'));
      expect(map['chapterNumbers'], equals(['1']));
      expect(map['volumeNumber'], isNull);
      expect(map['chaptersCount'], equals(1));
      expect(map['timestamp'], equals(Timestamp.fromDate(now)));
    });

    test('copyWith updates specified fields', () {
      final initial = ReadingHistoryRecord(
        eventId: 'event-1',
        uid: 'uid-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        actionType: 'chapter_read',
        chapterNumbers: const ['1'],
        chaptersCount: 1,
        timestamp: now,
      );

      final updated = initial.copyWith(
        eventId: 'event-2',
        uid: 'uid-2',
        mangaId: 'manga-2',
        mangaTitle: 'Berserk',
        coverFileName: 'cover2.jpg',
        actionType: 'volume_read',
        chapterNumbers: ['1', '2'],
        volumeNumber: '1',
        chaptersCount: 2,
        timestamp: DateTime(2026, 12),
      );

      expect(updated.eventId, equals('event-2'));
      expect(updated.uid, equals('uid-2'));
      expect(updated.mangaId, equals('manga-2'));
      expect(updated.mangaTitle, equals('Berserk'));
      expect(updated.coverFileName, equals('cover2.jpg'));
      expect(updated.actionType, equals('volume_read'));
      expect(updated.chapterNumbers, equals(['1', '2']));
      expect(updated.volumeNumber, equals('1'));
      expect(updated.chaptersCount, equals(2));
      expect(updated.timestamp, equals(DateTime(2026, 12)));

      final unchanged = initial.copyWith();
      expect(unchanged, equals(initial));
    });
  });
}
