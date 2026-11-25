import 'package:dio/dio.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler;

void main() {
  group('KomaUserAgentInterceptor', () {
    late KomaUserAgentInterceptor interceptor;
    late _MockRequestInterceptorHandler handler;

    setUp(() {
      interceptor = const KomaUserAgentInterceptor();
      handler = _MockRequestInterceptorHandler();
    });

    test('injects canonical User-Agent header', () {
      final options = RequestOptions(path: '/manga');

      interceptor.onRequest(options, handler);

      expect(
        options.headers['User-Agent'],
        equals('Koma/0.1.0 (https://github.com/mattcianna/koma)'),
      );
      verify(() => handler.next(options)).called(1);
    });

    test('strips Referer and referer headers to avoid hotlink cat image', () {
      final options = RequestOptions(
        path: '/covers/123/cover.jpg',
        headers: {
          'Referer': 'https://koma.app/',
          'referer': 'https://koma.app/details',
          'Authorization': 'Bearer token',
        },
      );

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Referer'), isFalse);
      expect(options.headers.containsKey('referer'), isFalse);
      expect(options.headers['Authorization'], equals('Bearer token'));
      expect(
        options.headers['User-Agent'],
        equals(KomaUserAgentInterceptor.komaUserAgent),
      );
      verify(() => handler.next(options)).called(1);
    });
  });
}
