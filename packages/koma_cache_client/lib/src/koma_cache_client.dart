import 'package:drift/drift.dart';
import 'package:koma_cache_client/src/koma_cache_database.dart';
import 'package:meta/meta.dart';

/// Represents a cached entry with its raw JSON payload, timestamp,
/// expiration status, and optional deserialized data [T].
@immutable
class CacheEntry<T> {
  /// Creates a [CacheEntry].
  const new({
    required this.payloadJson,
    required this.updatedAt,
    required this.isExpired,
    this.data,
  });

  /// The raw serialized JSON payload stored in SQLite.
  final String payloadJson;

  /// The timestamp when this entry was created or last refreshed.
  final DateTime updatedAt;

  /// Whether this entry has exceeded its time-to-live.
  final bool isExpired;

  /// Optional deserialized representation of the payload.
  final T? data;

  /// Creates a copy of this [CacheEntry] with optional updated fields.
  CacheEntry<T> copyWith({
    String? payloadJson,
    DateTime? updatedAt,
    bool? isExpired,
    T? data,
  }) {
    return CacheEntry<T>(
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      isExpired: isExpired ?? this.isExpired,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheEntry<T> &&
        other.payloadJson == payloadJson &&
        other.updatedAt == updatedAt &&
        other.isExpired == isExpired &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(payloadJson, updatedAt, isExpired, data);

  @override
  String toString() =>
      'CacheEntry<$T>(payloadJson: $payloadJson, updatedAt: $updatedAt, '
      'isExpired: $isExpired, data: $data)';
}

/// Client interface for Koma's local Drift SQLite caching layer.
///
/// Provides fast, offline-first access to MangaDex metadata and aggregate
/// hierarchies with configurable time-to-live (TTL) expiration policies.
class KomaCacheClient {
  /// Creates a [KomaCacheClient] backed by a new [KomaCacheDatabase]
  /// with the provided [executor].
  new(
    QueryExecutor executor, {
    DateTime Function()? clock,
    Duration mangaMetadataTtl = defaultMangaMetadataTtl,
    Duration aggregateTtl = defaultAggregateTtl,
  }) : this.fromDatabase(
         KomaCacheDatabase(executor, clock: clock),
         clock: clock,
         mangaMetadataTtl: mangaMetadataTtl,
         aggregateTtl: aggregateTtl,
       );

  /// Creates a [KomaCacheClient] using an existing [database] instance.
  new fromDatabase(
    KomaCacheDatabase database, {
    DateTime Function()? clock,
    this.mangaMetadataTtl = defaultMangaMetadataTtl,
    this.aggregateTtl = defaultAggregateTtl,
  }) : _database = database,
       _clock = clock ?? database.clock;

  /// Default time-to-live for manga metadata (24 hours).
  static const Duration defaultMangaMetadataTtl = Duration(hours: 24);

  /// Default time-to-live for chapter aggregates (30 minutes).
  static const Duration defaultAggregateTtl = Duration(minutes: 30);

  final KomaCacheDatabase _database;
  final DateTime Function() _clock;

  /// Time-to-live duration for cached manga metadata entries.
  final Duration mangaMetadataTtl;

  /// Time-to-live duration for cached aggregate entries.
  final Duration aggregateTtl;

  /// The underlying Drift SQLite database.
  KomaCacheDatabase get database => _database;

  /// The clock provider returning the current timestamp.
  DateTime Function() get clock => _clock;

  /// Generates a deterministic languages key from an iterable of language
  /// codes.
  ///
  /// Trims, lowercases, and sorts the language codes alphabetically before
  /// joining them with commas (e.g. `['it', 'en']` -> `'en,it'`).
  static String normalizeLanguagesKey(Iterable<String> languages) {
    final normalized =
        languages
            .map((l) => l.trim().toLowerCase())
            .where((l) => l.isNotEmpty)
            .toList()
          ..sort();
    return normalized.join(',');
  }

  /// Retrieves a cached manga metadata entry by [mangaId].
  ///
  /// Returns `null` if the entry does not exist. If the entry exists, returns
  /// a [CacheEntry] containing the payload and setting [CacheEntry.isExpired]
  /// if the elapsed time exceeds [mangaMetadataTtl].
  Future<CacheEntry<String>?> getManga(String mangaId) async {
    final row = await (_database.select(
      _database.cachedMangas,
    )..where((tbl) => tbl.mangaId.equals(mangaId))).getSingleOrNull();

    if (row == null) return null;

    final isExpired =
        _clock().toUtc().difference(row.updatedAt.toUtc()) >= mangaMetadataTtl;
    return CacheEntry<String>(
      payloadJson: row.payloadJson,
      updatedAt: row.updatedAt.toUtc(),
      isExpired: isExpired,
      data: row.payloadJson,
    );
  }

  /// Inserts or updates a manga metadata entry in the cache.
  Future<void> upsertManga(String mangaId, String payloadJson) async {
    final now = _clock().toUtc();
    await _database
        .into(_database.cachedMangas)
        .insertOnConflictUpdate(
          CachedMangasCompanion.insert(
            mangaId: mangaId,
            payloadJson: payloadJson,
            updatedAt: now,
          ),
        );
  }

  /// Inserts or updates multiple manga metadata entries in a single batch.
  Future<void> upsertMangas(Map<String, String> entries) async {
    if (entries.isEmpty) return;

    final now = _clock().toUtc();
    await _database.batch((batch) {
      for (final entry in entries.entries) {
        batch.insert(
          _database.cachedMangas,
          CachedMangasCompanion.insert(
            mangaId: entry.key,
            payloadJson: entry.value,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Retrieves a cached chapter aggregate hierarchy for [mangaId] and
  /// [languages].
  ///
  /// Returns `null` if the entry does not exist. If found, returns a
  /// [CacheEntry] with [CacheEntry.isExpired] indicating whether [aggregateTtl]
  /// has elapsed.
  Future<CacheEntry<String>?> getAggregate(
    String mangaId,
    List<String> languages,
  ) async {
    final languagesKey = normalizeLanguagesKey(languages);
    final row =
        await (_database.select(_database.cachedAggregates)..where(
              (tbl) =>
                  tbl.mangaId.equals(mangaId) &
                  tbl.languagesKey.equals(languagesKey),
            ))
            .getSingleOrNull();

    if (row == null) return null;

    final isExpired =
        _clock().toUtc().difference(row.updatedAt.toUtc()) >= aggregateTtl;
    return CacheEntry<String>(
      payloadJson: row.payloadJson,
      updatedAt: row.updatedAt.toUtc(),
      isExpired: isExpired,
      data: row.payloadJson,
    );
  }

  /// Inserts or updates a chapter aggregate entry in the cache.
  Future<void> upsertAggregate(
    String mangaId,
    List<String> languages,
    String payloadJson,
  ) async {
    final now = _clock().toUtc();
    final languagesKey = normalizeLanguagesKey(languages);
    await _database
        .into(_database.cachedAggregates)
        .insertOnConflictUpdate(
          CachedAggregatesCompanion.insert(
            mangaId: mangaId,
            languagesKey: languagesKey,
            payloadJson: payloadJson,
            updatedAt: now,
          ),
        );
  }

  /// Deletes cached chapter aggregates for the given [mangaId].
  ///
  /// If [languages] is provided, only the aggregate matching that specific
  /// language set is removed. Otherwise, all cached aggregates for [mangaId]
  /// are invalidated.
  Future<int> invalidateAggregate(
    String mangaId, {
    List<String>? languages,
  }) async {
    final query = _database.delete(_database.cachedAggregates)
      ..where((tbl) => tbl.mangaId.equals(mangaId));
    if (languages != null) {
      final languagesKey = normalizeLanguagesKey(languages);
      query.where((tbl) => tbl.languagesKey.equals(languagesKey));
    }
    return await query.go();
  }

  /// Deletes all cached entries that have exceeded their time-to-live.
  ///
  /// Optionally overrides [mangaTtl] and [aggregateTtl]. Defaults to
  /// [mangaMetadataTtl] and [aggregateTtl].
  ///
  /// Returns the total number of entries removed.
  Future<int> pruneExpired({Duration? mangaTtl, Duration? aggregateTtl}) async {
    final now = _clock().toUtc();
    final mangaCutoff = now.subtract(mangaTtl ?? mangaMetadataTtl);
    final aggregateCutoff = now.subtract(aggregateTtl ?? this.aggregateTtl);

    final mangasDeleted = await (_database.delete(
      _database.cachedMangas,
    )..where((tbl) => tbl.updatedAt.isSmallerThanValue(mangaCutoff))).go();

    final aggregatesDeleted = await (_database.delete(
      _database.cachedAggregates,
    )..where((tbl) => tbl.updatedAt.isSmallerThanValue(aggregateCutoff))).go();

    return mangasDeleted + aggregatesDeleted;
  }

  /// Deletes all cached manga metadata and chapter aggregate rows.
  Future<void> clearAll() async {
    await _database.delete(_database.cachedMangas).go();
    await _database.delete(_database.cachedAggregates).go();
  }

  /// Closes the underlying database connection.
  Future<void> close() => _database.close();
}
