/// Exception hierarchy for the manga repository package.
library;

/// Base exception for all errors thrown by the manga repository.
abstract class MangaRepositoryException implements Exception {
  /// Creates a [MangaRepositoryException].
  const new(this.message, {this.cause, this.statusCode});

  /// Descriptive error message.
  final String message;

  /// Underlying cause if available.
  final Object? cause;

  /// HTTP status code if applicable.
  final int? statusCode;

  @override
  String toString() => '$runtimeType: $message (status: $statusCode)';
}

/// Thrown when a requested manga or aggregate is not found (HTTP 404).
class MangaNotFoundException extends MangaRepositoryException {
  /// Creates a [MangaNotFoundException].
  const new(super.message, {super.cause, super.statusCode = 404});
}

/// Thrown when MangaDex rate limits are exceeded (HTTP 429).
class MangaRateLimitException extends MangaRepositoryException {
  /// Creates a [MangaRateLimitException].
  const new(
    super.message, {
    super.cause,
    super.statusCode = 429,
    this.retryAfterHeader,
  });

  /// Raw `x-ratelimit-retry-after` header value if provided by MangaDex.
  final String? retryAfterHeader;
}

/// Thrown when network connectivity fails and no cached fallback is available.
class MangaNetworkException extends MangaRepositoryException {
  /// Creates a [MangaNetworkException].
  const new(super.message, {super.cause, super.statusCode});
}

/// Thrown when MangaDex returns a 5xx server error.
class MangaServerException extends MangaRepositoryException {
  /// Creates a [MangaServerException].
  const new(super.message, {super.cause, super.statusCode});
}

/// Thrown when MangaDex rejects input with validation errors (HTTP 400).
class MangaValidationException extends MangaRepositoryException {
  /// Creates a [MangaValidationException].
  const new(super.message, {super.cause, super.statusCode = 400});
}

/// Thrown when parsing response or cache JSON fails.
class MangaParseException extends MangaRepositoryException {
  /// Creates a [MangaParseException].
  const new(super.message, {super.cause, super.statusCode});
}

/// Thrown when an unclassified error occurs in the manga repository.
class MangaUnknownException extends MangaRepositoryException {
  /// Creates a [MangaUnknownException].
  const new(super.message, {super.cause, super.statusCode});
}
