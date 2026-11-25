import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaDexCoverUrlResolver', () {
    const mangaId = 'a1c7c817-4e59-43b7-9365-09675a149a6f';
    const jpgFileName = 'da0341d8-5526-452c-8bd3-dc8e3cd89f99.jpg';
    const pngFileName = '2f4aca53-64c7-46ac-ae85-3bc9b3169890.png';

    test('generates canonical 256px thumbnail URLs', () {
      expect(
        MangaDexCoverUrlResolver.thumbnail256(
          mangaId: mangaId,
          fileName: jpgFileName,
        ),
        equals(
          'https://uploads.mangadex.org/covers/$mangaId/$jpgFileName.256.jpg',
        ),
      );

      // Appends .256.jpg to PNG file names without stripping original extension
      expect(
        MangaDexCoverUrlResolver.thumbnail256(
          mangaId: mangaId,
          fileName: pngFileName,
        ),
        equals(
          'https://uploads.mangadex.org/covers/$mangaId/$pngFileName.256.jpg',
        ),
      );
    });

    test('generates canonical 512px medium image URLs', () {
      expect(
        MangaDexCoverUrlResolver.medium512(
          mangaId: mangaId,
          fileName: jpgFileName,
        ),
        equals(
          'https://uploads.mangadex.org/covers/$mangaId/$jpgFileName.512.jpg',
        ),
      );

      expect(
        MangaDexCoverUrlResolver.medium512(
          mangaId: mangaId,
          fileName: pngFileName,
        ),
        equals(
          'https://uploads.mangadex.org/covers/$mangaId/$pngFileName.512.jpg',
        ),
      );
    });

    test('generates canonical original uncompressed URLs', () {
      expect(
        MangaDexCoverUrlResolver.original(
          mangaId: mangaId,
          fileName: jpgFileName,
        ),
        equals('https://uploads.mangadex.org/covers/$mangaId/$jpgFileName'),
      );

      expect(
        MangaDexCoverUrlResolver.original(
          mangaId: mangaId,
          fileName: pngFileName,
        ),
        equals('https://uploads.mangadex.org/covers/$mangaId/$pngFileName'),
      );
    });
  });
}
