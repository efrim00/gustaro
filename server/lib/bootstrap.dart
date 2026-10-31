import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import 'schema.dart';

/// First load only: fills an EMPTY database from [file]. It does nothing
/// once the catalogue has a version, so it can never overwrite live data.
Future<void> seedIfEmpty(Pool<void> pool, File file) async {
  if (!file.existsSync()) return;
  final version =
      (await pool.execute('SELECT data_version FROM meta WHERE id = 1'))
              .single[0]
          as int;
  if (version != 0) return;

  final seed = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final tables = seed['tables'] as Map<String, dynamic>;
  await pool.runTx((tx) async {
    for (final table in catalogTables) {
      for (final row in tables[table] as List<dynamic>) {
        final values = (row as Map<String, dynamic>);
        final columns = values.keys.toList();
        await tx.execute(
          Sql.named(
            'INSERT INTO $table (${columns.join(', ')}) '
            'VALUES (${[for (final c in columns) '@$c'].join(', ')})',
          ),
          parameters: values,
        );
      }
      stdout.writeln('seeded $table: ${(tables[table] as List).length}');
    }
    final photos = (seed['photos'] as Map<String, dynamic>? ?? {});
    for (final MapEntry(:key, :value) in photos.entries) {
      await tx.execute(
        Sql.named('INSERT INTO wine_photo (wine_id, jpeg) VALUES (@id, @jpeg)'),
        parameters: {
          'id': int.parse(key),
          'jpeg': TypedValue(Type.byteArray, base64Decode(value as String)),
        },
      );
    }
    await tx.execute(
      Sql.named('UPDATE meta SET data_version = @v WHERE id = 1'),
      parameters: {'v': seed['data_version']},
    );
  });
}
