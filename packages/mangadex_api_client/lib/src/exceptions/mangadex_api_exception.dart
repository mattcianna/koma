import 'package:dio/dio.dart';

/// Single error entry returned by MangaDex v5 error payloads.
class MangaDexApiError {
  /// Creates a [MangaDexApiError].
  const new({
    required this.id,
    required this.status,
    required this.title,
    this.detail,
    this.context,
  });

  /// Safely parses a [MangaDexApiError] from a dynamic map.
  factory fromJson(Map<String, dynamic> json) {
    final statusVal = json['status'];
    final parsedStatus = statusVal is int
        ? statusVal
        : int.tryParse(statusVal?.toString() ?? '') ?? 0;

    return MangaDexApiError(
      id: json['id']?.toString() ?? '',
      status: parsedStatus,
      title: json['title']?.toString() ?? 'unknown_error',
      detail: json['detail']?.toString(),
      context: json['context'],
    );
  }

  /// Unique identifier of the error occurrence.
  final String id;

  /// HTTP status code as integer.
  final int status;

  /// Short machine-readable error title (e.g. `'validation_exception'`).
  final String title;

  /// Descriptive human-readable error detail.
  final String? detail;

  /// Contextual details if provided by the MangaDex API.
  final Object? context;

  @override
  String toString() =>
      'MangaDexApiError(status: $status, title: $title, detail: $detail)';
}

/// Base exception for all MangaDex API and network errors.
abstract class MangaDexApiException implements Exception {
  /// Creates a [MangaDexApiException].
  const new(
    this.message, {
    this.statusCode,
    this.cause,
    this.errors = const [],
  });

  /// Creates a specialized [MangaDexApiException] subclass from a
  /// [DioException].
  factory fromDioException(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;

    // Parse structured MangaDex errors if payload is a Map with 'errors'
    final errors = <MangaDexApiError>[];
    final data = response?.data;
    if (data is Map<String, dynamic> && data['errors'] is List) {
      for (final raw in data['errors'] as List) {
        if (raw is Map<String, dynamic>) {
          errors.add(MangaDexApiError.fromJson(raw));
        } else if (raw is Map) {
          final casted = Map<String, dynamic>.from(raw);
          errors.add(MangaDexApiError.fromJson(casted));
        }
      }
    }

    final defaultDetail = errors.isNotEmpty ? errors.first.detail : null;
    final defaultTitle = errors.isNotEmpty ? errors.first.title : null;
    final message =
        defaultDetail ??
        defaultTitle ??
        exception.message ??
        'MangaDex API request failed';

    if (statusCode == 429) {
      final retryAfterHeader = response?.headers.value(
        'x-ratelimit-retry-after',
      );
      return MangaDexRateLimitException(
        message,
        statusCode: statusCode,
        cause: exception,
        errors: errors,
        retryAfterHeader: retryAfterHeader,
      );
    }

    if (statusCode == 404) {
      return MangaDexNotFoundException(
        message,
        statusCode: statusCode,
        cause: exception,
        errors: errors,
      );
    }

    if (statusCode == 400) {
      return MangaDexValidationException(
        message,
        statusCode: statusCode,
        cause: exception,
        errors: errors,
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return MangaDexUnauthorizedException(
        message,
        statusCode: statusCode,
        cause: exception,
        errors: errors,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return MangaDexServerException(
        message,
        statusCode: statusCode,
        cause: exception,
        errors: errors,
      );
    }

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      return MangaDexNetworkException(
        message,
        statusCode: statusCode,
        cause: exception,
        errors: errors,
      );
    }

    return MangaDexUnknownException(
      message,
      statusCode: statusCode,
      cause: exception,
      errors: errors,
    );
  }

  /// Descriptive error message.
  final String message;

  /// HTTP status code if the error originated from an HTTP response.
  final int? statusCode;

  /// Underlying error or cause if available.
  final Object? cause;

  /// List of structured [MangaDexApiError] entries returned by the API.
  final List<MangaDexApiError> errors;

  @override
  String toString() =>
      '$runtimeType: $message (status: $statusCode, errors: ${errors.length})';
}

/// Thrown when MangaDex returns HTTP 429 Too Many Requests.
class MangaDexRateLimitException extends MangaDexApiException {
  /// Creates a [MangaDexRateLimitException].
  const new(
    super.message, {
    super.statusCode = 429,
    super.cause,
    super.errors,
    this.retryAfterHeader,
  });

  /// Raw `X-RateLimit-Retry-After` header value from the response.
  final String? retryAfterHeader;
}

/// Thrown when MangaDex returns HTTP 404 Not Found.
class MangaDexNotFoundException extends MangaDexApiException {
  /// Creates a [MangaDexNotFoundException].
  const new(super.message, {super.statusCode = 404, super.cause, super.errors});
}

/// Thrown when MangaDex returns HTTP 400 Bad Request
/// (e.g. parameter validation error).
class MangaDexValidationException extends MangaDexApiException {
  /// Creates a [MangaDexValidationException].
  const new(super.message, {super.statusCode = 400, super.cause, super.errors});
}

/// Thrown when MangaDex returns HTTP 401 Unauthorized or HTTP 403 Forbidden.
class MangaDexUnauthorizedException extends MangaDexApiException {
  /// Creates a [MangaDexUnauthorizedException].
  const new(super.message, {super.statusCode, super.cause, super.errors});
}

/// Thrown when MangaDex returns HTTP 5xx Server Error.
class MangaDexServerException extends MangaDexApiException {
  /// Creates a [MangaDexServerException].
  const new(super.message, {super.statusCode, super.cause, super.errors});
}

/// Thrown when a network connectivity or timeout error occurs.
class MangaDexNetworkException extends MangaDexApiException {
  /// Creates a [MangaDexNetworkException].
  const new(super.message, {super.statusCode, super.cause, super.errors});
}

/// Thrown when parsing a MangaDex response payload fails.
class MangaDexParseException extends MangaDexApiException {
  /// Creates a [MangaDexParseException].
  const new(super.message, {super.statusCode, super.cause, super.errors});
}

/// Thrown when an unclassified error occurs during MangaDex API interaction.
class MangaDexUnknownException extends MangaDexApiException {
  /// Creates a [MangaDexUnknownException].
  const new(super.message, {super.statusCode, super.cause, super.errors});
}
