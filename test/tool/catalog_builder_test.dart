import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/gustaro_core.dart';

import '../../tool/src/catalog_builder.dart';

/// A small valid catalogue; tests override single files to break it.
Map<String, String> validFiles() => {
  'wineries.csv': 'id,name,region\n1,Crama Țărăncuța,Codru\n',
  'wines.csv':
      'id,winery_id,name,type,grape_varieties\n'
      '10,1,Fetească Neagră,red,Fetească Neagră\n'
      '11,1,Cupaj Roșu,Red,Fetească Neagră | Rară Neagră\n',
  'vintages.csv':
      'id,wine_id,year,abv,acidity_g_l,tannins_g_l,residual_sugar_g_l\n'
      '101,10,2020,"13,5",5.8,,2.1\n'
      '111,11,2021,13,,,\n',
  'barcodes.csv':
      'code,wine_id,vintage_id,bottle_size_ml\n'
      '4841000000010,10,101,750\n'
      '4841000000027,11,,\n',
  'wine_translations.csv':
      'wine_id,lang,description\n'
      '10,ro,Vin roșu sec.\n'
      '11,ro,Cupaj.\n',
  'vintage_translations.csv':
      'vintage_id,lang,sensory_notes,food_pairings\n'
      '101,ro,Vișine.,Miel | Brânză maturată\n'
      '111,ro,Prune.,\n',
};

CatalogBuild validate(Map<String, String> overrides) =>
    validateCatalog({...validFiles(), ...overrides}, now: DateTime(2026, 9));

void main() {
  test('valid catalogue: no errors, lists and decimal comma parsed', () {
    final build = validate({});
    expect(build.errors, isEmpty);
    expect(build.wines.length, 2);
    expect(build.wines[1].type.value, WineType.red, reason: 'case-insensitive');
    expect(build.wines[1].grapeVarieties.value, [
      'Fetească Neagră',
      'Rară Neagră',
    ]);
    expect(build.vintages[0].abv.value, 13.5);
    expect(build.vintages[0].tanninsGL.value, isNull);
    expect(build.vintageTranslations[0].foodPairings.value, [
      'Miel',
      'Brânză maturată',
    ]);
  });

  test('semicolon-separated CSV (Excel, Romanian locale) and BOM work', () {
    final build = validate({
      'wineries.csv': '﻿id;name;region\n1;Crama Țărăncuța;Codru\n',
    });
    expect(build.errors, isEmpty);
    expect(build.wineries.single.name.value, 'Crama Țărăncuța');
  });

  test('written catalogue is readable by the app', () async {
    final db = CatalogDatabase(NativeDatabase.memory());
    await writeCatalog(
      validate({}),
      db,
      dataVersion: 7,
      builtAt: DateTime.utc(2026, 9, 30),
    );
    final repo = CatalogRepository(db);
    expect((await repo.meta())!.dataVersion, 7);
    expect(
      (await repo.meta())!.schemaVersion,
      CatalogDatabase.currentSchemaVersion,
    );
    expect(
      await ScanService(repo).resolveBarcode('4841000000010'),
      isA<ShowVintage>(),
    );
    await db.close();
  });

  test('refuses to write a catalogue with errors', () {
    final db = CatalogDatabase(NativeDatabase.memory());
    expect(
      () => writeCatalog(
        validate({'wines.csv': 'id,winery_id,name,type,grape_varieties\n'}),
        db,
        dataVersion: 1,
        builtAt: DateTime.utc(2026),
      ),
      throwsStateError,
    );
    return db.close();
  });

  group('validation errors', () {
    void expectError(Map<String, String> overrides, String fragment) {
      final build = validate(overrides);
      expect(build.isValid, isFalse);
      expect(build.errors.join('\n'), contains(fragment));
    }

    test('missing column', () {
      expectError({
        'wineries.csv': 'id,name\n1,X\n',
      }, 'missing column(s): region');
    });

    test('required field empty, with file and row', () {
      expectError({
        'wineries.csv': 'id,name,region\n1,,Codru\n',
      }, 'wineries.csv row 2: name is required');
    });

    test('not a number', () {
      expectError({
        'vintages.csv':
            'id,wine_id,year,abv,acidity_g_l,tannins_g_l,residual_sugar_g_l\n'
            '101,10,2020,strong,,,\n111,11,2021,,,,\n',
      }, 'abv must be a number');
    });

    test('unknown wine type', () {
      expectError({
        'wines.csv':
            'id,winery_id,name,type,grape_varieties\n'
            '10,1,A,purple,\n11,1,B,red,\n',
      }, 'type "purple" is not one of');
    });

    test('reference to a missing winery', () {
      expectError({
        'wines.csv':
            'id,winery_id,name,type,grape_varieties\n'
            '10,9,A,red,\n11,1,B,red,\n',
      }, 'winery_id 9 does not exist');
    });

    test('id in the range reserved for on-device bottles', () {
      expectError({
        'wineries.csv': 'id,name,region\n1000000000,A,\n',
      }, 'id must be below');
    });

    test('duplicate id', () {
      expectError({
        'wineries.csv': 'id,name,region\n1,A,\n1,B,\n',
      }, 'duplicate winery id 1');
    });

    test('two vintages of one wine with the same year', () {
      expectError({
        'vintages.csv':
            'id,wine_id,year,abv,acidity_g_l,tannins_g_l,residual_sugar_g_l\n'
            '101,10,2020,,,,\n102,10,2020,,,,\n111,11,2021,,,,\n',
      }, 'already has a 2020 vintage');
    });

    test('year out of range', () {
      expectError({
        'vintages.csv':
            'id,wine_id,year,abv,acidity_g_l,tannins_g_l,residual_sugar_g_l\n'
            '101,10,1820,,,,\n111,11,2021,,,,\n',
      }, 'year 1820 is outside');
    });

    test('barcode vintage belongs to another wine', () {
      expectError({
        'barcodes.csv':
            'code,wine_id,vintage_id,bottle_size_ml\n4841000000010,10,111,\n',
      }, 'vintage_id 111 belongs to wine 11, not 10');
    });

    test('barcode mangled by Excel into scientific notation', () {
      expectError({
        'barcodes.csv':
            'code,wine_id,vintage_id,bottle_size_ml\n4.84E+12,10,,\n',
      }, 'turned into a number by the spreadsheet');
    });

    test('wine without any vintage', () {
      expectError({
        'vintages.csv':
            'id,wine_id,year,abv,acidity_g_l,tannins_g_l,residual_sugar_g_l\n'
            '101,10,2020,,,,\n',
      }, 'wine 11 (Cupaj Roșu) has no vintage');
    });

    test('missing Romanian wine translation', () {
      expectError({
        'wine_translations.csv': 'wine_id,lang,description\n10,ro,X\n',
      }, 'wine 11 (Cupaj Roșu) is missing its "ro" translation');
    });

    test('missing Romanian vintage translation', () {
      expectError({
        'vintage_translations.csv':
            'vintage_id,lang,sensory_notes,food_pairings\n101,ro,X,\n'
            '111,en,Plum.,\n',
      }, 'vintage 111 (wine 11) is missing its "ro" translation');
    });

    test('unsupported language', () {
      expectError({
        'wine_translations.csv':
            'wine_id,lang,description\n10,ro,X\n11,ro,Y\n11,de,Z\n',
      }, 'lang "de" is not one of');
    });
  });

  group('warnings (build still succeeds)', () {
    test('barcode shared by two wines', () {
      final build = validate({
        'barcodes.csv':
            'code,wine_id,vintage_id,bottle_size_ml\n'
            '4841000000010,10,,\n4841000000010,11,,\n',
      });
      expect(build.isValid, isTrue);
      expect(build.warnings.join(), contains('shared by wines 10, 11'));
    });

    test('wine without barcode', () {
      final build = validate({
        'barcodes.csv':
            'code,wine_id,vintage_id,bottle_size_ml\n4841000000010,10,101,\n',
      });
      expect(build.isValid, isTrue);
      expect(
        build.warnings.join(),
        contains('wine 11 (Cupaj Roșu) has no barcode'),
      );
    });

    test('empty English text is allowed but reported', () {
      final build = validate({
        'wine_translations.csv':
            'wine_id,lang,description\n10,ro,X\n11,ro,Y\n11,en,\n',
      });
      expect(build.isValid, isTrue);
      expect(build.warnings.join(), contains('description is empty'));
    });

    test('empty catalogue (only headers)', () {
      final build = validateCatalog({
        for (final MapEntry(key: file, value: columns) in catalogFiles.entries)
          file: '${columns.join(',')}\n',
      });
      expect(build.isValid, isTrue);
      expect(build.warnings, contains('the catalogue has no wines'));
    });
  });
}
