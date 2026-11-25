import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/auth/bloc/auth_state.dart';

void main() {
  group('AuthState', () {
    test('supports value equality', () {
      expect(const AuthState(), equals(const AuthState()));
    });

    test('has expected default values', () {
      const state = AuthState();
      expect(state.mode, equals(AuthMode.signIn));
      expect(state.status, equals(AuthStatus.initial));
      expect(state.errorCode, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.isSignUp, isFalse);
    });

    test('computed getters reflect state correctly', () {
      expect(const AuthState(mode: AuthMode.signUp).isSignUp, isTrue);
      expect(
        const AuthState(status: AuthStatus.submitting).isSubmitting,
        isTrue,
      );
      expect(const AuthState(status: AuthStatus.success).isSuccess, isTrue);
      expect(const AuthState(status: AuthStatus.failure).isFailure, isTrue);
    });

    test('copyWith copies values correctly', () {
      const state = AuthState();
      final updated = state.copyWith(
        mode: AuthMode.signUp,
        status: AuthStatus.failure,
        errorCode: () => AuthErrorCode.weakPassword,
      );

      expect(updated.mode, equals(AuthMode.signUp));
      expect(updated.status, equals(AuthStatus.failure));
      expect(updated.errorCode, equals(AuthErrorCode.weakPassword));

      final cleared = updated.copyWith(errorCode: () => null);
      expect(cleared.errorCode, isNull);
    });

    test('props includes all properties', () {
      const state = AuthState(
        mode: AuthMode.signUp,
        status: AuthStatus.failure,
        errorCode: AuthErrorCode.invalidCredentials,
      );
      expect(
        state.props,
        equals([
          AuthMode.signUp,
          AuthStatus.failure,
          AuthErrorCode.invalidCredentials,
        ]),
      );
    });
  });
}
