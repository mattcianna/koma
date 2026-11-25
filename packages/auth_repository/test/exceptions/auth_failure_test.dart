import 'package:auth_repository/auth_repository.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart' as client;
import 'package:flutter_test/flutter_test.dart';

class _CustomAuthClientException extends client.AuthClientException {
  const new([super.error]);
}

void main() {
  group('AuthFailure', () {
    test('InvalidCredentialsFailure supports value equality', () {
      expect(
        const InvalidCredentialsFailure('error'),
        equals(const InvalidCredentialsFailure('error')),
      );
    });

    test('EmailAlreadyInUseFailure supports value equality', () {
      expect(
        const EmailAlreadyInUseFailure('error'),
        equals(const EmailAlreadyInUseFailure('error')),
      );
    });

    test('WeakPasswordFailure supports value equality', () {
      expect(
        const WeakPasswordFailure('error'),
        equals(const WeakPasswordFailure('error')),
      );
    });

    test('GoogleSignInCancelledFailure supports value equality', () {
      expect(
        const GoogleSignInCancelledFailure('error'),
        equals(const GoogleSignInCancelledFailure('error')),
      );
    });

    test('GoogleSignInFailure supports value equality', () {
      expect(
        const GoogleSignInFailure('error'),
        equals(const GoogleSignInFailure('error')),
      );
    });

    test('NetworkFailure supports value equality', () {
      expect(
        const NetworkFailure('error'),
        equals(const NetworkFailure('error')),
      );
    });

    test('UnknownAuthFailure supports value equality', () {
      expect(
        const UnknownAuthFailure('error'),
        equals(const UnknownAuthFailure('error')),
      );
    });

    test('props contains error', () {
      expect(const InvalidCredentialsFailure('error').props, equals(['error']));
      expect(const UnknownAuthFailure().props, equals([null]));
    });

    group('toString', () {
      test('returns runtimeType when error is null', () {
        expect(
          const UnknownAuthFailure().toString(),
          equals('UnknownAuthFailure'),
        );
      });

      test('returns runtimeType and error when error is provided', () {
        expect(
          const UnknownAuthFailure('some message').toString(),
          equals('UnknownAuthFailure: some message'),
        );
      });
    });

    group('fromAuthClientException', () {
      test(
        'maps InvalidCredentialsAuthFailure to InvalidCredentialsFailure',
        () {
          const clientException = client.InvalidCredentialsAuthFailure('bad');
          final failure = AuthFailure.fromAuthClientException(clientException);

          expect(failure, isA<InvalidCredentialsFailure>());
          expect(failure.error, equals('bad'));
        },
      );

      test('maps EmailAlreadyInUseAuthFailure to EmailAlreadyInUseFailure', () {
        const clientException = client.EmailAlreadyInUseAuthFailure('exists');
        final failure = AuthFailure.fromAuthClientException(clientException);

        expect(failure, isA<EmailAlreadyInUseFailure>());
        expect(failure.error, equals('exists'));
      });

      test('maps WeakPasswordAuthFailure to WeakPasswordFailure', () {
        const clientException = client.WeakPasswordAuthFailure('weak');
        final failure = AuthFailure.fromAuthClientException(clientException);

        expect(failure, isA<WeakPasswordFailure>());
        expect(failure.error, equals('weak'));
      });

      test(
        'maps GoogleSignInCancelledAuthFailure to GoogleSignInCancelledFailure',
        () {
          const clientException = client.GoogleSignInCancelledAuthFailure(
            'cancel',
          );
          final failure = AuthFailure.fromAuthClientException(clientException);

          expect(failure, isA<GoogleSignInCancelledFailure>());
          expect(failure.error, equals('cancel'));
        },
      );

      test('maps GoogleSignInAuthFailure to GoogleSignInFailure', () {
        const clientException = client.GoogleSignInAuthFailure('google err');
        final failure = AuthFailure.fromAuthClientException(clientException);

        expect(failure, isA<GoogleSignInFailure>());
        expect(failure.error, equals('google err'));
      });

      test('maps NetworkAuthFailure to NetworkFailure', () {
        const clientException = client.NetworkAuthFailure('offline');
        final failure = AuthFailure.fromAuthClientException(clientException);

        expect(failure, isA<NetworkFailure>());
        expect(failure.error, equals('offline'));
      });

      test('maps UnknownAuthFailure to UnknownAuthFailure', () {
        const clientException = client.UnknownAuthFailure('unknown err');
        final failure = AuthFailure.fromAuthClientException(clientException);

        expect(failure, isA<UnknownAuthFailure>());
        expect(failure.error, equals('unknown err'));
      });

      test('maps unhandled AuthClientException to UnknownAuthFailure', () {
        const customException = _CustomAuthClientException('custom err');
        final failure = AuthFailure.fromAuthClientException(customException);

        expect(failure, isA<UnknownAuthFailure>());
        expect(failure.error, equals('custom err'));
      });
    });
  });
}
