import 'package:postgres/postgres.dart';

import 'config.dart';
import 'schema.dart';

Future<Pool<void>> openPool(String url) async {
  final endpoint = endpointFromUrl(url);
  return Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(
      maxConnectionCount: 5,
      sslMode: sslModeFor(endpoint),
      connectTimeout: const Duration(seconds: 10),
    ),
  );
}

/// Applies the migrations that are not applied yet.
Future<void> migrate(Pool<void> pool) async {
  await pool.execute(
    'CREATE TABLE IF NOT EXISTS schema_migration '
    '(id integer PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())',
  );
  final done = {
    for (final row in await pool.execute('SELECT id FROM schema_migration'))
      row[0] as int,
  };
  for (var i = 0; i < migrations.length; i++) {
    if (done.contains(i)) continue;
    await pool.runTx((tx) async {
      await tx.execute(migrations[i], queryMode: QueryMode.simple);
      await tx.execute(
        Sql.named('INSERT INTO schema_migration (id) VALUES (@id)'),
        parameters: {'id': i},
      );
    });
  }
}
