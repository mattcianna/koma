import 'dart:convert';

import 'package:koma_cache_client/koma_cache_client.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockMangaDexApiClient extends Mock implements MangaDexApiClient;

class _MockKomaCacheClient extends Mock implements KomaCacheClient;

class _MockOfficialReleaseFeedService extends Mock
    implements OfficialReleaseFeedService;

void main() {
  group('MangaRepository', () {
    late MangaDexApiClient apiClient;
    late KomaCacheClient cacheClient;
    late MangaRepository repository;

    const testMangaId = 'manga-uuid-1';

    const testMangaData = MangaData(
      id: testMangaId,
      attributes: MangaAttributes(
        title: {'en': 'Chainsaw Man'},
        description: {
          'en': 'Denji is a teenage boy living with a Chainsaw Devil.',
        },
        status: 'ongoing',
        contentRating: 'safe',
        lastVolume: '18',
        lastChapter: '175',
        availableTranslatedLanguages: ['en', 'it'],
      ),
      relationships: [
        RelationshipData(
          id: 'auth-1',
          type: 'author',
          attributes: {'name': 'Tatsuki Fujimoto'},
        ),
        RelationshipData(
          id: 'cover-1',
          type: 'cover_art',
          attributes: {'fileName': 'csm_cover.jpg'},
        ),
      ],
    );

    const testAggregateResponse = AggregateResponse(
      volumes: {
        '1': AggregateVolume(
          volume: '1',
          count: 2,
          chapters: {
            '2': AggregateChapter(chapter: '2', id: 'chap-2'),
            '1': AggregateChapter(chapter: '1', id: 'chap-1'),
          },
        ),
      },
    );

    setUp(() {
      apiClient = _MockMangaDexApiClient();
      cacheClient = _MockKomaCacheClient();
      repository = MangaRepository(
        apiClient: apiClient,
        cacheClient: cacheClient,
      );
    });

    group('searchManga', () {
      test(
        'searches with query using relevance ordering and caches results',
        () async {
          when(
            () => apiClient.searchManga(
              title: 'Chainsaw',
              limit: 25,
              offset: 2,
              orderRelevance: 'desc',
            ),
          ).thenAnswer(
            (_) async => const MangaListResponse(
              data: [testMangaData],
              limit: 25,
              offset: 2,
              total: 1,
            ),
          );

          when(() => cacheClient.upsertMangas(any())).thenAnswer((_) async {});

          final results = await repository.searchManga(
            query: 'Chainsaw',
            limit: 25,
            offset: 2,
          );

          expect(results.length, equals(1));
          expect(results.first.id, equals(testMangaId));
          expect(results.first.title, equals('Chainsaw Man'));
          expect(results.first.authorName, equals('Tatsuki Fujimoto'));

          verify(
            () => apiClient.searchManga(
              title: 'Chainsaw',
              limit: 25,
              offset: 2,
              orderRelevance: 'desc',
            ),
          ).called(1);

          verify(() => cacheClient.upsertMangas(any())).called(1);
        },
      );

      test(
        'browses popular when query is null or empty using followedCount',
        () async {
          when(
            () => apiClient.searchManga(
              limit: 10,
              offset: 5,
              contentRating: const ['safe'],
              availableTranslatedLanguage: const ['it'],
              orderFollowedCount: 'desc',
            ),
          ).thenAnswer(
            (_) async => const MangaListResponse(
              data: [testMangaData],
              limit: 10,
              offset: 5,
              total: 1,
            ),
          );

          when(() => cacheClient.upsertMangas(any())).thenAnswer((_) async {});

          final results = await repository.searchManga(
            query: '   ',
            limit: 10,
            offset: 5,
            contentRatings: const ['safe'],
            translatedLanguages: const ['it'],
          );

          expect(results.length, equals(1));
          verify(
            () => apiClient.searchManga(
              limit: 10,
              offset: 5,
              contentRating: const ['safe'],
              availableTranslatedLanguage: const ['it'],
              orderFollowedCount: 'desc',
            ),
          ).called(1);
        },
      );

      test('maps and rethrows exceptions from API client', () async {
        when(
          () => apiClient.searchManga(
            title: any(named: 'title'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            contentRating: any(named: 'contentRating'),
            availableTranslatedLanguage: any(
              named: 'availableTranslatedLanguage',
            ),
            orderRelevance: any(named: 'orderRelevance'),
            orderFollowedCount: any(named: 'orderFollowedCount'),
          ),
        ).thenThrow(const MangaDexNetworkException('Network unreachable'));

        expect(
          () => repository.searchManga(query: 'test'),
          throwsA(isA<MangaNetworkException>()),
        );
      });
    });

    group('getMangaDetails', () {
      test('returns cached manga without network fetch when fresh', () async {
        final cachedJson = jsonEncode(<String, dynamic>{
          'id': testMangaId,
          'title': 'Cached CSM',
          'status': 'ongoing',
        });

        when(() => cacheClient.getManga(testMangaId)).thenAnswer(
          (_) async => CacheEntry<String>(
            payloadJson: cachedJson,
            updatedAt: DateTime.now().toUtc(),
            isExpired: false,
          ),
        );

        final manga = await repository.getMangaDetails(testMangaId);

        expect(manga.id, equals(testMangaId));
        expect(manga.title, equals('Cached CSM'));

        verify(() => cacheClient.getManga(testMangaId)).called(1);
        verifyZeroInteractions(apiClient);
      });

      test('fetches from network, caches, and returns on cache miss', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId))
            .thenAnswer((_) async => const MangaResponse(data: testMangaData));
        when(() => cacheClient.upsertManga(testMangaId, any()))
            .thenAnswer((_) async {});

        final manga = await repository.getMangaDetails(testMangaId);

        expect(manga.id, equals(testMangaId));
        expect(manga.title, equals('Chainsaw Man'));

        verify(() => apiClient.getMangaById(testMangaId)).called(1);
        verify(() => cacheClient.upsertManga(testMangaId, any())).called(1);
      });

      test('fetches from network when cache entry is expired', () async {
        final cachedJson = jsonEncode(<String, dynamic>{
          'id': testMangaId,
          'title': 'Expired CSM',
        });

        when(() => cacheClient.getManga(testMangaId)).thenAnswer(
          (_) async => CacheEntry<String>(
            payloadJson: cachedJson,
            updatedAt: DateTime.now().subtract(const Duration(days: 2)).toUtc(),
            isExpired: true,
          ),
        );
        when(() => apiClient.getMangaById(testMangaId))
            .thenAnswer((_) async => const MangaResponse(data: testMangaData));
        when(() => cacheClient.upsertManga(testMangaId, any()))
            .thenAnswer((_) async {});

        final manga = await repository.getMangaDetails(testMangaId);

        expect(manga.title, equals('Chainsaw Man'));
        verify(() => apiClient.getMangaById(testMangaId)).called(1);
        verify(() => cacheClient.upsertManga(testMangaId, any())).called(1);
      });

      test(
        'fetches from network when forceRefresh is true despite fresh cache',
        () async {
          when(
            () => apiClient.getMangaById(testMangaId),
          ).thenAnswer((_) async => const MangaResponse(data: testMangaData));
          when(() => cacheClient.upsertManga(testMangaId, any()))
              .thenAnswer((_) async {});

          final manga = await repository.getMangaDetails(
            testMangaId,
            forceRefresh: true,
          );

          expect(manga.title, equals('Chainsaw Man'));
          verify(() => apiClient.getMangaById(testMangaId)).called(1);
          verify(() => cacheClient.upsertManga(testMangaId, any())).called(1);
        },
      );

      test('falls back to stale cache on network failure', () async {
        final staleJson = jsonEncode(<String, dynamic>{
          'id': testMangaId,
          'title': 'Stale Chainsaw Man',
        });

        when(() => cacheClient.getManga(testMangaId)).thenAnswer(
          (_) async => CacheEntry<String>(
            payloadJson: staleJson,
            updatedAt: DateTime.now().subtract(const Duration(days: 5)).toUtc(),
            isExpired: true,
          ),
        );

        when(() => apiClient.getMangaById(testMangaId))
            .thenThrow(const MangaDexNetworkException('Connection timeout'));

        final manga = await repository.getMangaDetails(testMangaId);

        expect(manga.title, equals('Stale Chainsaw Man'));
      });

      test(
        'throws mapped exception when network fails and no stale cache exists',
        () async {
          when(() => cacheClient.getManga(testMangaId))
              .thenAnswer((_) async => null);
          when(() => apiClient.getMangaById(testMangaId))
              .thenThrow(const MangaDexNetworkException('No internet'));

          expect(
            () => repository.getMangaDetails(testMangaId),
            throwsA(isA<MangaNetworkException>()),
          );
        },
      );

      test('does not fall back to stale cache on 404 not found', () async {
        final staleJson = jsonEncode(<String, dynamic>{
          'id': testMangaId,
          'title': 'Old Deleted Manga',
        });

        when(() => cacheClient.getManga(testMangaId)).thenAnswer(
          (_) async => CacheEntry<String>(
            payloadJson: staleJson,
            updatedAt: DateTime.now().subtract(const Duration(days: 5)).toUtc(),
            isExpired: true,
          ),
        );

        when(() => apiClient.getMangaById(testMangaId))
            .thenThrow(const MangaDexNotFoundException('Manga not found'));

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(isA<MangaNotFoundException>()),
        );
      });

      test(
        'proceeds to network fetch when initial cache read throws',
        () async {
          when(() => cacheClient.getManga(testMangaId))
              .thenThrow(Exception('SQLite disk read error'));
          when(
            () => apiClient.getMangaById(testMangaId),
          ).thenAnswer((_) async => const MangaResponse(data: testMangaData));
          when(() => cacheClient.upsertManga(testMangaId, any()))
              .thenAnswer((_) async {});

          final manga = await repository.getMangaDetails(testMangaId);

          expect(manga.title, equals('Chainsaw Man'));
        },
      );

      test(
        'throws MangaParseException when cache payload is not a JSON map',
        () async {
          when(() => cacheClient.getManga(testMangaId)).thenAnswer(
            (_) async => CacheEntry<String>(
              payloadJson: '["not", "a", "map"]',
              updatedAt: DateTime.now().toUtc(),
              isExpired: false,
            ),
          );

          expect(
            () => repository.getMangaDetails(testMangaId),
            throwsA(isA<MangaParseException>()),
          );
        },
      );

      test(
        'throws MangaParseException when cache payload has malformed JSON',
        () async {
          when(() => cacheClient.getManga(testMangaId)).thenAnswer(
            (_) async => CacheEntry<String>(
              payloadJson: '{malformed',
              updatedAt: DateTime.now().toUtc(),
              isExpired: false,
            ),
          );

          expect(
            () => repository.getMangaDetails(testMangaId),
            throwsA(isA<MangaParseException>()),
          );
        },
      );
    });

    group('getMangaAggregate', () {
      test(
        'returns cached aggregate without network fetch when fresh',
        () async {
          final cachedJson = jsonEncode(testAggregateResponse.toJson());

          when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
              .thenAnswer(
                (_) async => CacheEntry<String>(
                  payloadJson: cachedJson,
                  updatedAt: DateTime.now().toUtc(),
                  isExpired: false,
                ),
              );

          final aggregate = await repository.getMangaAggregate(testMangaId);

          expect(aggregate.mangaId, equals(testMangaId));
          expect(aggregate.volumes.length, equals(1));
          expect(aggregate.orderedChapters.length, equals(2));

          verify(
            () => cacheClient.getAggregate(testMangaId, const ['en', 'it']),
          ).called(1);
          verifyZeroInteractions(apiClient);
        },
      );

      test('fetches from network, caches, and returns on cache miss', () async {
        when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
            .thenAnswer((_) async => null);

        when(() => apiClient.getMangaAggregate(testMangaId))
            .thenAnswer((_) async => testAggregateResponse);

        when(
          () => cacheClient.upsertAggregate(testMangaId, const [
            'en',
            'it',
          ], any()),
        ).thenAnswer((_) async {});

        final aggregate = await repository.getMangaAggregate(testMangaId);

        expect(aggregate.mangaId, equals(testMangaId));
        expect(aggregate.volumes.first.volumeNumber, equals('1'));

        verify(() => apiClient.getMangaAggregate(testMangaId)).called(1);
        verify(
          () => cacheClient.upsertAggregate(testMangaId, const [
            'en',
            'it',
          ], any()),
        ).called(1);
      });

      test('fetches from network when cache entry is expired', () async {
        final cachedJson = jsonEncode(testAggregateResponse.toJson());

        when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
            .thenAnswer(
              (_) async => CacheEntry<String>(
                payloadJson: cachedJson,
                updatedAt: DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toUtc(),
                isExpired: true,
              ),
            );

        when(() => apiClient.getMangaAggregate(testMangaId))
            .thenAnswer((_) async => testAggregateResponse);

        when(
          () => cacheClient.upsertAggregate(testMangaId, const [
            'en',
            'it',
          ], any()),
        ).thenAnswer((_) async {});

        final aggregate = await repository.getMangaAggregate(testMangaId);

        expect(aggregate.mangaId, equals(testMangaId));
        verify(() => apiClient.getMangaAggregate(testMangaId)).called(1);
      });

      test(
        'fetches from network when forceRefresh is true despite fresh cache',
        () async {
          when(() => apiClient.getMangaAggregate(testMangaId))
              .thenAnswer((_) async => testAggregateResponse);

          when(
            () => cacheClient.upsertAggregate(testMangaId, const [
              'en',
              'it',
            ], any()),
          ).thenAnswer((_) async {});

          final aggregate = await repository.getMangaAggregate(
            testMangaId,
            forceRefresh: true,
          );

          expect(aggregate.mangaId, equals(testMangaId));
          verify(() => apiClient.getMangaAggregate(testMangaId)).called(1);
        },
      );

      test('falls back to stale cache on network failure', () async {
        final staleJson = jsonEncode(testAggregateResponse.toJson());

        when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
            .thenAnswer(
              (_) async => CacheEntry<String>(
                payloadJson: staleJson,
                updatedAt: DateTime.now()
                    .subtract(const Duration(hours: 3))
                    .toUtc(),
                isExpired: true,
              ),
            );

        when(() => apiClient.getMangaAggregate(testMangaId))
            .thenThrow(const MangaDexNetworkException('Network down'));

        final aggregate = await repository.getMangaAggregate(testMangaId);

        expect(aggregate.mangaId, equals(testMangaId));
        expect(aggregate.volumes.length, equals(1));
      });

      test(
        'throws mapped exception when network fails and no stale cache exists',
        () async {
          when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
              .thenAnswer((_) async => null);

          when(() => apiClient.getMangaAggregate(testMangaId))
              .thenThrow(const MangaDexNetworkException('Network down'));

          expect(
            () => repository.getMangaAggregate(testMangaId),
            throwsA(isA<MangaNetworkException>()),
          );
        },
      );

      test('does not fall back to stale cache on 404 not found', () async {
        final staleJson = jsonEncode(testAggregateResponse.toJson());

        when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
            .thenAnswer(
              (_) async => CacheEntry<String>(
                payloadJson: staleJson,
                updatedAt: DateTime.now()
                    .subtract(const Duration(hours: 3))
                    .toUtc(),
                isExpired: true,
              ),
            );

        when(() => apiClient.getMangaAggregate(testMangaId))
            .thenThrow(const MangaDexNotFoundException('Aggregate not found'));

        expect(
          () => repository.getMangaAggregate(testMangaId),
          throwsA(isA<MangaNotFoundException>()),
        );
      });

      test(
        'proceeds to network fetch when initial cache read throws',
        () async {
          when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
              .thenThrow(Exception('DB locked'));

          when(() => apiClient.getMangaAggregate(testMangaId))
              .thenAnswer((_) async => testAggregateResponse);

          when(
            () => cacheClient.upsertAggregate(testMangaId, const [
              'en',
              'it',
            ], any()),
          ).thenAnswer((_) async {});

          final aggregate = await repository.getMangaAggregate(testMangaId);

          expect(aggregate.mangaId, equals(testMangaId));
        },
      );

      test(
        'throws MangaParseException when cache payload is not a JSON map',
        () async {
          when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
              .thenAnswer(
                (_) async => CacheEntry<String>(
                  payloadJson: '"just a string"',
                  updatedAt: DateTime.now().toUtc(),
                  isExpired: false,
                ),
              );

          expect(
            () => repository.getMangaAggregate(testMangaId),
            throwsA(isA<MangaParseException>()),
          );
        },
      );

      test(
        'throws MangaParseException when aggregate cache has malformed JSON',
        () async {
          when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
              .thenAnswer(
                (_) async => CacheEntry<String>(
                  payloadJson: '{malformed',
                  updatedAt: DateTime.now().toUtc(),
                  isExpired: false,
                ),
              );

          expect(
            () => repository.getMangaAggregate(testMangaId),
            throwsA(isA<MangaParseException>()),
          );
        },
      );
    });

    group('computePreviousUnreadChapters', () {
      test('delegates cleanly to aggregate implementation', () {
        const aggregate = ChapterAggregate(
          mangaId: 'm1',
          orderedChapters: [
            MangaChapter(chapterNumber: '1', id: 'c1'),
            MangaChapter(chapterNumber: '2', id: 'c2'),
            MangaChapter(chapterNumber: '3', id: 'c3'),
          ],
        );

        final unread = repository.computePreviousUnreadChapters(
          aggregate: aggregate,
          upToChapterNumber: '2',
          alreadyReadChapters: {'1'},
        );

        expect(unread, equals(['2']));
      });
    });

    group('invalidateAggregateCache', () {
      test('calls cacheClient.invalidateAggregate', () async {
        when(() => cacheClient.invalidateAggregate(testMangaId))
            .thenAnswer((_) async => 1);

        await repository.invalidateAggregateCache(testMangaId);

        verify(() => cacheClient.invalidateAggregate(testMangaId)).called(1);
      });

      test('maps and rethrows exception when cacheClient throws', () async {
        when(() => cacheClient.invalidateAggregate(testMangaId))
            .thenThrow(const FormatException('Bad state'));

        expect(
          () => repository.invalidateAggregateCache(testMangaId),
          throwsA(isA<MangaParseException>()),
        );
      });
    });

    group('_mapException coverage', () {
      test('maps MangaRateLimitException and preserves header', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId)).thenThrow(
          const MangaDexRateLimitException(
            'Rate limit exceeded',
            retryAfterHeader: '2.5',
          ),
        );

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(
            isA<MangaRateLimitException>().having(
              (e) => e.retryAfterHeader,
              'retryAfterHeader',
              '2.5',
            ),
          ),
        );
      });

      test('maps MangaValidationException', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId))
            .thenThrow(const MangaDexValidationException('Invalid id format'));

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(isA<MangaValidationException>()),
        );
      });

      test('maps MangaServerException', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId)).thenThrow(
          const MangaDexServerException('Bad Gateway', statusCode: 502),
        );

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(
            isA<MangaServerException>().having(
              (e) => e.statusCode,
              'statusCode',
              502,
            ),
          ),
        );
      });

      test('maps MangaDexParseException', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId))
            .thenThrow(const MangaDexParseException('Corrupt payload'));

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(isA<MangaParseException>()),
        );
      });

      test('maps unknown MangaDexApiException', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId)).thenThrow(
          const MangaDexUnknownException('Weird error', statusCode: 418),
        );

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(isA<MangaUnknownException>()),
        );
      });

      test('maps FormatException to MangaParseException', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(() => apiClient.getMangaById(testMangaId))
            .thenThrow(const FormatException('Bad character'));

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(isA<MangaParseException>()),
        );
      });

      test('re-throws existing MangaRepositoryException as is', () async {
        when(() => cacheClient.getManga(testMangaId))
            .thenAnswer((_) async => null);
        when(
          () => apiClient.getMangaById(testMangaId),
        ).thenThrow(const MangaNotFoundException('Already custom exception'));

        expect(
          () => repository.getMangaDetails(testMangaId),
          throwsA(isA<MangaNotFoundException>()),
        );
      });

      test(
        'maps unclassified generic error to MangaUnknownException',
        () async {
          when(() => cacheClient.getManga(testMangaId))
              .thenAnswer((_) async => null);
          when(() => apiClient.getMangaById(testMangaId))
              .thenThrow('A plain string error');

          expect(
            () => repository.getMangaDetails(testMangaId),
            throwsA(isA<MangaUnknownException>()),
          );
        },
      );
    });

    group('official release feed & fallback merging', () {
      test(
        'merges all-language fallback and official RSS chapters cleanly',
        () async {
          final feedService = _MockOfficialReleaseFeedService();
          final repoWithFeed = MangaRepository(
            apiClient: apiClient,
            cacheClient: cacheClient,
            officialFeedService: feedService,
          );

          const ragMangaData = MangaData(
            id: testMangaId,
            attributes: MangaAttributes(
              title: {'en': 'Rent-A-Girlfriend'},
              links: {'raw': 'https://pocket.shonenmagazine.com/ep/1'},
            ),
          );

          when(() => cacheClient.getManga(testMangaId))
              .thenAnswer((_) async => null);
          when(() => apiClient.getMangaById(testMangaId))
              .thenAnswer((_) async => const MangaResponse(data: ragMangaData));
          when(() => cacheClient.upsertManga(testMangaId, any()))
              .thenAnswer((_) async {});
          when(() => cacheClient.getAggregate(testMangaId, const ['en', 'it']))
              .thenAnswer((_) async => null);
          when(() => apiClient.getMangaAggregate(testMangaId)).thenAnswer(
            (_) async => const AggregateResponse(
              volumes: {
                '1': AggregateVolume(
                  volume: '1',
                  count: 1,
                  chapters: {
                    '1': AggregateChapter(chapter: '1', id: 'en-ch-1'),
                  },
                ),
              },
            ),
          );
          when(
            () => apiClient.getMangaAggregate(
              testMangaId,
              translatedLanguage: null,
            ),
          ).thenAnswer(
            (_) async => const AggregateResponse(
              volumes: {
                '47': AggregateVolume(
                  volume: '47',
                  count: 1,
                  chapters: {
                    '418': AggregateChapter(chapter: '418', id: 'id-ch-418'),
                  },
                ),
              },
            ),
          );
          when(
            () => feedService.fetchChaptersFromRawUrl(
              'https://pocket.shonenmagazine.com/ep/1',
            ),
          ).thenAnswer(
            (_) async => const [
              OfficialFeedChapter(
                chapterNumber: '449',
                id: 'ext:449',
                externalUrl: 'https://pocket.shonenmagazine.com/ep/449',
              ),
              OfficialFeedChapter(
                chapterNumber: '418',
                id: 'ext:418',
                externalUrl: 'https://pocket.shonenmagazine.com/ep/418',
              ),
            ],
          );
          when(
            () => cacheClient.upsertAggregate(testMangaId, const [
              'en',
              'it',
            ], any()),
          ).thenAnswer((_) async {});

          final latest = await repoWithFeed.getLatestReleasedChapter(
            testMangaId,
          );
          expect(latest, isNotNull);
          expect(latest!.chapterNumber, equals('449'));
          expect(latest.id, equals('ext:449'));
          expect(
            latest.externalUrl,
            equals('https://pocket.shonenmagazine.com/ep/449'),
          );
        },
      );
    });
  });
}
