import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('AggregateData models', () {
    test('AggregateChapter supports fromJson, toJson, and allChapterIds', () {
      final json = <String, dynamic>{
        'chapter': '10.5',
        'id': 'main-id',
        'others': ['alt-id-1', 'alt-id-2'],
        'count': 3,
        'isUnavailable': true,
      };

      final chapter = AggregateChapter.fromJson(json);

      expect(chapter.chapter, equals('10.5'));
      expect(chapter.id, equals('main-id'));
      expect(chapter.others, equals(['alt-id-1', 'alt-id-2']));
      expect(chapter.count, equals(3));
      expect(chapter.isUnavailable, isTrue);
      expect(
        chapter.allChapterIds,
        equals(['main-id', 'alt-id-1', 'alt-id-2']),
      );

      final serialized = chapter.toJson();
      expect(serialized['chapter'], equals('10.5'));
      expect(serialized['isUnavailable'], isTrue);
    });

    test('AggregateVolume supports fromJson and toJson', () {
      final json = <String, dynamic>{
        'volume': '2',
        'count': 1,
        'chapters': {
          '5': {
            'chapter': '5',
            'id': 'ch-5-id',
            'others': <dynamic>[],
            'count': 1,
            'isUnavailable': false,
          },
        },
      };

      final volume = AggregateVolume.fromJson(json);

      expect(volume.volume, equals('2'));
      expect(volume.count, equals(1));
      expect(volume.chapters.containsKey('5'), isTrue);

      final serialized = volume.toJson();
      expect(serialized['volume'], equals('2'));
      expect(serialized['chapters'], isNotEmpty);
    });
  });
}
