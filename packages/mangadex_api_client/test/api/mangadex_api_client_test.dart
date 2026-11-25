import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClientAdapter extends Mock implements HttpClientAdapter;

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  group('MangaDexApiClient', () {
    late Dio dio;
    late _MockHttpClientAdapter adapter;
    late MangaDexApiClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: MangaDexApiClient.defaultBaseUrl));
      adapter = _MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;
      client = MangaDexApiClient(dio);
    });

    test('createDefaultDio installs User-Agent and RateLimit interceptors', () {
      final configuredDio = MangaDexApiClient.createDefaultDio();

      expect(
        configuredDio.options.baseUrl,
        equals(MangaDexApiClient.defaultBaseUrl),
      );
      expect(
        configuredDio.interceptors.any((i) => i is KomaUserAgentInterceptor),
        isTrue,
      );
      expect(
        configuredDio.interceptors.any(
          (i) => i is MangaDexRateLimitInterceptor,
        ),
        isTrue,
      );
    });

    test(
      'searchManga queries /manga and deserializes MangaListResponse',
      () async {
        final mockData = {
          'result': 'ok',
          'response': 'collection',
          'data': [
            {
              'id': 'd90ea6cb-7bc3-4d80-8af0-28557e6c4e17',
              'type': 'manga',
              'attributes': {
                'title': {'ja-ro': 'Dungeon Meshi'},
                'altTitles': [
                  {'en': 'Delicious in Dungeon'},
                ],
                'status': 'completed',
              },
              'relationships': [
                {
                  'id': 'cover-1',
                  'type': 'cover_art',
                  'attributes': {'fileName': 'cover.jpg'},
                },
              ],
            },
          ],
          'limit': 20,
          'offset': 0,
          'total': 1,
        };

        when(() => adapter.fetch(any(), any(), any()))
            .thenAnswer((invocation) async {
              final options =
                  invocation.positionalArguments.first as RequestOptions;
              expect(options.path, equals('/manga'));
              expect(options.queryParameters['title'], equals('Dungeon Meshi'));
              expect(
                options.queryParameters['includes[]'],
                equals(['cover_art', 'author']),
              );

              return ResponseBody.fromString(
                jsonEncode(mockData),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            });

        final result = await client.searchManga(
          title: 'Dungeon Meshi',
          limit: 20,
        );

        expect(result.result, equals('ok'));
        expect(result.total, equals(1));
        expect(
          result.data.first.id,
          equals('d90ea6cb-7bc3-4d80-8af0-28557e6c4e17'),
        );
        expect(result.data.first.coverFileName, equals('cover.jpg'));
      },
    );

    test(
      'getMangaById queries /manga/{id} and returns MangaResponse',
      () async {
        const mangaId = 'a1c7c817-4e59-43b7-9365-09675a149a6f';
        final mockData = {
          'result': 'ok',
          'response': 'entity',
          'data': {
            'id': mangaId,
            'type': 'manga',
            'attributes': {
              'title': {'ja-ro': 'One Piece'},
              'status': 'ongoing',
            },
          },
        };

        when(() => adapter.fetch(any(), any(), any()))
            .thenAnswer((invocation) async {
              final options =
                  invocation.positionalArguments.first as RequestOptions;
              expect(options.path, equals('/manga/$mangaId'));

              return ResponseBody.fromString(
                jsonEncode(mockData),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            });

        final result = await client.getMangaById(mangaId);

        expect(result.result, equals('ok'));
        expect(result.data.id, equals(mangaId));
        expect(result.data.attributes.title['ja-ro'], equals('One Piece'));
      },
    );

    test(
      'getMangaAggregate queries /manga/{id}/aggregate with languages',
      () async {
        const mangaId = 'd90ea6cb-7bc3-4d80-8af0-28557e6c4e17';
        final mockData = {
          'result': 'ok',
          'volumes': {
            '1': {
              'volume': '1',
              'count': 1,
              'chapters': {
                '1': {
                  'chapter': '1',
                  'id': 'chapter-uuid-1',
                  'others': <dynamic>[],
                  'count': 1,
                  'isUnavailable': false,
                },
              },
            },
          },
        };

        when(() => adapter.fetch(any(), any(), any()))
            .thenAnswer((invocation) async {
              final options =
                  invocation.positionalArguments.first as RequestOptions;
              expect(options.path, equals('/manga/$mangaId/aggregate'));
              expect(
                options.queryParameters['translatedLanguage[]'],
                equals(['en', 'it']),
              );

              return ResponseBody.fromString(
                jsonEncode(mockData),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            });

        final result = await client.getMangaAggregate(mangaId);

        expect(result.result, equals('ok'));
        expect(result.volumes.containsKey('1'), isTrue);
        expect(result.volumes['1']!.chapters.containsKey('1'), isTrue);
      },
    );

    test(
      'getMangaFeed queries /manga/{id}/feed and preserves simulpub chapters',
      () async {
        const mangaId = 'a1c7c817-4e59-43b7-9365-09675a149a6f';
        final mockData = {
          'result': 'ok',
          'response': 'collection',
          'data': [
            {
              'id': 'ch-1198',
              'type': 'chapter',
              'attributes': {
                'chapter': '1198',
                'pages': 0, // Simulpub chapter (MangaPlus)
                'externalUrl': 'https://mangaplus.shueisha.co.jp/...',
              },
            },
          ],
          'limit': 100,
          'offset': 0,
          'total': 1,
        };

        when(() => adapter.fetch(any(), any(), any()))
            .thenAnswer((invocation) async {
              final options =
                  invocation.positionalArguments.first as RequestOptions;
              expect(options.path, equals('/manga/$mangaId/feed'));
              // Must NEVER include includeEmptyPages=0
              expect(
                options.queryParameters['includeEmptyPages'],
                isNot(equals(0)),
              );

              return ResponseBody.fromString(
                jsonEncode(mockData),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            });

        final result = await client.getMangaFeed(
          mangaId,
          limit: 100,
          publishAtSince: '2026-11-12T00:00:00',
        );

        expect(result.result, equals('ok'));
        expect(result.data.first.id, equals('ch-1198'));
        expect(result.data.first.attributes.pages, equals(0));
        expect(result.data.first.attributes.externalUrl, isNotNull);
      },
    );

    test(
      'getMangaFeedSince extension formats DateTime into strict UTC string',
      () async {
        const mangaId = 'a1c7c817-4e59-43b7-9365-09675a149a6f';
        final sinceDate = DateTime.utc(2026, 11, 10, 8, 30);

        when(() => adapter.fetch(any(), any(), any()))
            .thenAnswer((invocation) async {
              final options =
                  invocation.positionalArguments.first as RequestOptions;
              expect(
                options.queryParameters['publishAtSince'],
                equals('2026-11-10T08:30:00'),
              );

              return ResponseBody.fromString(
                jsonEncode({
                  'result': 'ok',
                  'response': 'collection',
                  'data': <dynamic>[],
                  'total': 0,
                }),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            });

        final result = await client.getMangaFeedSince(
          mangaId,
          publishAtSinceDate: sinceDate,
          translatedLanguage: ['en'],
        );

        expect(result.result, equals('ok'));
      },
    );
  });
}
