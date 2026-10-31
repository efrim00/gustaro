/// The catalogue as the editor page sees it: file name -> rows of strings.
/// Same shape as the CSV files the local editor used.
typedef Records = List<Map<String, String>>;

const wineriesFile = 'wineries.csv';
const winesFile = 'wines.csv';
const vintagesFile = 'vintages.csv';
const barcodesFile = 'barcodes.csv';
const wineTranslationsFile = 'wine_translations.csv';
const vintageTranslationsFile = 'vintage_translations.csv';

const wineTypes = {'red', 'white', 'rose', 'orange', 'sparkling', 'dessert'};

/// Texts must exist in these languages (the rest are optional).
const requiredLanguages = {'ro'};
const knownLanguages = {'ro', 'en', 'ru'};

/// IDs from here up belong to bottles added on phones.
const myBottleIdBase = 1000000000;

class Validation {
  final errors = <String>[];
  final warnings = <String>[];
  bool get isValid => errors.isEmpty;
}

int? _int(String? s) => int.tryParse((s ?? '').trim());

double? _number(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

List<String> splitList(String s) => [
  for (final part in s.split('|'))
    if (part.trim().isNotEmpty) part.trim(),
];

/// Checks [tables] the way the local editor's build did: nothing is saved
/// unless this returns no errors.
Validation validateTables(Map<String, Records> tables) {
  final v = Validation();
  Records rows(String file) => tables[file] ?? const [];

  Set<int> ids(String file, String what) {
    final seen = <int>{};
    for (final row in rows(file)) {
      final id = _int(row['id']);
      if (id == null || id <= 0 || id >= myBottleIdBase) {
        v.errors.add('$what: "${row['id']}" is not a valid id');
      } else if (!seen.add(id)) {
        v.errors.add('$what: duplicate id $id');
      }
    }
    return seen;
  }

  final wineryIds = ids(wineriesFile, 'winery');
  for (final row in rows(wineriesFile)) {
    if ((row['name'] ?? '').trim().isEmpty) {
      v.errors.add('winery ${row['id']}: name is required');
    }
  }

  final wineIds = ids(winesFile, 'wine');
  final wineNames = <int, String>{};
  for (final row in rows(winesFile)) {
    final id = _int(row['id']);
    final name = (row['name'] ?? '').trim();
    if (id != null) wineNames[id] = name;
    if (name.isEmpty) v.errors.add('wine ${row['id']}: name is required');
    if (!wineTypes.contains(row['type'])) {
      v.errors.add('wine $id: type must be one of ${wineTypes.join(', ')}');
    }
    if (!wineryIds.contains(_int(row['winery_id']))) {
      v.errors.add('wine $id: winery ${row['winery_id']} does not exist');
    }
  }

  final vintageIds = ids(vintagesFile, 'vintage');
  final vintageWine = <int, int>{};
  final yearsSeen = <(int, int)>{};
  for (final row in rows(vintagesFile)) {
    final id = _int(row['id']);
    final wineId = _int(row['wine_id']);
    final year = _int(row['year']);
    if (!wineIds.contains(wineId)) {
      v.errors.add('vintage $id: wine ${row['wine_id']} does not exist');
    } else if (id != null) {
      vintageWine[id] = wineId!;
    }
    if (year == null || year < 1900 || year > 2100) {
      v.errors.add('vintage $id: year must be between 1900 and 2100');
    } else if (wineId != null && !yearsSeen.add((wineId, year))) {
      v.errors.add('vintage $id: wine $wineId already has the year $year');
    }
    for (final column in [
      'abv',
      'acidity_g_l',
      'tannins_g_l',
      'residual_sugar_g_l',
    ]) {
      final text = (row[column] ?? '').trim();
      if (text.isEmpty) continue;
      final n = _number(text);
      if (n == null || n < 0 || (column == 'abv' && n > 100)) {
        v.errors.add('vintage $id: $column "$text" is not a valid number');
      } else if (n == 0) {
        v.warnings.add(
          'vintage $id: $column is 0; leave it empty if unknown '
          '(the app would show 0)',
        );
      }
    }
  }
  final winesWithVintage = vintageWine.values.toSet();

  final winesWithBarcode = <int>{};
  for (final row in rows(barcodesFile)) {
    final code = (row['code'] ?? '').trim();
    final wineId = _int(row['wine_id']);
    if (!RegExp(r'^\d+$').hasMatch(code)) {
      v.errors.add('barcode "$code": only digits are allowed');
    }
    if (!wineIds.contains(wineId)) {
      v.errors.add('barcode $code: wine ${row['wine_id']} does not exist');
      continue;
    }
    winesWithBarcode.add(wineId!);
    final vintageText = (row['vintage_id'] ?? '').trim();
    if (vintageText.isNotEmpty) {
      final vintageId = _int(vintageText);
      if (!vintageIds.contains(vintageId) || vintageWine[vintageId] != wineId) {
        v.errors.add(
          'barcode $code: year $vintageText does not belong to wine $wineId',
        );
      }
    }
    final size = (row['bottle_size_ml'] ?? '').trim();
    if (size.isNotEmpty && (_int(size) ?? 0) <= 0) {
      v.errors.add('barcode $code: bottle size "$size" is not valid');
    }
  }

  final wineLangs = <(int, String)>{};
  for (final row in rows(wineTranslationsFile)) {
    final wineId = _int(row['wine_id']);
    final lang = row['lang'] ?? '';
    if (!wineIds.contains(wineId) || !knownLanguages.contains(lang)) {
      v.errors.add(
        'wine text: wine ${row['wine_id']} / language "$lang" is not valid',
      );
    } else if (!wineLangs.add((wineId!, lang))) {
      v.errors.add('wine $wineId has two "$lang" texts');
    }
  }
  final vintageLangs = <(int, String)>{};
  for (final row in rows(vintageTranslationsFile)) {
    final vintageId = _int(row['vintage_id']);
    final lang = row['lang'] ?? '';
    if (!vintageIds.contains(vintageId) || !knownLanguages.contains(lang)) {
      v.errors.add(
        'year text: year ${row['vintage_id']} / language "$lang" is not valid',
      );
    } else if (!vintageLangs.add((vintageId!, lang))) {
      v.errors.add('year $vintageId has two "$lang" texts');
    }
  }

  for (final MapEntry(key: id, value: name) in wineNames.entries) {
    if (!winesWithVintage.contains(id)) {
      v.errors.add('wine $id ($name) has no year');
    }
    if (!winesWithBarcode.contains(id)) {
      v.warnings.add(
        'wine $id ($name) has no barcode; only label scans can find it',
      );
    }
    for (final lang in requiredLanguages) {
      if (!wineLangs.contains((id, lang))) {
        v.errors.add('wine $id ($name) is missing its "$lang" text');
      }
    }
  }
  for (final id in vintageWine.keys) {
    for (final lang in requiredLanguages) {
      if (!vintageLangs.contains((id, lang))) {
        v.errors.add('year $id is missing its "$lang" text');
      }
    }
  }
  if (wineNames.isEmpty) v.warnings.add('the catalogue has no wines');
  return v;
}
