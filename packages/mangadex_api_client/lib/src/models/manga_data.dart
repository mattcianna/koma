import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mangadex_api_client/src/models/relationship_data.dart';
import 'package:mangadex_api_client/src/utils/locale_resolver.dart';

part 'manga_data.g.dart';

Map<String, dynamic> _parseDescription(Object? value) =>
    MangaDexLocaleResolver.sanitizeMap(value);

String? _emptyStringToNull(Object? value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

/// Attributes object for a MangaDex manga entity.
@JsonSerializable()
class MangaAttributes extends Equatable {
  /// Creates a [MangaAttributes].
  const new({
    this.title = const {},
    this.altTitles = const [],
    this.description = const {},
    this.links = const {},
    this.isLocked,
    this.originalLanguage,
    this.lastVolume,
    this.lastChapter,
    this.publicationDemographic,
    this.status,
    this.year,
    this.contentRating,
    this.availableTranslatedLanguages,
  });

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$MangaAttributesFromJson(json);

  /// Map of localized titles keyed by language code (e.g. `'ja-ro'`, `'en'`).
  final Map<String, dynamic> title;

  /// List of single-entry maps containing alternative localized titles.
  final List<Map<String, dynamic>> altTitles;

  /// Map of localized descriptions keyed by language code.
  ///
  /// Safely handles MangaDex's PHP quirk where empty descriptions are `[]`.
  @JsonKey(fromJson: _parseDescription)
  final Map<String, dynamic> description;

  /// External tracker and official serialization URLs keyed by slug
  /// (e.g. `'raw'`, `'engtl'`, `'mu'`, `'al'`).
  ///
  /// Safely handles MangaDex's PHP quirk where empty maps are `[]`.
  @JsonKey(fromJson: _parseDescription)
  final Map<String, dynamic> links;

  /// Whether editing this manga metadata is locked on MangaDex.
  final bool? isLocked;

  /// ISO-639-1 code of the original publication language (e.g. `'ja'`).
  final String? originalLanguage;

  /// Last published volume number, or null if ongoing/unknown.
  @JsonKey(fromJson: _emptyStringToNull)
  final String? lastVolume;

  /// Last published chapter number, or null if ongoing/unknown.
  @JsonKey(fromJson: _emptyStringToNull)
  final String? lastChapter;

  /// Target demographic (e.g. `'shounen'`, `'seinen'`, `'shoujo'`, `'josei'`).
  final String? publicationDemographic;

  /// Publication status (e.g. `'ongoing'`, `'completed'`, `'hiatus'`).
  final String? status;

  /// Release year as integer.
  final int? year;

  /// Content rating (e.g. `'safe'`, `'suggestive'`, `'erotica'`).
  final String? contentRating;

  /// List of ISO-639-1 language codes with available translated chapters.
  final List<String>? availableTranslatedLanguages;

  /// Converts this [MangaAttributes] into a JSON map.
  Map<String, dynamic> toJson() => _$MangaAttributesToJson(this);

  @override
  List<Object?> get props => [
    title,
    altTitles,
    description,
    links,
    isLocked,
    originalLanguage,
    lastVolume,
    lastChapter,
    publicationDemographic,
    status,
    year,
    contentRating,
    availableTranslatedLanguages,
  ];
}

/// Core MangaDex manga entity data wrapper.
@JsonSerializable()
class MangaData extends Equatable {
  /// Creates a [MangaData].
  const new({
    required this.id,
    required this.attributes,
    this.type = 'manga',
    this.relationships = const [],
  });

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) => _$MangaDataFromJson(json);

  /// Unique MangaDex UUID for this manga.
  final String id;

  /// Resource type (typically `'manga'`).
  final String type;

  /// Detailed manga attributes.
  final MangaAttributes attributes;

  /// Related resources (e.g. `author`, `artist`, `cover_art`).
  final List<RelationshipData> relationships;

  /// Extracts the cover file name from the expanded `cover_art` relationship,
  /// or null if unexpanded or missing.
  String? get coverFileName =>
      MangaDexLocaleResolver.extractCoverFileName(relationships);

  /// Extracts the author name from the expanded `author` relationship,
  /// or null if unexpanded or missing.
  String? get authorName {
    for (final rel in relationships) {
      if (rel.type == 'author') {
        final attrs = rel.attributes;
        if (attrs != null && attrs['name'] is String) {
          final name = (attrs['name'] as String).trim();
          if (name.isNotEmpty) return name;
        }
      }
    }
    return null;
  }

  /// Extracts the artist name from the expanded `artist` relationship,
  /// or null if unexpanded or missing.
  String? get artistName {
    for (final rel in relationships) {
      if (rel.type == 'artist') {
        final attrs = rel.attributes;
        if (attrs != null && attrs['name'] is String) {
          final name = (attrs['name'] as String).trim();
          if (name.isNotEmpty) return name;
        }
      }
    }
    return null;
  }

  /// Converts this [MangaData] into a JSON map.
  Map<String, dynamic> toJson() => _$MangaDataToJson(this);

  @override
  List<Object?> get props => [id, type, attributes, relationships];
}

/// Single entity response wrapper for `GET /manga/{id}`.
@JsonSerializable()
class MangaResponse extends Equatable {
  /// Creates a [MangaResponse].
  const new({required this.data, this.result = 'ok', this.response = 'entity'});

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) => _$MangaResponseFromJson(json);

  /// Response status (typically `'ok'`).
  final String result;

  /// Response classification (typically `'entity'`).
  final String response;

  /// Manga data entity payload.
  final MangaData data;

  /// Converts this [MangaResponse] into a JSON map.
  Map<String, dynamic> toJson() => _$MangaResponseToJson(this);

  @override
  List<Object?> get props => [result, response, data];
}

/// Collection response wrapper for `GET /manga`.
@JsonSerializable()
class MangaListResponse extends Equatable {
  /// Creates a [MangaListResponse].
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
      _$MangaListResponseFromJson(json);

  /// Response status (typically `'ok'`).
  final String result;

  /// Response classification (typically `'collection'`).
  final String response;

  /// List of manga entities returned for the query.
  final List<MangaData> data;

  /// Page limit requested.
  final int limit;

  /// Page offset requested.
  final int offset;

  /// Total count of matching manga records on MangaDex.
  final int total;

  /// Converts this [MangaListResponse] into a JSON map.
  Map<String, dynamic> toJson() => _$MangaListResponseToJson(this);

  @override
  List<Object?> get props => [result, response, data, limit, offset, total];
}
