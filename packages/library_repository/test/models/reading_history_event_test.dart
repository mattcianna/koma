import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_repository/library_repository.dart';

void main() {
  group('ReadingHistoryEvent', () {
    final now = DateTime(2026, 11, 13, 10);

    test('supports value equality', () {
      final eventA = ReadingHistoryEvent(
        eventId: 'event-1',
        uid: 'user-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        actionType: ReadingHistoryActionType.chapterRead,
        chapterNumbers: const ['10'],
        chaptersCount: 1,
        timestamp: now,
      );
      final eventB = ReadingHistoryEvent(
        eventId: 'event-1',
        uid: 'user-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        actionType: ReadingHistoryActionType.chapterRead,
        chapterNumbers: const ['10'],
        chaptersCount: 1,
        timestamp: now,
      );

      expect(eventA, equals(eventB));
    });

    test('fromRecord maps all fields correctly', () {
      final record = ReadingHistoryRecord(
        eventId: 'event-99',
        uid: 'user-99',
        mangaId: 'manga-99',
        mangaTitle: 'Berserk',
        coverFileName: 'berserk.jpg',
        actionType: 'volume_read',
        chapterNumbers: const ['1', '2', '3'],
        volumeNumber: '1',
        chaptersCount: 3,
        timestamp: now,
      );

      final event = ReadingHistoryEvent.fromRecord(record);

      expect(event.eventId, equals('event-99'));
      expect(event.uid, equals('user-99'));
      expect(event.mangaId, equals('manga-99'));
      expect(event.mangaTitle, equals('Berserk'));
      expect(event.coverFileName, equals('berserk.jpg'));
      expect(event.actionType, equals(ReadingHistoryActionType.volumeRead));
      expect(event.chapterNumbers, equals(const ['1', '2', '3']));
      expect(event.volumeNumber, equals('1'));
      expect(event.chaptersCount, equals(3));
      expect(event.timestamp, equals(now));
    });

    test('toRecord converts to ReadingHistoryRecord accurately', () {
      final event = ReadingHistoryEvent(
        eventId: 'event-99',
        uid: 'user-99',
        mangaId: 'manga-99',
        mangaTitle: 'Berserk',
        coverFileName: 'berserk.jpg',
        actionType: ReadingHistoryActionType.bulkPreviousRead,
        chapterNumbers: const ['1', '2'],
        chaptersCount: 2,
        timestamp: now,
      );

      final record = event.toRecord();

      expect(record.eventId, equals('event-99'));
      expect(record.uid, equals('user-99'));
      expect(record.mangaId, equals('manga-99'));
      expect(record.mangaTitle, equals('Berserk'));
      expect(record.coverFileName, equals('berserk.jpg'));
      expect(record.actionType, equals('bulk_previous_read'));
      expect(record.chapterNumbers, equals(const ['1', '2']));
      expect(record.volumeNumber, isNull);
      expect(record.chaptersCount, equals(2));
      expect(record.timestamp, equals(now));
    });

    test('copyWith replaces specified fields and retains others', () {
      final initial = ReadingHistoryEvent(
        eventId: 'event-1',
        uid: 'user-1',
        mangaId: 'manga-1',
        mangaTitle: 'Old Title',
        actionType: ReadingHistoryActionType.chapterRead,
        chapterNumbers: const ['1'],
        chaptersCount: 1,
        timestamp: now,
      );

      final later = now.add(const Duration(minutes: 5));
      final updated = initial.copyWith(
        mangaTitle: 'New Title',
        coverFileName: 'cover.jpg',
        actionType: ReadingHistoryActionType.volumeRead,
        chapterNumbers: const ['1', '2'],
        volumeNumber: '1',
        chaptersCount: 2,
        timestamp: later,
      );

      expect(updated.eventId, equals('event-1'));
      expect(updated.uid, equals('user-1'));
      expect(updated.mangaId, equals('manga-1'));
      expect(updated.mangaTitle, equals('New Title'));
      expect(updated.coverFileName, equals('cover.jpg'));
      expect(updated.actionType, equals(ReadingHistoryActionType.volumeRead));
      expect(updated.chapterNumbers, equals(const ['1', '2']));
      expect(updated.volumeNumber, equals('1'));
      expect(updated.chaptersCount, equals(2));
      expect(updated.timestamp, equals(later));
    });

    test('copyWith with no arguments retains all fields', () {
      final initial = ReadingHistoryEvent(
        eventId: 'event-1',
        uid: 'user-1',
        mangaId: 'manga-1',
        mangaTitle: 'Title',
        actionType: ReadingHistoryActionType.chapterRead,
        chapterNumbers: const ['1'],
        chaptersCount: 1,
        timestamp: now,
        coverFileName: 'cover.jpg',
        volumeNumber: '1',
      );

      final copy = initial.copyWith();
      expect(copy, equals(initial));
    });
  });
}
