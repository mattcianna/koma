import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaDexLocaleResolver', () {
    group('resolveTitle', () {
      test('resolves preferred locale from primary title map', () {
        final title = {'en': 'One Piece', 'it': 'One Piece IT'};
        final result = MangaDexLocaleResolver.resolveTitle(
          rawTitle: title,
          rawAltTitles: const [],
          preferredLocales: ['it', 'en'],
        );
        expect(result, equals('One Piece IT'));
      });

      test(
        'resolves preferred locale from altTitles when missing from title',
        () {
          // Flagship series empirical quirk: title has only "ja-ro"
          final title = {'ja-ro': 'Dungeon Meshi'};
          final altTitles = [
            {'ja': 'ダンジョン飯'},
            {'it': 'Dungeon Food'},
            {'en': 'Delicious in Dungeon'},
          ];

          final resultIt = MangaDexLocaleResolver.resolveTitle(
            rawTitle: title,
            rawAltTitles: altTitles,
            preferredLocales: ['it', 'en'],
          );
          expect(resultIt, equals('Dungeon Food'));

          final resultEn = MangaDexLocaleResolver.resolveTitle(
            rawTitle: title,
            rawAltTitles: altTitles,
            preferredLocales: ['en', 'it'],
          );
          expect(resultEn, equals('Delicious in Dungeon'));
        },
      );

      test('falls back to English in primary title then altTitles', () {
        final titleWithEn = {'en': 'English Primary'};
        expect(
          MangaDexLocaleResolver.resolveTitle(
            rawTitle: titleWithEn,
            rawAltTitles: const [],
            preferredLocales: ['de'],
          ),
          equals('English Primary'),
        );

        final title = {'fr': 'Titre Français'};
        final altTitles = [
          {'ja': '日本語'},
          {'en': 'English Title'},
        ];

        final result = MangaDexLocaleResolver.resolveTitle(
          rawTitle: title,
          rawAltTitles: altTitles,
          preferredLocales: ['de'],
        );
        expect(result, equals('English Title'));
      });

      test('falls back to romanized Japanese/Korean/Chinese', () {
        final soloLevelingTitle = {'ko-ro': 'Na Honjaman Level-Up'};
        final result = MangaDexLocaleResolver.resolveTitle(
          rawTitle: soloLevelingTitle,
          rawAltTitles: const [],
          preferredLocales: ['de'],
        );
        expect(result, equals('Na Honjaman Level-Up'));
      });

      test('falls back to first available string in title', () {
        final title = {'es': 'Título en Español'};
        final result = MangaDexLocaleResolver.resolveTitle(
          rawTitle: title,
          rawAltTitles: const [],
          preferredLocales: ['de'],
        );
        expect(result, equals('Título en Español'));
      });

      test('returns Unknown Title when maps are empty or null', () {
        expect(
          MangaDexLocaleResolver.resolveTitle(
            rawTitle: null,
            rawAltTitles: null,
          ),
          equals('Unknown Title'),
        );

        expect(
          MangaDexLocaleResolver.resolveTitle(
            rawTitle: {'en': '  '},
            rawAltTitles: [],
          ),
          equals('Unknown Title'),
        );
      });
    });

    group('resolveDescription', () {
      test('resolves preferred locale from description map', () {
        final desc = {'en': 'English summary', 'it': 'Sommario in italiano'};

        expect(
          MangaDexLocaleResolver.resolveDescription(
            rawDescription: desc,
            preferredLocales: ['it', 'en'],
          ),
          equals('Sommario in italiano'),
        );

        expect(
          MangaDexLocaleResolver.resolveDescription(
            rawDescription: desc,
            preferredLocales: ['en'],
          ),
          equals('English summary'),
        );
      });

      test('falls back to English when preferred language is absent', () {
        final desc = {
          'en': 'English description',
          'fr': 'Description en français',
        };

        expect(
          MangaDexLocaleResolver.resolveDescription(
            rawDescription: desc,
            preferredLocales: ['de', 'it'],
          ),
          equals('English description'),
        );
      });

      test('safely handles MangaDex PHP empty array [] quirk', () {
        expect(
          MangaDexLocaleResolver.resolveDescription(
            rawDescription: const <dynamic>[],
          ),
          isNull,
        );

        expect(
          MangaDexLocaleResolver.resolveDescription(rawDescription: null),
          isNull,
        );
      });

      test('falls back to any available language in description', () {
        final desc = {'ja': '日本語の説明'};

        expect(
          MangaDexLocaleResolver.resolveDescription(
            rawDescription: desc,
            preferredLocales: ['it', 'es'],
          ),
          equals('日本語の説明'),
        );
      });

      test('returns null when description values are blank', () {
        expect(
          MangaDexLocaleResolver.resolveDescription(
            rawDescription: {'ja': '  '},
          ),
          isNull,
        );
      });
    });

    group('extractCoverFileName', () {
      test('extracts fileName from expanded cover_art relationship', () {
        final relationships = [
          {
            'id': 'author-1',
            'type': 'author',
            'attributes': {'name': 'Oda Eiichirou'},
          },
          {
            'id': 'cover-1',
            'type': 'cover_art',
            'attributes': {'fileName': 'cover_001.jpg'},
          },
        ];

        final fileName = MangaDexLocaleResolver.extractCoverFileName(
          relationships,
        );
        expect(fileName, equals('cover_001.jpg'));
      });

      test('safely handles unexpanded relationships with null attributes', () {
        final relationships = [
          {'id': 'artist-1', 'type': 'artist'},
          {'id': 'manga-spin-off', 'type': 'manga', 'related': 'spin_off'},
          {'id': 'cover-1', 'type': 'cover_art'}, // unexpanded
        ];

        final fileName = MangaDexLocaleResolver.extractCoverFileName(
          relationships,
        );
        expect(fileName, isNull);
      });

      test('returns null when input is not a list or empty', () {
        expect(MangaDexLocaleResolver.extractCoverFileName(null), isNull);
        expect(MangaDexLocaleResolver.extractCoverFileName('invalid'), isNull);
        expect(MangaDexLocaleResolver.extractCoverFileName(const []), isNull);
      });
    });
  });
}
