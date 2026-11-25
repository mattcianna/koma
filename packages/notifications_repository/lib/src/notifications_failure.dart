import 'package:equatable/equatable.dart';

/// {@template notifications_failure}
/// Exception thrown when a notifications repository operation fails.
/// {@endtemplate}
class NotificationsFailure with Equatable implements Exception {
  /// {@macro notifications_failure}
  const new([
    this.message = 'An unknown notifications failure occurred.',
    this.cause,
    this.stackTrace,
  ]);

  /// Creates a [NotificationsFailure] with named arguments.
  factory from({
    String message = 'An unknown notifications failure occurred.',
    Object? cause,
    StackTrace? stackTrace,
  }) => NotificationsFailure(message, cause, stackTrace);

  /// The human-readable error message.
  final String message;

  /// The underlying cause of the failure, if available.
  final Object? cause;

  /// The stack trace associated with the failure, if available.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, cause, stackTrace];

  @override
  String toString() => 'NotificationsFailure(message: $message, cause: $cause)';
}
