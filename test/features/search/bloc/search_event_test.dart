import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/search/bloc/search_event.dart';

void main() {
  group('SearchEvent', () {
    test('SearchStarted supports value equality', () {
      expect(const SearchStarted(), equals(const SearchStarted()));
      expect(const SearchStarted().props, isEmpty);
    });

    test('SearchQueryChanged supports value equality', () {
      expect(
        const SearchQueryChanged('frieren'),
        equals(const SearchQueryChanged('frieren')),
      );
      expect(const SearchQueryChanged('frieren').props, equals(['frieren']));
    });

    test('SearchRefreshed supports value equality', () {
      expect(const SearchRefreshed(), equals(const SearchRefreshed()));
      expect(const SearchRefreshed().props, isEmpty);
    });

    test('SearchLoadMore supports value equality', () {
      expect(const SearchLoadMore(), equals(const SearchLoadMore()));
      expect(const SearchLoadMore().props, isEmpty);
    });

    test('SearchPreferencesUpdated supports value equality', () {
      expect(
        const SearchPreferencesUpdated(
          translatedLanguages: ['en'],
          contentRatings: ['safe'],
          preferredLocales: ['en'],
        ),
        equals(
          const SearchPreferencesUpdated(
            translatedLanguages: ['en'],
            contentRatings: ['safe'],
            preferredLocales: ['en'],
          ),
        ),
      );
      expect(
        const SearchPreferencesUpdated(translatedLanguages: ['en']).props,
        equals([
          ['en'],
          null,
          null,
        ]),
      );
    });
  });
}
