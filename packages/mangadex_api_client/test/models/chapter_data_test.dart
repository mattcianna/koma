import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterData and ChapterFeedResponse', () {
    test('deserializes ChapterAttributes with empty string conversion', () {
      final json = <String, dynamic>{
        'volume': '',
        'chapter': '1198',
        'title': 'The Adventure Continues',
        'translatedLanguage': 'en',
        'externalUrl': 'https://mangaplus.shueisha.co.jp/viewer/1030906',
        'publishAt': '2026-11-08T00:00:00+00:00',
        'readableAt': '2026-11-08T00:00:00+00:00',
        'createdAt': '2026-11-08T00:00:00+00:00',
        'updatedAt': '2026-11-08T00:00:00+00:00',
        'pages': 0,
        'version': 1,
      };

      final attrs = ChapterAttributes.fromJson(json);

      expect(attrs.volume, isNull);
      expect(attrs.chapter, equals('1198'));
      expect(attrs.title, equals('The Adventure Continues'));
      expect(attrs.translatedLanguage, equals('en'));
      expect(attrs.externalUrl, contains('mangaplus'));
      expect(attrs.pages, equals(0));
      expect(attrs.publishAt, isNotNull);
      expect(attrs.publishAt!.year, equals(2026));
      expect(attrs.version, equals(1));
    });

    test('deserializes ChapterFeedResponse and supports Equatable', () {
      final json = <String, dynamic>{
        'result': 'ok',
        'response': 'collection',
        'data': [
          {
            'id': 'chapter-001',
            'type': 'chapter',
            'attributes': {
              'chapter': '1',
              'translatedLanguage': 'it',
              'pages': 20,
            },
          },
        ],
        'limit': 100,
        'offset': 0,
        'total': 1,
      };

      final response = ChapterFeedResponse.fromJson(json);

      expect(response.result, equals('ok'));
      expect(response.total, equals(1));
      expect(response.data, hasLength(1));
      expect(response.data.first.id, equals('chapter-001'));
      expect(response.data.first.attributes.chapter, equals('1'));
      expect(response.data.first.attributes.pages, equals(20));

      final serialized = response.toJson();
      expect(serialized['total'], equals(1));
      expect(serialized['data'], isNotEmpty);

      final response2 = ChapterFeedResponse.fromJson(json);
      expect(response, equals(response2));
    });

    test('ChapterAttributes and ChapterData support Equatable and toJson', () {
      final now = DateTime.utc(2026, 11, 13);
      final attrs1 = ChapterAttributes(
        volume: '1',
        chapter: '1',
        title: 'Title',
        translatedLanguage: 'en',
        externalUrl: 'https://...',
        publishAt: now,
        readableAt: now,
        createdAt: now,
        updatedAt: now,
        pages: 20,
        version: 1,
      );
      final attrs2 = ChapterAttributes(
        volume: '1',
        chapter: '1',
        title: 'Title',
        translatedLanguage: 'en',
        externalUrl: 'https://...',
        publishAt: now,
        readableAt: now,
        createdAt: now,
        updatedAt: now,
        pages: 20,
        version: 1,
      );

      expect(attrs1, equals(attrs2));
      expect(attrs1.toJson()['chapter'], equals('1'));

      final data1 = ChapterData(
        id: 'c1',
        attributes: attrs1,
        relationships: const [
          RelationshipData(id: 'r1', type: 'scanlation_group'),
        ],
      );
      final data2 = ChapterData(
        id: 'c1',
        attributes: attrs2,
        relationships: const [
          RelationshipData(id: 'r1', type: 'scanlation_group'),
        ],
      );

      expect(data1, equals(data2));
      expect(data1.toJson()['id'], equals('c1'));
    });
  });
}
