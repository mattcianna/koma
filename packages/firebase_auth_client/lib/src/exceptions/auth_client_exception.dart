import 'package:equatable/equatable.dart';

/// {@template auth_client_exception}
/// Base class for all authentication client exceptions.
/// {@endtemplate}
abstract class AuthClientException extends Equatable implements Exception {
  /// {@macro auth_client_exception}
  const new([this.error, this.stackTrace]);

  /// The underlying error or message, if any.
  final Object? error;

  /// The stack trace associated with this exception, if any.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error];

  @override
  String toString() {
    if (error == null) return runtimeType.toString();
    return '$runtimeType: $error';
  }
}

/// {@template invalid_credentials_auth_failure}
/// Thrown when authentication credentials are invalid or expired.
/// {@endtemplate}
class InvalidCredentialsAuthFailure extends AuthClientException {
  /// {@macro invalid_credentials_auth_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template email_already_in_use_auth_failure}
/// Thrown when signing up with an email address that is already registered.
/// {@endtemplate}
class EmailAlreadyInUseAuthFailure extends AuthClientException {
  /// {@macro email_already_in_use_auth_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template weak_password_auth_failure}
/// Thrown when signing up with a password that does not satisfy security
/// requirements.
/// {@endtemplate}
class WeakPasswordAuthFailure extends AuthClientException {
  /// {@macro weak_password_auth_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template google_sign_in_cancelled_auth_failure}
/// Thrown when the Google Sign-In interaction is cancelled by the user.
/// {@endtemplate}
class GoogleSignInCancelledAuthFailure extends AuthClientException {
  /// {@macro google_sign_in_cancelled_auth_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template google_sign_in_auth_failure}
/// Thrown when an error occurs during the Google Sign-In workflow.
/// {@endtemplate}
class GoogleSignInAuthFailure extends AuthClientException {
  /// {@macro google_sign_in_auth_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template network_auth_failure}
/// Thrown when a network-related failure prevents authentication from
/// completing.
/// {@endtemplate}
class NetworkAuthFailure extends AuthClientException {
  /// {@macro network_auth_failure}
  const new([super.error, super.stackTrace]);
}

/// {@template unknown_auth_failure}
/// Thrown when an unknown or unexpected authentication failure occurs.
/// {@endtemplate}
class UnknownAuthFailure extends AuthClientException {
  /// {@macro unknown_auth_failure}
  const new([super.error, super.stackTrace]);
}
