import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:koma_cache_client/koma_cache_client.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('CacheEntry', () {
    final now = DateTime.utc(2026, 11, 13, 12);

    test('supports value equality and hashCode', () {
      final entry1 = CacheEntry<String>(
        payloadJson: '{"id":"manga-1"}',
        updatedAt: now,
        isExpired: false,
        data: '{"id":"manga-1"}',
      );
      final entry2 = CacheEntry<String>(
        payloadJson: '{"id":"manga-1"}',
        updatedAt: now,
        isExpired: false,
        data: '{"id":"manga-1"}',
      );
      final differentPayload = entry1.copyWith(payloadJson: '{"id":"manga-2"}');
      final differentTime = entry1.copyWith(
        updatedAt: now.add(const Duration(minutes: 1)),
      );
      final differentExpired = entry1.copyWith(isExpired: true);
      final differentData = CacheEntry<String>(
        payloadJson: '{"id":"manga-1"}',
        updatedAt: now,
        isExpired: false,
        data: 'different',
      );

      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
      expect(entry1 == entry1, isTrue);
      expect(entry1, isNot(equals(Object())));
      expect(entry1, isNot(equals(differentPayload)));
      expect(entry1, isNot(equals(differentTime)));
      expect(entry1, isNot(equals(differentExpired)));
      expect(entry1, isNot(equals(differentData)));
    });

    test('copyWith preserves unchanged properties', () {
      final entry = CacheEntry<String>(
        payloadJson: '{"id":"1"}',
        updatedAt: now,
        isExpired: false,
      );

      final copy = entry.copyWith();
      expect(copy.payloadJson, equals(entry.payloadJson));
      expect(copy.updatedAt, equals(entry.updatedAt));
      expect(copy.isExpired, equals(entry.isExpired));
      expect(copy.data, equals(entry.data));
    });

    test('toString includes relevant fields', () {
      final entry = CacheEntry<String>(
        payloadJson: '{"id":"1"}',
        updatedAt: now,
        isExpired: false,
      );

      expect(entry.toString(), contains('CacheEntry<String>'));
      expect(entry.toString(), contains('{"id":"1"}'));
      expect(entry.toString(), contains('isExpired: false'));
    });
  });

  group('KomaCacheClient.normalizeLanguagesKey', () {
    test('sorts, trims, lowercases, and removes empty codes', () {
      expect(
        KomaCacheClient.normalizeLanguagesKey([' IT ', 'en', '  ', 'JA']),
        equals('en,it,ja'),
      );
    });

    test('returns empty string for empty iterable', () {
      expect(KomaCacheClient.normalizeLanguagesKey([]), isEmpty);
    });

    test('treats different ordering identically', () {
      final key1 = KomaCacheClient.normalizeLanguagesKey(['en', 'it']);
      final key2 = KomaCacheClient.normalizeLanguagesKey(['it', 'en']);
      expect(key1, equals(key2));
      expect(key1, equals('en,it'));
    });
  });

  group('KomaCacheDatabase', () {
    test('uses DateTime.now when clock is not provided', () async {
      final db = KomaCacheDatabase(NativeDatabase.memory());
      final time = db.clock();
      expect(time.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
      expect(db.schemaVersion, equals(1));
      await db.close();
    });
  });

  group('KomaCacheClient', () {
    late DateTime currentTime;
    late KomaCacheClient client;

    DateTime testClock() => currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 11, 13, 10);
      client = KomaCacheClient(NativeDatabase.memory(), clock: testClock);
    });

    tearDown(() async {
      await client.close();
    });

    test('exposes database, clock, and default TTLs', () {
      expect(client.database, isA<KomaCacheDatabase>());
      expect(client.clock, isNotNull);
      expect(client.mangaMetadataTtl, equals(const Duration(hours: 24)));
      expect(client.aggregateTtl, equals(const Duration(minutes: 30)));
    });

    test(
      'fromDatabase constructor creates client with injected clock',
      () async {
        final db = KomaCacheDatabase(NativeDatabase.memory(), clock: testClock);
        final customClient = KomaCacheClient.fromDatabase(db);
        expect(customClient.clock(), equals(currentTime));
        await customClient.close();
      },
    );

    group('manga metadata cache', () {
      test('getManga returns null for missing entry', () async {
        final result = await client.getManga('missing-id');
        expect(result, isNull);
      });

      test(
        'upsertManga stores entry and getManga retrieves it fresh',
        () async {
          const mangaId = 'manga-1';
          const payload = '{"id":"manga-1","title":"Chainsaw Man"}';

          await client.upsertManga(mangaId, payload);
          final entry = await client.getManga(mangaId);

          expect(entry, isNotNull);
          expect(entry!.payloadJson, equals(payload));
          expect(entry.data, equals(payload));
          expect(entry.updatedAt, equals(currentTime));
          expect(entry.isExpired, isFalse);
        },
      );

      test(
        'upsertManga updates existing entry and refreshes timestamp',
        () async {
          const mangaId = 'manga-1';
          await client.upsertManga(mangaId, '{"v":1}');

          currentTime = currentTime.add(const Duration(hours: 2));
          await client.upsertManga(mangaId, '{"v":2}');

          final entry = await client.getManga(mangaId);
          expect(entry, isNotNull);
          expect(entry!.payloadJson, equals('{"v":2}'));
          expect(entry.updatedAt, equals(currentTime));
        },
      );

      test(
        'getManga flags entry as expired after 24 hours (SWR support)',
        () async {
          const mangaId = 'manga-1';
          await client.upsertManga(mangaId, '{"title":"Frieren"}');

          // Advance clock by 23 hours and 59 minutes: should be fresh
          currentTime = currentTime.add(const Duration(hours: 23, minutes: 59));
          var entry = await client.getManga(mangaId);
          expect(entry!.isExpired, isFalse);

          // Advance clock to exactly 24 hours: should be expired
          currentTime = currentTime.add(const Duration(minutes: 1));
          entry = await client.getManga(mangaId);
          expect(entry!.isExpired, isTrue);
          // Stale payload is still returned for SWR fallback
          expect(entry.payloadJson, equals('{"title":"Frieren"}'));
        },
      );

      test('upsertMangas batches multiple entries', () async {
        await client.upsertMangas({});

        final entries = {
          'manga-1': '{"id":"1"}',
          'manga-2': '{"id":"2"}',
          'manga-3': '{"id":"3"}',
        };

        await client.upsertMangas(entries);

        for (final entry in entries.entries) {
          final cached = await client.getManga(entry.key);
          expect(cached, isNotNull);
          expect(cached!.payloadJson, equals(entry.value));
        }
      });
    });

    group('chapter aggregate cache', () {
      test('getAggregate returns null for missing entry', () async {
        final result = await client.getAggregate('manga-1', ['en']);
        expect(result, isNull);
      });

      test(
        'upsertAggregate stores entry and getAggregate retrieves it',
        () async {
          const mangaId = 'manga-1';
          const payload = '{"volumes":{"1":{"chapters":{"1":{}}}}}';

          await client.upsertAggregate(mangaId, ['en', 'it'], payload);
          final entry = await client.getAggregate(mangaId, ['en', 'it']);

          expect(entry, isNotNull);
          expect(entry!.payloadJson, equals(payload));
          expect(entry.data, equals(payload));
          expect(entry.isExpired, isFalse);
          expect(entry.updatedAt, equals(currentTime));
        },
      );

      test(
        'isolates aggregates by composite key (mangaId, languagesKey)',
        () async {
          const mangaId = 'manga-1';
          await client.upsertAggregate(mangaId, [
            'en',
            'it',
          ], '{"lang":"en,it"}');
          await client.upsertAggregate(mangaId, ['en'], '{"lang":"en"}');

          final enIt = await client.getAggregate(mangaId, ['it', 'en']);
          final enOnly = await client.getAggregate(mangaId, ['en']);
          final itOnly = await client.getAggregate(mangaId, ['it']);

          expect(enIt?.payloadJson, equals('{"lang":"en,it"}'));
          expect(enOnly?.payloadJson, equals('{"lang":"en"}'));
          expect(itOnly, isNull);
        },
      );

      test('flags aggregate as expired after 30 minutes', () async {
        const mangaId = 'manga-1';
        await client.upsertAggregate(mangaId, ['en'], '{"vol":1}');

        currentTime = currentTime.add(const Duration(minutes: 29));
        var entry = await client.getAggregate(mangaId, ['en']);
        expect(entry!.isExpired, isFalse);

        currentTime = currentTime.add(const Duration(minutes: 1));
        entry = await client.getAggregate(mangaId, ['en']);
        expect(entry!.isExpired, isTrue);
        expect(entry.payloadJson, equals('{"vol":1}'));
      });

      test(
        'invalidateAggregate removes all aggregates for manga when languages '
        'is null',
        () async {
          await client.upsertAggregate('manga-1', ['en'], '{"a":1}');
          await client.upsertAggregate('manga-1', ['it'], '{"b":2}');
          await client.upsertAggregate('manga-2', ['en'], '{"c":3}');

          final deleted = await client.invalidateAggregate('manga-1');
          expect(deleted, equals(2));

          expect(await client.getAggregate('manga-1', ['en']), isNull);
          expect(await client.getAggregate('manga-1', ['it']), isNull);
          expect(await client.getAggregate('manga-2', ['en']), isNotNull);
        },
      );

      test('invalidateAggregate removes specific language aggregate when '
          'specified', () async {
        await client.upsertAggregate('manga-1', ['en'], '{"a":1}');
        await client.upsertAggregate('manga-1', ['it'], '{"b":2}');

        final deleted = await client.invalidateAggregate(
          'manga-1',
          languages: ['en'],
        );
        expect(deleted, equals(1));

        expect(await client.getAggregate('manga-1', ['en']), isNull);
        expect(await client.getAggregate('manga-1', ['it']), isNotNull);
      });
    });

    group('pruning and cleanup', () {
      test(
        'pruneExpired deletes expired mangas and aggregates based on TTL',
        () async {
          // Add manga 1 (will expire) and manga 2 (will stay fresh)
          await client.upsertManga('manga-old', '{"id":"old"}');
          await client.upsertAggregate('manga-old', ['en'], '{"agg":"old"}');

          // Advance time by 1 hour (aggregate expires, manga still fresh)
          currentTime = currentTime.add(const Duration(hours: 1));
          await client.upsertManga('manga-fresh', '{"id":"fresh"}');
          await client.upsertAggregate('manga-fresh', [
            'en',
          ], '{"agg":"fresh"}');

          // Advance time by 24 more hours (both old manga and old agg expire)
          currentTime = currentTime.add(const Duration(hours: 24));

          final pruned = await client.pruneExpired();
          // manga-old (> 24h), manga-old agg (> 30m), manga-fresh agg (> 30m)
          expect(pruned, greaterThanOrEqualTo(2));

          expect(await client.getManga('manga-old'), isNull);
          expect(await client.getManga('manga-fresh'), isNotNull);
          expect(await client.getAggregate('manga-old', ['en']), isNull);
        },
      );

      test('pruneExpired supports custom duration overrides', () async {
        await client.upsertManga('manga-1', '{"id":"1"}');
        await client.upsertAggregate('manga-1', ['en'], '{"agg":"1"}');

        currentTime = currentTime.add(const Duration(minutes: 10));

        // With default TTLs (24h and 30m), nothing should be pruned
        var pruned = await client.pruneExpired();
        expect(pruned, equals(0));

        // With custom overrides (5m and 5m), both should be pruned
        pruned = await client.pruneExpired(
          mangaTtl: const Duration(minutes: 5),
          aggregateTtl: const Duration(minutes: 5),
        );
        expect(pruned, equals(2));
        expect(await client.getManga('manga-1'), isNull);
        expect(await client.getAggregate('manga-1', ['en']), isNull);
      });

      test('clearAll removes all rows from both tables', () async {
        await client.upsertManga('manga-1', '{"id":"1"}');
        await client.upsertAggregate('manga-1', ['en'], '{"agg":"1"}');

        await client.clearAll();

        expect(await client.getManga('manga-1'), isNull);
        expect(await client.getAggregate('manga-1', ['en']), isNull);
      });
    });
  });
}
