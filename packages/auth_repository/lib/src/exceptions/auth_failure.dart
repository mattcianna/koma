import 'package:equatable/equatable.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart' as auth_client;

/// {@template auth_failure}
/// Base class for all authentication domain failures.
/// {@endtemplate}
abstract class AuthFailure extends Equatable implements Exception {
  /// {@macro auth_failure}
  const new([this.error, this.stackTrace]);

  /// Maps an [auth_client.AuthClientException] to its corresponding domain
  /// [AuthFailure].
  factory fromAuthClientException(auth_client.AuthClientException exception) {
    switch (exception) {
      case auth_client.InvalidCredentialsAuthFailure():
        return InvalidCredentialsFailure(exception.error, exception.stackTrace);
      case auth_client.EmailAlreadyInUseAuthFailure():
        return EmailAlreadyInUseFailure(exception.error, exception.stackTrace);
      case auth_client.WeakPasswordAuthFailure():
        return WeakPasswordFailure(exception.error, exception.stackTrace);
      case auth_client.GoogleSignInCancelledAuthFailure():
        return GoogleSignInCancelledFailure(
          exception.error,
          exception.stackTrace,
        );
      case auth_client.GoogleSignInAuthFailure():
        return GoogleSignInFailure(exception.error, exception.stackTrace);
      case auth_client.NetworkAuthFailure():
        return NetworkFailure(exception.error, exception.stackTrace);
      case auth_client.UnknownAuthFailure():
        return UnknownAuthFailure(exception.error, exception.stackTrace);
      default:
        return UnknownAuthFailure(exception.error, exception.stackTrace);
    }
  }

  /// The underlying error or message, if any.
  final Object? error;

  /// The stack trace associated with this failure, if any.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error];

  @override
  String toString() {
    if (error == null) return runtimeType.toString();
    return '$runtimeType: $error';
  }
}

/// {@template invalid_credentials_failure}
/// Thrown when authentication credentials are invalid or expired.
/// {@endtemplate}
class InvalidCredentialsFailure extends AuthFailure {
  /// {@macro invalid_credentials_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template email_already_in_use_failure}
/// Thrown when signing up with an email address that is already registered.
/// {@endtemplate}
class EmailAlreadyInUseFailure extends AuthFailure {
  /// {@macro email_already_in_use_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template weak_password_failure}
/// Thrown when signing up with a password that does not satisfy security
/// requirements.
/// {@endtemplate}
class WeakPasswordFailure extends AuthFailure {
  /// {@macro weak_password_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template google_sign_in_cancelled_failure}
/// Thrown when the Google Sign-In interaction is cancelled by the user.
/// {@endtemplate}
class GoogleSignInCancelledFailure extends AuthFailure {
  /// {@macro google_sign_in_cancelled_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template google_sign_in_failure}
/// Thrown when an error occurs during the Google Sign-In workflow.
/// {@endtemplate}
class GoogleSignInFailure extends AuthFailure {
  /// {@macro google_sign_in_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template network_failure}
/// Thrown when a network-related failure prevents authentication from
/// completing.
/// {@endtemplate}
class NetworkFailure extends AuthFailure {
  /// {@macro network_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template unknown_auth_failure}
/// Thrown when an unknown or unexpected authentication failure occurs.
/// {@endtemplate}
class UnknownAuthFailure extends AuthFailure {
  /// {@macro unknown_auth_failure}
  const new([super.error, super.stackTrace]);
}
