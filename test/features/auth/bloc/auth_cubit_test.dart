import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/auth/bloc/auth_cubit.dart';
import 'package:koma/features/auth/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

void main() {
  group('AuthCubit', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = _MockAuthRepository();
    });

    test('initial state is AuthState()', () {
      final cubit = AuthCubit(authRepository: authRepository);
      expect(cubit.state, equals(const AuthState()));
      expect(cubit.authRepository, equals(authRepository));
    });

    group('toggleMode', () {
      blocTest<AuthCubit, AuthState>(
        'switches from signIn to signUp mode and resets error',
        build: () => AuthCubit(authRepository: authRepository),
        seed: () => const AuthState(
          status: AuthStatus.failure,
          errorCode: AuthErrorCode.invalidCredentials,
        ),
        act: (cubit) => cubit.toggleMode(),
        expect: () => const [AuthState(mode: AuthMode.signUp)],
      );

      blocTest<AuthCubit, AuthState>(
        'switches from signUp to signIn mode',
        build: () => AuthCubit(authRepository: authRepository),
        seed: () => const AuthState(mode: AuthMode.signUp),
        act: (cubit) => cubit.toggleMode(),
        expect: () => const [AuthState()],
      );
    });

    group('clearError', () {
      blocTest<AuthCubit, AuthState>(
        'clears failure and resets to initial when error is present',
        build: () => AuthCubit(authRepository: authRepository),
        seed: () => const AuthState(
          status: AuthStatus.failure,
          errorCode: AuthErrorCode.network,
        ),
        act: (cubit) => cubit.clearError(),
        expect: () => const [AuthState()],
      );

      blocTest<AuthCubit, AuthState>(
        'does not emit when already in initial state with no error',
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.clearError(),
        expect: () => <AuthState>[],
      );
    });

    group('submitCredentials', () {
      const email = 'test@example.com';
      const password = 'Password123!';
      const displayName = 'Test User';

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, success] when logInWithEmailAndPassword succeeds',
        setUp: () {
          when(
            () => authRepository.logInWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenAnswer((_) async {});
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) =>
            cubit.submitCredentials(email: email, password: password),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(status: AuthStatus.success),
        ],
        verify: (_) {
          verify(
            () => authRepository.logInWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).called(1);
        },
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with invalidCredentials failure',
        setUp: () {
          when(
            () => authRepository.logInWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenThrow(const InvalidCredentialsFailure('Invalid credentials'));
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) =>
            cubit.submitCredentials(email: email, password: password),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.invalidCredentials,
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with network error on NetworkFailure',
        setUp: () {
          when(
            () => authRepository.logInWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenThrow(const NetworkFailure('Network down'));
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) =>
            cubit.submitCredentials(email: email, password: password),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.network,
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, success] when signUp succeeds in signUp mode',
        setUp: () {
          when(
            () => authRepository.signUp(
              email: email,
              password: password,
              displayName: displayName,
            ),
          ).thenAnswer((_) async {});
        },
        build: () => AuthCubit(authRepository: authRepository),
        seed: () => const AuthState(mode: AuthMode.signUp),
        act: (cubit) => cubit.submitCredentials(
          email: email,
          password: password,
          displayName: displayName,
        ),
        expect: () => const [
          AuthState(mode: AuthMode.signUp, status: AuthStatus.submitting),
          AuthState(mode: AuthMode.signUp, status: AuthStatus.success),
        ],
        verify: (_) {
          verify(
            () => authRepository.signUp(
              email: email,
              password: password,
              displayName: displayName,
            ),
          ).called(1);
        },
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with emailAlreadyInUse on signup',
        setUp: () {
          when(
            () => authRepository.signUp(
              email: email,
              password: password,
              displayName: displayName,
            ),
          ).thenThrow(const EmailAlreadyInUseFailure());
        },
        build: () => AuthCubit(authRepository: authRepository),
        seed: () => const AuthState(mode: AuthMode.signUp),
        act: (cubit) => cubit.submitCredentials(
          email: email,
          password: password,
          displayName: displayName,
        ),
        expect: () => const [
          AuthState(mode: AuthMode.signUp, status: AuthStatus.submitting),
          AuthState(
            mode: AuthMode.signUp,
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.emailAlreadyInUse,
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with weakPassword on WeakPasswordFailure',
        setUp: () {
          when(
            () => authRepository.signUp(
              email: email,
              password: password,
              displayName: displayName,
            ),
          ).thenThrow(const WeakPasswordFailure());
        },
        build: () => AuthCubit(authRepository: authRepository),
        seed: () => const AuthState(mode: AuthMode.signUp),
        act: (cubit) => cubit.submitCredentials(
          email: email,
          password: password,
          displayName: displayName,
        ),
        expect: () => const [
          AuthState(mode: AuthMode.signUp, status: AuthStatus.submitting),
          AuthState(
            mode: AuthMode.signUp,
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.weakPassword,
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with unknown on generic exception',
        setUp: () {
          when(
            () => authRepository.logInWithEmailAndPassword(
              email: email,
              password: password,
            ),
          ).thenThrow(Exception('Crash'));
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) =>
            cubit.submitCredentials(email: email, password: password),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.unknown,
          ),
        ],
      );
    });

    group('signInWithGoogle', () {
      blocTest<AuthCubit, AuthState>(
        'emits [submitting, success] when logInWithGoogle succeeds',
        setUp: () {
          when(() => authRepository.logInWithGoogle()).thenAnswer((_) async {});
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.signInWithGoogle(),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(status: AuthStatus.success),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with googleCancelled',
        setUp: () {
          when(() => authRepository.logInWithGoogle())
              .thenThrow(const GoogleSignInCancelledFailure());
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.signInWithGoogle(),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.googleCancelled,
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with unknown on other error',
        setUp: () {
          when(() => authRepository.logInWithGoogle())
              .thenThrow(Exception('Crash'));
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.signInWithGoogle(),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.unknown,
          ),
        ],
      );
    });

    group('signInWithTestAccount', () {
      blocTest<AuthCubit, AuthState>(
        'emits [submitting, success] when logInWithTestAccount succeeds',
        setUp: () {
          when(() => authRepository.logInWithTestAccount())
              .thenAnswer((_) async {});
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.signInWithTestAccount(),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(status: AuthStatus.success),
        ],
        verify: (_) {
          verify(() => authRepository.logInWithTestAccount()).called(1);
        },
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with invalidCredentials on rejection',
        setUp: () {
          when(() => authRepository.logInWithTestAccount())
              .thenThrow(const InvalidCredentialsFailure());
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.signInWithTestAccount(),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.invalidCredentials,
          ),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [submitting, failure] with unknown on unexpected exception',
        setUp: () {
          when(() => authRepository.logInWithTestAccount())
              .thenThrow(Exception('Crash'));
        },
        build: () => AuthCubit(authRepository: authRepository),
        act: (cubit) => cubit.signInWithTestAccount(),
        expect: () => const [
          AuthState(status: AuthStatus.submitting),
          AuthState(
            status: AuthStatus.failure,
            errorCode: AuthErrorCode.unknown,
          ),
        ],
      );
    });
  });
}
