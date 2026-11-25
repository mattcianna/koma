import 'package:manga_repository/manga_repository.dart';
import 'package:test/test.dart';

void main() {
  group('MangaRepositoryException hierarchy', () {
    test('MangaNotFoundException has 404 status code and correct toString', () {
      const ex = MangaNotFoundException('Manga not found');

      expect(ex.message, equals('Manga not found'));
      expect(ex.statusCode, equals(404));
      expect(
        ex.toString(),
        contains('MangaNotFoundException: Manga not found'),
      );
    });

    test(
      'MangaRateLimitException holds retryAfterHeader and 429 status code',
      () {
        const ex = MangaRateLimitException(
          'Rate limit exceeded',
          retryAfterHeader: '1.5',
        );

        expect(ex.message, equals('Rate limit exceeded'));
        expect(ex.statusCode, equals(429));
        expect(ex.retryAfterHeader, equals('1.5'));
      },
    );

    test('MangaNetworkException retains message and cause', () {
      final cause = Exception('Socket closed');
      final ex = MangaNetworkException('Network error', cause: cause);

      expect(ex.message, equals('Network error'));
      expect(ex.cause, equals(cause));
      expect(ex.statusCode, isNull);
    });

    test('MangaServerException retains 500 status code', () {
      const ex = MangaServerException('Internal server error', statusCode: 500);

      expect(ex.statusCode, equals(500));
    });

    test('MangaValidationException defaults to status 400', () {
      const ex = MangaValidationException('Bad request');

      expect(ex.statusCode, equals(400));
    });

    test('MangaParseException retains message', () {
      const ex = MangaParseException('Failed to parse json');

      expect(ex.message, equals('Failed to parse json'));
    });

    test('MangaUnknownException holds generic message and cause', () {
      final cause = StateError('unexpected state');
      final ex = MangaUnknownException('Unexpected', cause: cause);

      expect(ex.message, equals('Unexpected'));
      expect(ex.cause, equals(cause));
    });
  });
}
