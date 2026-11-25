import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T>;

void main() {
  group('UserProfileRecord', () {
    final now = DateTime(2026, 11, 13, 10);

    test('supports value equality', () {
      final a = UserProfileRecord(
        uid: 'uid-1',
        email: 'test@example.com',
        createdAt: now,
        updatedAt: now,
      );
      final b = UserProfileRecord(
        uid: 'uid-1',
        email: 'test@example.com',
        createdAt: now,
        updatedAt: now,
      );

      expect(a, equals(b));
      expect(a.props, equals(b.props));
    });

    test('deserializes from map with Timestamp and custom preferences', () {
      final map = <String, dynamic>{
        'uid': 'uid-123',
        'email': 'reader@ciannavei.dev',
        'displayName': 'Matteo',
        'photoUrl': 'https://example.com/avatar.png',
        'uiLocale': 'it',
        'preferredLanguages': ['it', 'en'],
        'contentRatings': ['safe'],
        'notificationsEnabled': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final record = UserProfileRecord.fromMap(map);

      expect(record.uid, equals('uid-123'));
      expect(record.email, equals('reader@ciannavei.dev'));
      expect(record.displayName, equals('Matteo'));
      expect(record.photoUrl, equals('https://example.com/avatar.png'));
      expect(record.uiLocale, equals('it'));
      expect(record.preferredLanguages, equals(['it', 'en']));
      expect(record.contentRatings, equals(['safe']));
      expect(record.notificationsEnabled, isFalse);
      expect(record.createdAt, equals(now));
      expect(record.updatedAt, equals(now));
    });

    test('deserializes from map with fallbacks and multiple date formats', () {
      final record = UserProfileRecord.fromMap(<String, dynamic>{
        'createdAt': '2026-11-13T10:00:00.000',
        'updatedAt': now.millisecondsSinceEpoch,
      }, uid: 'fallback-uid');

      expect(record.uid, equals('fallback-uid'));
      expect(record.email, isEmpty);
      expect(record.uiLocale, equals('en'));
      expect(record.preferredLanguages, equals(['en', 'it']));
      expect(record.contentRatings, equals(['safe', 'suggestive']));
      expect(record.notificationsEnabled, isTrue);
      expect(record.createdAt, equals(now));
      expect(record.updatedAt, equals(now));

      final recordWithFallback = UserProfileRecord.fromMap(
        const <String, dynamic>{'createdAt': false, 'updatedAt': false},
      );
      expect(recordWithFallback.createdAt, isA<DateTime>());
      expect(recordWithFallback.updatedAt, isA<DateTime>());
    });

    test('deserializes from DocumentSnapshot', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('snapshot-uid');
      when(snapshot.data).thenReturn(<String, dynamic>{
        'email': 'snapshot@example.com',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final record = UserProfileRecord.fromDocument(snapshot);

      expect(record.uid, equals('snapshot-uid'));
      expect(record.email, equals('snapshot@example.com'));
    });

    test('deserializes from DocumentSnapshot with null data', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('null-uid');
      when(snapshot.data).thenReturn(null);

      final record = UserProfileRecord.fromDocument(snapshot);
      expect(record.uid, equals('null-uid'));
      expect(record.email, isEmpty);
    });

    test('serializes to map with Timestamp', () {
      final record = UserProfileRecord(
        uid: 'uid-1',
        email: 'user@example.com',
        displayName: 'User One',
        photoUrl: 'https://example.com/p.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final map = record.toMap();

      expect(map['uid'], equals('uid-1'));
      expect(map['email'], equals('user@example.com'));
      expect(map['displayName'], equals('User One'));
      expect(map['photoUrl'], equals('https://example.com/p.jpg'));
      expect(map['uiLocale'], equals('en'));
      expect(map['preferredLanguages'], equals(['en', 'it']));
      expect(map['contentRatings'], equals(['safe', 'suggestive']));
      expect(map['notificationsEnabled'], isTrue);
      expect(map['createdAt'], equals(Timestamp.fromDate(now)));
      expect(map['updatedAt'], equals(Timestamp.fromDate(now)));
    });

    test('copyWith updates specified fields', () {
      final initial = UserProfileRecord(
        uid: 'uid-1',
        email: 'user@example.com',
        createdAt: now,
        updatedAt: now,
      );

      final updated = initial.copyWith(
        uid: 'uid-2',
        email: 'new@example.com',
        displayName: 'New Name',
        photoUrl: 'https://new.url',
        uiLocale: 'it',
        preferredLanguages: ['it'],
        contentRatings: ['safe'],
        notificationsEnabled: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 2),
      );

      expect(updated.uid, equals('uid-2'));
      expect(updated.email, equals('new@example.com'));
      expect(updated.displayName, equals('New Name'));
      expect(updated.photoUrl, equals('https://new.url'));
      expect(updated.uiLocale, equals('it'));
      expect(updated.preferredLanguages, equals(['it']));
      expect(updated.contentRatings, equals(['safe']));
      expect(updated.notificationsEnabled, isFalse);
      expect(updated.createdAt, equals(DateTime(2026)));
      expect(updated.updatedAt, equals(DateTime(2026, 2)));

      final unchanged = initial.copyWith();
      expect(unchanged, equals(initial));
    });
  });
}
