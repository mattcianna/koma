import 'package:equatable/equatable.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';

/// Domain representation of a manga series with localized metadata and covers.
class Manga extends Equatable {
  /// Creates a [Manga] domain entity.
  const new({
    required this.id,
    required this.title,
    this.description,
    this.authorName,
    this.coverFileName,
    this.coverUrl256,
    this.coverUrl512,
    this.coverUrlOriginal,
    this.status,
    this.contentRating,
    this.lastVolume,
    this.lastChapter,
    this.availableTranslatedLanguages = const [],
    this.rawUrl,
    this.engtlUrl,
  });

  /// Factory constructor to map a raw [MangaData] API entity into a [Manga]
  /// domain entity, resolving localized titles, descriptions, and cover URLs.
  factory fromMangaData(
    MangaData data, {
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    final coverFile = data.coverFileName;
    final rawLink = data.attributes.links['raw']?.toString().trim();
    final engtlLink = data.attributes.links['engtl']?.toString().trim();
    return Manga(
      id: data.id,
      title: MangaDexLocaleResolver.resolveTitle(
        rawTitle: data.attributes.title,
        rawAltTitles: data.attributes.altTitles,
        preferredLocales: preferredLocales,
      ),
      description: MangaDexLocaleResolver.resolveDescription(
        rawDescription: data.attributes.description,
        preferredLocales: preferredLocales,
      ),
      authorName: data.authorName,
      coverFileName: coverFile,
      coverUrl256: coverFile != null
          ? MangaDexCoverUrlResolver.thumbnail256(
              mangaId: data.id,
              fileName: coverFile,
            )
          : null,
      coverUrl512: coverFile != null
          ? MangaDexCoverUrlResolver.medium512(
              mangaId: data.id,
              fileName: coverFile,
            )
          : null,
      coverUrlOriginal: coverFile != null
          ? MangaDexCoverUrlResolver.original(
              mangaId: data.id,
              fileName: coverFile,
            )
          : null,
      status: data.attributes.status,
      contentRating: data.attributes.contentRating,
      lastVolume: data.attributes.lastVolume,
      lastChapter: data.attributes.lastChapter,
      availableTranslatedLanguages: List<String>.unmodifiable(
        data.attributes.availableTranslatedLanguages ?? const [],
      ),
      rawUrl: (rawLink != null && rawLink.isNotEmpty) ? rawLink : null,
      engtlUrl: (engtlLink != null && engtlLink.isNotEmpty) ? engtlLink : null,
    );
  }

  /// Deserializes a [Manga] from a JSON map.
  ///
  /// Seamlessly parses either a raw MangaDex API entity (containing
  /// `'attributes'`) or a previously serialized [Manga] domain entity.
  factory fromJson(
    Map<String, dynamic> json, {
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    if (json.containsKey('attributes')) {
      final mangaData = MangaData.fromJson(json);
      return Manga.fromMangaData(mangaData, preferredLocales: preferredLocales);
    }

    final langsRaw = json['availableTranslatedLanguages'];
    final langs = langsRaw is List
        ? langsRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return Manga(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      authorName: json['authorName'] as String?,
      coverFileName: json['coverFileName'] as String?,
      coverUrl256: json['coverUrl256'] as String?,
      coverUrl512: json['coverUrl512'] as String?,
      coverUrlOriginal: json['coverUrlOriginal'] as String?,
      status: json['status'] as String?,
      contentRating: json['contentRating'] as String?,
      lastVolume: json['lastVolume'] as String?,
      lastChapter: json['lastChapter'] as String?,
      availableTranslatedLanguages: List<String>.unmodifiable(langs),
      rawUrl: json['rawUrl'] as String?,
      engtlUrl: json['engtlUrl'] as String?,
    );
  }

  /// Unique MangaDex UUID for this manga.
  final String id;

  /// Resolved localized title for display.
  final String title;

  /// Resolved localized description.
  final String? description;

  /// Resolved primary author name from expanded relationships.
  final String? authorName;

  /// Primary cover art file name from expanded relationships.
  final String? coverFileName;

  /// MangaDex CDN 256px thumbnail URL for grid items and list tiles.
  final String? coverUrl256;

  /// MangaDex CDN 512px medium image URL for detail screens.
  final String? coverUrl512;

  /// MangaDex CDN full original uncompressed cover image URL.
  final String? coverUrlOriginal;

  /// Publication status (e.g. `'ongoing'`, `'completed'`, `'hiatus'`).
  final String? status;

  /// Content rating (e.g. `'safe'`, `'suggestive'`, `'erotica'`).
  final String? contentRating;

  /// Last published volume number, or null if ongoing/unknown.
  final String? lastVolume;

  /// Last published chapter number, or null if ongoing/unknown.
  final String? lastChapter;

  /// List of ISO-639-1 language codes with available translated chapters.
  final List<String> availableTranslatedLanguages;

  /// Official raw serialization URL from MangaDex `links['raw']`, if any.
  final String? rawUrl;

  /// Official English publisher URL from MangaDex `links['engtl']`, if any.
  final String? engtlUrl;

  /// Serializes this [Manga] to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'authorName': authorName,
    'coverFileName': coverFileName,
    'coverUrl256': coverUrl256,
    'coverUrl512': coverUrl512,
    'coverUrlOriginal': coverUrlOriginal,
    'status': status,
    'contentRating': contentRating,
    'lastVolume': lastVolume,
    'lastChapter': lastChapter,
    'availableTranslatedLanguages': availableTranslatedLanguages,
    'rawUrl': rawUrl,
    'engtlUrl': engtlUrl,
  };

  /// Creates a copy of this [Manga] with the given fields replaced.
  Manga copyWith({
    String? id,
    String? title,
    String? description,
    String? authorName,
    String? coverFileName,
    String? coverUrl256,
    String? coverUrl512,
    String? coverUrlOriginal,
    String? status,
    String? contentRating,
    String? lastVolume,
    String? lastChapter,
    List<String>? availableTranslatedLanguages,
    String? rawUrl,
    String? engtlUrl,
  }) {
    return Manga(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      coverFileName: coverFileName ?? this.coverFileName,
      coverUrl256: coverUrl256 ?? this.coverUrl256,
      coverUrl512: coverUrl512 ?? this.coverUrl512,
      coverUrlOriginal: coverUrlOriginal ?? this.coverUrlOriginal,
      status: status ?? this.status,
      contentRating: contentRating ?? this.contentRating,
      lastVolume: lastVolume ?? this.lastVolume,
      lastChapter: lastChapter ?? this.lastChapter,
      availableTranslatedLanguages:
          availableTranslatedLanguages ?? this.availableTranslatedLanguages,
      rawUrl: rawUrl ?? this.rawUrl,
      engtlUrl: engtlUrl ?? this.engtlUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    authorName,
    coverFileName,
    coverUrl256,
    coverUrl512,
    coverUrlOriginal,
    status,
    contentRating,
    lastVolume,
    lastChapter,
    availableTranslatedLanguages,
    rawUrl,
    engtlUrl,
  ];
}
