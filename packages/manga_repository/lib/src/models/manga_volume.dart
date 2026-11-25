import 'package:equatable/equatable.dart';
import 'package:manga_repository/src/models/manga_chapter.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';

/// Domain representation of a manga volume containing naturally ordered
/// chapters.
class MangaVolume extends Equatable {
  /// Creates a [MangaVolume].
  const new({
    required this.volumeNumber,
    this.count = 0,
    this.chapters = const [],
  });

  /// Factory constructor to map an [AggregateVolume] from the MangaDex API,
  /// sorting its chapters naturally using [ChapterComparator].
  factory fromAggregateVolume(AggregateVolume volume) {
    final sortedChapters =
        volume.chapters.values.map(MangaChapter.fromAggregateChapter).toList()
          ..sort(
            (a, b) =>
                ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
          );

    return MangaVolume(
      volumeNumber: volume.volume,
      count: volume.count,
      chapters: List<MangaChapter>.unmodifiable(sortedChapters),
    );
  }

  /// Deserializes a [MangaVolume] from a JSON map, sorting chapters naturally.
  factory fromJson(Map<String, dynamic> json) {
    final volumeNumber = (json['volumeNumber'] ?? json['volume'] ?? 'none')
        .toString();
    final count = json['count'] is int ? json['count'] as int : 0;
    final chaptersRaw = json['chapters'];
    final List<MangaChapter> chapters;

    if (chaptersRaw is List) {
      chapters =
          chaptersRaw
              .whereType<Map<String, dynamic>>()
              .map(MangaChapter.fromJson)
              .toList()
            ..sort(
              (a, b) =>
                  ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
            );
    } else if (chaptersRaw is Map) {
      chapters =
          chaptersRaw.values
              .whereType<Map<String, dynamic>>()
              .map(MangaChapter.fromJson)
              .toList()
            ..sort(
              (a, b) =>
                  ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
            );
    } else {
      chapters = const [];
    }

    return MangaVolume(
      volumeNumber: volumeNumber,
      count: count,
      chapters: List<MangaChapter>.unmodifiable(chapters),
    );
  }

  /// Volume identifier or number (e.g. `"1"`, `"none"`).
  final String volumeNumber;

  /// Total count of chapters within this volume.
  final int count;

  /// List of chapters belonging to this volume, ordered naturally.
  final List<MangaChapter> chapters;

  /// Serializes this [MangaVolume] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'volumeNumber': volumeNumber,
    'count': count,
    'chapters': chapters.map((c) => c.toJson()).toList(),
  };

  @override
  List<Object?> get props => [volumeNumber, count, chapters];
}
