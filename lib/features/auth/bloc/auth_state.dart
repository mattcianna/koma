import 'package:equatable/equatable.dart';

/// Authentication display mode toggle.
enum AuthMode {
  /// Sign-in mode for returning users.
  signIn,

  /// Registration mode for new users.
  signUp,
}

/// Status of the active authentication submission.
enum AuthStatus {
  /// Initial idle state.
  initial,

  /// An authentication request is actively in-flight.
  submitting,

  /// Authentication completed successfully.
  success,

  /// Authentication failed with an error.
  failure,
}

/// Typed error codes mapped from domain authentication failures.
enum AuthErrorCode {
  /// The provided email and password combination is invalid.
  invalidCredentials,

  /// An account with this email address already exists.
  emailAlreadyInUse,

  /// The provided password does not meet minimum security requirements.
  weakPassword,

  /// The interactive Google Sign-In flow was dismissed by the user.
  googleCancelled,

  /// A network failure prevented authentication from completing.
  network,

  /// An unclassified or unknown authentication error occurred.
  unknown,
}

/// {@template auth_state}
/// Represents the presentation state of the authentication screen.
/// {@endtemplate}
class AuthState extends Equatable {
  /// {@macro auth_state}
  const new({
    this.mode = AuthMode.signIn,
    this.status = AuthStatus.initial,
    this.errorCode,
  });

  /// The active form mode (sign-in or sign-up).
  final AuthMode mode;

  /// The submission status of the current authentication action.
  final AuthStatus status;

  /// Typed error code if [status] is [AuthStatus.failure].
  final AuthErrorCode? errorCode;

  /// Whether an authentication request is actively processing.
  bool get isSubmitting => status == AuthStatus.submitting;

  /// Whether authentication succeeded.
  bool get isSuccess => status == AuthStatus.success;

  /// Whether authentication failed.
  bool get isFailure => status == AuthStatus.failure;

  /// Whether the user is currently on the sign-up form.
  bool get isSignUp => mode == AuthMode.signUp;

  /// Creates a copy of this state with optional updated fields.
  AuthState copyWith({
    AuthMode? mode,
    AuthStatus? status,
    AuthErrorCode? Function()? errorCode,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      errorCode: errorCode != null ? errorCode() : this.errorCode,
    );
  }

  @override
  List<Object?> get props => [mode, status, errorCode];
}
