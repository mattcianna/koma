import 'dart:math';

import 'package:dio/dio.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler;

class _MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler;

class _MockDio extends Mock implements Dio;

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions());
    registerFallbackValue(Response<dynamic>(requestOptions: RequestOptions()));
    registerFallbackValue(DioException(requestOptions: RequestOptions()));
  });

  group('MangaDexRateLimitInterceptor', () {
    late _MockRequestInterceptorHandler requestHandler;
    late _MockErrorInterceptorHandler errorHandler;
    late _MockDio retryClient;
    late List<Duration> recordedDelays;
    late DateTime simulatedNow;

    setUp(() {
      requestHandler = _MockRequestInterceptorHandler();
      errorHandler = _MockErrorInterceptorHandler();
      retryClient = _MockDio();
      recordedDelays = <Duration>[];
      simulatedNow = DateTime.utc(2026, 11, 13, 12);
    });

    test('allows burst of 4 requests without delay', () async {
      final interceptor = MangaDexRateLimitInterceptor(
        nowFn: () => simulatedNow,
        delayFn: (duration) async => recordedDelays.add(duration),
      );

      for (var i = 0; i < 4; i++) {
        final options = RequestOptions(path: '/test/$i');
        await interceptor.onRequest(options, requestHandler);
      }

      expect(recordedDelays, isEmpty);
      verify(() => requestHandler.next(any())).called(4);
    });

    test('delays 5th request when tokens are depleted', () async {
      final interceptor = MangaDexRateLimitInterceptor(
        nowFn: () => simulatedNow,
        delayFn: (duration) async {
          recordedDelays.add(duration);
          // Advance simulated clock by the delay so tokens refill.
          simulatedNow = simulatedNow.add(duration);
        },
      );

      for (var i = 0; i < 4; i++) {
        await interceptor.onRequest(
          RequestOptions(path: '/burst/$i'),
          requestHandler,
        );
      }
      expect(recordedDelays, isEmpty);

      // 5th request must wait for next token interval (250ms).
      await interceptor.onRequest(
        RequestOptions(path: '/delayed'),
        requestHandler,
      );

      expect(recordedDelays, hasLength(1));
      expect(recordedDelays.first, equals(const Duration(milliseconds: 250)));
      verify(() => requestHandler.next(any())).called(5);
    });

    test('passes non-429 error directly to handler.next', () async {
      final interceptor = MangaDexRateLimitInterceptor();
      final err = DioException(
        requestOptions: RequestOptions(path: '/manga/1'),
        response: Response(
          requestOptions: RequestOptions(path: '/manga/1'),
          statusCode: 500,
        ),
      );

      await interceptor.onError(err, errorHandler);

      verify(() => errorHandler.next(err)).called(1);
      verifyNever(() => errorHandler.resolve(any()));
    });

    test(
      'parses relative seconds from X-RateLimit-Retry-After on 429',
      () async {
        final random = Random(42); // deterministic jitter
        final interceptor = MangaDexRateLimitInterceptor(
          retryClient: retryClient,
          nowFn: () => simulatedNow,
          delayFn: (duration) async => recordedDelays.add(duration),
          random: random,
        );

        final requestOptions = RequestOptions(path: '/rate-limited');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 429,
            headers: Headers.fromMap({
              'x-ratelimit-retry-after': ['3'],
            }),
          ),
        );

        final retryResponse = Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'ok'},
        );

        when(() => retryClient.fetch<dynamic>(any()))
            .thenAnswer((_) async => retryResponse);

        await interceptor.onError(err, errorHandler);

        expect(recordedDelays, hasLength(1));
        // waitMs = 3 * 1000 = 3000ms + jitter >= 3000ms
        expect(recordedDelays.first.inMilliseconds, greaterThanOrEqualTo(3000));
        expect(requestOptions.extra['_retryCount'], equals(1));
        verify(() => errorHandler.resolve(retryResponse)).called(1);
      },
    );

    test(
      'parses 10-digit Unix timestamp seconds from X-RateLimit-Retry-After',
      () async {
        final random = Random(0);
        final interceptor = MangaDexRateLimitInterceptor(
          retryClient: retryClient,
          nowFn: () => simulatedNow,
          delayFn: (duration) async => recordedDelays.add(duration),
          random: random,
        );

        final nowSeconds = simulatedNow.millisecondsSinceEpoch ~/ 1000;
        final futureTimestamp = nowSeconds + 4; // 4 seconds in future

        final requestOptions = RequestOptions(path: '/manga');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 429,
            headers: Headers.fromMap({
              'X-RateLimit-Retry-After': ['$futureTimestamp'],
            }),
          ),
        );

        final retryResponse = Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'result': 'ok'},
        );

        when(() => retryClient.fetch<dynamic>(any()))
            .thenAnswer((_) async => retryResponse);

        await interceptor.onError(err, errorHandler);

        expect(recordedDelays, hasLength(1));
        // 4000ms + jitter
        expect(recordedDelays.first.inMilliseconds, greaterThanOrEqualTo(4000));
        verify(() => errorHandler.resolve(retryResponse)).called(1);
      },
    );

    test(
      'parses 13-digit Unix timestamp milliseconds from retry header',
      () async {
        final random = Random(0);
        final interceptor = MangaDexRateLimitInterceptor(
          retryClient: retryClient,
          nowFn: () => simulatedNow,
          delayFn: (duration) async => recordedDelays.add(duration),
          random: random,
        );

        final nowMs = simulatedNow.millisecondsSinceEpoch;
        final futureTimestampMs = nowMs + 5000;

        final requestOptions = RequestOptions(path: '/manga');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 429,
            headers: Headers.fromMap({
              'x-ratelimit-retry-after': ['$futureTimestampMs'],
            }),
          ),
        );

        final retryResponse = Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 200,
        );

        when(() => retryClient.fetch<dynamic>(any()))
            .thenAnswer((_) async => retryResponse);

        await interceptor.onError(err, errorHandler);

        expect(recordedDelays, hasLength(1));
        expect(recordedDelays.first.inMilliseconds, greaterThanOrEqualTo(5000));
        verify(() => errorHandler.resolve(retryResponse)).called(1);
      },
    );

    test('handles unparseable or missing retry header with fallback', () async {
      final random = Random(0);
      final interceptor = MangaDexRateLimitInterceptor(
        retryClient: retryClient,
        nowFn: () => simulatedNow,
        delayFn: (duration) async => recordedDelays.add(duration),
        random: random,
      );

      final requestOptions = RequestOptions(path: '/manga');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 429),
      );

      final retryResponse = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
      );

      when(() => retryClient.fetch<dynamic>(any()))
          .thenAnswer((_) async => retryResponse);

      await interceptor.onError(err, errorHandler);

      expect(recordedDelays, hasLength(1));
      // Default fallback is 2000ms + jitter
      expect(recordedDelays.first.inMilliseconds, greaterThanOrEqualTo(2000));
      verify(() => errorHandler.resolve(retryResponse)).called(1);
    });

    test('stops retrying when maxRetries is reached', () async {
      final interceptor = MangaDexRateLimitInterceptor(
        maxRetries: 2,
        nowFn: () => simulatedNow,
        delayFn: (duration) async => recordedDelays.add(duration),
      );

      final requestOptions = RequestOptions(
        path: '/manga',
        extra: {'_retryCount': 2},
      );
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 429),
      );

      await interceptor.onError(err, errorHandler);

      expect(recordedDelays, isEmpty);
      verify(() => errorHandler.next(err)).called(1);
      verifyNever(() => errorHandler.resolve(any()));
    });

    test('forwards retry DioException on retry failure', () async {
      final interceptor = MangaDexRateLimitInterceptor(
        retryClient: retryClient,
        nowFn: () => simulatedNow,
        delayFn: (duration) async => recordedDelays.add(duration),
      );

      final requestOptions = RequestOptions(path: '/fail');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 429),
      );

      final retryErr = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 503),
      );

      when(() => retryClient.fetch<dynamic>(any())).thenThrow(retryErr);

      await interceptor.onError(err, errorHandler);

      verify(() => errorHandler.next(retryErr)).called(1);
    });

    test('wraps non-DioException during retry in DioException', () async {
      final interceptor = MangaDexRateLimitInterceptor(
        retryClient: retryClient,
        nowFn: () => simulatedNow,
        delayFn: (duration) async => recordedDelays.add(duration),
      );

      final requestOptions = RequestOptions(path: '/error');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 429),
      );

      const formatException = FormatException('Corrupted response');
      when(() => retryClient.fetch<dynamic>(any())).thenThrow(formatException);

      await interceptor.onError(err, errorHandler);

      verify(() => errorHandler.next(any(that: isA<DioException>()))).called(1);
    });
  });
}
