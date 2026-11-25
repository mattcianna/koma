import 'package:mangadex_api_client/src/models/aggregate_data.dart';

/// Defensive parser for MangaDex aggregate response structures.
///
/// MangaDex's PHP backend serializes empty associative arrays as
/// JSON arrays `[]` instead of JSON objects `{}`. This parser safely converts
/// unexpected lists into empty maps, parses `"none"` keys, extracts
/// `isUnavailable`, and merges primary and secondary (`others`) chapter UUIDs.
abstract final class AggregateResponseParser {
  /// Parses an [AggregateResponse] from a raw JSON map, safely handling PHP
  /// empty array quirks where `volumes` or `chapters` are serialized as `[]`.
  static AggregateResponse parse(Map<String, dynamic> json) {
    final result = json['result']?.toString() ?? 'ok';
    final rawVolumes = json['volumes'];

    final volumes = <String, AggregateVolume>{};
    if (rawVolumes is Map) {
      for (final entry in rawVolumes.entries) {
        final volKey = entry.key.toString();
        final volVal = entry.value;
        if (volVal is Map<String, dynamic>) {
          volumes[volKey] = parseVolume(volKey, volVal);
        } else if (volVal is Map) {
          volumes[volKey] = parseVolume(
            volKey,
            Map<String, dynamic>.from(volVal),
          );
        }
      }
    }

    return AggregateResponse(result: result, volumes: volumes);
  }

  /// Parses a single volume map into an [AggregateVolume].
  static AggregateVolume parseVolume(
    String fallbackKey,
    Map<String, dynamic> json,
  ) {
    final volumeStr = (json['volume'] ?? fallbackKey).toString();
    final count = (json['count'] as num?)?.toInt() ?? 0;
    final rawChapters = json['chapters'];

    final chapters = <String, AggregateChapter>{};
    if (rawChapters is Map) {
      for (final entry in rawChapters.entries) {
        final chapKey = entry.key.toString();
        final chapVal = entry.value;
        if (chapVal is Map<String, dynamic>) {
          chapters[chapKey] = parseChapter(chapKey, chapVal);
        } else if (chapVal is Map) {
          chapters[chapKey] = parseChapter(
            chapKey,
            Map<String, dynamic>.from(chapVal),
          );
        }
      }
    }

    return AggregateVolume(volume: volumeStr, count: count, chapters: chapters);
  }

  /// Parses a single chapter map into an [AggregateChapter].
  static AggregateChapter parseChapter(
    String fallbackKey,
    Map<String, dynamic> json,
  ) {
    final chapterStr = (json['chapter'] ?? fallbackKey).toString();
    final id = json['id']?.toString() ?? '';
    final count = (json['count'] as num?)?.toInt() ?? 1;
    final isUnavailable = json['isUnavailable'] == true;

    final others = <String>[];
    final rawOthers = json['others'];
    if (rawOthers is List) {
      for (final item in rawOthers) {
        if (item != null) {
          final s = item.toString().trim();
          if (s.isNotEmpty) others.add(s);
        }
      }
    }

    return AggregateChapter(
      chapter: chapterStr,
      id: id,
      others: others,
      count: count,
      isUnavailable: isUnavailable,
    );
  }

  /// Merges primary [id] with [others] list into a deduplicated list of UUIDs.
  static List<String> mergeChapterIds(String id, List<String> others) {
    final set = <String>{};
    final trimmedId = id.trim();
    if (trimmedId.isNotEmpty) {
      set.add(trimmedId);
    }
    for (final other in others) {
      final s = other.trim();
      if (s.isNotEmpty) {
        set.add(s);
      }
    }
    return set.toList();
  }
}
