import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:koma/features/auth/bloc/auth_state.dart';

/// {@template auth_cubit}
/// Cubit managing presentation state and actions for authentication.
/// {@endtemplate}
class AuthCubit extends Cubit<AuthState> {
  /// {@macro auth_cubit}
  new({required this.authRepository}) : super(const AuthState());

  /// The underlying authentication domain repository.
  final AuthRepository authRepository;

  /// Toggles between sign-in and sign-up form modes, clearing any error.
  void toggleMode() {
    emit(
      state.copyWith(
        mode: state.isSignUp ? AuthMode.signIn : AuthMode.signUp,
        status: AuthStatus.initial,
        errorCode: () => null,
      ),
    );
  }

  /// Clears the active error code and resets status to initial.
  void clearError() {
    if (state.errorCode != null || state.status == AuthStatus.failure) {
      emit(state.copyWith(status: AuthStatus.initial, errorCode: () => null));
    }
  }

  /// Submits user credentials for either sign-in or account registration.
  Future<void> submitCredentials({
    required String email,
    required String password,
    String? displayName,
  }) async {
    emit(state.copyWith(status: AuthStatus.submitting, errorCode: () => null));

    try {
      if (state.isSignUp) {
        await authRepository.signUp(
          email: email.trim(),
          password: password,
          displayName: displayName?.trim(),
        );
      } else {
        await authRepository.logInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      }
      emit(state.copyWith(status: AuthStatus.success, errorCode: () => null));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorCode: () => _mapFailureToErrorCode(failure),
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorCode: () => AuthErrorCode.unknown,
        ),
      );
    }
  }

  /// Authenticates using the interactive Google Sign-In flow.
  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.submitting, errorCode: () => null));

    try {
      await authRepository.logInWithGoogle();
      emit(state.copyWith(status: AuthStatus.success, errorCode: () => null));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorCode: () => _mapFailureToErrorCode(failure),
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorCode: () => AuthErrorCode.unknown,
        ),
      );
    }
  }

  /// Authenticates using the canonical QA test account credentials.
  Future<void> signInWithTestAccount() async {
    emit(state.copyWith(status: AuthStatus.submitting, errorCode: () => null));

    try {
      await authRepository.logInWithTestAccount();
      emit(state.copyWith(status: AuthStatus.success, errorCode: () => null));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorCode: () => _mapFailureToErrorCode(failure),
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorCode: () => AuthErrorCode.unknown,
        ),
      );
    }
  }

  AuthErrorCode _mapFailureToErrorCode(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return AuthErrorCode.invalidCredentials;
    } else if (failure is EmailAlreadyInUseFailure) {
      return AuthErrorCode.emailAlreadyInUse;
    } else if (failure is WeakPasswordFailure) {
      return AuthErrorCode.weakPassword;
    } else if (failure is GoogleSignInCancelledFailure) {
      return AuthErrorCode.googleCancelled;
    } else if (failure is NetworkFailure) {
      return AuthErrorCode.network;
    }
    return AuthErrorCode.unknown;
  }
}
