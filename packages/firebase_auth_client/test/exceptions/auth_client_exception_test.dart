import 'package:firebase_auth_client/firebase_auth_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthClientException', () {
    test('props contains error', () {
      const exception = InvalidCredentialsAuthFailure('test-error');
      expect(exception.props, equals(['test-error']));
      expect(exception.error, equals('test-error'));
      expect(exception.stackTrace, isNull);
    });

    test('InvalidCredentialsAuthFailure supports value equality', () {
      expect(
        const InvalidCredentialsAuthFailure('invalid'),
        equals(const InvalidCredentialsAuthFailure('invalid')),
      );
      expect(
        const InvalidCredentialsAuthFailure('invalid').toString(),
        contains('InvalidCredentialsAuthFailure: invalid'),
      );
      expect(
        const InvalidCredentialsAuthFailure().toString(),
        equals('InvalidCredentialsAuthFailure'),
      );
    });

    test('EmailAlreadyInUseAuthFailure supports value equality', () {
      expect(
        const EmailAlreadyInUseAuthFailure('email-in-use'),
        equals(const EmailAlreadyInUseAuthFailure('email-in-use')),
      );
      expect(
        const EmailAlreadyInUseAuthFailure('email-in-use').toString(),
        contains('EmailAlreadyInUseAuthFailure: email-in-use'),
      );
    });

    test('WeakPasswordAuthFailure supports value equality', () {
      expect(
        const WeakPasswordAuthFailure('weak-pass'),
        equals(const WeakPasswordAuthFailure('weak-pass')),
      );
      expect(
        const WeakPasswordAuthFailure('weak-pass').toString(),
        contains('WeakPasswordAuthFailure: weak-pass'),
      );
    });

    test('GoogleSignInCancelledAuthFailure supports value equality', () {
      expect(
        const GoogleSignInCancelledAuthFailure(),
        equals(const GoogleSignInCancelledAuthFailure()),
      );
      expect(
        const GoogleSignInCancelledAuthFailure().toString(),
        equals('GoogleSignInCancelledAuthFailure'),
      );
    });

    test('GoogleSignInAuthFailure supports value equality', () {
      expect(
        const GoogleSignInAuthFailure('sign-in-failed'),
        equals(const GoogleSignInAuthFailure('sign-in-failed')),
      );
      expect(
        const GoogleSignInAuthFailure('sign-in-failed').toString(),
        contains('GoogleSignInAuthFailure: sign-in-failed'),
      );
    });

    test('NetworkAuthFailure supports value equality', () {
      expect(
        const NetworkAuthFailure('network-error'),
        equals(const NetworkAuthFailure('network-error')),
      );
      expect(
        const NetworkAuthFailure('network-error').toString(),
        contains('NetworkAuthFailure: network-error'),
      );
    });

    test('UnknownAuthFailure supports value equality', () {
      expect(
        const UnknownAuthFailure('unknown-error'),
        equals(const UnknownAuthFailure('unknown-error')),
      );
      expect(
        const UnknownAuthFailure('unknown-error').toString(),
        contains('UnknownAuthFailure: unknown-error'),
      );
    });
  });
}
