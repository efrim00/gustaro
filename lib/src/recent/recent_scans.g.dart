// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_scans.dart';

// ignore_for_file: type=lint
class $RecentScanTableTable extends RecentScanTable
    with TableInfo<$RecentScanTableTable, RecentScanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentScanTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vintageIdMeta = const VerificationMeta(
    'vintageId',
  );
  @override
  late final GeneratedColumn<int> vintageId = GeneratedColumn<int>(
    'vintage_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viewedAtMeta = const VerificationMeta(
    'viewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> viewedAt = GeneratedColumn<DateTime>(
    'viewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _likedMeta = const VerificationMeta('liked');
  @override
  late final GeneratedColumn<bool> liked = GeneratedColumn<bool>(
    'liked',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("liked" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [vintageId, viewedAt, liked];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_scan';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentScanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vintage_id')) {
      context.handle(
        _vintageIdMeta,
        vintageId.isAcceptableOrUnknown(data['vintage_id']!, _vintageIdMeta),
      );
    }
    if (data.containsKey('viewed_at')) {
      context.handle(
        _viewedAtMeta,
        viewedAt.isAcceptableOrUnknown(data['viewed_at']!, _viewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_viewedAtMeta);
    }
    if (data.containsKey('liked')) {
      context.handle(
        _likedMeta,
        liked.isAcceptableOrUnknown(data['liked']!, _likedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vintageId};
  @override
  RecentScanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentScanRow(
      vintageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vintage_id'],
      )!,
      viewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}viewed_at'],
      )!,
      liked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}liked'],
      ),
    );
  }

  @override
  $RecentScanTableTable createAlias(String alias) {
    return $RecentScanTableTable(attachedDatabase, alias);
  }
}

class RecentScanRow extends DataClass implements Insertable<RecentScanRow> {
  /// Catalogue vintage ID (stable across data versions).
  final int vintageId;
  final DateTime viewedAt;

  /// The user's own answer to "Did you like it?"; null until answered. Stays
  /// on the device and is never shown as a score.
  final bool? liked;
  const RecentScanRow({
    required this.vintageId,
    required this.viewedAt,
    this.liked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vintage_id'] = Variable<int>(vintageId);
    map['viewed_at'] = Variable<DateTime>(viewedAt);
    if (!nullToAbsent || liked != null) {
      map['liked'] = Variable<bool>(liked);
    }
    return map;
  }

  RecentScanTableCompanion toCompanion(bool nullToAbsent) {
    return RecentScanTableCompanion(
      vintageId: Value(vintageId),
      viewedAt: Value(viewedAt),
      liked: liked == null && nullToAbsent
          ? const Value.absent()
          : Value(liked),
    );
  }

  factory RecentScanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentScanRow(
      vintageId: serializer.fromJson<int>(json['vintageId']),
      viewedAt: serializer.fromJson<DateTime>(json['viewedAt']),
      liked: serializer.fromJson<bool?>(json['liked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vintageId': serializer.toJson<int>(vintageId),
      'viewedAt': serializer.toJson<DateTime>(viewedAt),
      'liked': serializer.toJson<bool?>(liked),
    };
  }

  RecentScanRow copyWith({
    int? vintageId,
    DateTime? viewedAt,
    Value<bool?> liked = const Value.absent(),
  }) => RecentScanRow(
    vintageId: vintageId ?? this.vintageId,
    viewedAt: viewedAt ?? this.viewedAt,
    liked: liked.present ? liked.value : this.liked,
  );
  RecentScanRow copyWithCompanion(RecentScanTableCompanion data) {
    return RecentScanRow(
      vintageId: data.vintageId.present ? data.vintageId.value : this.vintageId,
      viewedAt: data.viewedAt.present ? data.viewedAt.value : this.viewedAt,
      liked: data.liked.present ? data.liked.value : this.liked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentScanRow(')
          ..write('vintageId: $vintageId, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('liked: $liked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(vintageId, viewedAt, liked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentScanRow &&
          other.vintageId == this.vintageId &&
          other.viewedAt == this.viewedAt &&
          other.liked == this.liked);
}

class RecentScanTableCompanion extends UpdateCompanion<RecentScanRow> {
  final Value<int> vintageId;
  final Value<DateTime> viewedAt;
  final Value<bool?> liked;
  const RecentScanTableCompanion({
    this.vintageId = const Value.absent(),
    this.viewedAt = const Value.absent(),
    this.liked = const Value.absent(),
  });
  RecentScanTableCompanion.insert({
    this.vintageId = const Value.absent(),
    required DateTime viewedAt,
    this.liked = const Value.absent(),
  }) : viewedAt = Value(viewedAt);
  static Insertable<RecentScanRow> custom({
    Expression<int>? vintageId,
    Expression<DateTime>? viewedAt,
    Expression<bool>? liked,
  }) {
    return RawValuesInsertable({
      if (vintageId != null) 'vintage_id': vintageId,
      if (viewedAt != null) 'viewed_at': viewedAt,
      if (liked != null) 'liked': liked,
    });
  }

  RecentScanTableCompanion copyWith({
    Value<int>? vintageId,
    Value<DateTime>? viewedAt,
    Value<bool?>? liked,
  }) {
    return RecentScanTableCompanion(
      vintageId: vintageId ?? this.vintageId,
      viewedAt: viewedAt ?? this.viewedAt,
      liked: liked ?? this.liked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vintageId.present) {
      map['vintage_id'] = Variable<int>(vintageId.value);
    }
    if (viewedAt.present) {
      map['viewed_at'] = Variable<DateTime>(viewedAt.value);
    }
    if (liked.present) {
      map['liked'] = Variable<bool>(liked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentScanTableCompanion(')
          ..write('vintageId: $vintageId, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('liked: $liked')
          ..write(')'))
        .toString();
  }
}

class $SettingTableTable extends SettingTable
    with TableInfo<$SettingTableTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingTableTable createAlias(String alias) {
    return $SettingTableTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingTableCompanion toCompanion(bool nullToAbsent) {
    return SettingTableCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingTableCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingTableCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $RecentScanTableTable recentScanTable = $RecentScanTableTable(
    this,
  );
  late final $SettingTableTable settingTable = $SettingTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recentScanTable,
    settingTable,
  ];
}

typedef $$RecentScanTableTableCreateCompanionBuilder =
    RecentScanTableCompanion Function({
      Value<int> vintageId,
      required DateTime viewedAt,
      Value<bool?> liked,
    });
typedef $$RecentScanTableTableUpdateCompanionBuilder =
    RecentScanTableCompanion Function({
      Value<int> vintageId,
      Value<DateTime> viewedAt,
      Value<bool?> liked,
    });

class $$RecentScanTableTableFilterComposer
    extends Composer<_$UserDatabase, $RecentScanTableTable> {
  $$RecentScanTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get vintageId => $composableBuilder(
    column: $table.vintageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get viewedAt => $composableBuilder(
    column: $table.viewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get liked => $composableBuilder(
    column: $table.liked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentScanTableTableOrderingComposer
    extends Composer<_$UserDatabase, $RecentScanTableTable> {
  $$RecentScanTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get vintageId => $composableBuilder(
    column: $table.vintageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get viewedAt => $composableBuilder(
    column: $table.viewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get liked => $composableBuilder(
    column: $table.liked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentScanTableTableAnnotationComposer
    extends Composer<_$UserDatabase, $RecentScanTableTable> {
  $$RecentScanTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get vintageId =>
      $composableBuilder(column: $table.vintageId, builder: (column) => column);

  GeneratedColumn<DateTime> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => column);

  GeneratedColumn<bool> get liked =>
      $composableBuilder(column: $table.liked, builder: (column) => column);
}

class $$RecentScanTableTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $RecentScanTableTable,
          RecentScanRow,
          $$RecentScanTableTableFilterComposer,
          $$RecentScanTableTableOrderingComposer,
          $$RecentScanTableTableAnnotationComposer,
          $$RecentScanTableTableCreateCompanionBuilder,
          $$RecentScanTableTableUpdateCompanionBuilder,
          (
            RecentScanRow,
            BaseReferences<
              _$UserDatabase,
              $RecentScanTableTable,
              RecentScanRow
            >,
          ),
          RecentScanRow,
          PrefetchHooks Function()
        > {
  $$RecentScanTableTableTableManager(
    _$UserDatabase db,
    $RecentScanTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentScanTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentScanTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentScanTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> vintageId = const Value.absent(),
                Value<DateTime> viewedAt = const Value.absent(),
                Value<bool?> liked = const Value.absent(),
              }) => RecentScanTableCompanion(
                vintageId: vintageId,
                viewedAt: viewedAt,
                liked: liked,
              ),
          createCompanionCallback:
              ({
                Value<int> vintageId = const Value.absent(),
                required DateTime viewedAt,
                Value<bool?> liked = const Value.absent(),
              }) => RecentScanTableCompanion.insert(
                vintageId: vintageId,
                viewedAt: viewedAt,
                liked: liked,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecentScanTableTable, RecentScanRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $RecentScanTableTable,
                    RecentScanRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentScanTableTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $RecentScanTableTable,
      RecentScanRow,
      $$RecentScanTableTableFilterComposer,
      $$RecentScanTableTableOrderingComposer,
      $$RecentScanTableTableAnnotationComposer,
      $$RecentScanTableTableCreateCompanionBuilder,
      $$RecentScanTableTableUpdateCompanionBuilder,
      (
        RecentScanRow,
        BaseReferences<_$UserDatabase, $RecentScanTableTable, RecentScanRow>,
      ),
      RecentScanRow,
      PrefetchHooks Function()
    >;
typedef $$SettingTableTableCreateCompanionBuilder =
    SettingTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingTableTableUpdateCompanionBuilder =
    SettingTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingTableTableFilterComposer
    extends Composer<_$UserDatabase, $SettingTableTable> {
  $$SettingTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingTableTableOrderingComposer
    extends Composer<_$UserDatabase, $SettingTableTable> {
  $$SettingTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingTableTableAnnotationComposer
    extends Composer<_$UserDatabase, $SettingTableTable> {
  $$SettingTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingTableTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SettingTableTable,
          SettingRow,
          $$SettingTableTableFilterComposer,
          $$SettingTableTableOrderingComposer,
          $$SettingTableTableAnnotationComposer,
          $$SettingTableTableCreateCompanionBuilder,
          $$SettingTableTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$UserDatabase, $SettingTableTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingTableTableTableManager(_$UserDatabase db, $SettingTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingTableTable, SettingRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $SettingTableTable,
                    SettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingTableTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SettingTableTable,
      SettingRow,
      $$SettingTableTableFilterComposer,
      $$SettingTableTableOrderingComposer,
      $$SettingTableTableAnnotationComposer,
      $$SettingTableTableCreateCompanionBuilder,
      $$SettingTableTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$UserDatabase, $SettingTableTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$RecentScanTableTableTableManager get recentScanTable =>
      $$RecentScanTableTableTableManager(_db, _db.recentScanTable);
  $$SettingTableTableTableManager get settingTable =>
      $$SettingTableTableTableManager(_db, _db.settingTable);
}
