import 'package:dio/dio.dart';
import 'package:mangadex_api_client/src/interceptors/koma_user_agent_interceptor.dart';
import 'package:mangadex_api_client/src/interceptors/mangadex_rate_limit_interceptor.dart';
import 'package:mangadex_api_client/src/models/aggregate_data.dart';
import 'package:mangadex_api_client/src/models/chapter_data.dart';
import 'package:mangadex_api_client/src/models/manga_data.dart';
import 'package:mangadex_api_client/src/utils/timestamp_formatter.dart';
import 'package:retrofit/retrofit.dart';

part 'mangadex_api_client.g.dart';

/// Retrofit REST API client for the MangaDex v5 API.
///
/// Supports metadata search, single manga retrieval, volume/chapter aggregation,
/// and chapter feed updates.
@RestApi(baseUrl: MangaDexApiClient.defaultBaseUrl)
abstract class MangaDexApiClient {
  /// Creates a [MangaDexApiClient] instance backed by Retrofit.
  factory(Dio dio, {String baseUrl}) = _MangaDexApiClient;

  /// Canonical MangaDex v5 REST API base URL.
  static const String defaultBaseUrl = 'https://api.mangadex.org';

  /// Creates a configured [Dio] instance with [KomaUserAgentInterceptor]
  /// and [MangaDexRateLimitInterceptor] pre-installed.
  static Dio createDefaultDio({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    int requestsPerSecond = 4,
    int maxBurst = 4,
    int maxRetries = 3,
  }) {
    final client = dio ?? Dio();
    client.options.baseUrl = baseUrl;
    client.interceptors.addAll([
      const KomaUserAgentInterceptor(),
      MangaDexRateLimitInterceptor(
        requestsPerSecond: requestsPerSecond,
        maxBurst: maxBurst,
        maxRetries: maxRetries,
      ),
    ]);
    return client;
  }

  /// Searches manga titles with optional pagination, relationship expansion,
  /// and content/language filters.
  ///
  /// Corresponds to `GET /manga`.
  @GET('/manga')
  Future<MangaListResponse> searchManga({
    @Query('title') String? title,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('includes[]') List<String>? includes = const ['cover_art', 'author'],
    @Query('contentRating[]')
    List<String>? contentRating = const ['safe', 'suggestive'],
    @Query('availableTranslatedLanguage[]')
    List<String>? availableTranslatedLanguage = const ['en', 'it'],
    @Query('order[relevance]') String? orderRelevance,
    @Query('order[followedCount]') String? orderFollowedCount,
    @Query('order[rating]') String? orderRating,
    @Queries() Map<String, dynamic>? extraQueries,
  });

  /// Retrieves full metadata for a single manga by its unique UUID.
  ///
  /// Corresponds to `GET /manga/{id}`.
  @GET('/manga/{id}')
  Future<MangaResponse> getMangaById(
    @Path('id') String id, {
    @Query('includes[]') List<String>? includes = const ['cover_art', 'author'],
  });

  /// Retrieves the hierarchical volume and chapter aggregate tree for a manga.
  ///
  /// Corresponds to `GET /manga/{id}/aggregate`.
  @GET('/manga/{id}/aggregate')
  Future<AggregateResponse> getMangaAggregate(
    @Path('id') String id, {
    @Query('translatedLanguage[]')
    List<String>? translatedLanguage = const ['en', 'it'],
  });

  /// Retrieves the chapter feed for a manga, ordered and filtered by language
  /// or publication timestamp.
  ///
  /// Corresponds to `GET /manga/{id}/feed`.
  ///
  /// Note: [includeEmptyPages] must NEVER be set to `0`, so that
  /// official simulpub releases (e.g. MangaPlus chapters with `pages: 0`)
  /// remain visible. [publishAtSince] must be formatted as
  /// `YYYY-MM-DDTHH:mm:ss` UTC without milliseconds or trailing `'Z'`.
  @GET('/manga/{id}/feed')
  Future<ChapterFeedResponse> getMangaFeed(
    @Path('id') String id, {
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('translatedLanguage[]') List<String>? translatedLanguage,
    @Query('order[publishAt]') String? orderPublishAt,
    @Query('order[chapter]') String? orderChapter,
    @Query('order[volume]') String? orderVolume,
    @Query('publishAtSince') String? publishAtSince,
    @Query('includeEmptyPages') int? includeEmptyPages,
  });
}

/// Convenience extensions on [MangaDexApiClient].
extension MangaDexApiClientExtensions on MangaDexApiClient {
  /// Fetches the chapter feed for [id], automatically formatting
  /// [publishAtSinceDate] into MangaDex's required
  /// `YYYY-MM-DDTHH:mm:ss` UTC string.
  ///
  /// `includeEmptyPages` is omitted so official simulpub chapters
  /// (`pages: 0`) remain visible.
  Future<ChapterFeedResponse> getMangaFeedSince(
    String id, {
    DateTime? publishAtSinceDate,
    List<String>? translatedLanguage,
    int? limit,
    int? offset,
    String? orderPublishAt,
  }) => getMangaFeed(
    id,
    limit: limit,
    offset: offset,
    translatedLanguage: translatedLanguage,
    orderPublishAt: orderPublishAt,
    publishAtSince: publishAtSinceDate != null
        ? formatMangaDexTimestamp(publishAtSinceDate)
        : null,
  );
}
