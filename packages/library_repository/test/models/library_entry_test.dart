import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_repository/library_repository.dart';

void main() {
  group('LibraryEntry', () {
    final now = DateTime(2026, 11, 13, 10);

    test('supports value equality', () {
      final entryA = LibraryEntry(
        mangaId: 'manga-1',
        uid: 'user-1',
        title: 'Chainsaw Man',
        status: ReadingStatus.reading,
        addedAt: now,
        updatedAt: now,
        readChapters: const {'1', '2'},
      );
      final entryB = LibraryEntry(
        mangaId: 'manga-1',
        uid: 'user-1',
        title: 'Chainsaw Man',
        status: ReadingStatus.reading,
        addedAt: now,
        updatedAt: now,
        readChapters: const {'1', '2'},
      );

      expect(entryA, equals(entryB));
    });

    test('has sensible default values', () {
      final entry = LibraryEntry(
        mangaId: 'manga-1',
        uid: 'user-1',
        title: 'Chainsaw Man',
        status: ReadingStatus.planToRead,
        addedAt: now,
        updatedAt: now,
      );

      expect(entry.coverFileName, isNull);
      expect(entry.preferredLanguages, equals(const ['en', 'it']));
      expect(entry.readChapters, isEmpty);
      expect(entry.readVolumes, isEmpty);
      expect(entry.lastReadChapter, isNull);
      expect(entry.lastReadChapterId, isNull);
      expect(entry.latestKnownChapterId, isNull);
      expect(entry.latestKnownChapterNumber, isNull);
    });

    test('fromRecord maps all fields correctly', () {
      final record = LibraryRecord(
        mangaId: 'manga-99',
        uid: 'user-99',
        title: 'Frieren',
        coverFileName: 'frieren.jpg',
        status: 'Reading',
        preferredLanguages: const ['en'],
        readChapters: const ['1', '2', '3'],
        readVolumes: const ['1'],
        lastReadChapter: '3',
        lastReadChapterId: 'chap-3',
        latestKnownChapterId: 'chap-100',
        latestKnownChapterNumber: '100',
        addedAt: now,
        updatedAt: now,
      );

      final entry = LibraryEntry.fromRecord(record);

      expect(entry.mangaId, equals('manga-99'));
      expect(entry.uid, equals('user-99'));
      expect(entry.title, equals('Frieren'));
      expect(entry.coverFileName, equals('frieren.jpg'));
      expect(entry.status, equals(ReadingStatus.reading));
      expect(entry.preferredLanguages, equals(const ['en']));
      expect(entry.readChapters, equals({'1', '2', '3'}));
      expect(entry.readVolumes, equals(const ['1']));
      expect(entry.lastReadChapter, equals('3'));
      expect(entry.lastReadChapterId, equals('chap-3'));
      expect(entry.latestKnownChapterId, equals('chap-100'));
      expect(entry.latestKnownChapterNumber, equals('100'));
      expect(entry.addedAt, equals(now));
      expect(entry.updatedAt, equals(now));
    });

    test('toRecord converts to LibraryRecord accurately', () {
      final entry = LibraryEntry(
        mangaId: 'manga-99',
        uid: 'user-99',
        title: 'Frieren',
        coverFileName: 'frieren.jpg',
        status: ReadingStatus.completed,
        preferredLanguages: const ['en'],
        readChapters: const {'1', '2'},
        readVolumes: const ['1'],
        lastReadChapter: '2',
        lastReadChapterId: 'chap-2',
        latestKnownChapterId: 'chap-100',
        latestKnownChapterNumber: '100',
        addedAt: now,
        updatedAt: now,
      );

      final record = entry.toRecord();

      expect(record.mangaId, equals('manga-99'));
      expect(record.uid, equals('user-99'));
      expect(record.title, equals('Frieren'));
      expect(record.coverFileName, equals('frieren.jpg'));
      expect(record.status, equals('Completed'));
      expect(record.preferredLanguages, equals(const ['en']));
      expect(record.readChapters, equals(['1', '2']));
      expect(record.readVolumes, equals(const ['1']));
      expect(record.lastReadChapter, equals('2'));
      expect(record.lastReadChapterId, equals('chap-2'));
      expect(record.latestKnownChapterId, equals('chap-100'));
      expect(record.latestKnownChapterNumber, equals('100'));
      expect(record.addedAt, equals(now));
      expect(record.updatedAt, equals(now));
    });

    test('isChapterRead and isVolumeRead report membership correctly', () {
      final entry = LibraryEntry(
        mangaId: 'manga-1',
        uid: 'user-1',
        title: 'Manga',
        status: ReadingStatus.reading,
        addedAt: now,
        updatedAt: now,
        readChapters: const {'1', '2', '3.5'},
        readVolumes: const ['1', '2'],
      );

      expect(entry.isChapterRead('1'), isTrue);
      expect(entry.isChapterRead('2'), isTrue);
      expect(entry.isChapterRead('3.5'), isTrue);
      expect(entry.isChapterRead('4'), isFalse);

      expect(entry.isVolumeRead('1'), isTrue);
      expect(entry.isVolumeRead('2'), isTrue);
      expect(entry.isVolumeRead('3'), isFalse);
    });

    test('copyWith replaces specified fields and retains others', () {
      final initial = LibraryEntry(
        mangaId: 'manga-1',
        uid: 'user-1',
        title: 'Title',
        status: ReadingStatus.planToRead,
        addedAt: now,
        updatedAt: now,
      );

      final later = now.add(const Duration(days: 1));
      final updated = initial.copyWith(
        title: 'New Title',
        coverFileName: 'new.jpg',
        status: ReadingStatus.reading,
        preferredLanguages: const ['it'],
        readChapters: const {'1'},
        readVolumes: const ['1'],
        lastReadChapter: '1',
        lastReadChapterId: 'cid-1',
        latestKnownChapterId: 'cid-2',
        latestKnownChapterNumber: '2',
        updatedAt: later,
      );

      expect(updated.mangaId, equals('manga-1'));
      expect(updated.uid, equals('user-1'));
      expect(updated.title, equals('New Title'));
      expect(updated.coverFileName, equals('new.jpg'));
      expect(updated.status, equals(ReadingStatus.reading));
      expect(updated.preferredLanguages, equals(const ['it']));
      expect(updated.readChapters, equals(const {'1'}));
      expect(updated.readVolumes, equals(const ['1']));
      expect(updated.lastReadChapter, equals('1'));
      expect(updated.lastReadChapterId, equals('cid-1'));
      expect(updated.latestKnownChapterId, equals('cid-2'));
      expect(updated.latestKnownChapterNumber, equals('2'));
      expect(updated.addedAt, equals(now));
      expect(updated.updatedAt, equals(later));
    });

    test('copyWith with no arguments retains all fields', () {
      final initial = LibraryEntry(
        mangaId: 'manga-1',
        uid: 'user-1',
        title: 'Title',
        status: ReadingStatus.reading,
        addedAt: now,
        updatedAt: now,
        coverFileName: 'cover.jpg',
        preferredLanguages: const ['it'],
        readChapters: const {'1'},
        readVolumes: const ['1'],
        lastReadChapter: '1',
        lastReadChapterId: 'cid-1',
        latestKnownChapterId: 'cid-2',
        latestKnownChapterNumber: '2',
      );

      final copy = initial.copyWith();
      expect(copy, equals(initial));
    });
  });
}
