import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:gustaro/src/catalog/catalog_database.dart';
import 'package:gustaro/src/catalog/models.dart';

/// Every wine and vintage must have a translation row in these languages.
const requiredLanguages = {'ro'};
const supportedLanguages = {'ro', 'en', 'ru'};

/// Separates items inside one cell (grape varieties, food pairings).
const listSeparator = '|';

/// Source files and the columns each must have. Extra columns (e.g. your
/// own notes) are allowed and ignored.
const catalogFiles = {
  'wineries.csv': ['id', 'name', 'region'],
  'wines.csv': ['id', 'winery_id', 'name', 'type', 'grape_varieties'],
  'vintages.csv': [
    'id',
    'wine_id',
    'year',
    'abv',
    'acidity_g_l',
    'tannins_g_l',
    'residual_sugar_g_l',
  ],
  'barcodes.csv': ['code', 'wine_id', 'vintage_id', 'bottle_size_ml'],
  'wine_translations.csv': ['wine_id', 'lang', 'description'],
  'vintage_translations.csv': [
    'vintage_id',
    'lang',
    'sensory_notes',
    'food_pairings',
  ],
};

/// Result of validating the CSV files. Only write it when [errors] is empty.
final class CatalogBuild {
  final errors = <String>[];
  final warnings = <String>[];
  final wineries = <WineryTableCompanion>[];
  final wines = <WineTableCompanion>[];
  final vintages = <VintageTableCompanion>[];
  final barcodes = <BarcodeTableCompanion>[];
  final wineTranslations = <WineTranslationTableCompanion>[];
  final vintageTranslations = <VintageTranslationTableCompanion>[];

  bool get isValid => errors.isEmpty;
}

final class _Row {
  _Row(this.file, this.number, this._cells);

  final String file;

  /// 1-based, header is row 1, as shown in a spreadsheet.
  final int number;
  final Map<String, String> _cells;

  String operator [](String column) => (_cells[column] ?? '').trim();
  String get where => '$file row $number';
}

// Excel shows long numbers like 4840000000010 as 4.84E+12 and saves them so.
final RegExp _scientific = RegExp(r'^\d+([.,]\d+)?[eE][+]?\d+$');

/// Validates the CSV files (file name → content) and converts them to rows.
/// A missing file counts as an empty table.
CatalogBuild validateCatalog(Map<String, String> csvFiles, {DateTime? now}) {
  final build = CatalogBuild();
  final c = _Checker(build);
  final maxYear = (now ?? DateTime.now()).year + 1;

  final tables = {
    for (final MapEntry(key: file, value: columns) in catalogFiles.entries)
      file: _parse(file, csvFiles[file], columns, build),
  };

  final wineryIds = <int>{};
  for (final row in tables['wineries.csv']!) {
    final id = c.catalogId(row);
    final name = c.text(row, 'name', required: true);
    if (id == null || name == null) continue;
    if (!wineryIds.add(id)) {
      c.error(row, 'duplicate winery id $id');
      continue;
    }
    build.wineries.add(
      WineryTableCompanion.insert(
        id: Value(id),
        name: name,
        region: Value(c.text(row, 'region')),
      ),
    );
  }

  final wineNames = <int, String>{};
  for (final row in tables['wines.csv']!) {
    final id = c.catalogId(row);
    final wineryId = c.integer(row, 'winery_id', required: true);
    final name = c.text(row, 'name', required: true);
    final type = c.wineType(row);
    if (id == null || wineryId == null || name == null || type == null) {
      continue;
    }
    if (!wineryIds.contains(wineryId)) {
      c.error(row, 'winery_id $wineryId does not exist in wineries.csv');
      continue;
    }
    if (wineNames.containsKey(id)) {
      c.error(row, 'duplicate wine id $id');
      continue;
    }
    wineNames[id] = name;
    build.wines.add(
      WineTableCompanion.insert(
        id: Value(id),
        wineryId: wineryId,
        name: name,
        type: type,
        grapeVarieties: Value(c.list(row, 'grape_varieties')),
      ),
    );
  }

  final vintageWine = <int, int>{};
  final wineYears = <(int, int)>{};
  for (final row in tables['vintages.csv']!) {
    final id = c.catalogId(row);
    final wineId = c.integer(row, 'wine_id', required: true);
    final year = c.integer(row, 'year', required: true);
    final abv = c.decimal(row, 'abv', max: 100);
    final acidity = c.decimal(row, 'acidity_g_l');
    final tannins = c.decimal(row, 'tannins_g_l');
    final sugar = c.decimal(row, 'residual_sugar_g_l');
    if (id == null || wineId == null || year == null) continue;
    if (year < 1900 || year > maxYear) {
      c.error(row, 'year $year is outside 1900–$maxYear');
      continue;
    }
    if (!wineNames.containsKey(wineId)) {
      c.error(row, 'wine_id $wineId does not exist in wines.csv');
      continue;
    }
    if (vintageWine.containsKey(id)) {
      c.error(row, 'duplicate vintage id $id');
      continue;
    }
    if (!wineYears.add((wineId, year))) {
      c.error(row, 'wine $wineId already has a $year vintage');
      continue;
    }
    vintageWine[id] = wineId;
    build.vintages.add(
      VintageTableCompanion.insert(
        id: Value(id),
        wineId: wineId,
        year: year,
        abv: Value(abv),
        acidityGL: Value(acidity),
        tanninsGL: Value(tannins),
        residualSugarGL: Value(sugar),
      ),
    );
  }

  final barcodeKeys = <(String, int, int?, int?)>{};
  final winesByCode = <String, Set<int>>{};
  for (final row in tables['barcodes.csv']!) {
    final code = c.text(row, 'code', required: true);
    final wineId = c.integer(row, 'wine_id', required: true);
    final vintageId = c.integer(row, 'vintage_id');
    final size = c.integer(row, 'bottle_size_ml');
    if (code == null || wineId == null) continue;
    if (_scientific.hasMatch(code)) {
      c.error(
        row,
        'code "$code" was turned into a number by the spreadsheet; '
        'format the code column as Text and re-type it',
      );
      continue;
    }
    if (!wineNames.containsKey(wineId)) {
      c.error(row, 'wine_id $wineId does not exist in wines.csv');
      continue;
    }
    if (vintageId != null && vintageWine[vintageId] != wineId) {
      c.error(
        row,
        vintageWine.containsKey(vintageId)
            ? 'vintage_id $vintageId belongs to wine ${vintageWine[vintageId]}, not $wineId'
            : 'vintage_id $vintageId does not exist in vintages.csv',
      );
      continue;
    }
    if (size != null && size <= 0) {
      c.error(row, 'bottle_size_ml must be positive');
      continue;
    }
    if (!barcodeKeys.add((code, wineId, vintageId, size))) {
      c.error(row, 'duplicate barcode row');
      continue;
    }
    (winesByCode[code] ??= {}).add(wineId);
    build.barcodes.add(
      BarcodeTableCompanion.insert(
        id: Value(build.barcodes.length + 1),
        code: code,
        wineId: wineId,
        vintageId: Value(vintageId),
        bottleSizeMl: Value(size),
      ),
    );
  }

  final wineLangs = <(int, String)>{};
  for (final row in tables['wine_translations.csv']!) {
    final wineId = c.integer(row, 'wine_id', required: true);
    final lang = c.language(row);
    if (wineId == null || lang == null) continue;
    if (!wineNames.containsKey(wineId)) {
      c.error(row, 'wine_id $wineId does not exist in wines.csv');
      continue;
    }
    if (!wineLangs.add((wineId, lang))) {
      c.error(row, 'duplicate "$lang" translation for wine $wineId');
      continue;
    }
    final description = c.text(row, 'description');
    if (description == null) c.warning(row, 'description is empty');
    build.wineTranslations.add(
      WineTranslationTableCompanion.insert(
        wineId: wineId,
        lang: lang,
        description: Value(description),
      ),
    );
  }

  final vintageLangs = <(int, String)>{};
  for (final row in tables['vintage_translations.csv']!) {
    final vintageId = c.integer(row, 'vintage_id', required: true);
    final lang = c.language(row);
    if (vintageId == null || lang == null) continue;
    if (!vintageWine.containsKey(vintageId)) {
      c.error(row, 'vintage_id $vintageId does not exist in vintages.csv');
      continue;
    }
    if (!vintageLangs.add((vintageId, lang))) {
      c.error(row, 'duplicate "$lang" translation for vintage $vintageId');
      continue;
    }
    final notes = c.text(row, 'sensory_notes');
    if (notes == null) c.warning(row, 'sensory_notes is empty');
    build.vintageTranslations.add(
      VintageTranslationTableCompanion.insert(
        vintageId: vintageId,
        lang: lang,
        sensoryNotes: Value(notes),
        foodPairings: Value(c.list(row, 'food_pairings')),
      ),
    );
  }

  // Whole-catalogue checks.
  final winesWithVintage = vintageWine.values.toSet();
  final winesWithBarcode = {for (final ids in winesByCode.values) ...ids};
  for (final MapEntry(key: id, value: name) in wineNames.entries) {
    if (!winesWithVintage.contains(id)) {
      build.errors.add('wine $id ($name) has no vintage in vintages.csv');
    }
    if (!winesWithBarcode.contains(id)) {
      build.warnings.add(
        'wine $id ($name) has no barcode; only label scans can find it',
      );
    }
    for (final lang in requiredLanguages) {
      if (!wineLangs.contains((id, lang))) {
        build.errors.add('wine $id ($name) is missing its "$lang" translation');
      }
    }
  }
  for (final MapEntry(key: id, value: wineId) in vintageWine.entries) {
    for (final lang in requiredLanguages) {
      if (!vintageLangs.contains((id, lang))) {
        build.errors.add(
          'vintage $id (wine $wineId) is missing its "$lang" translation',
        );
      }
    }
  }
  for (final MapEntry(key: code, value: wineIds) in winesByCode.entries) {
    if (wineIds.length > 1) {
      build.warnings.add(
        'barcode $code is shared by wines ${wineIds.join(', ')} '
        '(users will pick from a list)',
      );
    }
  }
  if (wineNames.isEmpty) build.warnings.add('the catalogue has no wines');
  return build;
}

List<_Row> _parse(
  String file,
  String? content,
  List<String> requiredColumns,
  CatalogBuild build,
) {
  if (content == null) {
    build.warnings.add('$file not found, treated as empty');
    return const [];
  }
  final text = content.startsWith('﻿') ? content.substring(1) : content;
  final rows = Csv(skipEmptyLines: false).decode(text);
  if (rows.isEmpty) return const [];

  final header = [
    for (final cell in rows.first) cell.toString().trim().toLowerCase(),
  ];
  final missing = requiredColumns.where((col) => !header.contains(col));
  if (missing.isNotEmpty) {
    build.errors.add('$file is missing column(s): ${missing.join(', ')}');
    return const [];
  }

  final result = <_Row>[];
  for (var i = 1; i < rows.length; i++) {
    final cells = rows[i].map((cell) => cell.toString()).toList();
    if (cells.every((cell) => cell.trim().isEmpty)) continue;
    result.add(
      _Row(file, i + 1, {
        for (var col = 0; col < header.length && col < cells.length; col++)
          header[col]: cells[col],
      }),
    );
  }
  return result;
}

class _Checker {
  _Checker(this._build);

  final CatalogBuild _build;

  void error(_Row row, String message) =>
      _build.errors.add('${row.where}: $message');

  void warning(_Row row, String message) =>
      _build.warnings.add('${row.where}: $message');

  String? text(_Row row, String column, {bool required = false}) {
    final value = row[column];
    if (value.isNotEmpty) return value;
    if (required) error(row, '$column is required');
    return null;
  }

  int? integer(_Row row, String column, {bool required = false}) {
    final value = text(row, column, required: required);
    if (value == null) return null;
    final number = int.tryParse(value);
    if (number == null) {
      error(row, '$column must be a whole number, got "$value"');
    }
    return number;
  }

  /// IDs from [myBottleIdBase] up are reserved for bottles added on phones.
  int? catalogId(_Row row) {
    final id = integer(row, 'id', required: true);
    if (id != null && id >= myBottleIdBase) {
      error(row, 'id must be below $myBottleIdBase');
      return null;
    }
    return id;
  }

  /// Accepts a decimal comma ("13,5") as spreadsheets in Romanian use it.
  double? decimal(_Row row, String column, {double? max}) {
    final value = text(row, column);
    if (value == null) return null;
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number < 0 || (max != null && number > max)) {
      error(row, '$column must be a number >= 0, got "$value"');
      return null;
    }
    return number;
  }

  List<String> list(_Row row, String column) => [
    for (final item in row[column].split(listSeparator))
      if (item.trim().isNotEmpty) item.trim(),
  ];

  WineType? wineType(_Row row) {
    final value = text(row, 'type', required: true);
    if (value == null) return null;
    final type = WineType.values.asNameMap()[value.toLowerCase()];
    if (type == null) {
      error(
        row,
        'type "$value" is not one of ${WineType.values.map((t) => t.name).join(', ')}',
      );
    }
    return type;
  }

  String? language(_Row row) {
    final value = text(row, 'lang', required: true)?.toLowerCase();
    if (value == null) return null;
    if (!supportedLanguages.contains(value)) {
      error(
        row,
        'lang "$value" is not one of ${supportedLanguages.join(', ')}',
      );
      return null;
    }
    return value;
  }
}

/// Writes a validated build into an empty database, plus the meta row.
Future<void> writeCatalog(
  CatalogBuild build,
  CatalogDatabase db, {
  required int dataVersion,
  required DateTime builtAt,
}) {
  if (!build.isValid) {
    throw StateError('refusing to write a catalogue with errors');
  }
  return db.batch((b) {
    b.insertAll(db.wineryTable, build.wineries);
    b.insertAll(db.wineTable, build.wines);
    b.insertAll(db.vintageTable, build.vintages);
    b.insertAll(db.barcodeTable, build.barcodes);
    b.insertAll(db.wineTranslationTable, build.wineTranslations);
    b.insertAll(db.vintageTranslationTable, build.vintageTranslations);
    b.insert(
      db.metaTable,
      MetaTableCompanion.insert(
        dataVersion: dataVersion,
        schemaVersion: CatalogDatabase.currentSchemaVersion,
        builtAt: builtAt.toUtc().toIso8601String(),
      ),
    );
  });
}
