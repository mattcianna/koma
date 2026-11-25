import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/search/bloc/search_bloc.dart';
import 'package:koma/features/search/bloc/search_event.dart';
import 'package:koma/features/search/bloc/search_state.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockMangaRepository extends Mock implements MangaRepository;

void main() {
  group('SearchBloc', () {
    late MangaRepository mangaRepository;

    const testManga1 = Manga(
      id: 'manga-1',
      title: 'Chainsaw Man',
      authorName: 'Tatsuki Fujimoto',
      coverUrl256: 'https://uploads.mangadex.org/covers/1/cover.256.jpg',
    );
    const testManga2 = Manga(
      id: 'manga-2',
      title: "Frieren: Beyond Journey's End",
      authorName: 'Kanehito Yamada',
      coverUrl256: 'https://uploads.mangadex.org/covers/2/cover.256.jpg',
    );

    setUp(() {
      mangaRepository = _MockMangaRepository();
    });

    test('initial state has default parameters', () {
      final bloc = SearchBloc(
        mangaRepository: mangaRepository,
        debounceDuration: Duration.zero,
      );
      expect(bloc.state, equals(const SearchState()));
      expect(bloc.mangaRepository, equals(mangaRepository));
    });

    group('SearchStarted', () {
      blocTest<SearchBloc, SearchState>(
        'emits [loading, success] when popular titles fetch succeeds',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenAnswer((_) async => [testManga1, testManga2]);
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        act: (bloc) => bloc.add(const SearchStarted()),
        expect: () => [
          const SearchState(status: SearchStatus.loading),
          const SearchState(
            status: SearchStatus.success,
            results: [testManga1, testManga2],
            offset: 2,
          ),
        ],
        verify: (_) {
          verify(() => mangaRepository.searchManga()).called(1);
        },
      );

      blocTest<SearchBloc, SearchState>(
        'emits [loading, failure] with rateLimit on MangaRateLimitException',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenThrow(const MangaRateLimitException('Rate limit'));
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        act: (bloc) => bloc.add(const SearchStarted()),
        expect: () => const [
          SearchState(status: SearchStatus.loading),
          SearchState(
            status: SearchStatus.failure,
            errorKind: SearchErrorKind.rateLimit,
          ),
        ],
      );

      blocTest<SearchBloc, SearchState>(
        'emits [loading, failure] with network on MangaNetworkException',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenThrow(const MangaNetworkException('No network'));
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        act: (bloc) => bloc.add(const SearchStarted()),
        expect: () => const [
          SearchState(status: SearchStatus.loading),
          SearchState(
            status: SearchStatus.failure,
            errorKind: SearchErrorKind.network,
          ),
        ],
      );

      blocTest<SearchBloc, SearchState>(
        'emits [loading, failure] with generic on generic exception',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenThrow(Exception('Server error'));
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        act: (bloc) => bloc.add(const SearchStarted()),
        expect: () => const [
          SearchState(status: SearchStatus.loading),
          SearchState(
            status: SearchStatus.failure,
            errorKind: SearchErrorKind.generic,
          ),
        ],
      );
    });

    group('SearchQueryChanged', () {
      blocTest<SearchBloc, SearchState>(
        'queries mangaRepository with trimmed query and emits success',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: 'dungeon',
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenAnswer((_) async => [testManga1]);
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        act: (bloc) => bloc.add(const SearchQueryChanged('  dungeon  ')),
        expect: () => [
          const SearchState(status: SearchStatus.loading, query: '  dungeon  '),
          const SearchState(
            status: SearchStatus.success,
            query: '  dungeon  ',
            results: [testManga1],
            offset: 1,
          ),
        ],
      );

      blocTest<SearchBloc, SearchState>(
        'does not emit when query is identical and state is already success',
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        seed: () => const SearchState(
          status: SearchStatus.success,
          query: 'berserk',
          results: [testManga1],
        ),
        act: (bloc) => bloc.add(const SearchQueryChanged('berserk')),
        expect: () => <SearchState>[],
      );
    });

    group('SearchRefreshed', () {
      blocTest<SearchBloc, SearchState>(
        'refreshes current search query from offset 0',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: 'frieren',
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenAnswer((_) async => [testManga2]);
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        seed: () => const SearchState(
          status: SearchStatus.success,
          query: 'frieren',
          results: [testManga1],
          offset: 1,
        ),
        act: (bloc) => bloc.add(const SearchRefreshed()),
        expect: () => [
          const SearchState(
            status: SearchStatus.loading,
            query: 'frieren',
            results: [testManga1],
          ),
          const SearchState(
            status: SearchStatus.success,
            query: 'frieren',
            results: [testManga2],
            offset: 1,
          ),
        ],
      );
    });

    group('SearchLoadMore', () {
      final twentyItems = List.generate(
        20,
        (i) => Manga(id: 'id_$i', title: 'Manga $i'),
      );
      final nextTenItems = List.generate(
        10,
        (i) => Manga(id: 'id_next_$i', title: 'Next Manga $i'),
      );

      blocTest<SearchBloc, SearchState>(
        'appends next page of results when hasMore is true',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              offset: 20,
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenAnswer((_) async => nextTenItems);
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        seed: () => SearchState(
          status: SearchStatus.success,
          results: twentyItems,
          hasMore: true,
          offset: 20,
        ),
        act: (bloc) => bloc.add(const SearchLoadMore()),
        expect: () => [
          SearchState(
            status: SearchStatus.success,
            results: twentyItems,
            hasMore: true,
            offset: 20,
            isLoadingMore: true,
          ),
          SearchState(
            status: SearchStatus.success,
            results: [...twentyItems, ...nextTenItems],
            offset: 30,
          ),
        ],
      );

      blocTest<SearchBloc, SearchState>(
        'does nothing if hasMore is false',
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        seed: () => SearchState(
          status: SearchStatus.success,
          results: twentyItems,
          offset: 20,
        ),
        act: (bloc) => bloc.add(const SearchLoadMore()),
        expect: () => <SearchState>[],
      );

      blocTest<SearchBloc, SearchState>(
        'handles load more error without clearing existing results',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              offset: 20,
              translatedLanguages: any(named: 'translatedLanguages'),
              contentRatings: any(named: 'contentRatings'),
              preferredLocales: any(named: 'preferredLocales'),
            ),
          ).thenThrow(Exception('Page fetch failed'));
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        seed: () => SearchState(
          status: SearchStatus.success,
          results: twentyItems,
          hasMore: true,
          offset: 20,
        ),
        act: (bloc) => bloc.add(const SearchLoadMore()),
        expect: () => [
          SearchState(
            status: SearchStatus.success,
            results: twentyItems,
            hasMore: true,
            offset: 20,
            isLoadingMore: true,
          ),
          SearchState(
            status: SearchStatus.success,
            results: twentyItems,
            hasMore: true,
            offset: 20,
          ),
        ],
      );
    });

    group('SearchPreferencesUpdated', () {
      blocTest<SearchBloc, SearchState>(
        'updates preferences and fetches again from offset 0',
        setUp: () {
          when(
            () => mangaRepository.searchManga(
              query: any(named: 'query'),
              translatedLanguages: ['ja'],
              contentRatings: ['safe'],
              preferredLocales: ['ja'],
            ),
          ).thenAnswer((_) async => [testManga1]);
        },
        build: () => SearchBloc(
          mangaRepository: mangaRepository,
          debounceDuration: Duration.zero,
        ),
        act: (bloc) => bloc.add(
          const SearchPreferencesUpdated(
            translatedLanguages: ['ja'],
            contentRatings: ['safe'],
            preferredLocales: ['ja'],
          ),
        ),
        expect: () => [
          const SearchState(
            status: SearchStatus.loading,
            translatedLanguages: ['ja'],
            contentRatings: ['safe'],
            preferredLocales: ['ja'],
          ),
          const SearchState(
            status: SearchStatus.success,
            results: [testManga1],
            offset: 1,
            translatedLanguages: ['ja'],
            contentRatings: ['safe'],
            preferredLocales: ['ja'],
          ),
        ],
      );
    });
  });
}
