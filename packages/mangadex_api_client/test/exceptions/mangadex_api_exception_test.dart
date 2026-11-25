import 'package:dio/dio.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaDexApiException', () {
    test('maps HTTP 429 to MangaDexRateLimitException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/manga'),
        response: Response(
          requestOptions: RequestOptions(path: '/manga'),
          statusCode: 429,
          headers: Headers.fromMap({
            'x-ratelimit-retry-after': ['5'],
          }),
        ),
      );

      final exception = MangaDexApiException.fromDioException(dioException);

      expect(exception, isA<MangaDexRateLimitException>());
      final rateLimit = exception as MangaDexRateLimitException;
      expect(rateLimit.statusCode, equals(429));
      expect(rateLimit.retryAfterHeader, equals('5'));
      expect(rateLimit.toString(), contains('429'));
    });

    test('maps HTTP 429 with capitalized X-RateLimit-Retry-After header', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/manga'),
        response: Response(
          requestOptions: RequestOptions(path: '/manga'),
          statusCode: 429,
          headers: Headers.fromMap({
            'X-RateLimit-Retry-After': ['10'],
          }),
        ),
      );

      final exception = MangaDexApiException.fromDioException(dioException);

      expect(exception, isA<MangaDexRateLimitException>());
      final rateLimit = exception as MangaDexRateLimitException;
      expect(rateLimit.retryAfterHeader, equals('10'));
    });

    test('maps HTTP 404 to MangaDexNotFoundException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/manga/not-found'),
        response: Response(
          requestOptions: RequestOptions(path: '/manga/not-found'),
          statusCode: 404,
          data: {
            'result': 'error',
            'errors': [
              {
                'id': 'err-1',
                'status': 404,
                'title': 'not_found',
                'detail': 'Manga not found',
              },
            ],
          },
        ),
      );

      final exception = MangaDexApiException.fromDioException(dioException);

      expect(exception, isA<MangaDexNotFoundException>());
      expect(exception.statusCode, equals(404));
      expect(exception.message, equals('Manga not found'));
      expect(exception.errors, hasLength(1));
      expect(exception.errors.first.id, equals('err-1'));
      expect(exception.errors.first.status, equals(404));
      expect(exception.errors.first.title, equals('not_found'));
      expect(exception.errors.first.toString(), contains('not_found'));
    });

    test('maps HTTP 400 to MangaDexValidationException with error details', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        response: Response(
          requestOptions: RequestOptions(path: '/feed'),
          statusCode: 400,
          data: {
            'result': 'error',
            'errors': [
              {
                'id': 'val-1',
                'status': '400',
                'title': 'validation_exception',
                'detail': 'Invalid publishAtSince regex',
                'context': {'param': 'publishAtSince'},
              },
            ],
          },
        ),
      );

      final exception = MangaDexApiException.fromDioException(dioException);

      expect(exception, isA<MangaDexValidationException>());
      expect(exception.statusCode, equals(400));
      expect(exception.message, equals('Invalid publishAtSince regex'));
      expect(exception.errors.first.context, isNotNull);
    });

    test('maps HTTP 401 and 403 to MangaDexUnauthorizedException', () {
      for (final code in [401, 403]) {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/auth-only'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth-only'),
            statusCode: code,
          ),
        );

        final exception = MangaDexApiException.fromDioException(dioException);
        expect(exception, isA<MangaDexUnauthorizedException>());
        expect(exception.statusCode, equals(code));
      }
    });

    test('maps HTTP 5xx to MangaDexServerException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/manga'),
        response: Response(
          requestOptions: RequestOptions(path: '/manga'),
          statusCode: 502,
        ),
      );

      final exception = MangaDexApiException.fromDioException(dioException);
      expect(exception, isA<MangaDexServerException>());
      expect(exception.statusCode, equals(502));
    });

    test('maps connection errors to MangaDexNetworkException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/manga'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
      );

      final exception = MangaDexApiException.fromDioException(dioException);
      expect(exception, isA<MangaDexNetworkException>());
    });

    test('maps unclassified errors to MangaDexUnknownException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/custom'),
        type: DioExceptionType.badCertificate,
      );

      final exception = MangaDexApiException.fromDioException(dioException);
      expect(exception, isA<MangaDexUnknownException>());
    });

    test('instantiates MangaDexParseException directly', () {
      const exception = MangaDexParseException('Malformed JSON');
      expect(exception.message, equals('Malformed JSON'));
    });

    test('handles untyped Map in errors and falls back to error title', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/manga'),
        response: Response(
          requestOptions: RequestOptions(path: '/manga'),
          statusCode: 400,
          data: {
            'result': 'error',
            'errors': <dynamic>[
              <dynamic, dynamic>{
                'id': 'e1',
                'status': 400,
                'title': 'only_title_no_detail',
              },
            ],
          },
        ),
      );

      final exception = MangaDexApiException.fromDioException(dioException);
      expect(exception, isA<MangaDexValidationException>());
      expect(exception.message, equals('only_title_no_detail'));
      expect(exception.errors, hasLength(1));
    });
  });
}
