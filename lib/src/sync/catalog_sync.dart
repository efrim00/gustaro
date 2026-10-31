import 'dart:convert';
import 'dart:io';

import '../catalog/catalog_database.dart';
import '../catalog/catalog_repository.dart';

/// What a sync did.
enum SyncResult {
  /// The phone already had the newest catalogue.
  upToDate,

  /// A newer catalogue (or photos) was installed.
  updated,

  /// No answer, or an answer the app refuses. Nothing was changed.
  failed,
}

const _maxCatalogBytes = 20 * 1024 * 1024;
const _maxPhotoBytes = 3 * 1024 * 1024;
const _timeout = Duration(seconds: 8);

/// Children first: the order rows are removed in.
const _tables = [
  'barcode',
  'vintage_translation',
  'wine_translation',
  'vintage',
  'wine',
  'winery',
];

/// Whether the catalogue shipped inside the app should replace the one on
/// the phone: only when the phone has none, or the app's is newer.
bool shouldInstallBundled({int? localVersion, required int bundledVersion}) =>
    localVersion == null || bundledVersion > localVersion;

/// Brings the phone's catalogue up to date from the Gustaro server.
///
/// The server is only ever asked for the catalogue and the photos. The one
/// thing sent with it is the version the phone already has, so the server
/// can say "nothing new". Anything that goes wrong leaves the old catalogue
/// untouched, so scanning keeps working offline.
class CatalogSync {
  CatalogSync({
    required this.db,
    required this.baseUrl,
    required this.photosDirectory,
  }) {
    final secure = baseUrl.scheme == 'https';
    final local = baseUrl.host == 'localhost' || baseUrl.host == '127.0.0.1';
    if (!secure && !local) {
      throw ArgumentError('The server address must use https.');
    }
  }

  final CatalogDatabase db;
  final Uri baseUrl;

  /// Where downloaded photos are kept, as `<wine id>.jpg`.
  final Directory photosDirectory;

  File get _index => File('${photosDirectory.path}/index.json');

  Future<SyncResult> run() async {
    try {
      final client = HttpClient()..connectionTimeout = _timeout;
      try {
        final changed = await _syncCatalog(client);
        final photos = await _syncPhotos(client);
        return changed || photos ? SyncResult.updated : SyncResult.upToDate;
      } finally {
        client.close(force: true);
      }
    } on Object {
      return SyncResult.failed;
    }
  }

  Future<bool> _syncCatalog(HttpClient client) async {
    final local = (await CatalogRepository(db).meta())?.dataVersion;
    final request = await client
        .getUrl(baseUrl.resolve('/v1/catalog'))
        .timeout(_timeout);
    // Until the photo list is known, ask for the whole answer once.
    if (local != null && _index.existsSync()) {
      request.headers.set('if-none-match', '"v$local"');
    }
    final response = await request.close().timeout(_timeout);
    if (response.statusCode == 304) {
      await response.drain<void>();
      return false;
    }
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw const HttpException('Unexpected answer.');
    }
    final body = await _read(response, _maxCatalogBytes);
    final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
    final version = data['data_version'] as int;
    final newer = local == null || version != local;
    if (newer) await _install(data);
    await _remember(wanted: _photoMap(data['photos']));
    return newer;
  }

  Map<String, int> _photoMap(Object? photos) => {
    for (final MapEntry(:key, :value) in (photos as Map? ?? {}).entries)
      if (int.tryParse('$key') != null) '$key': value as int,
  };

  /// Replaces the catalogue in one step. If anything is wrong, nothing is.
  Future<void> _install(Map<String, dynamic> data) async {
    if (data['schema_version'] != CatalogDatabase.currentSchemaVersion) {
      throw const FormatException('Unknown catalogue format.');
    }
    final tables = data['tables'] as Map<String, dynamic>;
    // A broken or empty answer must never wipe a working catalogue.
    if ((tables['wine'] as List).isEmpty) {
      throw const FormatException('Empty catalogue.');
    }
    await db.transaction(() async {
      for (final table in _tables) {
        await db.customStatement('DELETE FROM $table');
      }
      for (final table in _tables.reversed) {
        for (final row in tables[table] as List) {
          final values = row as Map<String, dynamic>;
          final columns = values.keys.toList();
          for (final column in columns) {
            if (!RegExp(r'^[a-z_]+$').hasMatch(column)) {
              throw const FormatException('Bad column name.');
            }
          }
          await db.customStatement(
            'INSERT INTO $table (${columns.join(', ')}) '
            'VALUES (${List.filled(columns.length, '?').join(', ')})',
            [for (final c in columns) values[c]],
          );
        }
      }
      await db.customStatement('DELETE FROM meta');
      await db.customStatement(
        'INSERT INTO meta (data_version, schema_version, built_at) '
        'VALUES (?, ?, ?)',
        [
          data['data_version'],
          data['schema_version'],
          DateTime.now().toUtc().toIso8601String(),
        ],
      );
    });
  }

  // ---- photos: which the server has (wanted), which are here (have) ----

  Future<({Map<String, int> wanted, Map<String, int> have})> _state() async {
    if (!_index.existsSync()) {
      return (wanted: <String, int>{}, have: <String, int>{});
    }
    final json =
        jsonDecode(await _index.readAsString()) as Map<String, dynamic>;
    Map<String, int> read(String key) => {
      for (final MapEntry(:key, :value) in (json[key] as Map).entries)
        '$key': value as int,
    };
    return (wanted: read('wanted'), have: read('have'));
  }

  Future<void> _write(Map<String, int> wanted, Map<String, int> have) async {
    await photosDirectory.create(recursive: true);
    await _index.writeAsString(jsonEncode({'wanted': wanted, 'have': have}));
  }

  Future<void> _remember({required Map<String, int> wanted}) async {
    final state = await _state();
    await _write(wanted, state.have);
  }

  /// Downloads photos that are new or changed, and removes the ones the
  /// server no longer has. Returns whether anything changed.
  Future<bool> _syncPhotos(HttpClient client) async {
    final state = await _state();
    final have = {...state.have};
    var changed = false;

    for (final id in have.keys.toList()) {
      if (!state.wanted.containsKey(id)) {
        final file = File('${photosDirectory.path}/$id.jpg');
        if (file.existsSync()) await file.delete();
        have.remove(id);
        changed = true;
      }
    }
    for (final MapEntry(key: id, value: stamp) in state.wanted.entries) {
      if (have[id] == stamp) continue;
      final request = await client
          .getUrl(baseUrl.resolve('/v1/photos/$id'))
          .timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        await response.drain<void>();
        continue;
      }
      final bytes = await _read(response, _maxPhotoBytes);
      if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) continue;
      await photosDirectory.create(recursive: true);
      await File('${photosDirectory.path}/$id.jpg')
          .writeAsBytes(bytes, flush: true);
      have[id] = stamp;
      changed = true;
    }
    if (changed) await _write(state.wanted, have);
    return changed;
  }

  Future<List<int>> _read(Stream<List<int>> stream, int limit) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
      if (bytes.length > limit) throw const HttpException('Too large.');
    }
    return bytes;
  }
}
