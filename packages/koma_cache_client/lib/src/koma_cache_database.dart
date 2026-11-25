import 'package:drift/drift.dart';

part 'koma_cache_database.g.dart';

// coverage:ignore-start

/// Table definition for caching MangaDex manga metadata payloads.
///
/// Stores raw JSON payloads mapped to their unique MangaDex [mangaId].
/// Canonical TTL is 24 hours.
class CachedMangas extends Table {
  /// Unique MangaDex UUID for the manga.
  TextColumn get mangaId => text()();

  /// Raw JSON string representing the manga metadata payload.
  TextColumn get payloadJson => text()();

  /// Timestamp when this entry was written or refreshed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mangaId};
}

/// Table definition for caching MangaDex chapter aggregate hierarchies.
///
/// Partitioned by composite primary key `(mangaId, languagesKey)`.
/// Canonical TTL is 30 minutes.
class CachedAggregates extends Table {
  /// Unique MangaDex UUID for the manga.
  TextColumn get mangaId => text()();

  /// Sorted, comma-separated language codes (e.g. `'en,it'`).
  TextColumn get languagesKey => text()();

  /// Raw JSON string representing the chapter aggregate payload.
  TextColumn get payloadJson => text()();

  /// Timestamp when this entry was written or refreshed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mangaId, languagesKey};
}

// coverage:ignore-end

/// The Drift SQLite database powering Koma's local offline-first cache.
@DriftDatabase(tables: [CachedMangas, CachedAggregates])
class KomaCacheDatabase extends _$KomaCacheDatabase {
  /// Creates a [KomaCacheDatabase] using the provided [e] executor and
  /// an optional [clock] for deterministic testing.
  new(super.e, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// The clock provider returning the current timestamp.
  DateTime Function() get clock => _clock;

  @override
  int get schemaVersion => 1;
}
