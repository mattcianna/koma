import 'dart:convert';

import 'package:koma_cache_client/koma_cache_client.dart';
import 'package:manga_repository/src/exceptions/manga_repository_exception.dart';
import 'package:manga_repository/src/models/chapter_aggregate.dart';
import 'package:manga_repository/src/models/manga.dart';
import 'package:manga_repository/src/models/manga_chapter.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';

/// Repository that coordinates MangaDex REST API v5 access with local Drift
/// SQLite caching via Stale-While-Revalidate (SWR) policies.
class MangaRepository {
  /// Creates a [MangaRepository].
  const new({
    required this.apiClient,
    required this.cacheClient,
    this.officialFeedService,
  });

  /// The underlying MangaDex REST API client.
  final MangaDexApiClient apiClient;

  /// The local Drift SQLite cache client.
  final KomaCacheClient cacheClient;

  /// Optional service discovering official publisher RSS/Atom feeds.
  final OfficialReleaseFeedService? officialFeedService;

  OfficialReleaseFeedService get _feedService =>
      officialFeedService ?? OfficialReleaseFeedService();

  /// Searches for manga matching [query] or retrieves popular titles when
  /// [query] is null or empty.
  ///
  /// When [query] is non-empty, orders results by relevance descending.
  /// When [query] is null or empty, orders results by follower count
  /// descending.
  ///
  /// Writes through fetched manga metadata to [KomaCacheClient.upsertMangas]
  /// and maps results to domain [Manga] entities.
  Future<List<Manga>> searchManga({
    String? query,
    List<String> translatedLanguages = const ['en', 'it'],
    List<String> contentRatings = const ['safe', 'suggestive'],
    int limit = 20,
    int offset = 0,
    List<String> preferredLocales = const ['en', 'it'],
  }) async {
    try {
      final trimmed = query?.trim();
      final isQueryEmpty = trimmed == null || trimmed.isEmpty;

      final response = await apiClient.searchManga(
        title: isQueryEmpty ? null : trimmed,
        limit: limit,
        offset: offset,
        contentRating: contentRatings,
        availableTranslatedLanguage: translatedLanguages,
        orderRelevance: isQueryEmpty ? null : 'desc',
        orderFollowedCount: isQueryEmpty ? 'desc' : null,
      );

      final entries = <String, String>{
        for (final data in response.data)
          data.id: jsonEncode(_mangaDataToJson(data)),
      };
      await cacheClient.upsertMangas(entries);

      return response.data
          .map(
            (data) =>
                Manga.fromMangaData(data, preferredLocales: preferredLocales),
          )
          .toList();
    } catch (error, stackTrace) {
      throw _mapException(error, stackTrace);
    }
  }

  /// Retrieves manga details for [mangaId].
  ///
  /// Follows a Stale-While-Revalidate caching strategy:
  /// - If [forceRefresh] is `false` and a fresh (unexpired) cache entry exists
  ///   in [KomaCacheClient], returns the cached domain [Manga] immediately.
  /// - Otherwise, fetches latest metadata via [MangaDexApiClient.getMangaById],
  ///   writes through to [KomaCacheClient.upsertManga], and returns the mapped
  ///   domain model.
  /// - On network error, falls back to a stale cache entry if available.
  ///   If no cache entry exists, throws a typed [MangaRepositoryException].
  Future<Manga> getMangaDetails(
    String mangaId, {
    List<String> preferredLocales = const ['en', 'it'],
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      CacheEntry<String>? cached;
      try {
        cached = await cacheClient.getManga(mangaId);
      } on Object catch (_) {
        // Fall through to network request on cache read failure.
      }
      if (cached != null && !cached.isExpired) {
        return _mapMangaFromPayload(
          cached.payloadJson,
          preferredLocales: preferredLocales,
        );
      }
    }

    try {
      final response = await apiClient.getMangaById(mangaId);
      final payload = jsonEncode(_mangaDataToJson(response.data));
      await cacheClient.upsertManga(mangaId, payload);
      return Manga.fromMangaData(
        response.data,
        preferredLocales: preferredLocales,
      );
    } catch (error, stackTrace) {
      if (error is! MangaDexNotFoundException) {
        CacheEntry<String>? fallback;
        try {
          fallback = await cacheClient.getManga(mangaId);
        } on Object catch (_) {
          // Ignore cache read errors and throw original network exception.
        }
        if (fallback != null) {
          return _mapMangaFromPayload(
            fallback.payloadJson,
            preferredLocales: preferredLocales,
          );
        }
      }
      throw _mapException(error, stackTrace);
    }
  }

  /// Retrieves the volume and chapter aggregate tree for [mangaId] and
  /// [translatedLanguages].
  ///
  /// Follows a Stale-While-Revalidate caching strategy:
  /// - If [forceRefresh] is `false` and a fresh cache entry exists, returns
  ///   the cached [ChapterAggregate].
  /// - Otherwise, queries [MangaDexApiClient.getMangaAggregate], writes
  ///   through to [KomaCacheClient.upsertAggregate], and returns the mapped
  ///   domain tree.
  /// - On network error, falls back to a stale cache entry if available.
  ///   Volumes and chapters are always deterministically sorted using
  ///   [ChapterComparator].
  ///
  /// Also merges missing chapters from an all-language aggregate fallback and
  /// official publisher RSS/Atom feeds linked via `links['raw']`.
  Future<ChapterAggregate> getMangaAggregate(
    String mangaId, {
    List<String> translatedLanguages = const ['en', 'it'],
    bool forceRefresh = false,
    String? rawUrlHint,
  }) async {
    if (!forceRefresh) {
      CacheEntry<String>? cached;
      try {
        cached = await cacheClient.getAggregate(mangaId, translatedLanguages);
      } on Object catch (_) {
        // Fall through to network request on cache read failure.
      }
      if (cached != null && !cached.isExpired) {
        return _mapAggregateFromPayload(mangaId, cached.payloadJson);
      }
    }

    try {
      final response = await apiClient.getMangaAggregate(
        mangaId,
        translatedLanguage: translatedLanguages,
      );
      final primary = ChapterAggregate.fromAggregateResponse(mangaId, response);

      ChapterAggregate? allLangFallback;
      if (translatedLanguages.isNotEmpty) {
        try {
          final fallbackResponse = await apiClient.getMangaAggregate(
            mangaId,
            translatedLanguage: null,
          );
          allLangFallback = ChapterAggregate.fromAggregateResponse(
            mangaId,
            fallbackResponse,
          );
        } on Object catch (_) {
          // Best-effort fallback; retain primary aggregate on failure.
        }
      }

      var effectiveRawUrl = rawUrlHint;
      if (effectiveRawUrl == null) {
        try {
          final cachedManga = await cacheClient.getManga(mangaId);
          if (cachedManga != null) {
            effectiveRawUrl = _mapMangaFromPayload(cachedManga.payloadJson)
                .rawUrl;
          }
        } on Object catch (_) {
          // Best-effort cache lookup for official publisher URL.
        }
      }

      var officialChapters = const <OfficialFeedChapter>[];
      if (effectiveRawUrl != null && effectiveRawUrl.isNotEmpty) {
        try {
          officialChapters = await _feedService.fetchChaptersFromRawUrl(
            effectiveRawUrl,
          );
        } on Object catch (_) {
          officialChapters = const [];
        }
      }

      final merged = ChapterAggregate.mergeFallbacks(
        primary: primary,
        allLanguageFallback: allLangFallback,
        officialChapters: officialChapters,
      );

      final payload = jsonEncode(merged.toJson());
      await cacheClient.upsertAggregate(mangaId, translatedLanguages, payload);
      return merged;
    } catch (error, stackTrace) {
      if (error is! MangaDexNotFoundException) {
        CacheEntry<String>? fallback;
        try {
          fallback = await cacheClient.getAggregate(
            mangaId,
            translatedLanguages,
          );
        } on Object catch (_) {
          // Ignore cache read errors and throw original network exception.
        }
        if (fallback != null) {
          return _mapAggregateFromPayload(mangaId, fallback.payloadJson);
        }
      }
      throw _mapException(error, stackTrace);
    }
  }

  /// Resolves the highest numbered released chapter for [mangaId] across
  /// preferred languages, all-language MangaDex fallbacks, and official
  /// publisher RSS/Atom feeds.
  Future<MangaChapter?> getLatestReleasedChapter(
    String mangaId, {
    List<String> translatedLanguages = const ['en', 'it'],
    bool forceRefresh = true,
  }) async {
    String? rawUrl;
    try {
      final manga = await getMangaDetails(mangaId, forceRefresh: forceRefresh);
      rawUrl = manga.rawUrl;
    } on Object catch (_) {
      // Proceed with aggregate lookup even if metadata fetch fails.
    }

    final aggregate = await getMangaAggregate(
      mangaId,
      translatedLanguages: translatedLanguages,
      forceRefresh: forceRefresh,
      rawUrlHint: rawUrl,
    );

    if (aggregate.orderedChapters.isEmpty) return null;
    for (var i = aggregate.orderedChapters.length - 1; i >= 0; i--) {
      final chapter = aggregate.orderedChapters[i];
      if (chapter.chapterNumber != 'none') return chapter;
    }
    return aggregate.orderedChapters.last;
  }

  /// Computes an ordered list of chapter numbers up to and including
  /// [upToChapterNumber] that are not present in [alreadyReadChapters].
  ///
  /// Orders chapters using [ChapterComparator] across the aggregate tree.
  List<String> computePreviousUnreadChapters({
    required ChapterAggregate aggregate,
    required String upToChapterNumber,
    required Set<String> alreadyReadChapters,
  }) {
    return aggregate.computePreviousUnreadChapters(
      upToChapterNumber: upToChapterNumber,
      alreadyReadChapters: alreadyReadChapters,
    );
  }

  /// Invalidates the local SQLite cache for chapter aggregates of [mangaId].
  Future<void> invalidateAggregateCache(String mangaId) async {
    try {
      await cacheClient.invalidateAggregate(mangaId);
    } catch (error, stackTrace) {
      throw _mapException(error, stackTrace);
    }
  }

  static Map<String, dynamic> _mangaDataToJson(MangaData data) {
    return <String, dynamic>{
      'id': data.id,
      'type': data.type,
      'attributes': data.attributes.toJson(),
      'relationships': [for (final rel in data.relationships) rel.toJson()],
    };
  }

  static Manga _mapMangaFromPayload(
    String payloadJson, {
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(payloadJson);
    } on FormatException catch (e) {
      throw MangaParseException('Malformed JSON in cache payload', cause: e);
    }

    if (decoded is! Map) {
      throw const MangaParseException(
        'Decoded manga cache payload is not a Map',
      );
    }
    final map = Map<String, dynamic>.from(decoded);
    return Manga.fromJson(map, preferredLocales: preferredLocales);
  }

  static ChapterAggregate _mapAggregateFromPayload(
    String mangaId,
    String payloadJson,
  ) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(payloadJson);
    } on FormatException catch (e) {
      throw MangaParseException('Malformed JSON in cache payload', cause: e);
    }

    if (decoded is! Map) {
      throw const MangaParseException(
        'Decoded aggregate cache payload is not a Map',
      );
    }
    final map = Map<String, dynamic>.from(decoded);
    return ChapterAggregate.fromJson(map, mangaId: mangaId);
  }

  MangaRepositoryException _mapException(Object error, StackTrace stackTrace) {
    if (error is MangaRepositoryException) {
      return error;
    }
    if (error is MangaDexNotFoundException) {
      return MangaNotFoundException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
      );
    }
    if (error is MangaDexRateLimitException) {
      return MangaRateLimitException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
        retryAfterHeader: error.retryAfterHeader,
      );
    }
    if (error is MangaDexValidationException) {
      return MangaValidationException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
      );
    }
    if (error is MangaDexNetworkException) {
      return MangaNetworkException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
      );
    }
    if (error is MangaDexServerException) {
      return MangaServerException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
      );
    }
    if (error is MangaDexParseException) {
      return MangaParseException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
      );
    }
    if (error is MangaDexApiException) {
      return MangaUnknownException(
        error.message,
        cause: error,
        statusCode: error.statusCode,
      );
    }
    if (error is FormatException) {
      return MangaParseException(
        'Invalid JSON payload: ${error.message}',
        cause: error,
      );
    }
    return MangaUnknownException(error.toString(), cause: error);
  }
}
