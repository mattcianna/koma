import 'package:mangadex_api_client/src/models/relationship_data.dart';

/// Resolves localized strings from MangaDex `title`, `altTitles`, and
/// `description` maps, handling the empirical quirk where flagship series
/// omit `'en'` and `'it'` from `attributes.title` and store them inside
/// `attributes.altTitles`.
abstract final class MangaDexLocaleResolver {
  /// Safely converts a JSON field that may be `[]` (PHP empty array) into
  /// a Map.
  static Map<String, dynamic> sanitizeMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  /// Resolves the best display title given user preferred languages
  /// (e.g. `['it', 'en']`).
  static String resolveTitle({
    required Object? rawTitle,
    required Object? rawAltTitles,
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    final titleMap = sanitizeMap(rawTitle);
    final altList = rawAltTitles is List ? rawAltTitles : const <Object?>[];

    // 1. Check primary title map for preferred locales in priority order
    for (final locale in preferredLocales) {
      final candidate = titleMap[locale];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    // 2. Search altTitles list of single-key maps for preferred locales
    for (final locale in preferredLocales) {
      for (final item in altList) {
        final map = sanitizeMap(item);
        final candidate = map[locale];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    // 3. Fallback to English in primary title or altTitles
    final enTitle = titleMap['en'];
    if (enTitle is String && enTitle.trim().isNotEmpty) {
      return enTitle.trim();
    }
    for (final item in altList) {
      final map = sanitizeMap(item);
      final candidate = map['en'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    // 4. Fallback to romanized Japanese/Korean/Chinese or first available key
    for (final fallbackKey in const ['ja-ro', 'ko-ro', 'zh-ro', 'ja', 'ko']) {
      final candidate = titleMap[fallbackKey];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    for (final value in titleMap.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Unknown Title';
  }

  /// Resolves localized description with fallback to `'en'` or first
  /// available entry.
  static String? resolveDescription({
    required Object? rawDescription,
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    final descMap = sanitizeMap(rawDescription);
    if (descMap.isEmpty) return null;

    for (final locale in [...preferredLocales, 'en']) {
      final value = descMap[locale];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    for (final value in descMap.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Extracts `fileName` from the expanded `cover_art` relationship entry,
  /// safely handling unexpanded relationships where `attributes` is absent
  /// or null.
  static String? extractCoverFileName(Object? rawRelationships) {
    if (rawRelationships is! List) return null;
    for (final rel in rawRelationships) {
      if (rel is RelationshipData) {
        if (rel.type == 'cover_art') {
          final attrs = rel.attributes;
          if (attrs != null && attrs['fileName'] is String) {
            final fileName = attrs['fileName'] as String;
            if (fileName.isNotEmpty) return fileName;
          }
        }
        continue;
      }
      final map = sanitizeMap(rel);
      if (map['type'] == 'cover_art') {
        final attrs = sanitizeMap(map['attributes']);
        final fileName = attrs['fileName'];
        if (fileName is String && fileName.isNotEmpty) {
          return fileName;
        }
      }
    }
    return null;
  }
}
