import 'package:drift/drift.dart';

import 'catalog_database.dart';
import 'models.dart';

/// What the scan flow and screens need to read wines, wherever they live.
abstract interface class CatalogReader {
  Future<List<BarcodeHit>> findBarcodes(Set<String> codes);
  Future<Map<int, List<VintageOption>>> vintagesOf(Set<int> wineIds);
  Future<List<LabelIndexEntry>> labelIndex();
  Future<VintageDetails?> vintageDetails(int vintageId, {String language});
  Future<Map<int, VintageSummary>> vintageSummaries(Set<int> vintageIds);
}

/// Read-only queries over one catalogue database. Returns domain models only.
class CatalogRepository implements CatalogReader {
  CatalogRepository(this._db);

  final CatalogDatabase _db;

  /// Language used when a text is missing in the requested one.
  static const String fallbackLanguage = 'ro';

  @override
  Future<List<BarcodeHit>> findBarcodes(Set<String> codes) async {
    if (codes.isEmpty) return const [];
    final b = _db.barcodeTable;
    final query = _db.select(b).join(_wineJoins(b.wineId))
      ..where(b.code.isIn(codes))
      ..orderBy([OrderingTerm.asc(b.id)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        BarcodeHit(
          wine: _wineSummary(row),
          vintageId: row.readTable(b).vintageId,
          bottleSizeMl: row.readTable(b).bottleSizeMl,
        ),
    ];
  }

  /// Verified vintages per wine, newest first. Wines without vintages are
  /// absent from the map.
  @override
  Future<Map<int, List<VintageOption>>> vintagesOf(Set<int> wineIds) async {
    if (wineIds.isEmpty) return const {};
    final v = _db.vintageTable;
    final rows =
        await (_db.select(v)
              ..where((t) => t.wineId.isIn(wineIds))
              ..orderBy([(t) => OrderingTerm.desc(t.year)]))
            .get();
    final result = <int, List<VintageOption>>{};
    for (final row in rows) {
      (result[row.wineId] ??= []).add(
        VintageOption(id: row.id, year: row.year),
      );
    }
    return result;
  }

  /// Every wine with at least one verified vintage, for label matching.
  @override
  Future<List<LabelIndexEntry>> labelIndex() async {
    final w = _db.wineTable;
    final query = _db.select(w).join([
      innerJoin(_db.wineryTable, _db.wineryTable.id.equalsExp(w.wineryId)),
    ])..orderBy([OrderingTerm.asc(w.id)]);
    final wines = [for (final row in await query.get()) _wineSummary(row)];
    final vintages = await vintagesOf({for (final wine in wines) wine.id});
    return [
      for (final wine in wines)
        if (vintages[wine.id] case final list?)
          LabelIndexEntry(wine: wine, vintages: list),
    ];
  }

  /// Full data for the result screen, texts in [language] with a fallback
  /// to Romanian per field group. Null if the vintage does not exist.
  @override
  Future<VintageDetails?> vintageDetails(
    int vintageId, {
    String language = fallbackLanguage,
  }) async {
    final v = _db.vintageTable;
    final row =
        await (_db.select(v).join(_wineJoins(v.wineId))
              ..where(v.id.equals(vintageId)))
            .getSingleOrNull();
    if (row == null) return null;
    final vintage = row.readTable(v);
    final wine = row.readTable(_db.wineTable);
    final languages = {language, fallbackLanguage};

    final wineTexts = await (_db.select(
      _db.wineTranslationTable,
    )..where((t) => t.wineId.equals(wine.id) & t.lang.isIn(languages))).get();
    final vintageTexts =
        await (_db.select(_db.vintageTranslationTable)..where(
              (t) => t.vintageId.equals(vintageId) & t.lang.isIn(languages),
            ))
            .get();
    final wineText = _preferLanguage(wineTexts, (t) => t.lang, language);
    final vintageText = _preferLanguage(vintageTexts, (t) => t.lang, language);

    return VintageDetails(
      vintageId: vintage.id,
      year: vintage.year,
      wine: _wineSummary(row),
      region: row.readTable(_db.wineryTable).region,
      grapeVarieties: wine.grapeVarieties,
      abv: vintage.abv,
      acidityGL: vintage.acidityGL,
      tanninsGL: vintage.tanninsGL,
      residualSugarGL: vintage.residualSugarGL,
      language: vintageText?.lang ?? wineText?.lang ?? fallbackLanguage,
      description: wineText?.description,
      sensoryNotes: vintageText?.sensoryNotes,
      foodPairings: vintageText?.foodPairings ?? const [],
    );
  }

  /// Summaries for the given vintage IDs. IDs that no longer exist in the
  /// catalogue are silently absent.
  @override
  Future<Map<int, VintageSummary>> vintageSummaries(Set<int> vintageIds) async {
    if (vintageIds.isEmpty) return const {};
    final v = _db.vintageTable;
    final rows =
        await (_db.select(v).join(_wineJoins(v.wineId))
              ..where(v.id.isIn(vintageIds)))
            .get();
    return {
      for (final row in rows)
        row.readTable(v).id: VintageSummary(
          vintageId: row.readTable(v).id,
          year: row.readTable(v).year,
          wine: _wineSummary(row),
        ),
    };
  }

  Future<MetaRow?> meta() => _db.select(_db.metaTable).getSingleOrNull();

  List<Join> _wineJoins(Expression<int> wineId) => [
    innerJoin(_db.wineTable, _db.wineTable.id.equalsExp(wineId)),
    innerJoin(
      _db.wineryTable,
      _db.wineryTable.id.equalsExp(_db.wineTable.wineryId),
    ),
  ];

  WineSummary _wineSummary(TypedResult row) {
    final wine = row.readTable(_db.wineTable);
    return WineSummary(
      id: wine.id,
      name: wine.name,
      wineryName: row.readTable(_db.wineryTable).name,
      type: wine.type,
      region: row.readTable(_db.wineryTable).region,
    );
  }

  static T? _preferLanguage<T>(
    List<T> rows,
    String Function(T) langOf,
    String language,
  ) {
    for (final row in rows) {
      if (langOf(row) == language) return row;
    }
    return rows.isEmpty ? null : rows.first;
  }
}
