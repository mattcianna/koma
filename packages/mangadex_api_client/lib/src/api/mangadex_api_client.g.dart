// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mangadex_api_client.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: type=lint
// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _MangaDexApiClient implements MangaDexApiClient {
  _MangaDexApiClient(this._dio, {this.baseUrl, this.errorLogger}) {
    baseUrl ??= 'https://api.mangadex.org';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<MangaListResponse> searchManga({
    String? title,
    int? limit,
    int? offset,
    List<String>? includes = const ['cover_art', 'author'],
    List<String>? contentRating = const ['safe', 'suggestive'],
    List<String>? availableTranslatedLanguage = const ['en', 'it'],
    String? orderRelevance,
    String? orderFollowedCount,
    String? orderRating,
    Map<String, dynamic>? extraQueries,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'title': title,
      r'limit': limit,
      r'offset': offset,
      r'includes[]': includes,
      r'contentRating[]': contentRating,
      r'availableTranslatedLanguage[]': availableTranslatedLanguage,
      r'order[relevance]': orderRelevance,
      r'order[followedCount]': orderFollowedCount,
      r'order[rating]': orderRating,
    };
    queryParameters.addAll(extraQueries ?? <String, dynamic>{});
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<MangaListResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/manga',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late MangaListResponse _value;
    try {
      _value = MangaListResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<MangaResponse> getMangaById(
    String id, {
    List<String>? includes = const ['cover_art', 'author'],
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'includes[]': includes};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<MangaResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/manga/${id}',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late MangaResponse _value;
    try {
      _value = MangaResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<AggregateResponse> getMangaAggregate(
    String id, {
    List<String>? translatedLanguage = const ['en', 'it'],
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'translatedLanguage[]': translatedLanguage,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<AggregateResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/manga/${id}/aggregate',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late AggregateResponse _value;
    try {
      _value = AggregateResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<ChapterFeedResponse> getMangaFeed(
    String id, {
    int? limit,
    int? offset,
    List<String>? translatedLanguage,
    String? orderPublishAt,
    String? orderChapter,
    String? orderVolume,
    String? publishAtSince,
    int? includeEmptyPages,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'limit': limit,
      r'offset': offset,
      r'translatedLanguage[]': translatedLanguage,
      r'order[publishAt]': orderPublishAt,
      r'order[chapter]': orderChapter,
      r'order[volume]': orderVolume,
      r'publishAtSince': publishAtSince,
      r'includeEmptyPages': includeEmptyPages,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<ChapterFeedResponse>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/manga/${id}/feed',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late ChapterFeedResponse _value;
    try {
      _value = ChapterFeedResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
