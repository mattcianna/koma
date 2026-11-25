import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Function signature for delaying execution by a given [Duration].
typedef DelayFunction = Future<void> Function(Duration duration);

/// Function signature for providing the current [DateTime].
typedef ClockFunction = DateTime Function();

/// Leaky/Token-bucket Dio interceptor that throttles outgoing MangaDex
/// requests to a safe 4 requests per second (250ms spacing) and transparently
/// handles HTTP 429 responses using bounded retries and
/// `X-RateLimit-Retry-After` parsing.
class MangaDexRateLimitInterceptor extends QueuedInterceptor {
  /// Creates a [MangaDexRateLimitInterceptor].
  ///
  /// [requestsPerSecond] specifies the sustained token refill rate (default 4).
  /// [maxBurst] specifies the maximum token capacity (default 4).
  /// [maxRetries] specifies the maximum 429 retry attempts (default 3).
  /// [_retryClient] provides an optional [Dio] instance for executing retries.
  /// [delayFn] provides an injectable delay function (for testing).
  /// [nowFn] provides an injectable clock function (for testing).
  /// [random] provides an injectable random number generator (for testing).
  new({
    this.requestsPerSecond = 4,
    this.maxBurst = 4,
    this.maxRetries = 3,
    this._retryClient,
    DelayFunction? delayFn,
    ClockFunction? nowFn,
    Random? random,
  }) : _tokenInterval = Duration(milliseconds: 1000 ~/ requestsPerSecond),
       _delayFn = delayFn ?? Future<void>.delayed,
       _nowFn = nowFn ?? DateTime.now,
       _random = random ?? Random() {
    _availableTokens = maxBurst.toDouble();
    _lastRefill = _nowFn();
  }

  /// Sustained request rate per second.
  final int requestsPerSecond;

  /// Maximum burst capacity in tokens.
  final int maxBurst;

  /// Maximum retry attempts for HTTP 429 Too Many Requests responses.
  final int maxRetries;

  final Duration _tokenInterval;
  final Dio? _retryClient;
  final DelayFunction _delayFn;
  final ClockFunction _nowFn;
  final Random _random;

  double _availableTokens = 4;
  late DateTime _lastRefill;

  /// Refills tokens based on elapsed wall-clock time since last refill.
  void _refillTokens() {
    final now = _nowFn();
    final elapsedMs = now.difference(_lastRefill).inMilliseconds;
    if (elapsedMs <= 0) return;

    final tokensToAdd = elapsedMs / _tokenInterval.inMilliseconds;
    if (tokensToAdd > 0) {
      _availableTokens = min(
        maxBurst.toDouble(),
        _availableTokens + tokensToAdd,
      );
      _lastRefill = now;
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    while (true) {
      _refillTokens();
      if (_availableTokens >= 1.0) {
        _availableTokens -= 1.0;
        return handler.next(options);
      }

      // Wait 250ms for next token interval before re-checking available tokens.
      await _delayFn(_tokenInterval);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 429) {
      final currentRetries =
          (err.requestOptions.extra['_retryCount'] as int?) ?? 0;
      if (currentRetries >= maxRetries) {
        return handler.next(err);
      }

      final retryAfterHeader = err.response?.headers.value(
        'x-ratelimit-retry-after',
      );

      var waitMs = 2000;

      if (retryAfterHeader != null) {
        final parsed = int.tryParse(retryAfterHeader.trim());
        if (parsed != null) {
          final nowMs = _nowFn().millisecondsSinceEpoch;
          if (parsed < 100000) {
            // Relative delta in seconds.
            waitMs = parsed * 1000;
          } else if (parsed < 100000000000) {
            // 10-digit Unix timestamp in seconds (e.g. 1794593250).
            waitMs = (parsed * 1000) - nowMs;
          } else {
            // 13-digit Unix timestamp in milliseconds.
            waitMs = parsed - nowMs;
          }
        }
      }

      if (waitMs < 0) {
        waitMs = 0;
      }

      // Add full jitter (0–499ms) to prevent thundering herd.
      final jitter = _random.nextInt(500);
      final totalWait = max(1000, waitMs + jitter);

      await _delayFn(Duration(milliseconds: totalWait));

      try {
        final options = err.requestOptions;
        options.extra['_retryCount'] = currentRetries + 1;
        final client = _retryClient ?? Dio();
        final response = await client.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      } on Object catch (retryErr) {
        return handler.next(
          DioException(requestOptions: err.requestOptions, error: retryErr),
        );
      }
    }

    return handler.next(err);
  }
}
