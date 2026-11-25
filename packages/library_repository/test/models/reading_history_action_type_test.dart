import 'package:flutter_test/flutter_test.dart';
import 'package:library_repository/library_repository.dart';

void main() {
  group('ReadingHistoryActionType', () {
    test('enum values map to expected strings', () {
      expect(
        ReadingHistoryActionType.chapterRead.value,
        equals('chapter_read'),
      );
      expect(ReadingHistoryActionType.volumeRead.value, equals('volume_read'));
      expect(
        ReadingHistoryActionType.bulkPreviousRead.value,
        equals('bulk_previous_read'),
      );
    });

    test('fromValue parses valid action strings', () {
      expect(
        ReadingHistoryActionType.fromValue('chapter_read'),
        equals(ReadingHistoryActionType.chapterRead),
      );
      expect(
        ReadingHistoryActionType.fromValue('volume_read'),
        equals(ReadingHistoryActionType.volumeRead),
      );
      expect(
        ReadingHistoryActionType.fromValue('bulk_previous_read'),
        equals(ReadingHistoryActionType.bulkPreviousRead),
      );
    });

    test('fromValue defaults to chapterRead on null or unknown value', () {
      expect(
        ReadingHistoryActionType.fromValue(null),
        equals(ReadingHistoryActionType.chapterRead),
      );
      expect(
        ReadingHistoryActionType.fromValue('invalid_type'),
        equals(ReadingHistoryActionType.chapterRead),
      );
    });
  });
}
