import 'package:flutter_test/flutter_test.dart';
import 'package:library_repository/library_repository.dart';

void main() {
  group('ReadingStatus', () {
    test('enum values map to expected firestore values', () {
      expect(ReadingStatus.reading.firestoreValue, equals('Reading'));
      expect(ReadingStatus.planToRead.firestoreValue, equals('Plan to Read'));
      expect(ReadingStatus.completed.firestoreValue, equals('Completed'));
      expect(ReadingStatus.onHold.firestoreValue, equals('On Hold'));
      expect(ReadingStatus.dropped.firestoreValue, equals('Dropped'));
    });

    test('fromFirestore parses valid firestore strings', () {
      expect(
        ReadingStatus.fromFirestore('Reading'),
        equals(ReadingStatus.reading),
      );
      expect(
        ReadingStatus.fromFirestore('Plan to Read'),
        equals(ReadingStatus.planToRead),
      );
      expect(
        ReadingStatus.fromFirestore('Completed'),
        equals(ReadingStatus.completed),
      );
      expect(
        ReadingStatus.fromFirestore('On Hold'),
        equals(ReadingStatus.onHold),
      );
      expect(
        ReadingStatus.fromFirestore('Dropped'),
        equals(ReadingStatus.dropped),
      );
    });

    test('fromFirestore defaults to planToRead for null or unknown values', () {
      expect(
        ReadingStatus.fromFirestore(null),
        equals(ReadingStatus.planToRead),
      );
      expect(
        ReadingStatus.fromFirestore('unknown_status'),
        equals(ReadingStatus.planToRead),
      );
    });
  });
}
