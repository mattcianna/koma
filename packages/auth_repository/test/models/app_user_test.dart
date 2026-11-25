import 'package:auth_repository/auth_repository.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser', () {
    test('supports value equality', () {
      expect(
        const AppUser(
          uid: '123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/avatar.png',
        ),
        equals(
          const AppUser(
            uid: '123',
            email: 'test@example.com',
            displayName: 'Test User',
            photoUrl: 'https://example.com/avatar.png',
          ),
        ),
      );
    });

    test('empty user has empty uid and isEmpty true', () {
      expect(AppUser.empty.uid, isEmpty);
      expect(AppUser.empty.isEmpty, isTrue);
      expect(AppUser.empty.isNotEmpty, isFalse);
      expect(AppUser.empty.email, isNull);
      expect(AppUser.empty.displayName, isNull);
      expect(AppUser.empty.photoUrl, isNull);
    });

    test('non-empty user has isEmpty false and isNotEmpty true', () {
      const user = AppUser(uid: '123');
      expect(user.isEmpty, isFalse);
      expect(user.isNotEmpty, isTrue);
    });

    group('fromAuthClientUser', () {
      test('returns AppUser.empty when clientUser is empty', () {
        expect(
          AppUser.fromAuthClientUser(AuthClientUser.empty),
          equals(AppUser.empty),
        );
      });

      test('converts populated AuthClientUser correctly', () {
        const clientUser = AuthClientUser(
          uid: '456',
          email: 'manga@example.com',
          displayName: 'Manga Reader',
          photoUrl: 'https://example.com/pic.jpg',
        );

        final user = AppUser.fromAuthClientUser(clientUser);

        expect(user.uid, equals('456'));
        expect(user.email, equals('manga@example.com'));
        expect(user.displayName, equals('Manga Reader'));
        expect(user.photoUrl, equals('https://example.com/pic.jpg'));
      });
    });

    group('copyWith', () {
      test('returns same object when no arguments passed', () {
        const user = AppUser(
          uid: '123',
          email: 'test@example.com',
          displayName: 'Test',
          photoUrl: 'https://example.com/avatar.png',
        );

        expect(user.copyWith(), equals(user));
      });

      test('replaces updated fields', () {
        const user = AppUser(
          uid: '123',
          email: 'old@example.com',
          displayName: 'Old Name',
          photoUrl: 'https://example.com/old.png',
        );

        final updated = user.copyWith(
          uid: '456',
          email: 'new@example.com',
          displayName: 'New Name',
          photoUrl: 'https://example.com/new.png',
        );

        expect(
          updated,
          equals(
            const AppUser(
              uid: '456',
              email: 'new@example.com',
              displayName: 'New Name',
              photoUrl: 'https://example.com/new.png',
            ),
          ),
        );
      });
    });
  });
}
