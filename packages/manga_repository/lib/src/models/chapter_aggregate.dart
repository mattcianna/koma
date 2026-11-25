import 'package:equatable/equatable.dart';
import 'package:manga_repository/src/models/manga_chapter.dart';
import 'package:manga_repository/src/models/manga_volume.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';

/// Domain representation of a manga's volume and chapter aggregation tree.
class ChapterAggregate extends Equatable {
  /// Creates a [ChapterAggregate].
  const new({
    required this.mangaId,
    this.volumes = const [],
    this.orderedChapters = const [],
  });

  /// Factory constructor to map an [AggregateResponse] from MangaDex,
  /// sorting volumes naturally with `"none"` last, and producing a
  /// deterministic flat list of [orderedChapters] ordered by
  /// [ChapterComparator].
  factory fromAggregateResponse(String mangaId, AggregateResponse response) {
    final sortedVolumes =
        response.volumes.values.map(MangaVolume.fromAggregateVolume).toList()
          ..sort(
            (a, b) => ChapterComparator.compare(a.volumeNumber, b.volumeNumber),
          );

    final allChapters =
        <MangaChapter>[for (final vol in sortedVolumes) ...vol.chapters]..sort(
          (a, b) => ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
        );

    final seenNumbers = <String>{};
    final ordered = <MangaChapter>[];
    for (final chapter in allChapters) {
      if (seenNumbers.add(chapter.chapterNumber)) {
        ordered.add(chapter);
      }
    }

    return ChapterAggregate(
      mangaId: mangaId,
      volumes: List<MangaVolume>.unmodifiable(sortedVolumes),
      orderedChapters: List<MangaChapter>.unmodifiable(ordered),
    );
  }

  /// Deserializes a [ChapterAggregate] from a JSON map.
  factory fromJson(Map<String, dynamic> json, {String mangaId = ''}) {
    final resolvedId = (json['mangaId'] ?? mangaId).toString();

    // If json represents a raw MangaDex AggregateResponse payload
    if (json['volumes'] is Map) {
      final agg = AggregateResponse.fromJson(json);
      return ChapterAggregate.fromAggregateResponse(resolvedId, agg);
    }

    final volumesRaw = json['volumes'];
    final volumes = volumesRaw is List
        ? (volumesRaw
              .whereType<Map<String, dynamic>>()
              .map(MangaVolume.fromJson)
              .toList()
            ..sort(
              (a, b) =>
                  ChapterComparator.compare(a.volumeNumber, b.volumeNumber),
            ))
        : const <MangaVolume>[];

    final orderedRaw = json['orderedChapters'];
    final List<MangaChapter> ordered;
    if (orderedRaw is List) {
      ordered =
          orderedRaw
              .whereType<Map<String, dynamic>>()
              .map(MangaChapter.fromJson)
              .toList()
            ..sort(
              (a, b) =>
                  ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
            );
    } else {
      final seenNumbers = <String>{};
      final all = <MangaChapter>[for (final v in volumes) ...v.chapters]
        ..sort(
          (a, b) => ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
        );
      ordered = [];
      for (final ch in all) {
        if (seenNumbers.add(ch.chapterNumber)) {
          ordered.add(ch);
        }
      }
    }

    return ChapterAggregate(
      mangaId: resolvedId,
      volumes: List<MangaVolume>.unmodifiable(volumes),
      orderedChapters: List<MangaChapter>.unmodifiable(ordered),
    );
  }

  /// Merges missing chapters from an all-language [allLanguageFallback]
  /// aggregate and official publisher [officialChapters] into [primary],
  /// preserving primary volume/chapter precedence and natural ordering.
  factory mergeFallbacks({
    required ChapterAggregate primary,
    ChapterAggregate? allLanguageFallback,
    List<OfficialFeedChapter> officialChapters = const [],
  }) {
    final hasAllLang =
        allLanguageFallback != null &&
        allLanguageFallback.orderedChapters.isNotEmpty;
    if (!hasAllLang && officialChapters.isEmpty) {
      return primary;
    }

    final volumeMap = <String, Map<String, MangaChapter>>{};
    final seenNumbers = <String>{};

    for (final vol in primary.volumes) {
      final map = volumeMap.putIfAbsent(
        vol.volumeNumber,
        () => <String, MangaChapter>{},
      );
      for (final ch in vol.chapters) {
        map[ch.chapterNumber] = ch;
        seenNumbers.add(ch.chapterNumber);
      }
    }

    if (allLanguageFallback != null) {
      for (final vol in allLanguageFallback.volumes) {
        for (final ch in vol.chapters) {
          if (seenNumbers.add(ch.chapterNumber)) {
            volumeMap.putIfAbsent(
              vol.volumeNumber,
              () => <String, MangaChapter>{},
            )[ch.chapterNumber] = ch;
          }
        }
      }
    }

    if (officialChapters.isNotEmpty) {
      final unassigned = volumeMap.putIfAbsent(
        'none',
        () => <String, MangaChapter>{},
      );
      for (final official in officialChapters) {
        if (seenNumbers.add(official.chapterNumber)) {
          unassigned[official.chapterNumber] = MangaChapter(
            chapterNumber: official.chapterNumber,
            id: official.id,
            externalUrl: official.externalUrl,
          );
        }
      }
    }

    final mergedVolumes = <MangaVolume>[];
    for (final entry in volumeMap.entries) {
      if (entry.value.isEmpty) continue;
      final chapters = entry.value.values.toList()
        ..sort(
          (a, b) => ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
        );
      mergedVolumes.add(
        MangaVolume(
          volumeNumber: entry.key,
          count: chapters.length,
          chapters: List<MangaChapter>.unmodifiable(chapters),
        ),
      );
    }
    mergedVolumes.sort(
      (a, b) => ChapterComparator.compare(a.volumeNumber, b.volumeNumber),
    );

    final ordered =
        <MangaChapter>[for (final vol in mergedVolumes) ...vol.chapters]..sort(
          (a, b) => ChapterComparator.compare(a.chapterNumber, b.chapterNumber),
        );

    return ChapterAggregate(
      mangaId: primary.mangaId,
      volumes: List<MangaVolume>.unmodifiable(mergedVolumes),
      orderedChapters: List<MangaChapter>.unmodifiable(ordered),
    );
  }

  /// Unique MangaDex UUID for this manga.
  final String mangaId;

  /// Ordered list of volumes with `"none"` (unnumbered chapters) placed last.
  final List<MangaVolume> volumes;

  /// Chronologically and naturally ordered flat list of all chapters.
  final List<MangaChapter> orderedChapters;

  /// Computes the ordered list of chapter numbers up to and including
  /// [upToChapterNumber] that are not present in [alreadyReadChapters].
  List<String> computePreviousUnreadChapters({
    required String upToChapterNumber,
    required Set<String> alreadyReadChapters,
  }) {
    final result = <String>[];
    final seen = <String>{};

    for (final chapter in orderedChapters) {
      final number = chapter.chapterNumber;
      if (ChapterComparator.compare(number, upToChapterNumber) <= 0) {
        if (!alreadyReadChapters.contains(number) && seen.add(number)) {
          result.add(number);
        }
      }
    }
    return List<String>.unmodifiable(result);
  }

  /// Serializes this [ChapterAggregate] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'mangaId': mangaId,
    'volumes': volumes.map((v) => v.toJson()).toList(),
    'orderedChapters': orderedChapters.map((c) => c.toJson()).toList(),
  };

  @override
  List<Object?> get props => [mangaId, volumes, orderedChapters];
}
