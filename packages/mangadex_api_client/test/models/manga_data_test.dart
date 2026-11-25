import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaData and MangaAttributes', () {
    test(
      'deserializes MangaAttributes handling empty string to null conversion',
      () {
        final json = <String, dynamic>{
          'title': {'ja-ro': 'One Piece'},
          'altTitles': [
            {'en': 'One Piece'},
          ],
          'description': <dynamic>[], // PHP empty array quirk
          'lastVolume': '', // empty string ongoing quirk
          'lastChapter': '  ',
          'status': 'ongoing',
          'year': 1997,
        };

        final attrs = MangaAttributes.fromJson(json);

        expect(attrs.title['ja-ro'], equals('One Piece'));
        expect(attrs.altTitles, hasLength(1));
        expect(attrs.description, isEmpty);
        expect(attrs.links, isEmpty);
        expect(attrs.lastVolume, isNull);
        expect(attrs.lastChapter, isNull);
        expect(attrs.status, equals('ongoing'));
        expect(attrs.year, equals(1997));
      },
    );

    test('parses links map and handles PHP empty array quirk on links', () {
      final mapAttrs = MangaAttributes.fromJson(const <String, dynamic>{
        'title': {'en': 'Rent-A-Girlfriend'},
        'links': {
          'raw': 'https://pocket.shonenmagazine.com/episode/1',
          'engtl': 'https://comics.inkr.com/title/2254',
        },
      });
      expect(
        mapAttrs.links['raw'],
        equals('https://pocket.shonenmagazine.com/episode/1'),
      );
      expect(
        mapAttrs.links['engtl'],
        equals('https://comics.inkr.com/title/2254'),
      );

      final emptyLinksAttrs = MangaAttributes.fromJson(const <String, dynamic>{
        'title': {'en': 'Test'},
        'links': <dynamic>[],
      });
      expect(emptyLinksAttrs.links, isEmpty);
    });

    test('retains non-empty lastVolume and lastChapter', () {
      final json = <String, dynamic>{
        'title': {'en': 'Dungeon Meshi'},
        'lastVolume': '14',
        'lastChapter': '97',
      };

      final attrs = MangaAttributes.fromJson(json);
      expect(attrs.lastVolume, equals('14'));
      expect(attrs.lastChapter, equals('97'));
    });

    test(
      'extracts coverFileName, authorName, and artistName from relationships',
      () {
        final json = <String, dynamic>{
          'id': 'manga-001',
          'type': 'manga',
          'attributes': {
            'title': {'en': 'Test Manga'},
          },
          'relationships': [
            {
              'id': 'rel-author',
              'type': 'author',
              'attributes': {'name': 'Eiichiro Oda'},
            },
            {
              'id': 'rel-artist',
              'type': 'artist',
              'attributes': {'name': 'Oda Sensei'},
            },
            {
              'id': 'rel-cover',
              'type': 'cover_art',
              'attributes': {'fileName': 'cover.256.jpg'},
            },
          ],
        };

        final manga = MangaData.fromJson(json);

        expect(manga.id, equals('manga-001'));
        expect(manga.authorName, equals('Eiichiro Oda'));
        expect(manga.artistName, equals('Oda Sensei'));
        expect(manga.coverFileName, equals('cover.256.jpg'));
      },
    );

    test('safely handles missing or unexpanded relationships', () {
      const manga = MangaData(
        id: 'manga-002',
        attributes: MangaAttributes(),
        relationships: [
          RelationshipData(id: 'rel-1', type: 'artist'),
          RelationshipData(id: 'rel-2', type: 'author'),
          RelationshipData(id: 'rel-3', type: 'cover_art'),
        ],
      );

      expect(manga.coverFileName, isNull);
      expect(manga.authorName, isNull);
      expect(manga.artistName, isNull);
    });

    test('deserializes MangaResponse and MangaListResponse', () {
      final mangaJson = <String, dynamic>{
        'id': 'manga-001',
        'type': 'manga',
        'attributes': {
          'title': {'en': 'Test'},
        },
      };

      final entityResponse = MangaResponse.fromJson({
        'result': 'ok',
        'response': 'entity',
        'data': mangaJson,
      });

      expect(entityResponse.result, equals('ok'));
      expect(entityResponse.data.id, equals('manga-001'));

      final collectionResponse = MangaListResponse.fromJson({
        'result': 'ok',
        'response': 'collection',
        'data': [mangaJson],
        'limit': 20,
        'offset': 0,
        'total': 1,
      });

      expect(collectionResponse.total, equals(1));
      expect(collectionResponse.data, hasLength(1));
      expect(collectionResponse.toJson()['total'], equals(1));
      expect(entityResponse.toJson()['result'], equals('ok'));

      final entityResponse2 = MangaResponse.fromJson({
        'result': 'ok',
        'response': 'entity',
        'data': mangaJson,
      });
      expect(entityResponse, equals(entityResponse2));

      final collectionResponse2 = MangaListResponse.fromJson({
        'result': 'ok',
        'response': 'collection',
        'data': [mangaJson],
        'limit': 20,
        'offset': 0,
        'total': 1,
      });
      expect(collectionResponse, equals(collectionResponse2));
    });

    test('MangaAttributes and MangaData support full Equatable and toJson', () {
      const attrs1 = MangaAttributes(
        title: {'en': 'Title'},
        altTitles: [
          {'ja': 'Alt'},
        ],
        description: {'en': 'Desc'},
        isLocked: false,
        originalLanguage: 'ja',
        lastVolume: '1',
        lastChapter: '10',
        publicationDemographic: 'shounen',
        status: 'completed',
        year: 2020,
        contentRating: 'safe',
        availableTranslatedLanguages: ['en', 'it'],
      );
      const attrs2 = MangaAttributes(
        title: {'en': 'Title'},
        altTitles: [
          {'ja': 'Alt'},
        ],
        description: {'en': 'Desc'},
        isLocked: false,
        originalLanguage: 'ja',
        lastVolume: '1',
        lastChapter: '10',
        publicationDemographic: 'shounen',
        status: 'completed',
        year: 2020,
        contentRating: 'safe',
        availableTranslatedLanguages: ['en', 'it'],
      );

      expect(attrs1, equals(attrs2));
      expect(attrs1.toJson()['year'], equals(2020));

      const manga1 = MangaData(
        id: 'm1',
        attributes: attrs1,
        relationships: [RelationshipData(id: 'r1', type: 'author')],
      );
      const manga2 = MangaData(
        id: 'm1',
        attributes: attrs2,
        relationships: [RelationshipData(id: 'r1', type: 'author')],
      );
      expect(manga1, equals(manga2));
      expect(manga1.toJson()['id'], equals('m1'));
    });
  });
}
