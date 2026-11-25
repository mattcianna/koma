import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterAggregate', () {
    test('supports value equality', () {
      const agg1 = ChapterAggregate(
        mangaId: 'm1',
        volumes: [MangaVolume(volumeNumber: '1', count: 1)],
      );
      const agg2 = ChapterAggregate(
        mangaId: 'm1',
        volumes: [MangaVolume(volumeNumber: '1', count: 1)],
      );
      const agg3 = ChapterAggregate(mangaId: 'm2');

      expect(agg1, equals(agg2));
      expect(agg1, isNot(equals(agg3)));
    });

    test('fromAggregateResponse sorts volumes with "none" last', () {
      const response = AggregateResponse(
        volumes: {
          'none': AggregateVolume(
            volume: 'none',
            count: 1,
            chapters: {'none': AggregateChapter(chapter: 'none', id: 'c-none')},
          ),
          '10': AggregateVolume(
            volume: '10',
            count: 2,
            chapters: {
              '100': AggregateChapter(chapter: '100', id: 'c-100'),
              '99': AggregateChapter(chapter: '99', id: 'c-99'),
            },
          ),
          '1': AggregateVolume(
            volume: '1',
            count: 2,
            chapters: {
              '2': AggregateChapter(chapter: '2', id: 'c-2'),
              '1': AggregateChapter(chapter: '1', id: 'c-1'),
            },
          ),
        },
      );

      final agg = ChapterAggregate.fromAggregateResponse('manga-1', response);

      expect(agg.mangaId, equals('manga-1'));
      expect(
        agg.volumes.map((v) => v.volumeNumber).toList(),
        equals(['1', '10', 'none']),
      );
      expect(
        agg.orderedChapters.map((c) => c.chapterNumber).toList(),
        equals(['1', '2', '99', '100', 'none']),
      );
    });

    test('fromAggregateResponse deduplicates chapters across volumes', () {
      const response = AggregateResponse(
        volumes: {
          '1': AggregateVolume(
            volume: '1',
            count: 1,
            chapters: {'1': AggregateChapter(chapter: '1', id: 'c1-v1')},
          ),
          'none': AggregateVolume(
            volume: 'none',
            count: 1,
            chapters: {'1': AggregateChapter(chapter: '1', id: 'c1-none')},
          ),
        },
      );

      final agg = ChapterAggregate.fromAggregateResponse('manga-dup', response);

      expect(agg.orderedChapters.length, equals(1));
      expect(agg.orderedChapters.first.id, equals('c1-v1'));
    });

    test('toJson and fromJson roundtrip with domain structure', () {
      const agg = ChapterAggregate(
        mangaId: 'm1',
        volumes: [
          MangaVolume(
            volumeNumber: '2',
            count: 1,
            chapters: [MangaChapter(chapterNumber: '2', id: 'c2')],
          ),
          MangaVolume(
            volumeNumber: '1',
            count: 1,
            chapters: [MangaChapter(chapterNumber: '1', id: 'c1')],
          ),
        ],
        orderedChapters: [
          MangaChapter(chapterNumber: '2', id: 'c2'),
          MangaChapter(chapterNumber: '1', id: 'c1'),
        ],
      );

      final json = agg.toJson();
      final reconstructed = ChapterAggregate.fromJson(json);

      expect(reconstructed.mangaId, equals(agg.mangaId));
      expect(
        reconstructed.volumes.map((v) => v.volumeNumber).toList(),
        equals(['1', '2']),
      );
      expect(
        reconstructed.orderedChapters.map((c) => c.chapterNumber).toList(),
        equals(['1', '2']),
      );
    });

    test('fromJson parses raw MangaDex AggregateResponse map payload', () {
      final json = <String, dynamic>{
        'result': 'ok',
        'volumes': {
          '1': {
            'volume': '1',
            'count': 1,
            'chapters': {
              '1': {'chapter': '1', 'id': 'c1'},
            },
          },
        },
      };

      final agg = ChapterAggregate.fromJson(json, mangaId: 'm-raw');

      expect(agg.mangaId, equals('m-raw'));
      expect(agg.volumes.length, equals(1));
      expect(agg.orderedChapters.first.chapterNumber, equals('1'));
    });

    test('fromJson handles empty or missing volumes/chapters', () {
      final json = <String, dynamic>{'mangaId': 'm-empty'};
      final agg = ChapterAggregate.fromJson(json);

      expect(agg.mangaId, equals('m-empty'));
      expect(agg.volumes, isEmpty);
      expect(agg.orderedChapters, isEmpty);
    });

    test('fromJson generates orderedChapters from volumes when missing', () {
      final json = <String, dynamic>{
        'mangaId': 'm-novol',
        'volumes': [
          {
            'volumeNumber': '2',
            'count': 1,
            'chapters': [
              {'chapterNumber': '3', 'id': 'c3'},
            ],
          },
          {
            'volumeNumber': '1',
            'count': 2,
            'chapters': [
              {'chapterNumber': '2', 'id': 'c2'},
              {'chapterNumber': '1', 'id': 'c1'},
            ],
          },
        ],
      };

      final agg = ChapterAggregate.fromJson(json);

      expect(
        agg.volumes.map((v) => v.volumeNumber).toList(),
        equals(['1', '2']),
      );
      expect(
        agg.orderedChapters.map((c) => c.chapterNumber).toList(),
        equals(['1', '2', '3']),
      );
    });

    group('computePreviousUnreadChapters', () {
      const aggregate = ChapterAggregate(
        mangaId: 'test-manga',
        orderedChapters: [
          MangaChapter(chapterNumber: '1', id: 'c1'),
          MangaChapter(chapterNumber: '2', id: 'c2'),
          MangaChapter(chapterNumber: '10', id: 'c10'),
          MangaChapter(chapterNumber: '10a', id: 'c10a'),
          MangaChapter(chapterNumber: '10.5', id: 'c10.5'),
          MangaChapter(chapterNumber: '11', id: 'c11'),
          MangaChapter(chapterNumber: 'none', id: 'cnone'),
        ],
      );

      test('computes up to chapter "10" filtering read chapters', () {
        final result = aggregate.computePreviousUnreadChapters(
          upToChapterNumber: '10',
          alreadyReadChapters: {'1'},
        );

        expect(result, equals(['2', '10']));
      });

      test('computes up to chapter "10a" where "10" is before "10a"', () {
        final result = aggregate.computePreviousUnreadChapters(
          upToChapterNumber: '10a',
          alreadyReadChapters: {'1', '2'},
        );

        expect(result, equals(['10', '10a']));
      });

      test('computes up to decimal chapter "10.5"', () {
        final result = aggregate.computePreviousUnreadChapters(
          upToChapterNumber: '10.5',
          alreadyReadChapters: {'1', '2', '10'},
        );

        // In ChapterComparator: "10" < "10a" < "10.5"
        expect(result, equals(['10a', '10.5']));
      });

      test('computes up to "none" including all preceding and unnumbered', () {
        final result = aggregate.computePreviousUnreadChapters(
          upToChapterNumber: 'none',
          alreadyReadChapters: {'1', '2', '10', '10a', '10.5'},
        );

        expect(result, equals(['11', 'none']));
      });

      test('returns empty when all target chapters are already read', () {
        final result = aggregate.computePreviousUnreadChapters(
          upToChapterNumber: '2',
          alreadyReadChapters: {'1', '2', '3'},
        );

        expect(result, isEmpty);
      });
    });
  });
}
