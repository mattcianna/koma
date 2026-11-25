import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingStatus', () {
    test('contains canonical firestore values', () {
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

    test('fromFirestore falls back to planToRead on null or unknown value', () {
      expect(
        ReadingStatus.fromFirestore(null),
        equals(ReadingStatus.planToRead),
      );
      expect(
        ReadingStatus.fromFirestore('UnknownStatus'),
        equals(ReadingStatus.planToRead),
      );
    });
  });
}
