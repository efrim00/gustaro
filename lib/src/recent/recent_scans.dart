import 'package:drift/drift.dart';

part 'recent_scans.g.dart';

/// On-device user data, kept separate from the catalogue so a catalogue
/// swap never touches it. Nothing here leaves the device.
@DriftDatabase(tables: [RecentScanTable, SettingTable])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(recentScanTable, recentScanTable.liked);
        await m.createTable(settingTable);
      }
    },
  );
}

@DataClassName('RecentScanRow')
class RecentScanTable extends Table {
  @override
  String get tableName => 'recent_scan';

  /// Catalogue vintage ID (stable across data versions).
  IntColumn get vintageId => integer()();
  DateTimeColumn get viewedAt => dateTime()();

  /// The user's own answer to "Did you like it?"; null until answered. Stays
  /// on the device and is never shown as a score.
  BoolColumn get liked => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {vintageId};
}

@DataClassName('SettingRow')
class SettingTable extends Table {
  @override
  String get tableName => 'setting';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

final class RecentScan {
  const RecentScan({
    required this.vintageId,
    required this.viewedAt,
    this.liked,
  });

  final int vintageId;
  final DateTime viewedAt;
  final bool? liked;
}

/// Most recently viewed results, newest first, one entry per vintage.
class RecentScansStore {
  RecentScansStore(this._db, {this.limit = 50, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UserDatabase _db;
  final int limit;
  final DateTime Function() _clock;

  /// Call when the result screen for [vintageId] is shown. Viewing the
  /// same vintage again moves it to the top.
  Future<void> record(int vintageId) => _db.transaction(() async {
    await _db
        .into(_db.recentScanTable)
        .insert(
          RecentScanTableCompanion.insert(
            vintageId: Value(vintageId),
            viewedAt: _clock(),
          ),
          // Keeps the user's "liked" answer when a wine is viewed again.
          onConflict: DoUpdate(
            (_) => RecentScanTableCompanion(viewedAt: Value(_clock())),
          ),
        );
    final keep = _db.selectOnly(_db.recentScanTable)
      ..addColumns([_db.recentScanTable.vintageId])
      ..orderBy([OrderingTerm.desc(_db.recentScanTable.viewedAt)])
      ..limit(limit);
    await (_db.delete(
      _db.recentScanTable,
    )..where((t) => t.vintageId.isNotInQuery(keep))).go();
  });

  Future<List<RecentScan>> list() async {
    final rows = await (_db.select(
      _db.recentScanTable,
    )..orderBy([(t) => OrderingTerm.desc(t.viewedAt)])).get();
    return [
      for (final row in rows)
        RecentScan(
          vintageId: row.vintageId,
          viewedAt: row.viewedAt,
          liked: row.liked,
        ),
    ];
  }

  Future<void> setLiked(int vintageId, bool? liked) =>
      (_db.update(_db.recentScanTable)
            ..where((t) => t.vintageId.equals(vintageId)))
          .write(RecentScanTableCompanion(liked: Value(liked)));

  Future<void> remove(int vintageId) => (_db.delete(
    _db.recentScanTable,
  )..where((t) => t.vintageId.equals(vintageId))).go();

  Future<void> clear() => _db.delete(_db.recentScanTable).go();
}

/// Small key/value settings kept on the device.
class SettingsStore {
  SettingsStore(this._db);

  final UserDatabase _db;

  Future<String?> read(String key) async {
    final row = await (_db.select(
      _db.settingTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) => _db
      .into(_db.settingTable)
      .insertOnConflictUpdate(
        SettingTableCompanion.insert(key: key, value: value),
      );

  Future<void> clear() => _db.delete(_db.settingTable).go();
}
