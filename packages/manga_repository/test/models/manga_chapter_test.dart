import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaChapter', () {
    test('supports value equality', () {
      const chapter1 = MangaChapter(
        chapterNumber: '1',
        id: 'chap-1',
        otherIds: ['chap-1-alt'],
      );
      const chapter2 = MangaChapter(
        chapterNumber: '1',
        id: 'chap-1',
        otherIds: ['chap-1-alt'],
      );
      const chapter3 = MangaChapter(chapterNumber: '2', id: 'chap-2');

      expect(chapter1, equals(chapter2));
      expect(chapter1, isNot(equals(chapter3)));
    });

    test('fromAggregateChapter maps all fields correctly', () {
      const aggChapter = AggregateChapter(
        chapter: '10.5',
        id: 'uuid-10-5',
        others: ['alt-1', 'alt-2'],
        count: 3,
        isUnavailable: true,
      );

      final domain = MangaChapter.fromAggregateChapter(aggChapter);

      expect(domain.chapterNumber, equals('10.5'));
      expect(domain.id, equals('uuid-10-5'));
      expect(domain.otherIds, equals(['alt-1', 'alt-2']));
      expect(domain.count, equals(3));
      expect(domain.isUnavailable, isTrue);
    });

    test('allIds returns primary id and unique other ids', () {
      const chapter = MangaChapter(
        chapterNumber: '5',
        id: 'id-main',
        otherIds: ['id-alt-1', 'id-main', 'id-alt-2'],
      );

      expect(chapter.allIds, equals(['id-main', 'id-alt-1', 'id-alt-2']));
    });

    test('allIds handles empty primary id', () {
      const chapter = MangaChapter(
        chapterNumber: 'none',
        id: '',
        otherIds: ['id-alt-1'],
      );

      expect(chapter.allIds, equals(['id-alt-1']));
    });

    test('toJson and fromJson roundtrip correctly', () {
      const chapter = MangaChapter(
        chapterNumber: '99',
        id: 'chap-99',
        otherIds: ['alt-99'],
        count: 2,
      );

      final json = chapter.toJson();
      final reconstructed = MangaChapter.fromJson(json);

      expect(reconstructed, equals(chapter));
    });

    test('fromJson handles legacy/alternate key names and defaults', () {
      final json = <String, dynamic>{
        'chapter': '10',
        'id': 'chap-10',
        'others': ['alt-1'],
      };

      final chapter = MangaChapter.fromJson(json);

      expect(chapter.chapterNumber, equals('10'));
      expect(chapter.id, equals('chap-10'));
      expect(chapter.otherIds, equals(['alt-1']));
      expect(chapter.count, equals(1));
      expect(chapter.isUnavailable, isFalse);
    });
  });
}
