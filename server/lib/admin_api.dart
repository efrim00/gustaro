import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'admin_auth.dart';
import 'catalog_tables.dart';

const _maxBody = 10 * 1024 * 1024;
const _maxPhoto = 3 * 1024 * 1024;
const _json = {'content-type': 'application/json; charset=utf-8'};

/// The editors' API. Every route needs a signed-in editor, and writes also
/// need the request to come from our own page.
class AdminApi {
  AdminApi(this.pool, this.auth, {required this.baseUrl, required this.page});

  final Pool<void> pool;
  final AdminAuth auth;
  final String baseUrl;
  final File page;

  Handler get handler {
    final router = Router()
      ..get('/admin', _page)
      ..get('/admin/api/me', _guard(_me))
      ..get('/admin/api/catalog', _guard(_catalog))
      ..post('/admin/api/save', _guard(_save, write: true))
      ..post('/admin/api/photo', _guard(_setPhoto, write: true))
      ..post('/admin/api/photo/delete', _guard(_deletePhoto, write: true))
      ..post('/admin/api/invite', _guard(_invite, write: true, owner: true))
      ..post('/admin/api/logout', auth.logout);
    return router.call;
  }

  Response _page(Request request) => Response.ok(
    page.readAsStringSync(),
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
      'content-security-policy':
          "default-src 'none'; script-src 'unsafe-inline'; "
          "style-src 'unsafe-inline'; img-src 'self' data: blob:; "
          "connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; "
          "form-action 'none'",
      'x-frame-options': 'DENY',
      'referrer-policy': 'no-referrer',
    },
  );

  Handler _guard(
    Future<Response> Function(Request, Editor) inner, {
    bool write = false,
    bool owner = false,
  }) => (request) async {
    final editor = await auth.editorOf(request);
    if (editor == null) return _error(401, 'Sign in first.');
    if (owner && !editor.isOwner) return _error(403, 'Not allowed.');
    if (write) {
      // Only our own page may change things, and only as JSON.
      final origin = request.headers['origin'];
      if (origin != baseUrl) return _error(403, 'Forbidden origin.');
      if (request.mimeType != 'application/json') {
        return _error(415, 'Expected JSON.');
      }
    }
    return inner(request, editor);
  };

  Future<Response> _me(Request request, Editor editor) async =>
      _ok({'role': editor.role});

  Future<Response> _catalog(Request request, Editor editor) async =>
      _ok(await _snapshot());

  Future<Map<String, Object?>> _snapshot() async {
    String text(Object? v) => v == null ? '' : '$v';
    String number(Object? v) {
      if (v == null) return '';
      final d = v as double;
      return d == d.roundToDouble() ? '${d.toInt()}' : '$d';
    }

    String list(Object? v) =>
        [for (final item in jsonDecode(v as String) as List) '$item']
            .join(' | ');

    Future<Result> q(String sql) => pool.execute(sql);
    final version = (await q('SELECT data_version FROM meta')).single[0] as int;
    final wineries = await q('SELECT id, name, region FROM winery ORDER BY id');
    final wines = await q(
      'SELECT id, winery_id, name, type, grape_varieties FROM wine ORDER BY id',
    );
    final vintages = await q(
      'SELECT id, wine_id, year, abv, acidity_g_l, tannins_g_l, '
      'residual_sugar_g_l FROM vintage ORDER BY id',
    );
    final barcodes = await q(
      'SELECT code, wine_id, vintage_id, bottle_size_ml FROM barcode ORDER BY id',
    );
    final wineTexts = await q(
      'SELECT wine_id, lang, description FROM wine_translation ORDER BY 1, 2',
    );
    final vintageTexts = await q(
      'SELECT vintage_id, lang, sensory_notes, food_pairings '
      'FROM vintage_translation ORDER BY 1, 2',
    );
    final photos = await q('SELECT wine_id FROM wine_photo ORDER BY 1');

    final tables = <String, Records>{
      wineriesFile: [
        for (final r in wineries)
          {'id': text(r[0]), 'name': text(r[1]), 'region': text(r[2])},
      ],
      winesFile: [
        for (final r in wines)
          {
            'id': text(r[0]),
            'winery_id': text(r[1]),
            'name': text(r[2]),
            'type': text(r[3]),
            'grape_varieties': list(r[4]),
          },
      ],
      vintagesFile: [
        for (final r in vintages)
          {
            'id': text(r[0]),
            'wine_id': text(r[1]),
            'year': text(r[2]),
            'abv': number(r[3]),
            'acidity_g_l': number(r[4]),
            'tannins_g_l': number(r[5]),
            'residual_sugar_g_l': number(r[6]),
          },
      ],
      barcodesFile: [
        for (final r in barcodes)
          {
            'code': text(r[0]),
            'wine_id': text(r[1]),
            'vintage_id': text(r[2]),
            'bottle_size_ml': text(r[3]),
          },
      ],
      wineTranslationsFile: [
        for (final r in wineTexts)
          {
            'wine_id': text(r[0]),
            'lang': text(r[1]),
            'description': text(r[2]),
          },
      ],
      vintageTranslationsFile: [
        for (final r in vintageTexts)
          {
            'vintage_id': text(r[0]),
            'lang': text(r[1]),
            'sensory_notes': text(r[2]),
            'food_pairings': list(r[3]),
          },
      ],
    };
    final check = validateTables(tables);
    return {
      'version': '$version',
      'tables': tables,
      'errors': check.errors,
      'warnings': check.warnings,
      'photos': [for (final r in photos) '${r[0]}'],
    };
  }

  Future<Response> _save(Request request, Editor editor) async {
    final body = await _readJson(request);
    final given = body?['tables'];
    if (body == null || body['version'] is! String || given is! Map) {
      return _error(400, 'Invalid request.');
    }
    final Map<String, Records> tables;
    try {
      tables = _parseTables(given);
    } on FormatException {
      return _error(400, 'Invalid request.');
    }
    final check = validateTables(tables);
    if (!check.isValid) return _ok({'errors': check.errors}, status: 422);

    try {
      await pool.runTx((tx) async {
        final current =
            (await tx.execute('SELECT data_version FROM meta FOR UPDATE'))
                    .single[0]
                as int;
        if ('$current' != body['version']) throw _Conflict();
        await _replace(tx, tables);
        await _bump(tx);
      });
    } on _Conflict {
      return _error(
        409,
        'Someone else changed the catalogue. Reload the page; your last '
        'change was not saved.',
      );
    }
    return _ok(await _snapshot());
  }

  Future<void> _replace(TxSession tx, Map<String, Records> t) async {
    List<int> idsOf(String file, [String col = 'id']) => [
      for (final r in t[file]!) int.parse(r[col]!.trim()),
    ];
    final wineryIds = idsOf(wineriesFile);
    final wineIds = idsOf(winesFile);
    final vintageIds = idsOf(vintagesFile);

    Future<void> deleteExcept(String table, List<int> keep) => tx.execute(
      Sql.named('DELETE FROM $table WHERE id <> ALL(@keep)'),
      parameters: {'keep': TypedValue(Type.integerArray, keep)},
    );

    // Children first, so nothing still points at what is removed.
    await tx.execute('DELETE FROM barcode');
    await tx.execute('DELETE FROM vintage_translation');
    await tx.execute('DELETE FROM wine_translation');
    await deleteExcept('vintage', vintageIds);
    await tx.execute(
      Sql.named('DELETE FROM wine_photo WHERE wine_id <> ALL(@keep)'),
      parameters: {'keep': TypedValue(Type.integerArray, wineIds)},
    );
    await deleteExcept('wine', wineIds);
    await deleteExcept('winery', wineryIds);

    // Parents first.
    for (final r in t[wineriesFile]!) {
      await tx.execute(
        Sql.named(
          'INSERT INTO winery (id, name, region) VALUES (@id, @name, @region) '
          'ON CONFLICT (id) DO UPDATE SET name = @name, region = @region',
        ),
        parameters: {
          'id': int.parse(r['id']!.trim()),
          'name': r['name']!.trim(),
          'region': _nullIfEmpty(r['region']),
        },
      );
    }
    for (final r in t[winesFile]!) {
      final grapes = jsonEncode(splitList(r['grape_varieties'] ?? ''));
      await tx.execute(
        Sql.named(
          'INSERT INTO wine (id, winery_id, name, type, grape_varieties) '
          'VALUES (@id, @winery, @name, @type, @grapes) ON CONFLICT (id) DO '
          'UPDATE SET winery_id = @winery, name = @name, type = @type, '
          'grape_varieties = @grapes',
        ),
        parameters: {
          'id': int.parse(r['id']!.trim()),
          'winery': int.parse(r['winery_id']!.trim()),
          'name': r['name']!.trim(),
          'type': r['type'],
          'grapes': grapes,
        },
      );
    }
    for (final r in t[vintagesFile]!) {
      double? n(String c) {
        final s = (r[c] ?? '').trim().replaceAll(',', '.');
        return s.isEmpty ? null : double.parse(s);
      }

      await tx.execute(
        Sql.named(
          'INSERT INTO vintage (id, wine_id, year, abv, acidity_g_l, '
          'tannins_g_l, residual_sugar_g_l) VALUES (@id, @wine, @year, @abv, '
          '@acid, @tan, @sugar) ON CONFLICT (id) DO UPDATE SET wine_id = @wine, '
          'year = @year, abv = @abv, acidity_g_l = @acid, tannins_g_l = @tan, '
          'residual_sugar_g_l = @sugar',
        ),
        parameters: {
          'id': int.parse(r['id']!.trim()),
          'wine': int.parse(r['wine_id']!.trim()),
          'year': int.parse(r['year']!.trim()),
          'abv': n('abv'),
          'acid': n('acidity_g_l'),
          'tan': n('tannins_g_l'),
          'sugar': n('residual_sugar_g_l'),
        },
      );
    }
    var barcodeId = 0;
    for (final r in t[barcodesFile]!) {
      await tx.execute(
        Sql.named(
          'INSERT INTO barcode (id, code, wine_id, vintage_id, bottle_size_ml) '
          'VALUES (@id, @code, @wine, @vintage, @size)',
        ),
        parameters: {
          'id': ++barcodeId,
          'code': r['code']!.trim(),
          'wine': int.parse(r['wine_id']!.trim()),
          'vintage': int.tryParse((r['vintage_id'] ?? '').trim()),
          'size': int.tryParse((r['bottle_size_ml'] ?? '').trim()),
        },
      );
    }
    for (final r in t[wineTranslationsFile]!) {
      await tx.execute(
        Sql.named(
          'INSERT INTO wine_translation (wine_id, lang, description) '
          'VALUES (@id, @lang, @text)',
        ),
        parameters: {
          'id': int.parse(r['wine_id']!.trim()),
          'lang': r['lang'],
          'text': _nullIfEmpty(r['description']),
        },
      );
    }
    for (final r in t[vintageTranslationsFile]!) {
      await tx.execute(
        Sql.named(
          'INSERT INTO vintage_translation (vintage_id, lang, sensory_notes, '
          'food_pairings) VALUES (@id, @lang, @notes, @food)',
        ),
        parameters: {
          'id': int.parse(r['vintage_id']!.trim()),
          'lang': r['lang'],
          'notes': _nullIfEmpty(r['sensory_notes']),
          'food': jsonEncode(splitList(r['food_pairings'] ?? '')),
        },
      );
    }
  }

  Future<Response> _setPhoto(Request request, Editor editor) async {
    final body = await _readJson(request);
    final id = int.tryParse('${body?['wine_id']}');
    final data = body?['data'];
    if (id == null || data is! String) return _error(400, 'Invalid request.');
    final Uint8List bytes;
    try {
      bytes = base64Decode(data);
    } on FormatException {
      return _error(400, 'Invalid image.');
    }
    if (bytes.length > _maxPhoto) return _error(413, 'The photo is too large.');
    if (bytes.length < 4 ||
        bytes[0] != 0xFF ||
        bytes[1] != 0xD8 ||
        bytes[2] != 0xFF) {
      return _error(415, 'Expected a JPEG image.');
    }
    final saved = await pool.runTx((tx) async {
      final wine = await tx.execute(
        Sql.named('SELECT 1 FROM wine WHERE id = @id'),
        parameters: {'id': id},
      );
      if (wine.isEmpty) return false;
      await tx.execute(
        Sql.named(
          'INSERT INTO wine_photo (wine_id, jpeg) VALUES (@id, @jpeg) '
          'ON CONFLICT (wine_id) DO UPDATE SET jpeg = @jpeg, updated_at = now()',
        ),
        parameters: {'id': id, 'jpeg': TypedValue(Type.byteArray, bytes)},
      );
      await _bump(tx);
      return true;
    });
    if (!saved) return _error(400, 'Invalid request.');
    return _ok({'photos': await _photoIds()});
  }

  Future<Response> _deletePhoto(Request request, Editor editor) async {
    final body = await _readJson(request);
    final id = int.tryParse('${body?['wine_id']}');
    if (id == null) return _error(400, 'Invalid request.');
    await pool.runTx((tx) async {
      await tx.execute(
        Sql.named('DELETE FROM wine_photo WHERE wine_id = @id'),
        parameters: {'id': id},
      );
      await _bump(tx);
    });
    return _ok({'photos': await _photoIds()});
  }

  Future<List<String>> _photoIds() async => [
    for (final r in await pool.execute(
      'SELECT wine_id FROM wine_photo ORDER BY 1',
    ))
      '${r[0]}',
  ];

  Future<Response> _invite(Request request, Editor editor) async {
    final code = await auth.createInvite('editor');
    return _ok({'url': '$baseUrl/auth/apple/start?invite=$code', 'days': 2});
  }
}

class _Conflict implements Exception {}

const _files = [
  wineriesFile,
  winesFile,
  vintagesFile,
  barcodesFile,
  wineTranslationsFile,
  vintageTranslationsFile,
];

Map<String, Records> _parseTables(Map given) => {
  for (final file in _files)
    file: [
      for (final record
          in (given[file] as List? ?? (throw const FormatException('missing'))))
        if (record is Map && record.values.every((v) => v is String))
          record.cast<String, String>()
        else
          throw const FormatException('bad row'),
    ],
};

/// A new version number: always bigger than the last, and readable as a time.
Future<void> _bump(TxSession tx) async {
  final now = DateTime.now().toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp = int.parse(
    '${now.year}${two(now.month)}${two(now.day)}${two(now.hour)}${two(now.minute)}',
  );
  await tx.execute(
    Sql.named(
      'UPDATE meta SET data_version = GREATEST(data_version + 1, @stamp)',
    ),
    parameters: {'stamp': stamp},
  );
}

String? _nullIfEmpty(String? s) {
  final t = (s ?? '').trim();
  return t.isEmpty ? null : t;
}

Future<Map<String, dynamic>?> _readJson(Request request) async {
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > _maxBody) return null;
  }
  if (bytes.isEmpty) return null;
  try {
    final value = jsonDecode(utf8.decode(bytes));
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}

Response _ok(Object body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _json);

Response _error(int status, String message) =>
    Response(status, body: jsonEncode({'error': message}), headers: _json);
