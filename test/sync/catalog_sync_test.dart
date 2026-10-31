import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/gustaro_core.dart';

/// A pretend Gustaro server that answers like the real one.
class FakeServer {
  late HttpServer _server;
  var version = 202611010000;
  Map<String, dynamic>? body;
  List<int> photo = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];
  int photoStamp = 1000;
  var withPhoto = true;
  var requests = <String>[];
  var catalogRequests = 0;

  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      requests.add(request.uri.path);
      final response = request.response;
      if (request.uri.path == '/v1/catalog') {
        catalogRequests++;
        if (request.headers.value('if-none-match') == '"v$version"') {
          response.statusCode = 304;
        } else {
          response.write(jsonEncode(body ?? catalog()));
        }
      } else if (request.uri.path == '/v1/photos/1' && withPhoto) {
        response.add(photo);
      } else {
        response.statusCode = 404;
      }
      await response.close();
    });
  }

  Map<String, dynamic> catalog({String wineName = 'Rara'}) => {
    'data_version': version,
    'schema_version': 1,
    'tables': {
      'winery': [
        {'id': 1, 'name': 'Chateau', 'region': 'Codru'},
      ],
      'wine': [
        {
          'id': 1,
          'winery_id': 1,
          'name': wineName,
          'type': 'red',
          'grape_varieties': '["A"]',
        },
      ],
      'vintage': [
        {
          'id': 1,
          'wine_id': 1,
          'year': 2022,
          'abv': 13.5,
          'acidity_g_l': null,
          'tannins_g_l': null,
          'residual_sugar_g_l': null,
        },
      ],
      'barcode': [
        {
          'id': 1,
          'code': '4841986001140',
          'wine_id': 1,
          'vintage_id': null,
          'bottle_size_ml': 750,
        },
      ],
      'wine_translation': [
        {'wine_id': 1, 'lang': 'ro', 'description': 'Sec.'},
      ],
      'vintage_translation': [
        {
          'vintage_id': 1,
          'lang': 'ro',
          'sensory_notes': 'Vișine',
          'food_pairings': '["Miel"]',
        },
      ],
    },
    'photos': withPhoto ? {'1': photoStamp} : {},
  };

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late FakeServer server;
  late CatalogDatabase db;
  late Directory dir;

  Future<void> install(int version, {String wineName = 'Old'}) async {
    await db.customStatement("INSERT INTO winery VALUES (1, 'W', NULL)");
    await db.customStatement(
      "INSERT INTO wine VALUES (1, 1, '$wineName', 'red', '[]')",
    );
    await db.customStatement(
      'INSERT INTO vintage VALUES (1, 1, 2020, NULL, NULL, NULL, NULL)',
    );
    await db.customStatement(
      "INSERT INTO meta VALUES ($version, 1, '2026-01-01T00:00:00Z')",
    );
  }

  Future<String> wineName() async =>
      (await db.customSelect('SELECT name FROM wine WHERE id = 1').getSingle())
          .read<String>('name');

  CatalogSync sync([Uri? url]) => CatalogSync(
    db: db,
    baseUrl: url ?? server.url,
    photosDirectory: Directory('${dir.path}/photos'),
  );

  setUp(() async {
    server = FakeServer();
    await server.start();
    db = CatalogDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('sync');
  });

  tearDown(() async {
    await server.stop();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'installs a newer catalogue and its photos, then is up to date',
    () async {
      await install(202610010000);
      expect(await sync().run(), SyncResult.updated);

      expect(await wineName(), 'Rara');
      expect((await CatalogRepository(db).meta())!.dataVersion, server.version);
      expect(File('${dir.path}/photos/1.jpg').readAsBytesSync(), server.photo);
      final barcode = await db
          .customSelect('SELECT code FROM barcode')
          .getSingle();
      expect(barcode.read<String>('code'), '4841986001140');

      expect(await sync().run(), SyncResult.upToDate);
      expect(
        server.requests.where((p) => p.startsWith('/v1/photos')).length,
        1,
      );
    },
  );

  test(
    'learns about photos even when the catalogue version is the same',
    () async {
      await install(server.version, wineName: 'Same');
      expect(await sync().run(), SyncResult.updated);
      expect(await wineName(), 'Same');
      expect(File('${dir.path}/photos/1.jpg').existsSync(), isTrue);
      expect(await sync().run(), SyncResult.upToDate);
    },
  );

  test(
    'removes a photo the server dropped, and replaces a changed one',
    () async {
      await install(202610010000);
      await sync().run();
      server
        ..version += 1
        ..photoStamp = 2000
        ..photo = [0xFF, 0xD8, 0xFF, 9, 9];
      expect(await sync().run(), SyncResult.updated);
      expect(File('${dir.path}/photos/1.jpg').readAsBytesSync(), [
        0xFF,
        0xD8,
        0xFF,
        9,
        9,
      ]);

      server
        ..version += 1
        ..withPhoto = false;
      expect(await sync().run(), SyncResult.updated);
      expect(File('${dir.path}/photos/1.jpg').existsSync(), isFalse);
    },
  );

  test('offline: nothing changes and it reports failure', () async {
    await install(202610010000);
    final url = server.url;
    await server.stop();
    expect(await sync(url).run(), SyncResult.failed);
    expect(await wineName(), 'Old');
    server = FakeServer();
    await server.start();
  });

  test('refuses answers it cannot trust, keeping the old catalogue', () async {
    await install(202610010000);

    Map<String, dynamic> broken(void Function(Map<String, dynamic>) change) {
      final copy =
          jsonDecode(jsonEncode(server.catalog())) as Map<String, dynamic>;
      change(copy);
      return copy;
    }

    server.body = broken((c) => c['schema_version'] = 99);
    expect(await sync().run(), SyncResult.failed);

    server.body = broken((c) => c['tables']['wine'] = []);
    expect(await sync().run(), SyncResult.failed);

    server.body = broken(
      (c) => c['tables']['wine'][0]['name; DROP TABLE wine'] = 'x',
    );
    expect(await sync().run(), SyncResult.failed);

    server.body = broken((c) => c['tables']['barcode'][0]['wine_id'] = 99);
    expect(await sync().run(), SyncResult.failed);

    expect(await wineName(), 'Old');
    expect((await CatalogRepository(db).meta())!.dataVersion, 202610010000);
  });

  test('only talks to the server over https', () {
    expect(() => sync(Uri.parse('http://example.com')), throwsArgumentError);
    expect(() => sync(Uri.parse('https://example.com')), returnsNormally);
  });

  test('the catalogue in the app replaces the phone\'s only when newer', () {
    expect(shouldInstallBundled(localVersion: null, bundledVersion: 5), isTrue);
    expect(shouldInstallBundled(localVersion: 4, bundledVersion: 5), isTrue);
    expect(shouldInstallBundled(localVersion: 5, bundledVersion: 5), isFalse);
    expect(shouldInstallBundled(localVersion: 9, bundledVersion: 5), isFalse);
  });
}
