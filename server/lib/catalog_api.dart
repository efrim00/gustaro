import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'schema.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

/// The read-only API phones use. It has no endpoint that changes data.
Handler catalogHandler(Pool<void> pool) {
  final router = Router()
    ..get('/healthz', (Request _) async {
      await pool.execute('SELECT 1');
      return Response.ok('ok');
    })
    ..get('/v1/catalog', (Request request) => _catalog(pool, request))
    ..get('/v1/photos/<id|[0-9]{1,9}>', (Request request, String id) {
      return _photo(pool, request, int.parse(id));
    });
  return router.call;
}

Future<Response> _catalog(Pool<void> pool, Request request) async {
  final meta = (await pool.execute(
    'SELECT data_version, schema_version FROM meta WHERE id = 1',
  )).single;
  final version = meta[0] as int;
  final etag = '"v$version"';
  final headers = {'etag': etag, 'cache-control': 'no-cache'};
  if (request.headers['if-none-match'] == etag) {
    return Response.notModified(headers: headers);
  }

  final tables = <String, Object>{};
  for (final table in catalogTables) {
    final rows = await pool.execute('SELECT * FROM $table ORDER BY 1, 2');
    tables[table] = [for (final row in rows) row.toColumnMap()];
  }
  final photos = await pool.execute(
    'SELECT wine_id, extract(epoch FROM updated_at)::bigint '
    'FROM wine_photo ORDER BY 1',
  );
  return Response.ok(
    jsonEncode({
      'data_version': version,
      'schema_version': meta[1],
      'tables': tables,
      'photos': {for (final row in photos) '${row[0]}': row[1]},
    }),
    headers: {..._json, ...headers},
  );
}

Future<Response> _photo(Pool<void> pool, Request request, int wineId) async {
  final rows = await pool.execute(
    Sql.named(
      'SELECT jpeg, extract(epoch FROM updated_at)::bigint '
      'FROM wine_photo WHERE wine_id = @id',
    ),
    parameters: {'id': wineId},
  );
  if (rows.isEmpty) return Response.notFound('Not found');
  final etag = '"p${rows.single[1]}"';
  final headers = {'etag': etag, 'cache-control': 'public, max-age=3600'};
  if (request.headers['if-none-match'] == etag) {
    return Response.notModified(headers: headers);
  }
  return Response.ok(
    rows.single[0] as List<int>,
    headers: {...headers, 'content-type': 'image/jpeg'},
  );
}
