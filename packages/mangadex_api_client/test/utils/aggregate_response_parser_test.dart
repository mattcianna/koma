import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('AggregateResponseParser', () {
    test('parses full hierarchical aggregate response', () {
      final json = <String, dynamic>{
        'result': 'ok',
        'volumes': {
          '1': {
            'volume': '1',
            'count': 2,
            'chapters': {
              '1': {
                'chapter': '1',
                'id': 'uuid-ch1-main',
                'others': ['uuid-ch1-alt1', 'uuid-ch1-alt2'],
                'count': 3,
                'isUnavailable': false,
              },
              '2': {
                'chapter': '2',
                'id': 'uuid-ch2-main',
                'others': <dynamic>[],
                'count': 1,
                'isUnavailable': true,
              },
            },
          },
          'none': {
            'volume': 'none',
            'count': 1,
            'chapters': {
              'none': {
                'chapter': 'none',
                'id': 'uuid-oneshot',
                'others': <dynamic>[],
                'count': 1,
                'isUnavailable': false,
              },
            },
          },
        },
      };

      final response = AggregateResponseParser.parse(json);

      expect(response.result, equals('ok'));
      expect(response.volumes, hasLength(2));
      expect(response.volumes.containsKey('1'), isTrue);
      expect(response.volumes.containsKey('none'), isTrue);

      final vol1 = response.volumes['1']!;
      expect(vol1.volume, equals('1'));
      expect(vol1.count, equals(2));
      expect(vol1.chapters, hasLength(2));

      final ch1 = vol1.chapters['1']!;
      expect(ch1.chapter, equals('1'));
      expect(ch1.id, equals('uuid-ch1-main'));
      expect(ch1.others, equals(['uuid-ch1-alt1', 'uuid-ch1-alt2']));
      expect(ch1.count, equals(3));
      expect(ch1.isUnavailable, isFalse);
      expect(
        ch1.allChapterIds,
        equals(['uuid-ch1-main', 'uuid-ch1-alt1', 'uuid-ch1-alt2']),
      );

      final ch2 = vol1.chapters['2']!;
      expect(ch2.isUnavailable, isTrue);
      expect(ch2.allChapterIds, equals(['uuid-ch2-main']));

      final volNone = response.volumes['none']!;
      expect(volNone.volume, equals('none'));
      final oneshot = volNone.chapters['none']!;
      expect(oneshot.chapter, equals('none'));
      expect(oneshot.id, equals('uuid-oneshot'));
    });

    test('safely handles MangaDex PHP empty array [] quirk on volumes', () {
      // MangaDex returns {"result":"ok","volumes":[]} when no volumes exist
      final emptyVolumesJson = <String, dynamic>{
        'result': 'ok',
        'volumes': <dynamic>[],
      };

      final response = AggregateResponseParser.parse(emptyVolumesJson);

      expect(response.result, equals('ok'));
      expect(response.volumes, isEmpty);
    });

    test('safely handles MangaDex PHP empty array [] quirk on chapters', () {
      final json = <String, dynamic>{
        'result': 'ok',
        'volumes': {
          '1': {
            'volume': '1',
            'count': 0,
            'chapters': <dynamic>[], // PHP empty array quirk
          },
        },
      };

      final response = AggregateResponseParser.parse(json);

      expect(response.volumes, hasLength(1));
      final vol1 = response.volumes['1']!;
      expect(vol1.chapters, isEmpty);
      expect(vol1.count, equals(0));
    });

    test('merges and deduplicates primary id and others list', () {
      final merged = AggregateResponseParser.mergeChapterIds('uuid-1', [
        'uuid-2',
        'uuid-1',
        '  ',
        'uuid-3',
      ]);

      expect(merged, equals(['uuid-1', 'uuid-2', 'uuid-3']));
    });

    test('converts AggregateResponse to and from JSON symmetrically', () {
      const response = AggregateResponse(
        volumes: {
          '1': AggregateVolume(
            volume: '1',
            count: 1,
            chapters: {
              '1': AggregateChapter(
                chapter: '1',
                id: 'id-1',
                others: ['id-2'],
                count: 2,
              ),
            },
          ),
        },
      );

      final json = response.toJson();
      final roundTrip = AggregateResponse.fromJson(json);

      expect(roundTrip, equals(response));
    });

    test('safely parses untyped dynamic maps for volumes and chapters', () {
      final untypedJson = <dynamic, dynamic>{
        'result': 'ok',
        'volumes': <dynamic, dynamic>{
          '1': <dynamic, dynamic>{
            'volume': '1',
            'count': 1,
            'chapters': <dynamic, dynamic>{
              '1': <dynamic, dynamic>{
                'chapter': '1',
                'id': 'untyped-id',
                'others': <dynamic>[],
                'count': 1,
              },
            },
          },
        },
      };

      final parsed = AggregateResponseParser.parse(
        Map<String, dynamic>.from(untypedJson),
      );

      expect(parsed.volumes.containsKey('1'), isTrue);
      expect(parsed.volumes['1']!.chapters.containsKey('1'), isTrue);
      expect(parsed.volumes['1']!.chapters['1']!.id, equals('untyped-id'));
    });
  });
}
