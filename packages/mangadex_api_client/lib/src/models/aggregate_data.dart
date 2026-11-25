import 'package:equatable/equatable.dart';
import 'package:mangadex_api_client/src/utils/aggregate_response_parser.dart';

/// Single chapter node in MangaDex's `/aggregate` response tree.
class AggregateChapter extends Equatable {
  /// Creates an [AggregateChapter].
  const new({
    required this.chapter,
    required this.id,
    this.others = const [],
    this.count = 1,
    this.isUnavailable = false,
  });

  /// Creates an [AggregateChapter] from JSON using [AggregateResponseParser].
  factory fromJson(Map<String, dynamic> json) =>
      AggregateResponseParser.parseChapter(
        json['chapter']?.toString() ?? 'none',
        json,
      );

  /// Chapter number or identifier (e.g. `"1"`, `"97.5"`, `"none"`).
  final String chapter;

  /// Primary MangaDex chapter UUID.
  final String id;

  /// Alternative/other scanlation group chapter UUIDs for the same chapter.
  final List<String> others;

  /// Number of releases associated with this chapter number.
  final int count;

  /// Whether this chapter is marked unavailable on MangaDex.
  final bool isUnavailable;

  /// Returns all unique chapter UUIDs ([id] merged with [others]).
  List<String> get allChapterIds =>
      AggregateResponseParser.mergeChapterIds(id, others);

  /// Converts this [AggregateChapter] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'chapter': chapter,
    'id': id,
    'others': others,
    'count': count,
    'isUnavailable': isUnavailable,
  };

  @override
  List<Object?> get props => [chapter, id, others, count, isUnavailable];
}

/// Single volume node in MangaDex's `/aggregate` response tree.
class AggregateVolume extends Equatable {
  /// Creates an [AggregateVolume].
  const new({required this.volume, this.count = 0, this.chapters = const {}});

  /// Creates an [AggregateVolume] from JSON using [AggregateResponseParser].
  factory fromJson(Map<String, dynamic> json) =>
      AggregateResponseParser.parseVolume(
        json['volume']?.toString() ?? 'none',
        json,
      );

  /// Volume number or identifier (e.g. `"1"`, `"none"`).
  final String volume;

  /// Total count of chapters within this volume.
  final int count;

  /// Map of chapters belonging to this volume, keyed by chapter number.
  final Map<String, AggregateChapter> chapters;

  /// Converts this [AggregateVolume] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'volume': volume,
    'count': count,
    'chapters': chapters.map((k, v) => MapEntry(k, v.toJson())),
  };

  @override
  List<Object?> get props => [volume, count, chapters];
}

/// Hierarchical response model for `GET /manga/{id}/aggregate`.
class AggregateResponse extends Equatable {
  /// Creates an [AggregateResponse].
  const new({this.result = 'ok', this.volumes = const {}});

  /// Creates an [AggregateResponse] from JSON using [AggregateResponseParser].
  factory fromJson(Map<String, dynamic> json) =>
      AggregateResponseParser.parse(json);

  /// Status of the API response (typically `'ok'`).
  final String result;

  /// Map of volumes keyed by volume string (`"1"`, `"none"`, etc.).
  final Map<String, AggregateVolume> volumes;

  /// Converts this [AggregateResponse] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'result': result,
    'volumes': volumes.map((k, v) => MapEntry(k, v.toJson())),
  };

  @override
  List<Object?> get props => [result, volumes];
}
