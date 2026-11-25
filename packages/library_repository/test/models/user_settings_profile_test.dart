import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_repository/library_repository.dart';

void main() {
  group('UserSettingsProfile', () {
    final now = DateTime(2026, 11, 13, 10);

    test('supports value equality', () {
      final profileA = UserSettingsProfile(
        uid: 'user-1',
        email: 'user@test.com',
        createdAt: now,
        updatedAt: now,
      );
      final profileB = UserSettingsProfile(
        uid: 'user-1',
        email: 'user@test.com',
        createdAt: now,
        updatedAt: now,
      );

      expect(profileA, equals(profileB));
    });

    test('has sensible default values', () {
      final profile = UserSettingsProfile(
        uid: 'user-1',
        email: 'user@test.com',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.uiLocale, equals('en'));
      expect(profile.preferredLanguages, equals(const ['en', 'it']));
      expect(profile.contentRatings, equals(const ['safe', 'suggestive']));
      expect(profile.notificationsEnabled, isTrue);
      expect(profile.displayName, isNull);
      expect(profile.photoUrl, isNull);
    });

    test('fromRecord maps all fields correctly', () {
      final record = UserProfileRecord(
        uid: 'user-42',
        email: 'reader@koma.dev',
        displayName: 'Matteo',
        photoUrl: 'https://example.com/avatar.png',
        uiLocale: 'it',
        preferredLanguages: const ['it', 'en'],
        contentRatings: const ['safe'],
        notificationsEnabled: false,
        createdAt: now,
        updatedAt: now,
      );

      final profile = UserSettingsProfile.fromRecord(record);

      expect(profile.uid, equals('user-42'));
      expect(profile.email, equals('reader@koma.dev'));
      expect(profile.displayName, equals('Matteo'));
      expect(profile.photoUrl, equals('https://example.com/avatar.png'));
      expect(profile.uiLocale, equals('it'));
      expect(profile.preferredLanguages, equals(const ['it', 'en']));
      expect(profile.contentRatings, equals(const ['safe']));
      expect(profile.notificationsEnabled, isFalse);
      expect(profile.createdAt, equals(now));
      expect(profile.updatedAt, equals(now));
    });

    test('toRecord converts to UserProfileRecord accurately', () {
      final profile = UserSettingsProfile(
        uid: 'user-42',
        email: 'reader@koma.dev',
        displayName: 'Matteo',
        photoUrl: 'https://example.com/avatar.png',
        uiLocale: 'it',
        preferredLanguages: const ['it', 'en'],
        contentRatings: const ['safe'],
        notificationsEnabled: false,
        createdAt: now,
        updatedAt: now,
      );

      final record = profile.toRecord();

      expect(record.uid, equals('user-42'));
      expect(record.email, equals('reader@koma.dev'));
      expect(record.displayName, equals('Matteo'));
      expect(record.photoUrl, equals('https://example.com/avatar.png'));
      expect(record.uiLocale, equals('it'));
      expect(record.preferredLanguages, equals(const ['it', 'en']));
      expect(record.contentRatings, equals(const ['safe']));
      expect(record.notificationsEnabled, isFalse);
      expect(record.createdAt, equals(now));
      expect(record.updatedAt, equals(now));
    });

    test('copyWith replaces specified fields and retains others', () {
      final initial = UserSettingsProfile(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Name 1',
        photoUrl: 'https://example.com/1.png',
        uiLocale: 'fr',
        preferredLanguages: const ['en'],
        contentRatings: const ['safe'],
        notificationsEnabled: false,
        createdAt: now,
        updatedAt: now,
      );

      final later = now.add(const Duration(hours: 1));
      final updated = initial.copyWith(
        displayName: 'Name 2',
        photoUrl: 'https://example.com/2.png',
        uiLocale: 'it',
        preferredLanguages: const ['it', 'en'],
        contentRatings: const ['safe', 'suggestive'],
        notificationsEnabled: true,
        updatedAt: later,
      );

      expect(updated.uid, equals('user-1'));
      expect(updated.email, equals('test@example.com'));
      expect(updated.displayName, equals('Name 2'));
      expect(updated.photoUrl, equals('https://example.com/2.png'));
      expect(updated.uiLocale, equals('it'));
      expect(updated.preferredLanguages, equals(const ['it', 'en']));
      expect(updated.contentRatings, equals(const ['safe', 'suggestive']));
      expect(updated.notificationsEnabled, isTrue);
      expect(updated.createdAt, equals(now));
      expect(updated.updatedAt, equals(later));
    });

    test('copyWith with no arguments retains all fields', () {
      final initial = UserSettingsProfile(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Name',
        photoUrl: 'https://example.com/pic.png',
        uiLocale: 'fr',
        preferredLanguages: const ['fr'],
        contentRatings: const ['safe'],
        notificationsEnabled: false,
        createdAt: now,
        updatedAt: now,
      );

      final copy = initial.copyWith();
      expect(copy, equals(initial));
    });
  });
}
