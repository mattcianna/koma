import 'package:firebase_auth_client/firebase_auth_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthClientUser', () {
    const user = AuthClientUser(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.png',
    );

    test('supports value equality', () {
      const userCopy = AuthClientUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.png',
      );
      expect(user, equals(userCopy));
    });

    test('props contains all fields', () {
      expect(
        user.props,
        equals([
          'test-uid',
          'test@example.com',
          'Test User',
          'https://example.com/photo.png',
        ]),
      );
    });

    test('empty user has expected properties', () {
      expect(AuthClientUser.empty.uid, isEmpty);
      expect(AuthClientUser.empty.email, isNull);
      expect(AuthClientUser.empty.displayName, isNull);
      expect(AuthClientUser.empty.photoUrl, isNull);
      expect(AuthClientUser.empty.isEmpty, isTrue);
      expect(AuthClientUser.empty.isNotEmpty, isFalse);
    });

    test('non-empty user reports isEmpty false and isNotEmpty true', () {
      expect(user.isEmpty, isFalse);
      expect(user.isNotEmpty, isTrue);
    });
  });
}
