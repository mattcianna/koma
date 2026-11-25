import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/search/bloc/search_state.dart';
import 'package:manga_repository/manga_repository.dart';

void main() {
  group('SearchState', () {
    test('supports value equality', () {
      expect(const SearchState(), equals(const SearchState()));
    });

    test('has expected default values', () {
      const state = SearchState();
      expect(state.status, equals(SearchStatus.initial));
      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.offset, equals(0));
      expect(state.isLoadingMore, isFalse);
      expect(state.errorKind, isNull);
      expect(state.translatedLanguages, equals(['en', 'it']));
      expect(state.contentRatings, equals(['safe', 'suggestive']));
      expect(state.preferredLocales, equals(['en', 'it']));
      expect(state.isPopular, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);
    });

    test('computed getters evaluate correctly', () {
      expect(const SearchState(query: 'Chainsaw Man').isPopular, isFalse);
      expect(const SearchState(query: '   ').isPopular, isTrue);
      expect(const SearchState(status: SearchStatus.loading).isLoading, isTrue);
      expect(const SearchState(status: SearchStatus.success).isSuccess, isTrue);
      expect(const SearchState(status: SearchStatus.failure).isFailure, isTrue);
    });

    test('copyWith copies all properties correctly', () {
      const state = SearchState();
      const manga = Manga(id: '1', title: 'Chainsaw Man');

      final updated = state.copyWith(
        status: SearchStatus.success,
        query: 'Chainsaw',
        results: [manga],
        hasMore: true,
        offset: 20,
        isLoadingMore: true,
        errorKind: () => SearchErrorKind.rateLimit,
        translatedLanguages: ['en'],
        contentRatings: ['safe'],
        preferredLocales: ['en'],
      );

      expect(updated.status, equals(SearchStatus.success));
      expect(updated.query, equals('Chainsaw'));
      expect(updated.results, equals([manga]));
      expect(updated.hasMore, isTrue);
      expect(updated.offset, equals(20));
      expect(updated.isLoadingMore, isTrue);
      expect(updated.errorKind, equals(SearchErrorKind.rateLimit));
      expect(updated.translatedLanguages, equals(['en']));
      expect(updated.contentRatings, equals(['safe']));
      expect(updated.preferredLocales, equals(['en']));

      final cleared = updated.copyWith(errorKind: () => null);
      expect(cleared.errorKind, isNull);
    });

    test('props includes all fields', () {
      const state = SearchState(
        status: SearchStatus.failure,
        query: 'test',
        errorKind: SearchErrorKind.network,
      );
      expect(
        state.props,
        equals([
          SearchStatus.failure,
          'test',
          <Manga>[],
          false,
          0,
          false,
          SearchErrorKind.network,
          ['en', 'it'],
          ['safe', 'suggestive'],
          ['en', 'it'],
        ]),
      );
    });
  });
}
