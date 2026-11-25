import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mangadex_api_client/src/models/relationship_data.dart';

part 'chapter_data.g.dart';

String? _emptyStringToNull(Object? value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

/// Attributes object for a MangaDex chapter entity.
@JsonSerializable()
class ChapterAttributes extends Equatable {
  /// Creates a [ChapterAttributes].
  const new({
    this.volume,
    this.chapter,
    this.title,
    this.translatedLanguage,
    this.externalUrl,
    this.publishAt,
    this.readableAt,
    this.createdAt,
    this.updatedAt,
    this.pages = 0,
    this.version,
  });

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$ChapterAttributesFromJson(json);

  /// Volume number or identifier, or null if unvolumed.
  @JsonKey(fromJson: _emptyStringToNull)
  final String? volume;

  /// Chapter number or identifier (e.g. `'1'`, `'10.5'`, `'none'`).
  @JsonKey(fromJson: _emptyStringToNull)
  final String? chapter;

  /// Chapter title if available.
  final String? title;

  /// Translated language ISO code (e.g. `'en'`, `'it'`).
  final String? translatedLanguage;

  /// External URL for official simulpub releases (e.g. MangaPlus, Viz).
  ///
  /// Official simulpub releases have [pages] == 0 and non-null [externalUrl].
  final String? externalUrl;

  /// Timestamp when the chapter was published.
  final DateTime? publishAt;

  /// Timestamp when the chapter became readable.
  final DateTime? readableAt;

  /// Timestamp when the chapter record was created.
  final DateTime? createdAt;

  /// Timestamp when the chapter record was last updated.
  final DateTime? updatedAt;

  /// Page count (0 for external simulpub chapters).
  @JsonKey(defaultValue: 0)
  final int pages;

  /// Version number of this chapter record.
  final int? version;

  /// Converts this [ChapterAttributes] into a JSON map.
  Map<String, dynamic> toJson() => _$ChapterAttributesToJson(this);

  @override
  List<Object?> get props => [
    volume,
    chapter,
    title,
    translatedLanguage,
    externalUrl,
    publishAt,
    readableAt,
    createdAt,
    updatedAt,
    pages,
    version,
  ];
}

/// Single chapter entity returned by MangaDex chapter and feed endpoints.
@JsonSerializable()
class ChapterData extends Equatable {
  /// Creates a [ChapterData].
  const new({
    required this.id,
    required this.attributes,
    this.type = 'chapter',
    this.relationships = const [],
  });

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) => _$ChapterDataFromJson(json);

  /// Unique MangaDex UUID for this chapter.
  final String id;

  /// Resource type (typically `'chapter'`).
  final String type;

  /// Chapter attributes.
  final ChapterAttributes attributes;

  /// Related resources (e.g. `scanlation_group`, `manga`, `user`).
  final List<RelationshipData> relationships;

  /// Converts this [ChapterData] into a JSON map.
  Map<String, dynamic> toJson() => _$ChapterDataToJson(this);

  @override
  List<Object?> get props => [id, type, attributes, relationships];
}

/// Response wrapper for `GET /manga/{id}/feed`.
@JsonSerializable()
class ChapterFeedResponse extends Equatable {
  /// Creates a [ChapterFeedResponse].
  const new({
    this.result = 'ok',
    this.response = 'collection',
    this.data = const [],
    this.limit = 0,
    this.offset = 0,
    this.total = 0,
  });

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$ChapterFeedResponseFromJson(json);

  /// Response status (typically `'ok'`).
  final String result;

  /// Response classification (typically `'collection'`).
  final String response;

  /// List of chapters returned for the requested feed query.
  final List<ChapterData> data;

  /// Page limit requested.
  final int limit;

  /// Page offset requested.
  final int offset;

  /// Total count of matching chapters on MangaDex.
  final int total;

  /// Converts this [ChapterFeedResponse] into a JSON map.
  Map<String, dynamic> toJson() => _$ChapterFeedResponseToJson(this);

  @override
  List<Object?> get props => [result, response, data, limit, offset, total];
}
