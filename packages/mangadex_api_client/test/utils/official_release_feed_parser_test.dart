import 'package:dio/dio.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDio extends Mock implements Dio;

void main() {
  group('OfficialReleaseFeedService', () {
    test('extractFeedUrlFromHtml discovers RSS and prefers it over Atom', () {
      const html = '''
        <html>
          <head>
            <link rel="alternate" type="application/atom+xml" title="Atom" href="/atom/series/123">
            <link rel="alternate" type="application/rss+xml" title="RSS" href="/rss/series/123">
          </head>
        </html>
      ''';

      final url = OfficialReleaseFeedService.extractFeedUrlFromHtml(
        html,
        baseUrl: 'https://www.sunday-webry.com/episode/999',
      );
      expect(url, equals('https://www.sunday-webry.com/rss/series/123'));
    });

    test(
      'extractFeedUrlFromHtml handles Atom-only pages & attribute order',
      () {
        const html = '''
        <link href="https://example.com/atom.xml" type='application/atom+xml' rel="alternate" />
      ''';

        final url = OfficialReleaseFeedService.extractFeedUrlFromHtml(
          html,
          baseUrl: 'https://example.com/manga',
        );
        expect(url, equals('https://example.com/atom.xml'));
      },
    );

    test(
      'extractChapterNumberFromTitle handles bracketed & keyword formats',
      () {
        expect(
          OfficialReleaseFeedService.extractChapterNumberFromTitle(
            '【満足度448】ラーメンと彼女⑤',
          ),
          equals('448'),
        );
        expect(
          OfficialReleaseFeedService.extractChapterNumberFromTitle(
            'GAME72 幼なじみと好きなコト',
          ),
          equals('72'),
        );
        expect(
          OfficialReleaseFeedService.extractChapterNumberFromTitle(
            'Chapter 012.5 - Bonus Story',
          ),
          equals('12.5'),
        );
        expect(
          OfficialReleaseFeedService.extractChapterNumberFromTitle(
            '【第105話】Special',
          ),
          equals('105'),
        );
        expect(
          OfficialReleaseFeedService.extractChapterNumberFromTitle(
            '【500万部突破】Volume 5 Release Notice',
          ),
          isNull,
        );
      },
    );

    test('parseFeedXml parses Magazine Pocket RSS 2.0 items safely', () {
      const rss = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>【満足度448】ラーメンと彼女⑤</title>
      <link>https://pocket.shonenmagazine.com/title/00289/episode/446787</link>
      <guid isPermalink="false">446787</guid>
      <pubDate>Wed, 11 Nov 2026 00:00:00 +0900</pubDate>
    </item>
    <item>
      <title>単行本第47巻発売のお知らせ</title>
      <link>https://pocket.shonenmagazine.com/notice</link>
      <guid>promo-1</guid>
    </item>
    <item>
      <title>【満足度447】ラーメンと彼女④</title>
      <link>https://pocket.shonenmagazine.com/title/00289/episode/446284</link>
      <guid isPermalink="false">446284</guid>
      <pubDate>Wed, 04 Nov 2026 00:00:00 +0900</pubDate>
    </item>
  </channel>
</rss>
''';

      final chapters = OfficialReleaseFeedService.parseFeedXml(rss);
      expect(chapters, hasLength(2));
      expect(chapters[0].chapterNumber, equals('448'));
      expect(chapters[0].id, equals('ext:446787'));
      expect(
        chapters[0].externalUrl,
        equals('https://pocket.shonenmagazine.com/title/00289/episode/446787'),
      );
      expect(chapters[0].publishedAt, equals(DateTime.utc(2026, 11, 10, 15)));
      expect(chapters[1].chapterNumber, equals('447'));
    });

    test('parseFeedXml parses Sunday Webry Atom entries', () {
      const atom = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <title>GAME72 幼なじみと好きなコト</title>
    <link href="https://www.sunday-webry.com/episode/12207421984382913956"/>
    <id>sunday_webry:episode:12207421984382913956</id>
    <updated>2026-10-15T15:00:00Z</updated>
    <link rel="enclosure" href="https://example.com/thumb.jpg" type="image/jpeg" />
  </entry>
</feed>
''';

      final chapters = OfficialReleaseFeedService.parseFeedXml(atom);
      expect(chapters, hasLength(1));
      expect(chapters.first.chapterNumber, equals('72'));
      expect(chapters.first.id, equals('ext:12207421984382913956'));
      expect(chapters.first.id.length, lessThanOrEqualTo(36));
      expect(
        chapters.first.externalUrl,
        equals('https://www.sunday-webry.com/episode/12207421984382913956'),
      );
      expect(
        chapters.first.publishedAt,
        equals(DateTime.utc(2026, 10, 15, 15)),
      );
    });

    test(
      'fetchChaptersFromRawUrl fetches HTML then XML and handles errors',
      () async {
        final mockDio = _MockDio();
        final service = OfficialReleaseFeedService(dio: mockDio);

        when(
          () => mockDio.get<String>(
            'https://pocket.shonenmagazine.com/episode/1',
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<String>(
            requestOptions: RequestOptions(
              path: 'https://pocket.shonenmagazine.com/episode/1',
            ),
            data:
                '<link rel="alternate" type="application/rss+xml" '
                'href="https://mgpk-cdn.magazinepocket.com/static/rss/289/feed.xml">',
          ),
        );
        when(
          () => mockDio.get<String>(
            'https://mgpk-cdn.magazinepocket.com/static/rss/289/feed.xml',
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<String>(
            requestOptions: RequestOptions(
              path:
                  'https://mgpk-cdn.magazinepocket.com/static/rss/289/feed.xml',
            ),
            data:
                '<rss><channel><item><title>【満足度449】Title</title>'
                '<link>https://pocket.shonenmagazine.com/ep/449</link>'
                '<guid>999</guid></item></channel></rss>',
          ),
        );

        final result = await service.fetchChaptersFromRawUrl(
          'https://pocket.shonenmagazine.com/episode/1',
        );
        expect(result, hasLength(1));
        expect(result.first.chapterNumber, equals('449'));

        expect(await service.fetchChaptersFromRawUrl(null), isEmpty);
        expect(
          await service.fetchChaptersFromRawUrl('http://insecure.example.com'),
          isEmpty,
        );
      },
    );
  });
}
