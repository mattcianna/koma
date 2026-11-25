import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart' as client;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuthClient extends Mock implements client.FirebaseAuthClient;

void main() {
  group('AuthRepository', () {
    late client.FirebaseAuthClient authClient;
    late AuthRepository authRepository;

    setUp(() {
      authClient = _MockFirebaseAuthClient();
      authRepository = AuthRepository(authClient: authClient);
    });

    group('constructor', () {
      test('can be instantiated with authClient', () {
        expect(AuthRepository(authClient: authClient), isNotNull);
      });

      test('attempts to instantiate default client when none provided', () {
        expect(AuthRepository.new, throwsA(isA<Exception>()));
      });
    });

    group('user', () {
      test('emits AppUser.empty when client emits null', () {
        when(() => authClient.user).thenAnswer((_) => Stream.value(null));

        expect(authRepository.user, emitsInOrder([AppUser.empty]));
      });

      test('emits AppUser.empty when client emits AuthClientUser.empty', () {
        when(() => authClient.user)
            .thenAnswer((_) => Stream.value(client.AuthClientUser.empty));

        expect(authRepository.user, emitsInOrder([AppUser.empty]));
      });

      test('emits mapped AppUser when client emits populated user', () {
        const clientUser = client.AuthClientUser(
          uid: 'user-123',
          email: 'reader@koma.app',
          displayName: 'Reader',
          photoUrl: 'https://koma.app/p.png',
        );

        when(() => authClient.user).thenAnswer((_) => Stream.value(clientUser));

        expect(
          authRepository.user,
          emitsInOrder([
            const AppUser(
              uid: 'user-123',
              email: 'reader@koma.app',
              displayName: 'Reader',
              photoUrl: 'https://koma.app/p.png',
            ),
          ]),
        );
      });
    });

    group('currentUser', () {
      test('returns AppUser.empty when client.currentUser is null', () {
        when(() => authClient.currentUser).thenReturn(null);

        expect(authRepository.currentUser, equals(AppUser.empty));
      });

      test(
        'returns AppUser.empty when client.currentUser is AuthClientUser.empty',
        () {
          when(() => authClient.currentUser)
              .thenReturn(client.AuthClientUser.empty);

          expect(authRepository.currentUser, equals(AppUser.empty));
        },
      );

      test('returns mapped AppUser when client.currentUser is populated', () {
        const clientUser = client.AuthClientUser(
          uid: 'user-789',
          email: 'test@example.com',
          displayName: 'Tester',
          photoUrl: 'https://example.com/avatar.png',
        );
        when(() => authClient.currentUser).thenReturn(clientUser);

        expect(
          authRepository.currentUser,
          equals(
            const AppUser(
              uid: 'user-789',
              email: 'test@example.com',
              displayName: 'Tester',
              photoUrl: 'https://example.com/avatar.png',
            ),
          ),
        );
      });
    });

    group('logInWithEmailAndPassword', () {
      test('calls signInWithEmailAndPassword with correct arguments', () async {
        when(
          () => authClient.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'Password123!',
          ),
        ).thenAnswer((_) async => const client.AuthClientUser(uid: 'uid-123'));

        await authRepository.logInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'Password123!',
        );

        verify(
          () => authClient.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'Password123!',
          ),
        ).called(1);
      });

      test(
        'rethrows mapped AuthFailure when AuthClientException occurs',
        () async {
          when(
            () => authClient.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(const client.InvalidCredentialsAuthFailure('invalid'));

          expect(
            () => authRepository.logInWithEmailAndPassword(
              email: 'bad@example.com',
              password: 'wrong',
            ),
            throwsA(isA<InvalidCredentialsFailure>()),
          );
        },
      );

      test('rethrows UnknownAuthFailure on generic exception', () async {
        when(
          () => authClient.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Unexpected crash'));

        expect(
          () => authRepository.logInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'pass',
          ),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });
    });

    group('signUp', () {
      test('calls signUpWithEmailAndPassword with correct arguments', () async {
        when(
          () => authClient.signUpWithEmailAndPassword(
            email: 'new@example.com',
            password: 'Password123!',
            displayName: 'New User',
          ),
        ).thenAnswer((_) async => const client.AuthClientUser(uid: 'uid-new'));

        await authRepository.signUp(
          email: 'new@example.com',
          password: 'Password123!',
          displayName: 'New User',
        );

        verify(
          () => authClient.signUpWithEmailAndPassword(
            email: 'new@example.com',
            password: 'Password123!',
            displayName: 'New User',
          ),
        ).called(1);
      });

      test(
        'rethrows mapped AuthFailure when AuthClientException occurs',
        () async {
          when(
            () => authClient.signUpWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            ),
          ).thenThrow(const client.EmailAlreadyInUseAuthFailure('exists'));

          expect(
            () => authRepository.signUp(
              email: 'existing@example.com',
              password: 'Password123!',
            ),
            throwsA(isA<EmailAlreadyInUseFailure>()),
          );
        },
      );

      test('rethrows UnknownAuthFailure on generic exception', () async {
        when(
          () => authClient.signUpWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(Exception('Unexpected'));

        expect(
          () => authRepository.signUp(
            email: 'err@example.com',
            password: 'Password123!',
          ),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });
    });

    group('logInWithGoogle', () {
      test('calls signInWithGoogle', () async {
        when(() => authClient.signInWithGoogle()).thenAnswer(
          (_) async => const client.AuthClientUser(uid: 'google-uid'),
        );

        await authRepository.logInWithGoogle();

        verify(() => authClient.signInWithGoogle()).called(1);
      });

      test(
        'rethrows mapped AuthFailure when AuthClientException occurs',
        () async {
          when(() => authClient.signInWithGoogle())
              .thenThrow(const client.GoogleSignInCancelledAuthFailure());

          expect(
            () => authRepository.logInWithGoogle(),
            throwsA(isA<GoogleSignInCancelledFailure>()),
          );
        },
      );

      test('rethrows UnknownAuthFailure on generic exception', () async {
        when(() => authClient.signInWithGoogle()).thenThrow(Exception('Crash'));

        expect(
          () => authRepository.logInWithGoogle(),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });
    });

    group('logInWithTestAccount', () {
      test('signs in with default canonical QA credentials', () async {
        when(
          () => authClient.signInWithEmailAndPassword(
            email: AuthRepository.testAccountEmail,
            password: AuthRepository.testAccountPassword,
          ),
        ).thenAnswer(
          (_) async => const client.AuthClientUser(uid: 'koma-test-uid-001'),
        );

        await authRepository.logInWithTestAccount();

        verify(
          () => authClient.signInWithEmailAndPassword(
            email: 'test@mangatracker.local',
            password: 'KomaTest!2026#Dev',
          ),
        ).called(1);
      });

      test('signs in with custom credentials when provided', () async {
        when(
          () => authClient.signInWithEmailAndPassword(
            email: 'custom@test.local',
            password: 'CustomPassword123!',
          ),
        ).thenAnswer(
          (_) async => const client.AuthClientUser(uid: 'custom-uid'),
        );

        await authRepository.logInWithTestAccount(
          email: 'custom@test.local',
          password: 'CustomPassword123!',
        );

        verify(
          () => authClient.signInWithEmailAndPassword(
            email: 'custom@test.local',
            password: 'CustomPassword123!',
          ),
        ).called(1);
      });
    });

    group('logOut', () {
      test('calls signOut', () async {
        when(() => authClient.signOut()).thenAnswer((_) async {});

        await authRepository.logOut();

        verify(() => authClient.signOut()).called(1);
      });

      test(
        'rethrows mapped AuthFailure when AuthClientException occurs',
        () async {
          when(() => authClient.signOut())
              .thenThrow(const client.NetworkAuthFailure('no internet'));

          expect(() => authRepository.logOut(), throwsA(isA<NetworkFailure>()));
        },
      );

      test('rethrows UnknownAuthFailure on generic exception', () async {
        when(() => authClient.signOut()).thenThrow(Exception('Fatal'));

        expect(
          () => authRepository.logOut(),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });
    });
  });
}
