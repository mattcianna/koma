import 'package:equatable/equatable.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';

/// Domain representation of a manga chapter node within a volume.
class MangaChapter extends Equatable {
  /// Creates a [MangaChapter].
  const new({
    required this.chapterNumber,
    required this.id,
    this.otherIds = const [],
    this.count = 1,
    this.isUnavailable = false,
    this.externalUrl,
  });

  /// Factory constructor to map an [AggregateChapter] from the MangaDex API.
  factory fromAggregateChapter(AggregateChapter chapter) {
    return MangaChapter(
      chapterNumber: chapter.chapter,
      id: chapter.id,
      otherIds: List<String>.unmodifiable(chapter.others),
      count: chapter.count,
      isUnavailable: chapter.isUnavailable,
    );
  }

  /// Deserializes a [MangaChapter] from a JSON map.
  factory fromJson(Map<String, dynamic> json) {
    final number = (json['chapterNumber'] ?? json['chapter'] ?? 'none')
        .toString();
    final id = (json['id'] ?? '').toString();
    final othersRaw = json['otherIds'] ?? json['others'];
    final others = othersRaw is List
        ? othersRaw.map((e) => e.toString()).toList()
        : const <String>[];
    final count = json['count'] is int ? json['count'] as int : 1;
    final isUnavailable = json['isUnavailable'] == true;
    final externalUrl = json['externalUrl'] as String?;

    return MangaChapter(
      chapterNumber: number,
      id: id,
      otherIds: List<String>.unmodifiable(others),
      count: count,
      isUnavailable: isUnavailable,
      externalUrl: externalUrl,
    );
  }

  /// Chapter identifier or number (e.g. `"1"`, `"10.5"`, `"none"`).
  final String chapterNumber;

  /// Primary MangaDex chapter UUID.
  final String id;

  /// Alternative/other scanlation group chapter UUIDs for this chapter number.
  final List<String> otherIds;

  /// Total number of releases available for this chapter number.
  final int count;

  /// Whether this chapter is marked unavailable on MangaDex.
  final bool isUnavailable;

  /// External publisher URL when discovered via official RSS/Atom feeds.
  final String? externalUrl;

  /// Returns all unique chapter UUIDs ([id] merged with [otherIds]).
  List<String> get allIds {
    final ids = <String>[];
    if (id.isNotEmpty) ids.add(id);
    for (final other in otherIds) {
      if (!ids.contains(other)) ids.add(other);
    }
    return List<String>.unmodifiable(ids);
  }

  /// Serializes this [MangaChapter] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'chapterNumber': chapterNumber,
    'id': id,
    'otherIds': otherIds,
    'count': count,
    'isUnavailable': isUnavailable,
    'externalUrl': externalUrl,
  };

  @override
  List<Object?> get props => [
    chapterNumber,
    id,
    otherIds,
    count,
    isUnavailable,
    externalUrl,
  ];
}
