import 'package:drift/drift.dart';

import '../catalog/catalog_database.dart';
import '../catalog/models.dart';
import '../scan/text_normalizer.dart';

/// A bottle entered on the device. Only the fields a label always has are
/// required; everything else is optional, like in the catalogue.
final class NewBottle {
  const NewBottle({
    required this.wineryName,
    required this.wineName,
    required this.type,
    required this.year,
    this.barcode,
    this.region,
    this.grapeVarieties = const [],
    this.abv,
    this.acidityGL,
    this.tanninsGL,
    this.residualSugarGL,
    this.bottleSizeMl,
    this.description,
    this.sensoryNotes,
    this.foodPairings = const [],
  });

  final String wineryName;
  final String wineName;
  final WineType type;
  final int year;
  final String? barcode;
  final String? region;
  final List<String> grapeVarieties;
  final double? abv;
  final double? acidityGL;
  final double? tanninsGL;
  final double? residualSugarGL;
  final int? bottleSizeMl;
  final String? description;
  final String? sensoryNotes;
  final List<String> foodPairings;
}

/// Thrown by [MyBottlesStore.add] when that wine and year already exist.
final class BottleAlreadyAdded implements Exception {
  const BottleAlreadyAdded(this.vintageId);

  final int vintageId;
}

/// Bottles added on this device. They use the catalogue schema so scanning
/// and the wine page treat them like any other wine, and they survive
/// catalogue updates because they live in their own database file. They are
/// never sent anywhere.
class MyBottlesStore {
  MyBottlesStore(this._db);

  final CatalogDatabase _db;

  /// Language tag of the texts typed on the device.
  static const String language = 'en';

  /// Saves [bottle] and returns its vintage ID, ready to scan or open.
  Future<int> add(NewBottle bottle) => _db.transaction(() async {
    final wineryId = await _wineryFor(bottle);
    final wineId = await _wineFor(bottle, wineryId);

    final existing =
        await (_db.select(_db.vintageTable)..where(
              (t) => t.wineId.equals(wineId) & t.year.equals(bottle.year),
            ))
            .getSingleOrNull();
    if (existing != null) throw BottleAlreadyAdded(existing.id);

    final vintageId = await _nextId(_db.vintageTable, _db.vintageTable.id);
    await _db
        .into(_db.vintageTable)
        .insert(
          VintageTableCompanion.insert(
            id: Value(vintageId),
            wineId: wineId,
            year: bottle.year,
            abv: Value(bottle.abv),
            acidityGL: Value(bottle.acidityGL),
            tanninsGL: Value(bottle.tanninsGL),
            residualSugarGL: Value(bottle.residualSugarGL),
          ),
        );
    await _db
        .into(_db.vintageTranslationTable)
        .insert(
          VintageTranslationTableCompanion.insert(
            vintageId: vintageId,
            lang: language,
            sensoryNotes: Value(bottle.sensoryNotes),
            foodPairings: Value(bottle.foodPairings),
          ),
        );
    if (bottle.barcode case final code?) {
      await _db
          .into(_db.barcodeTable)
          .insert(
            BarcodeTableCompanion.insert(
              id: Value(await _nextId(_db.barcodeTable, _db.barcodeTable.id)),
              code: code,
              wineId: wineId,
              vintageId: Value(vintageId),
              bottleSizeMl: Value(bottle.bottleSizeMl),
            ),
          );
    }
    return vintageId;
  });

  /// Removes one vintage, and its wine and winery if nothing else uses them.
  Future<void> remove(int vintageId) => _db.transaction(() async {
    final vintage = await (_db.select(
      _db.vintageTable,
    )..where((t) => t.id.equals(vintageId))).getSingleOrNull();
    if (vintage == null) return;
    await (_db.delete(
      _db.barcodeTable,
    )..where((t) => t.vintageId.equals(vintageId))).go();
    await (_db.delete(
      _db.vintageTranslationTable,
    )..where((t) => t.vintageId.equals(vintageId))).go();
    await (_db.delete(
      _db.vintageTable,
    )..where((t) => t.id.equals(vintageId))).go();

    final others = await (_db.select(
      _db.vintageTable,
    )..where((t) => t.wineId.equals(vintage.wineId))).get();
    if (others.isNotEmpty) return;
    final wine = await (_db.select(
      _db.wineTable,
    )..where((t) => t.id.equals(vintage.wineId))).getSingle();
    await (_db.delete(
      _db.barcodeTable,
    )..where((t) => t.wineId.equals(wine.id))).go();
    await (_db.delete(
      _db.wineTranslationTable,
    )..where((t) => t.wineId.equals(wine.id))).go();
    await (_db.delete(_db.wineTable)..where((t) => t.id.equals(wine.id))).go();
    final siblings = await (_db.select(
      _db.wineTable,
    )..where((t) => t.wineryId.equals(wine.wineryId))).get();
    if (siblings.isEmpty) {
      await (_db.delete(
        _db.wineryTable,
      )..where((t) => t.id.equals(wine.wineryId))).go();
    }
  });

  /// Deletes every bottle added on this device.
  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_db.barcodeTable).go();
    await _db.delete(_db.vintageTranslationTable).go();
    await _db.delete(_db.vintageTable).go();
    await _db.delete(_db.wineTranslationTable).go();
    await _db.delete(_db.wineTable).go();
    await _db.delete(_db.wineryTable).go();
  });

  Future<int> _wineryFor(NewBottle bottle) async {
    final wanted = normalizeForMatching(bottle.wineryName);
    for (final row in await _db.select(_db.wineryTable).get()) {
      if (normalizeForMatching(row.name) == wanted) return row.id;
    }
    final id = await _nextId(_db.wineryTable, _db.wineryTable.id);
    await _db
        .into(_db.wineryTable)
        .insert(
          WineryTableCompanion.insert(
            id: Value(id),
            name: bottle.wineryName,
            region: Value(bottle.region),
          ),
        );
    return id;
  }

  Future<int> _wineFor(NewBottle bottle, int wineryId) async {
    final wanted = normalizeForMatching(bottle.wineName);
    final wines = await (_db.select(
      _db.wineTable,
    )..where((t) => t.wineryId.equals(wineryId))).get();
    for (final row in wines) {
      if (normalizeForMatching(row.name) == wanted) return row.id;
    }
    final id = await _nextId(_db.wineTable, _db.wineTable.id);
    await _db
        .into(_db.wineTable)
        .insert(
          WineTableCompanion.insert(
            id: Value(id),
            wineryId: wineryId,
            name: bottle.wineName,
            type: bottle.type,
            grapeVarieties: Value(bottle.grapeVarieties),
          ),
        );
    await _db
        .into(_db.wineTranslationTable)
        .insert(
          WineTranslationTableCompanion.insert(
            wineId: id,
            lang: language,
            description: Value(bottle.description),
          ),
        );
    return id;
  }

  Future<int> _nextId<T extends Table, R>(
    TableInfo<T, R> table,
    GeneratedColumn<int> idColumn,
  ) async {
    final max = idColumn.max();
    final row = await (_db.selectOnly(table)..addColumns([max])).getSingle();
    final current = row.read(max);
    return current == null ? myBottleIdBase : current + 1;
  }
}
