// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'koma_cache_database.dart';

// ignore_for_file: type=lint
class $CachedMangasTable extends CachedMangas
    with TableInfo<$CachedMangasTable, CachedManga> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMangasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mangaIdMeta = const VerificationMeta(
    'mangaId',
  );
  @override
  late final GeneratedColumn<String> mangaId = GeneratedColumn<String>(
    'manga_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mangaId, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_mangas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedManga> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('manga_id')) {
      context.handle(
        _mangaIdMeta,
        mangaId.isAcceptableOrUnknown(data['manga_id']!, _mangaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mangaIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mangaId};
  @override
  CachedManga map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedManga(
      mangaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manga_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedMangasTable createAlias(String alias) {
    return $CachedMangasTable(attachedDatabase, alias);
  }
}

class CachedManga extends DataClass implements Insertable<CachedManga> {
  /// Unique MangaDex UUID for the manga.
  final String mangaId;

  /// Raw JSON string representing the manga metadata payload.
  final String payloadJson;

  /// Timestamp when this entry was written or refreshed.
  final DateTime updatedAt;
  const CachedManga({
    required this.mangaId,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['manga_id'] = Variable<String>(mangaId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMangasCompanion toCompanion(bool nullToAbsent) {
    return CachedMangasCompanion(
      mangaId: Value(mangaId),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedManga.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedManga(
      mangaId: serializer.fromJson<String>(json['mangaId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mangaId': serializer.toJson<String>(mangaId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedManga copyWith({
    String? mangaId,
    String? payloadJson,
    DateTime? updatedAt,
  }) => CachedManga(
    mangaId: mangaId ?? this.mangaId,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedManga copyWithCompanion(CachedMangasCompanion data) {
    return CachedManga(
      mangaId: data.mangaId.present ? data.mangaId.value : this.mangaId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedManga(')
          ..write('mangaId: $mangaId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mangaId, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedManga &&
          other.mangaId == this.mangaId &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class CachedMangasCompanion extends UpdateCompanion<CachedManga> {
  final Value<String> mangaId;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMangasCompanion({
    this.mangaId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMangasCompanion.insert({
    required String mangaId,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : mangaId = Value(mangaId),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedManga> custom({
    Expression<String>? mangaId,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mangaId != null) 'manga_id': mangaId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMangasCompanion copyWith({
    Value<String>? mangaId,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMangasCompanion(
      mangaId: mangaId ?? this.mangaId,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mangaId.present) {
      map['manga_id'] = Variable<String>(mangaId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMangasCompanion(')
          ..write('mangaId: $mangaId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAggregatesTable extends CachedAggregates
    with TableInfo<$CachedAggregatesTable, CachedAggregate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAggregatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mangaIdMeta = const VerificationMeta(
    'mangaId',
  );
  @override
  late final GeneratedColumn<String> mangaId = GeneratedColumn<String>(
    'manga_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languagesKeyMeta = const VerificationMeta(
    'languagesKey',
  );
  @override
  late final GeneratedColumn<String> languagesKey = GeneratedColumn<String>(
    'languages_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mangaId,
    languagesKey,
    payloadJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_aggregates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAggregate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('manga_id')) {
      context.handle(
        _mangaIdMeta,
        mangaId.isAcceptableOrUnknown(data['manga_id']!, _mangaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mangaIdMeta);
    }
    if (data.containsKey('languages_key')) {
      context.handle(
        _languagesKeyMeta,
        languagesKey.isAcceptableOrUnknown(
          data['languages_key']!,
          _languagesKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languagesKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mangaId, languagesKey};
  @override
  CachedAggregate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAggregate(
      mangaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manga_id'],
      )!,
      languagesKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}languages_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedAggregatesTable createAlias(String alias) {
    return $CachedAggregatesTable(attachedDatabase, alias);
  }
}

class CachedAggregate extends DataClass implements Insertable<CachedAggregate> {
  /// Unique MangaDex UUID for the manga.
  final String mangaId;

  /// Sorted, comma-separated language codes (e.g. `'en,it'`).
  final String languagesKey;

  /// Raw JSON string representing the chapter aggregate payload.
  final String payloadJson;

  /// Timestamp when this entry was written or refreshed.
  final DateTime updatedAt;
  const CachedAggregate({
    required this.mangaId,
    required this.languagesKey,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['manga_id'] = Variable<String>(mangaId);
    map['languages_key'] = Variable<String>(languagesKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedAggregatesCompanion toCompanion(bool nullToAbsent) {
    return CachedAggregatesCompanion(
      mangaId: Value(mangaId),
      languagesKey: Value(languagesKey),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedAggregate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAggregate(
      mangaId: serializer.fromJson<String>(json['mangaId']),
      languagesKey: serializer.fromJson<String>(json['languagesKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mangaId': serializer.toJson<String>(mangaId),
      'languagesKey': serializer.toJson<String>(languagesKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedAggregate copyWith({
    String? mangaId,
    String? languagesKey,
    String? payloadJson,
    DateTime? updatedAt,
  }) => CachedAggregate(
    mangaId: mangaId ?? this.mangaId,
    languagesKey: languagesKey ?? this.languagesKey,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedAggregate copyWithCompanion(CachedAggregatesCompanion data) {
    return CachedAggregate(
      mangaId: data.mangaId.present ? data.mangaId.value : this.mangaId,
      languagesKey: data.languagesKey.present
          ? data.languagesKey.value
          : this.languagesKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAggregate(')
          ..write('mangaId: $mangaId, ')
          ..write('languagesKey: $languagesKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(mangaId, languagesKey, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAggregate &&
          other.mangaId == this.mangaId &&
          other.languagesKey == this.languagesKey &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class CachedAggregatesCompanion extends UpdateCompanion<CachedAggregate> {
  final Value<String> mangaId;
  final Value<String> languagesKey;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedAggregatesCompanion({
    this.mangaId = const Value.absent(),
    this.languagesKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAggregatesCompanion.insert({
    required String mangaId,
    required String languagesKey,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : mangaId = Value(mangaId),
       languagesKey = Value(languagesKey),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedAggregate> custom({
    Expression<String>? mangaId,
    Expression<String>? languagesKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mangaId != null) 'manga_id': mangaId,
      if (languagesKey != null) 'languages_key': languagesKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAggregatesCompanion copyWith({
    Value<String>? mangaId,
    Value<String>? languagesKey,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedAggregatesCompanion(
      mangaId: mangaId ?? this.mangaId,
      languagesKey: languagesKey ?? this.languagesKey,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mangaId.present) {
      map['manga_id'] = Variable<String>(mangaId.value);
    }
    if (languagesKey.present) {
      map['languages_key'] = Variable<String>(languagesKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAggregatesCompanion(')
          ..write('mangaId: $mangaId, ')
          ..write('languagesKey: $languagesKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$KomaCacheDatabase extends GeneratedDatabase {
  _$KomaCacheDatabase(QueryExecutor e) : super(e);
  $KomaCacheDatabaseManager get managers => $KomaCacheDatabaseManager(this);
  late final $CachedMangasTable cachedMangas = $CachedMangasTable(this);
  late final $CachedAggregatesTable cachedAggregates = $CachedAggregatesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMangas,
    cachedAggregates,
  ];
}

typedef $$CachedMangasTableCreateCompanionBuilder =
    CachedMangasCompanion Function({
      required String mangaId,
      required String payloadJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMangasTableUpdateCompanionBuilder =
    CachedMangasCompanion Function({
      Value<String> mangaId,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMangasTableFilterComposer
    extends Composer<_$KomaCacheDatabase, $CachedMangasTable> {
  $$CachedMangasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mangaId => $composableBuilder(
    column: $table.mangaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMangasTableOrderingComposer
    extends Composer<_$KomaCacheDatabase, $CachedMangasTable> {
  $$CachedMangasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mangaId => $composableBuilder(
    column: $table.mangaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMangasTableAnnotationComposer
    extends Composer<_$KomaCacheDatabase, $CachedMangasTable> {
  $$CachedMangasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mangaId =>
      $composableBuilder(column: $table.mangaId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMangasTableTableManager
    extends
        RootTableManager<
          _$KomaCacheDatabase,
          $CachedMangasTable,
          CachedManga,
          $$CachedMangasTableFilterComposer,
          $$CachedMangasTableOrderingComposer,
          $$CachedMangasTableAnnotationComposer,
          $$CachedMangasTableCreateCompanionBuilder,
          $$CachedMangasTableUpdateCompanionBuilder,
          (
            CachedManga,
            BaseReferences<
              _$KomaCacheDatabase,
              $CachedMangasTable,
              CachedManga
            >,
          ),
          CachedManga,
          PrefetchHooks Function()
        > {
  $$CachedMangasTableTableManager(
    _$KomaCacheDatabase db,
    $CachedMangasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMangasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMangasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMangasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mangaId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMangasCompanion(
                mangaId: mangaId,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mangaId,
                required String payloadJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMangasCompanion.insert(
                mangaId: mangaId,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedMangasTable, CachedManga>(table),
                  BaseReferences<
                    _$KomaCacheDatabase,
                    $CachedMangasTable,
                    CachedManga
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMangasTableProcessedTableManager =
    ProcessedTableManager<
      _$KomaCacheDatabase,
      $CachedMangasTable,
      CachedManga,
      $$CachedMangasTableFilterComposer,
      $$CachedMangasTableOrderingComposer,
      $$CachedMangasTableAnnotationComposer,
      $$CachedMangasTableCreateCompanionBuilder,
      $$CachedMangasTableUpdateCompanionBuilder,
      (
        CachedManga,
        BaseReferences<_$KomaCacheDatabase, $CachedMangasTable, CachedManga>,
      ),
      CachedManga,
      PrefetchHooks Function()
    >;
typedef $$CachedAggregatesTableCreateCompanionBuilder =
    CachedAggregatesCompanion Function({
      required String mangaId,
      required String languagesKey,
      required String payloadJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedAggregatesTableUpdateCompanionBuilder =
    CachedAggregatesCompanion Function({
      Value<String> mangaId,
      Value<String> languagesKey,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedAggregatesTableFilterComposer
    extends Composer<_$KomaCacheDatabase, $CachedAggregatesTable> {
  $$CachedAggregatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mangaId => $composableBuilder(
    column: $table.mangaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languagesKey => $composableBuilder(
    column: $table.languagesKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAggregatesTableOrderingComposer
    extends Composer<_$KomaCacheDatabase, $CachedAggregatesTable> {
  $$CachedAggregatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mangaId => $composableBuilder(
    column: $table.mangaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languagesKey => $composableBuilder(
    column: $table.languagesKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAggregatesTableAnnotationComposer
    extends Composer<_$KomaCacheDatabase, $CachedAggregatesTable> {
  $$CachedAggregatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mangaId =>
      $composableBuilder(column: $table.mangaId, builder: (column) => column);

  GeneratedColumn<String> get languagesKey => $composableBuilder(
    column: $table.languagesKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedAggregatesTableTableManager
    extends
        RootTableManager<
          _$KomaCacheDatabase,
          $CachedAggregatesTable,
          CachedAggregate,
          $$CachedAggregatesTableFilterComposer,
          $$CachedAggregatesTableOrderingComposer,
          $$CachedAggregatesTableAnnotationComposer,
          $$CachedAggregatesTableCreateCompanionBuilder,
          $$CachedAggregatesTableUpdateCompanionBuilder,
          (
            CachedAggregate,
            BaseReferences<
              _$KomaCacheDatabase,
              $CachedAggregatesTable,
              CachedAggregate
            >,
          ),
          CachedAggregate,
          PrefetchHooks Function()
        > {
  $$CachedAggregatesTableTableManager(
    _$KomaCacheDatabase db,
    $CachedAggregatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAggregatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAggregatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAggregatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mangaId = const Value.absent(),
                Value<String> languagesKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAggregatesCompanion(
                mangaId: mangaId,
                languagesKey: languagesKey,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mangaId,
                required String languagesKey,
                required String payloadJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAggregatesCompanion.insert(
                mangaId: mangaId,
                languagesKey: languagesKey,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedAggregatesTable, CachedAggregate>(table),
                  BaseReferences<
                    _$KomaCacheDatabase,
                    $CachedAggregatesTable,
                    CachedAggregate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAggregatesTableProcessedTableManager =
    ProcessedTableManager<
      _$KomaCacheDatabase,
      $CachedAggregatesTable,
      CachedAggregate,
      $$CachedAggregatesTableFilterComposer,
      $$CachedAggregatesTableOrderingComposer,
      $$CachedAggregatesTableAnnotationComposer,
      $$CachedAggregatesTableCreateCompanionBuilder,
      $$CachedAggregatesTableUpdateCompanionBuilder,
      (
        CachedAggregate,
        BaseReferences<
          _$KomaCacheDatabase,
          $CachedAggregatesTable,
          CachedAggregate
        >,
      ),
      CachedAggregate,
      PrefetchHooks Function()
    >;

class $KomaCacheDatabaseManager {
  final _$KomaCacheDatabase _db;
  $KomaCacheDatabaseManager(this._db);
  $$CachedMangasTableTableManager get cachedMangas =>
      $$CachedMangasTableTableManager(_db, _db.cachedMangas);
  $$CachedAggregatesTableTableManager get cachedAggregates =>
      $$CachedAggregatesTableTableManager(_db, _db.cachedAggregates);
}
