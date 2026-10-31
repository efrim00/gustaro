import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/gustaro_core.dart';

import '../support/fixture_catalog.dart';

const _bottle = NewBottle(
  wineryName: 'Crama Mea',
  wineName: 'Cupaj Roșu',
  type: WineType.red,
  year: 2021,
  barcode: '4841000000999',
  region: 'Codru',
  grapeVarieties: ['Merlot'],
  abv: 13.5,
  sensoryNotes: 'Cherry and plum.',
  foodPairings: ['Lamb'],
  description: 'A house red.',
);

void main() {
  late CatalogDatabase catalogDb;
  late CatalogDatabase myDb;
  late MyBottlesStore store;
  late CombinedCatalog catalog;
  late ScanService scanner;

  setUp(() async {
    catalogDb = await openFixtureCatalog();
    myDb = CatalogDatabase(NativeDatabase.memory());
    store = MyBottlesStore(myDb);
    catalog = CombinedCatalog([
      CatalogRepository(catalogDb),
      CatalogRepository(myDb),
    ]);
    scanner = ScanService(catalog);
  });
  tearDown(() async {
    await catalogDb.close();
    await myDb.close();
  });

  test('an added bottle is found by barcode straight away', () async {
    final id = await store.add(_bottle);
    expect(
      await scanner.resolveBarcode('4841000000999'),
      isA<ShowVintage>().having((o) => o.vintageId, 'vintageId', id),
    );
  });

  test('an added bottle is found by its label', () async {
    await scanner.resolveLabel('warm up the index');
    await store.add(_bottle);
    scanner.catalogChanged();
    final outcome = await scanner.resolveLabel('CRAMA MEA Cupaj Roșu 2021');
    final first = (outcome as ChooseWine).candidates.first;
    expect(first.wine.name, 'Cupaj Roșu');
    expect(first.wine.isVerified, isFalse);
  });

  test('details come back in full and are marked unverified', () async {
    final id = await store.add(_bottle);
    final d = (await catalog.vintageDetails(id, language: 'en'))!;
    expect(d.wine.isVerified, isFalse);
    expect(d.wine.wineryName, 'Crama Mea');
    expect(d.region, 'Codru');
    expect(d.abv, 13.5);
    expect(d.sensoryNotes, 'Cherry and plum.');
    expect(d.foodPairings, ['Lamb']);
    expect(d.description, 'A house red.');
    expect(d.language, 'en');
  });

  test('bundled wines stay verified', () async {
    final d = (await catalog.vintageDetails(102))!;
    expect(d.wine.isVerified, isTrue);
  });

  test('IDs never clash with the catalogue', () async {
    final id = await store.add(_bottle);
    expect(id, greaterThanOrEqualTo(myBottleIdBase));
    final index = await catalog.labelIndex();
    expect(index.map((e) => e.wine.id).toSet().length, index.length);
  });

  test('a second year reuses the winery and wine, typed differently', () async {
    await store.add(_bottle);
    await store.add(
      const NewBottle(
        wineryName: 'crama mea',
        wineName: 'CUPAJ ROSU',
        type: WineType.red,
        year: 2022,
      ),
    );
    final mine = await CatalogRepository(myDb).labelIndex();
    expect(mine.single.vintages.map((v) => v.year), [2022, 2021]);
  });

  test('the same wine and year cannot be added twice', () async {
    final id = await store.add(_bottle);
    await expectLater(
      store.add(_bottle),
      throwsA(
        isA<BottleAlreadyAdded>().having((e) => e.vintageId, 'vintageId', id),
      ),
    );
    expect((await CatalogRepository(myDb).labelIndex()).length, 1);
  });

  test('barcode is optional', () async {
    await store.add(
      const NewBottle(
        wineryName: 'A',
        wineName: 'B',
        type: WineType.white,
        year: 2020,
      ),
    );
    expect((await CatalogRepository(myDb).labelIndex()).length, 1);
  });

  test('removing the last vintage removes its wine and winery', () async {
    final id = await store.add(_bottle);
    await store.remove(id);
    expect(await CatalogRepository(myDb).labelIndex(), isEmpty);
    expect(await myDb.select(myDb.wineryTable).get(), isEmpty);
    expect(
      await scanner.resolveBarcode('4841000000999'),
      isA<NotInCatalogue>(),
    );
  });

  test('removing one of two vintages keeps the wine', () async {
    final id = await store.add(_bottle);
    await store.add(
      const NewBottle(
        wineryName: 'Crama Mea',
        wineName: 'Cupaj Roșu',
        type: WineType.red,
        year: 2022,
      ),
    );
    await store.remove(id);
    final mine = await CatalogRepository(myDb).labelIndex();
    expect(mine.single.vintages.map((v) => v.year), [2022]);
  });

  test('clear deletes everything added', () async {
    await store.add(_bottle);
    await store.clear();
    expect(await CatalogRepository(myDb).labelIndex(), isEmpty);
  });

  test(
    'searchWines ignores case and diacritics and matches all words',
    () async {
      await store.add(_bottle);
      final index = await catalog.labelIndex();
      expect(searchWines(index, 'cupaj rosu').single.wine.name, 'Cupaj Roșu');
      expect(searchWines(index, 'taraNCUTA neagra').length, 2);
      expect(searchWines(index, '2017').single.wine.id, 30);
      expect(searchWines(index, 'codru').length, greaterThan(1));
      expect(searchWines(index, 'nothing here'), isEmpty);
      expect(searchWines(index, '  ').length, index.length);
    },
  );
}
