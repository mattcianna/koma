import 'package:dio/dio.dart';

/// Interceptor that attaches the mandatory Koma `User-Agent` header on every
/// request to MangaDex REST API and image CDN endpoints, and ensures that no
/// third-party `Referer` header is transmitted.
///
/// MangaDex Acceptable Use Policy mandates a descriptive custom `User-Agent`.
/// Transmitting a non-canonical `Referer` header triggers MangaDex's CDN to
/// return an anti-hotlinking placeholder JPEG instead of the requested cover.
class KomaUserAgentInterceptor extends Interceptor {
  /// Creates a [KomaUserAgentInterceptor].
  const new();

  /// Canonical `User-Agent` identification string for Koma.
  static const String komaUserAgent =
      'Koma/0.1.0 (https://github.com/mattcianna/koma)';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['User-Agent'] = komaUserAgent;
    // Strip Referer headers to avoid MangaDex anti-hotlink
    // placeholder cat images.
    options.headers.remove('Referer');
    options.headers.remove('referer');
    handler.next(options);
  }
}
