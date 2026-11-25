/// Utility class to generate canonical MangaDex CDN cover image URLs.
///
/// MangaDex hosts covers on
/// `https://uploads.mangadex.org/covers/{mangaId}/{fileName}`.
/// Derived thumbnail variants (`.256.jpg`, `.512.jpg`) append their suffix
/// directly to the full file name, even if the original asset was a PNG.
abstract final class MangaDexCoverUrlResolver {
  static const String _baseUrl = 'https://uploads.mangadex.org/covers';

  /// Generates the 256px wide thumbnail URL for grid cards and search lists.
  static String thumbnail256({
    required String mangaId,
    required String fileName,
  }) => '$_baseUrl/$mangaId/$fileName.256.jpg';

  /// Generates the 512px wide medium image URL for detail screens and sheets.
  static String medium512({
    required String mangaId,
    required String fileName,
  }) => '$_baseUrl/$mangaId/$fileName.512.jpg';

  /// Generates the full original uncompressed asset URL.
  static String original({required String mangaId, required String fileName}) =>
      '$_baseUrl/$mangaId/$fileName';
}
