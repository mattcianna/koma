import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockGoogleSignIn extends Mock implements GoogleSignIn;

class _MockUserCredential extends Mock implements UserCredential;

class _MockUser extends Mock implements User;

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount;

class _MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication;

class _FakeAuthCredential extends Fake implements AuthCredential;

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  group('FirebaseAuthClient', () {
    late FirebaseAuth firebaseAuth;
    late GoogleSignIn googleSignIn;
    late FirebaseAuthClient client;
    late User user;
    late UserCredential userCredential;

    setUp(() {
      firebaseAuth = _MockFirebaseAuth();
      googleSignIn = _MockGoogleSignIn();
      client = FirebaseAuthClient(
        firebaseAuth: firebaseAuth,
        googleSignIn: googleSignIn,
      );

      user = _MockUser();
      when(() => user.uid).thenReturn('uid-123');
      when(() => user.email).thenReturn('user@example.com');
      when(() => user.displayName).thenReturn('User 123');
      when(() => user.photoURL).thenReturn('https://example.com/avatar.jpg');

      userCredential = _MockUserCredential();
      when(() => userCredential.user).thenReturn(user);
    });

    group('constructor', () {
      test(
        'instantiates with default GoogleSignIn when firebaseAuth is provided',
        () {
          expect(FirebaseAuthClient(firebaseAuth: firebaseAuth), isNotNull);
        },
      );
    });

    group('user', () {
      test('emits null when authStateChanges emits null', () async {
        when(() => firebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.value(null));

        expect(client.user, emits(isNull));
      });

      test('emits AuthClientUser when authStateChanges emits User', () async {
        when(() => firebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.value(user));

        expect(
          client.user,
          emits(
            equals(
              const AuthClientUser(
                uid: 'uid-123',
                email: 'user@example.com',
                displayName: 'User 123',
                photoUrl: 'https://example.com/avatar.jpg',
              ),
            ),
          ),
        );
      });
    });

    group('currentUser', () {
      test('returns null when FirebaseAuth.currentUser is null', () {
        when(() => firebaseAuth.currentUser).thenReturn(null);

        expect(client.currentUser, isNull);
      });

      test(
        'returns AuthClientUser when FirebaseAuth.currentUser is not null',
        () {
          when(() => firebaseAuth.currentUser).thenReturn(user);

          expect(
            client.currentUser,
            equals(
              const AuthClientUser(
                uid: 'uid-123',
                email: 'user@example.com',
                displayName: 'User 123',
                photoUrl: 'https://example.com/avatar.jpg',
              ),
            ),
          );
        },
      );
    });

    group('signInWithEmailAndPassword', () {
      test('succeeds and returns AuthClientUser', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenAnswer((_) async => userCredential);

        final result = await client.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'secretPassword123',
        );

        expect(
          result,
          equals(
            const AuthClientUser(
              uid: 'uid-123',
              email: 'user@example.com',
              displayName: 'User 123',
              photoUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        );
      });

      test('throws UnknownAuthFailure when user is null', () async {
        when(() => userCredential.user).thenReturn(null);
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenAnswer((_) async => userCredential);

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });

      test(
        'maps invalid-credential to InvalidCredentialsAuthFailure',
        () async {
          when(
            () => firebaseAuth.signInWithEmailAndPassword(
              email: 'user@example.com',
              password: 'secretPassword123',
            ),
          ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

          expect(
            () => client.signInWithEmailAndPassword(
              email: 'user@example.com',
              password: 'secretPassword123',
            ),
            throwsA(isA<InvalidCredentialsAuthFailure>()),
          );
        },
      );

      test('maps wrong-password to InvalidCredentialsAuthFailure', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<InvalidCredentialsAuthFailure>()),
        );
      });

      test('maps user-not-found to InvalidCredentialsAuthFailure', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<InvalidCredentialsAuthFailure>()),
        );
      });

      test('maps invalid-email to InvalidCredentialsAuthFailure', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'bad-email',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'invalid-email'));

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'bad-email',
            password: 'secretPassword123',
          ),
          throwsA(isA<InvalidCredentialsAuthFailure>()),
        );
      });

      test('maps user-disabled to InvalidCredentialsAuthFailure', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'user-disabled'));

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<InvalidCredentialsAuthFailure>()),
        );
      });

      test('maps network-request-failed to NetworkAuthFailure', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<NetworkAuthFailure>()),
        );
      });

      test(
        'maps unknown FirebaseAuthException code to UnknownAuthFailure',
        () async {
          when(
            () => firebaseAuth.signInWithEmailAndPassword(
              email: 'user@example.com',
              password: 'secretPassword123',
            ),
          ).thenThrow(FirebaseAuthException(code: 'internal-error'));

          expect(
            () => client.signInWithEmailAndPassword(
              email: 'user@example.com',
              password: 'secretPassword123',
            ),
            throwsA(isA<UnknownAuthFailure>()),
          );
        },
      );

      test('maps generic Exception to UnknownAuthFailure', () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(Exception('Unexpected crash'));

        expect(
          () => client.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('succeeds without displayName', () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenAnswer((_) async => userCredential);

        final result = await client.signUpWithEmailAndPassword(
          email: 'user@example.com',
          password: 'secretPassword123',
        );

        expect(
          result,
          equals(
            const AuthClientUser(
              uid: 'uid-123',
              email: 'user@example.com',
              displayName: 'User 123',
              photoUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        );
        verifyNever(() => user.updateDisplayName(any()));
      });

      test('succeeds and updates displayName when provided', () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenAnswer((_) async => userCredential);
        when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
        when(() => user.reload()).thenAnswer((_) async {});

        final result = await client.signUpWithEmailAndPassword(
          email: 'user@example.com',
          password: 'secretPassword123',
          displayName: 'New Display Name',
        );

        expect(
          result,
          equals(
            const AuthClientUser(
              uid: 'uid-123',
              email: 'user@example.com',
              displayName: 'New Display Name',
              photoUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        );
        verify(() => user.updateDisplayName('New Display Name')).called(1);
        verify(() => user.reload()).called(1);
      });

      test('throws UnknownAuthFailure when user is null', () async {
        when(() => userCredential.user).thenReturn(null);
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenAnswer((_) async => userCredential);

        expect(
          () => client.signUpWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });

      test(
        'maps email-already-in-use to EmailAlreadyInUseAuthFailure',
        () async {
          when(
            () => firebaseAuth.createUserWithEmailAndPassword(
              email: 'user@example.com',
              password: 'secretPassword123',
            ),
          ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

          expect(
            () => client.signUpWithEmailAndPassword(
              email: 'user@example.com',
              password: 'secretPassword123',
            ),
            throwsA(isA<EmailAlreadyInUseAuthFailure>()),
          );
        },
      );

      test('maps weak-password to WeakPasswordAuthFailure', () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'user@example.com',
            password: '123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'weak-password'));

        expect(
          () => client.signUpWithEmailAndPassword(
            email: 'user@example.com',
            password: '123',
          ),
          throwsA(isA<WeakPasswordAuthFailure>()),
        );
      });

      test('maps invalid-email to InvalidCredentialsAuthFailure', () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'not-an-email',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'invalid-email'));

        expect(
          () => client.signUpWithEmailAndPassword(
            email: 'not-an-email',
            password: 'secretPassword123',
          ),
          throwsA(isA<InvalidCredentialsAuthFailure>()),
        );
      });

      test('maps network-request-failed to NetworkAuthFailure', () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        expect(
          () => client.signUpWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<NetworkAuthFailure>()),
        );
      });

      test('maps generic Exception to UnknownAuthFailure', () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
        ).thenThrow(Exception('Account creation crashed'));

        expect(
          () => client.signUpWithEmailAndPassword(
            email: 'user@example.com',
            password: 'secretPassword123',
          ),
          throwsA(isA<UnknownAuthFailure>()),
        );
      });
    });

    group('signInWithGoogle', () {
      late GoogleSignInAccount googleAccount;
      late GoogleSignInAuthentication googleAuth;

      setUp(() {
        googleAccount = _MockGoogleSignInAccount();
        googleAuth = _MockGoogleSignInAuthentication();

        when(() => googleAccount.authentication)
            .thenAnswer((_) async => googleAuth);
        when(() => googleAuth.accessToken).thenReturn('google-access-token');
        when(() => googleAuth.idToken).thenReturn('google-id-token');
      });

      test('succeeds and returns AuthClientUser', () async {
        when(() => googleSignIn.signIn())
            .thenAnswer((_) async => googleAccount);
        when(() => firebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) async => userCredential);

        final result = await client.signInWithGoogle();

        expect(
          result,
          equals(
            const AuthClientUser(
              uid: 'uid-123',
              email: 'user@example.com',
              displayName: 'User 123',
              photoUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        );
        verify(() => googleSignIn.signIn()).called(1);
        verify(() => firebaseAuth.signInWithCredential(any())).called(1);
      });

      test(
        'throws GoogleSignInCancelledAuthFailure when user cancels',
        () async {
          when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

          expect(
            () => client.signInWithGoogle(),
            throwsA(isA<GoogleSignInCancelledAuthFailure>()),
          );
          verifyNever(() => firebaseAuth.signInWithCredential(any()));
        },
      );

      test(
        'throws GoogleSignInAuthFailure when user is null after sign in',
        () async {
          when(() => googleSignIn.signIn())
              .thenAnswer((_) async => googleAccount);
          when(() => userCredential.user).thenReturn(null);
          when(() => firebaseAuth.signInWithCredential(any()))
              .thenAnswer((_) async => userCredential);

          expect(
            () => client.signInWithGoogle(),
            throwsA(isA<GoogleSignInAuthFailure>()),
          );
        },
      );

      test(
        'throws GoogleSignInAuthFailure when googleSignIn.signIn throws',
        () async {
          when(() => googleSignIn.signIn())
              .thenThrow(Exception('Google Play services error'));

          expect(
            () => client.signInWithGoogle(),
            throwsA(isA<GoogleSignInAuthFailure>()),
          );
        },
      );

      test(
        'throws GoogleSignInAuthFailure when authentication throws',
        () async {
          when(() => googleSignIn.signIn())
              .thenAnswer((_) async => googleAccount);
          when(() => googleAccount.authentication)
              .thenThrow(Exception('Auth token error'));

          expect(
            () => client.signInWithGoogle(),
            throwsA(isA<GoogleSignInAuthFailure>()),
          );
        },
      );

      test('maps account-exists-with-different-credential', () async {
        when(() => googleSignIn.signIn())
            .thenAnswer((_) async => googleAccount);
        when(() => firebaseAuth.signInWithCredential(any())).thenThrow(
          FirebaseAuthException(
            code: 'account-exists-with-different-credential',
          ),
        );

        expect(
          () => client.signInWithGoogle(),
          throwsA(isA<EmailAlreadyInUseAuthFailure>()),
        );
      });

      test('maps network-request-failed to NetworkAuthFailure', () async {
        when(() => googleSignIn.signIn())
            .thenAnswer((_) async => googleAccount);
        when(() => firebaseAuth.signInWithCredential(any()))
            .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        expect(
          () => client.signInWithGoogle(),
          throwsA(isA<NetworkAuthFailure>()),
        );
      });

      test(
        'maps other FirebaseAuthException to GoogleSignInAuthFailure',
        () async {
          when(() => googleSignIn.signIn())
              .thenAnswer((_) async => googleAccount);
          when(() => firebaseAuth.signInWithCredential(any()))
              .thenThrow(FirebaseAuthException(code: 'internal-error'));

          expect(
            () => client.signInWithGoogle(),
            throwsA(isA<GoogleSignInAuthFailure>()),
          );
        },
      );
    });

    group('signOut', () {
      test('signs out of both FirebaseAuth and GoogleSignIn', () async {
        when(() => firebaseAuth.signOut()).thenAnswer((_) async {});
        when(() => googleSignIn.signOut()).thenAnswer((_) async => null);

        await client.signOut();

        verify(() => firebaseAuth.signOut()).called(1);
        verify(() => googleSignIn.signOut()).called(1);
      });

      test('maps network-request-failed to NetworkAuthFailure', () async {
        when(() => firebaseAuth.signOut())
            .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
        when(() => googleSignIn.signOut()).thenAnswer((_) async => null);

        expect(() => client.signOut(), throwsA(isA<NetworkAuthFailure>()));
      });

      test('maps generic Exception to UnknownAuthFailure', () async {
        when(() => firebaseAuth.signOut())
            .thenThrow(Exception('Sign out failed'));
        when(() => googleSignIn.signOut()).thenAnswer((_) async => null);

        expect(() => client.signOut(), throwsA(isA<UnknownAuthFailure>()));
      });
    });
  });
}
