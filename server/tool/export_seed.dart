// Writes seed/catalog.json from the validated app catalogue and the bottle
// photos, for the server's one-time first load of an empty database.
//
//   dart run tool/export_seed.dart
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite;

const _tables = [
  'winery',
  'wine',
  'vintage',
  'barcode',
  'wine_translation',
  'vintage_translation',
];

void main(List<String> args) {
  final catalog = args.isNotEmpty ? args.first : '../assets/catalog.sqlite';
  final db = sqlite.sqlite3.open(catalog, mode: sqlite.OpenMode.readOnly);
  final meta = db
      .select('SELECT data_version, schema_version FROM meta')
      .single;

  final photos = <String, String>{};
  final photosDir = Directory('../data/photos');
  if (photosDir.existsSync()) {
    for (final file in photosDir.listSync().whereType<File>()) {
      final id = int.tryParse(
        file.uri.pathSegments.last.replaceFirst('.jpg', ''),
      );
      if (id != null) photos['$id'] = base64Encode(file.readAsBytesSync());
    }
  }

  final out = File('seed/catalog.json')..createSync(recursive: true);
  out.writeAsStringSync(
    jsonEncode({
      'data_version': meta['data_version'],
      'schema_version': meta['schema_version'],
      'tables': {
        for (final table in _tables)
          table: [
            for (final row in db.select('SELECT * FROM $table')) Map.of(row),
          ],
      },
      'photos': photos,
    }),
  );
  db.close();
  stdout.writeln('Wrote ${out.path}');
}
