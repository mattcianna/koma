import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('Manga', () {
    test('supports value equality', () {
      const manga1 = Manga(id: 'm1', title: 'Chainsaw Man');
      const manga2 = Manga(id: 'm1', title: 'Chainsaw Man');
      const manga3 = Manga(id: 'm2', title: 'Frieren');

      expect(manga1, equals(manga2));
      expect(manga1, isNot(equals(manga3)));
    });

    test(
      'fromMangaData resolves title, description, author, and cover URLs',
      () {
        const data = MangaData(
          id: 'm-frieren',
          attributes: MangaAttributes(
            title: {'ja-ro': 'Sousou no Frieren'},
            altTitles: [
              {'en': "Frieren: Beyond Journey's End"},
              {'it': 'Frieren: Oltre la Fine del Viaggio'},
            ],
            description: {
              'en': 'The adventure is over but life goes on for an elf mage.',
              'it': "L'avventura è finita per la maga elfa.",
            },
            status: 'ongoing',
            contentRating: 'safe',
            lastVolume: '13',
            lastChapter: '130',
            availableTranslatedLanguages: ['en', 'it'],
          ),
          relationships: [
            RelationshipData(
              id: 'auth-1',
              type: 'author',
              attributes: {'name': 'Yamada Kanehito'},
            ),
            RelationshipData(
              id: 'cover-1',
              type: 'cover_art',
              attributes: {'fileName': 'frieren_cover.jpg'},
            ),
          ],
        );

        final mangaIt = Manga.fromMangaData(
          data,
          preferredLocales: const ['it', 'en'],
        );

        expect(mangaIt.id, equals('m-frieren'));
        expect(mangaIt.title, equals('Frieren: Oltre la Fine del Viaggio'));
        expect(
          mangaIt.description,
          equals("L'avventura è finita per la maga elfa."),
        );
        expect(mangaIt.authorName, equals('Yamada Kanehito'));
        expect(mangaIt.coverFileName, equals('frieren_cover.jpg'));
        expect(
          mangaIt.coverUrl256,
          equals(
            'https://uploads.mangadex.org/covers/m-frieren/frieren_cover.jpg.256.jpg',
          ),
        );
        expect(
          mangaIt.coverUrl512,
          equals(
            'https://uploads.mangadex.org/covers/m-frieren/frieren_cover.jpg.512.jpg',
          ),
        );
        expect(
          mangaIt.coverUrlOriginal,
          equals(
            'https://uploads.mangadex.org/covers/m-frieren/frieren_cover.jpg',
          ),
        );
        expect(mangaIt.status, equals('ongoing'));
        expect(mangaIt.contentRating, equals('safe'));
        expect(mangaIt.lastVolume, equals('13'));
        expect(mangaIt.lastChapter, equals('130'));
        expect(mangaIt.availableTranslatedLanguages, equals(['en', 'it']));

        final mangaJa = Manga.fromMangaData(
          data,
          preferredLocales: const ['ja-ro'],
        );
        expect(mangaJa.title, equals('Sousou no Frieren'));
      },
    );

    test('fromMangaData handles missing covers and author gracefully', () {
      const data = MangaData(
        id: 'm-simple',
        attributes: MangaAttributes(title: {'en': 'Simple Manga'}),
      );

      final manga = Manga.fromMangaData(data);

      expect(manga.title, equals('Simple Manga'));
      expect(manga.authorName, isNull);
      expect(manga.coverFileName, isNull);
      expect(manga.coverUrl256, isNull);
      expect(manga.coverUrl512, isNull);
      expect(manga.coverUrlOriginal, isNull);
    });

    test('toJson and fromJson roundtrip correctly', () {
      const manga = Manga(
        id: 'm-full',
        title: 'Full Title',
        description: 'Description text',
        authorName: 'Author Name',
        coverFileName: 'cover.jpg',
        coverUrl256: 'https://cdn/256.jpg',
        coverUrl512: 'https://cdn/512.jpg',
        coverUrlOriginal: 'https://cdn/orig.jpg',
        status: 'completed',
        contentRating: 'suggestive',
        lastVolume: '5',
        lastChapter: '50',
        availableTranslatedLanguages: ['en'],
      );

      final json = manga.toJson();
      final reconstructed = Manga.fromJson(json);

      expect(reconstructed, equals(manga));
    });

    test('fromJson transparently deserializes raw MangaData JSON', () {
      final rawJson = <String, dynamic>{
        'id': 'm-raw',
        'type': 'manga',
        'attributes': {
          'title': {'en': 'Raw Manga Title'},
          'description': {'en': 'Raw Desc'},
          'status': 'ongoing',
        },
      };

      final manga = Manga.fromJson(rawJson);

      expect(manga.id, equals('m-raw'));
      expect(manga.title, equals('Raw Manga Title'));
      expect(manga.description, equals('Raw Desc'));
      expect(manga.status, equals('ongoing'));
    });

    test('copyWith creates copy with updated fields', () {
      const original = Manga(
        id: 'orig-id',
        title: 'Orig Title',
        description: 'Orig Desc',
      );

      final updated = original.copyWith(
        id: 'new-id',
        title: 'New Title',
        description: 'New Desc',
        authorName: 'New Author',
        coverFileName: 'new_cover.jpg',
        coverUrl256: 'url256',
        coverUrl512: 'url512',
        coverUrlOriginal: 'urlOrig',
        status: 'completed',
        contentRating: 'safe',
        lastVolume: '10',
        lastChapter: '100',
        availableTranslatedLanguages: ['en', 'it'],
      );

      expect(updated.id, equals('new-id'));
      expect(updated.title, equals('New Title'));
      expect(updated.description, equals('New Desc'));
      expect(updated.authorName, equals('New Author'));
      expect(updated.status, equals('completed'));
      expect(updated.availableTranslatedLanguages, equals(['en', 'it']));
    });

    test('copyWith with no arguments preserves all original fields', () {
      const original = Manga(
        id: 'orig-id',
        title: 'Orig Title',
        description: 'Orig Desc',
        authorName: 'Orig Author',
        coverFileName: 'cover.jpg',
        coverUrl256: 'u256',
        coverUrl512: 'u512',
        coverUrlOriginal: 'uOrig',
        status: 'ongoing',
        contentRating: 'safe',
        lastVolume: '1',
        lastChapter: '10',
        availableTranslatedLanguages: ['en'],
      );

      expect(original.copyWith(), equals(original));
    });
  });
}
