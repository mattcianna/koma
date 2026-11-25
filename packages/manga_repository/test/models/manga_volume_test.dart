import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaVolume', () {
    test('supports value equality', () {
      const vol1 = MangaVolume(
        volumeNumber: '1',
        count: 5,
        chapters: [MangaChapter(chapterNumber: '1', id: 'c1')],
      );
      const vol2 = MangaVolume(
        volumeNumber: '1',
        count: 5,
        chapters: [MangaChapter(chapterNumber: '1', id: 'c1')],
      );
      const vol3 = MangaVolume(volumeNumber: '2', count: 5);

      expect(vol1, equals(vol2));
      expect(vol1, isNot(equals(vol3)));
    });

    test('fromAggregateVolume naturally sorts chapters', () {
      const aggVol = AggregateVolume(
        volume: '1',
        count: 4,
        chapters: {
          '10': AggregateChapter(chapter: '10', id: 'id-10'),
          '2': AggregateChapter(chapter: '2', id: 'id-2'),
          '1': AggregateChapter(chapter: '1', id: 'id-1'),
          'none': AggregateChapter(chapter: 'none', id: 'id-none'),
        },
      );

      final domain = MangaVolume.fromAggregateVolume(aggVol);

      expect(domain.volumeNumber, equals('1'));
      expect(domain.count, equals(4));
      expect(
        domain.chapters.map((c) => c.chapterNumber).toList(),
        equals(['1', '2', '10', 'none']),
      );
    });

    test('toJson and fromJson roundtrip with list of chapters', () {
      const vol = MangaVolume(
        volumeNumber: '3',
        count: 2,
        chapters: [
          MangaChapter(chapterNumber: '11', id: 'c11'),
          MangaChapter(chapterNumber: '12', id: 'c12'),
        ],
      );

      final json = vol.toJson();
      final reconstructed = MangaVolume.fromJson(json);

      expect(reconstructed, equals(vol));
    });

    test('fromJson handles map-based chapters and legacy keys', () {
      final json = <String, dynamic>{
        'volume': '2',
        'count': 3,
        'chapters': {
          '10': {'chapterNumber': '10', 'id': 'c10'},
          '5': {'chapterNumber': '5', 'id': 'c5'},
          '10.5': {'chapterNumber': '10.5', 'id': 'c10.5'},
        },
      };

      final vol = MangaVolume.fromJson(json);

      expect(vol.volumeNumber, equals('2'));
      expect(vol.count, equals(3));
      expect(
        vol.chapters.map((c) => c.chapterNumber).toList(),
        equals(['5', '10', '10.5']),
      );
    });

    test('fromJson handles null or missing chapters', () {
      final json = <String, dynamic>{'volumeNumber': 'none'};

      final vol = MangaVolume.fromJson(json);

      expect(vol.volumeNumber, equals('none'));
      expect(vol.count, equals(0));
      expect(vol.chapters, isEmpty);
    });
  });
}
