import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T>;

void main() {
  group('DeviceTokenRecord', () {
    final now = DateTime(2026, 11, 13, 10, 30);

    test('supports value equality', () {
      final a = DeviceTokenRecord(
        deviceId: 'device-1',
        token: 'token-abc',
        platform: 'android',
        updatedAt: now,
      );
      final b = DeviceTokenRecord(
        deviceId: 'device-1',
        token: 'token-abc',
        platform: 'android',
        updatedAt: now,
      );

      expect(a, equals(b));
      expect(a.props, equals(b.props));
    });

    test('deserializes from map with Timestamp', () {
      final map = <String, dynamic>{
        'deviceId': 'device-1',
        'token': 'fcm-token-123',
        'platform': 'ios',
        'updatedAt': Timestamp.fromDate(now),
      };

      final record = DeviceTokenRecord.fromMap(map);

      expect(record.deviceId, equals('device-1'));
      expect(record.token, equals('fcm-token-123'));
      expect(record.platform, equals('ios'));
      expect(record.updatedAt, equals(now));
    });

    test('deserializes from map with DateTime, String, int, and fallback', () {
      final recordWithDateTime = DeviceTokenRecord.fromMap(<String, dynamic>{
        'updatedAt': now,
      }, deviceId: 'fallback-id');
      expect(recordWithDateTime.deviceId, equals('fallback-id'));
      expect(recordWithDateTime.updatedAt, equals(now));
      expect(recordWithDateTime.platform, equals('android'));

      final recordWithString = DeviceTokenRecord.fromMap(
        const <String, dynamic>{'updatedAt': '2026-11-13T10:30:00.000'},
      );
      expect(recordWithString.updatedAt, equals(now));

      final recordWithInt = DeviceTokenRecord.fromMap(<String, dynamic>{
        'updatedAt': now.millisecondsSinceEpoch,
      });
      expect(recordWithInt.updatedAt, equals(now));

      final recordWithInvalid = DeviceTokenRecord.fromMap(
        const <String, dynamic>{'updatedAt': true},
      );
      expect(recordWithInvalid.updatedAt, isA<DateTime>());
    });

    test('deserializes from DocumentSnapshot', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('snapshot-device-id');
      when(snapshot.data).thenReturn(<String, dynamic>{
        'token': 'token-xyz',
        'platform': 'android',
        'updatedAt': Timestamp.fromDate(now),
      });

      final record = DeviceTokenRecord.fromDocument(snapshot);

      expect(record.deviceId, equals('snapshot-device-id'));
      expect(record.token, equals('token-xyz'));
      expect(record.platform, equals('android'));
    });

    test('deserializes from DocumentSnapshot with null data', () {
      final snapshot = _MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => snapshot.id).thenReturn('device-null');
      when(snapshot.data).thenReturn(null);

      final record = DeviceTokenRecord.fromDocument(snapshot);
      expect(record.deviceId, equals('device-null'));
      expect(record.token, isEmpty);
      expect(record.platform, equals('android'));
    });

    test('serializes to map with Timestamp', () {
      final record = DeviceTokenRecord(
        deviceId: 'dev-1',
        token: 'tok-1',
        platform: 'android',
        updatedAt: now,
      );

      final map = record.toMap();

      expect(map['deviceId'], equals('dev-1'));
      expect(map['token'], equals('tok-1'));
      expect(map['platform'], equals('android'));
      expect(map['updatedAt'], equals(Timestamp.fromDate(now)));
    });

    test('copyWith updates specified fields', () {
      final initial = DeviceTokenRecord(
        deviceId: 'dev-1',
        token: 'tok-1',
        platform: 'android',
        updatedAt: now,
      );

      final updated = initial.copyWith(
        deviceId: 'dev-2',
        token: 'tok-2',
        platform: 'ios',
        updatedAt: DateTime(2026, 12),
      );

      expect(updated.deviceId, equals('dev-2'));
      expect(updated.token, equals('tok-2'));
      expect(updated.platform, equals('ios'));
      expect(updated.updatedAt, equals(DateTime(2026, 12)));

      final unchanged = initial.copyWith();
      expect(unchanged, equals(initial));
    });
  });
}
