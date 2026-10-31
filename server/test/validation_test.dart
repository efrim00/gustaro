import 'package:gustaro_server/catalog_tables.dart';
import 'package:test/test.dart';

Map<String, Records> sample() => {
  wineriesFile: [
    {'id': '1', 'name': 'Chateau', 'region': 'Codru'},
  ],
  winesFile: [
    {
      'id': '1',
      'winery_id': '1',
      'name': 'Rara',
      'type': 'red',
      'grape_varieties': 'A | B',
    },
  ],
  vintagesFile: [
    {
      'id': '1',
      'wine_id': '1',
      'year': '2022',
      'abv': '13,5',
      'acidity_g_l': '',
      'tannins_g_l': '',
      'residual_sugar_g_l': '',
    },
  ],
  barcodesFile: [
    {
      'code': '4841986001140',
      'wine_id': '1',
      'vintage_id': '',
      'bottle_size_ml': '750',
    },
  ],
  wineTranslationsFile: [
    {'wine_id': '1', 'lang': 'ro', 'description': 'Sec.'},
  ],
  vintageTranslationsFile: [
    {
      'vintage_id': '1',
      'lang': 'ro',
      'sensory_notes': '',
      'food_pairings': 'Miel',
    },
  ],
};

void main() {
  test('a complete catalogue is valid', () {
    final v = validateTables(sample());
    expect(v.errors, isEmpty);
  });

  test('catches the mistakes the editor must refuse', () {
    Validation mutated(void Function(Map<String, Records>) change) {
      final t = sample();
      change(t);
      return validateTables(t);
    }

    expect(
      mutated((t) => t[winesFile]![0]['type'] = 'purple').isValid,
      isFalse,
    );
    expect(
      mutated((t) => t[winesFile]![0]['winery_id'] = '9').isValid,
      isFalse,
    );
    expect(
      mutated((t) => t[vintagesFile]![0]['year'] = '1800').isValid,
      isFalse,
    );
    expect(mutated((t) => t[vintagesFile]![0]['abv'] = '140').isValid, isFalse);
    expect(
      mutated((t) => t[barcodesFile]![0]['code'] = '48 41').isValid,
      isFalse,
    );
    expect(
      mutated((t) => t[barcodesFile]![0]['vintage_id'] = '7').isValid,
      isFalse,
    );
    expect(mutated((t) => t[vintagesFile]!.clear()).isValid, isFalse);
    expect(mutated((t) => t[wineTranslationsFile]!.clear()).isValid, isFalse);
    expect(
      mutated((t) => t[wineriesFile]![0]['id'] = '1000000001').isValid,
      isFalse,
    );
    expect(
      mutated((t) => t[winesFile]!.add(<String, String>{...t[winesFile]![0]}))
          .isValid,
      isFalse,
    );
  });

  test('a barcode must point at a year of its own wine', () {
    final t = sample();
    t[winesFile]!.add({
      'id': '2',
      'winery_id': '1',
      'name': 'B',
      'type': 'white',
      'grape_varieties': '',
    });
    t[vintagesFile]!.add({
      'id': '2',
      'wine_id': '2',
      'year': '2021',
      'abv': '',
      'acidity_g_l': '',
      'tannins_g_l': '',
      'residual_sugar_g_l': '',
    });
    t[wineTranslationsFile]!.add({
      'wine_id': '2',
      'lang': 'ro',
      'description': '',
    });
    t[vintageTranslationsFile]!.add({
      'vintage_id': '2',
      'lang': 'ro',
      'sensory_notes': '',
      'food_pairings': '',
    });
    expect(validateTables(t).isValid, isTrue);
    t[barcodesFile]![0]['vintage_id'] = '2';
    expect(validateTables(t).isValid, isFalse);
  });

  test('a zero spec only warns', () {
    final t = sample();
    t[vintagesFile]![0]['abv'] = '0';
    final v = validateTables(t);
    expect(v.isValid, isTrue);
    expect(v.warnings.single, contains('abv is 0'));
  });
}
