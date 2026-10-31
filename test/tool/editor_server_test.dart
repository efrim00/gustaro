import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/catalog_builder.dart';
import '../../tool/src/editor_server.dart';

void main() {
  late Directory tmp;
  late HttpServer server;
  late HttpClient client;
  late String dataDir;
  late String outPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gustaro_editor_');
    dataDir = '${tmp.path}/data';
    outPath = '${tmp.path}/catalog.sqlite';
    Directory(dataDir).createSync();
    for (final MapEntry(key: file, value: columns) in catalogFiles.entries) {
      File('$dataDir/$file').writeAsStringSync('${columns.join(',')}\n');
    }
    server = await startEditorServer(
      dataDir: dataDir,
      outPath: outPath,
      htmlFile: File('tool/editor/index.html'),
      port: 0,
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
    await tmp.delete(recursive: true);
  });

  Future<(int, Map<String, dynamic>)> send(
    String method,
    String path, {
    Object? body,
    String host = 'localhost',
    String? origin,
    ContentType? contentType,
  }) async {
    final request = await client.open(method, '127.0.0.1', server.port, path);
    request.headers.host = host;
    if (origin != null) request.headers.set('origin', origin);
    if (body != null) {
      request.headers.contentType = contentType ?? ContentType.json;
      request.write(body is String ? body : jsonEncode(body));
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (
      response.statusCode,
      text.startsWith('{')
          ? jsonDecode(text) as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  // Round-trip through JSON so the maps are as loosely typed as a request.
  Map<String, dynamic> oneBottle(Map<String, dynamic> catalog) => jsonDecode(
    jsonEncode({
      'version': catalog['version'],
      'tables': {
        'wineries.csv': [
          {'id': '1', 'name': 'Crama Țărăncuța', 'region': 'Codru'},
        ],
        'wines.csv': [
          {
            'id': '1',
            'winery_id': '1',
            'name': 'Fetească Neagră',
            'type': 'red',
            'grape_varieties': '',
          },
        ],
        'vintages.csv': [
          {
            'id': '1',
            'wine_id': '1',
            'year': '2020',
            'abv': '13.5',
            'acidity_g_l': '',
            'tannins_g_l': '',
            'residual_sugar_g_l': '',
          },
        ],
        'barcodes.csv': [
          {
            'code': '4841000000029',
            'wine_id': '1',
            'vintage_id': '',
            'bottle_size_ml': '750',
          },
        ],
        'wine_translations.csv': [
          {'wine_id': '1', 'lang': 'ro', 'description': 'Sec.'},
        ],
        'vintage_translations.csv': [
          {
            'vintage_id': '1',
            'lang': 'ro',
            'sensory_notes': 'Vișine.',
            'food_pairings': 'Miel',
          },
        ],
      },
    }),
  ) as Map<String, dynamic>;

  test('serves the page and the catalogue', () async {
    final page =
        await (await (await client.get('127.0.0.1', server.port, '/')
                  ..headers.host = 'localhost')
                .close())
            .transform(utf8.decoder)
            .join();
    expect(page, contains('Gustaro'));
    final (status, catalog) = await send('GET', '/api/catalog');
    expect(status, 200);
    expect(catalog['tables']['wines.csv'], isEmpty);
    expect(catalog['version'], isA<String>());
  });

  test('a valid save writes the CSVs and rebuilds the catalogue', () async {
    final (_, catalog) = await send('GET', '/api/catalog');
    final (status, saved) = await send(
      'POST',
      '/api/save',
      body: oneBottle(catalog),
    );
    expect(status, 200, reason: '$saved');
    expect(saved['tables']['wines.csv'].single['name'], 'Fetească Neagră');
    expect(
      File('$dataDir/wines.csv').readAsStringSync(),
      contains('Fetească Neagră'),
    );
    expect(File(outPath).existsSync(), isTrue);
  });

  test('an invalid save is refused and changes nothing', () async {
    final (_, catalog) = await send('GET', '/api/catalog');
    final body = oneBottle(catalog);
    (body['tables'] as Map)['vintages.csv'] = <Object>[]; // wine without year
    final before = File('$dataDir/wines.csv').readAsStringSync();
    final (status, result) = await send('POST', '/api/save', body: body);
    expect(status, 422);
    expect((result['errors'] as List).join(), contains('has no vintage'));
    expect(File('$dataDir/wines.csv').readAsStringSync(), before);
    expect(File(outPath).existsSync(), isFalse);
  });

  test('refuses to overwrite files changed outside the editor', () async {
    final (_, catalog) = await send('GET', '/api/catalog');
    File('$dataDir/wineries.csv')
        .writeAsStringSync('id,name,region\n9,Other,\n');
    final (status, _) = await send(
      'POST',
      '/api/save',
      body: oneBottle(catalog),
    );
    expect(status, 409);
    expect(File('$dataDir/wineries.csv').readAsStringSync(), contains('Other'));
  });

  test('rejects unknown columns and non-string values', () async {
    final (_, catalog) = await send('GET', '/api/catalog');
    final body = oneBottle(catalog);
    ((body['tables'] as Map)['wineries.csv'] as List).add({
      'id': '2',
      'name': 'X',
      'evil': 'y',
    });
    expect((await send('POST', '/api/save', body: body)).$1, 400);
    final body2 = oneBottle(catalog);
    ((body2['tables'] as Map)['wineries.csv'] as List).add({
      'id': 2,
      'name': 'X',
    });
    expect((await send('POST', '/api/save', body: body2)).$1, 400);
  });

  group('only the local page can use it', () {
    test('foreign Host header (DNS rebinding) is refused', () async {
      expect((await send('GET', '/api/catalog', host: 'evil.example')).$1, 403);
    });

    test('POST from another website is refused', () async {
      final (_, catalog) = await send('GET', '/api/catalog');
      final (status, _) = await send(
        'POST',
        '/api/save',
        body: oneBottle(catalog),
        origin: 'https://evil.example',
      );
      expect(status, 403);
      expect(File(outPath).existsSync(), isFalse);
    });

    test('non-JSON POST (form/text, no CORS preflight) is refused', () async {
      final (_, catalog) = await send('GET', '/api/catalog');
      final (status, _) = await send(
        'POST',
        '/api/save',
        body: jsonEncode(oneBottle(catalog)),
        contentType: ContentType.text,
      );
      expect(status, 415);
    });

    test('POST from the editor page itself is accepted', () async {
      final (_, catalog) = await send('GET', '/api/catalog');
      final (status, _) = await send(
        'POST',
        '/api/save',
        body: oneBottle(catalog),
        origin: 'http://localhost:${server.port}',
      );
      expect(status, 200);
    });
  });

  group('photos', () {
    final jpeg = base64Encode([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

    Future<void> saveBottle() async {
      final (_, catalog) = await send('GET', '/api/catalog');
      expect(
        (await send('POST', '/api/save', body: oneBottle(catalog))).$1,
        200,
      );
    }

    test('are stored, copied into the app folder and removed again', () async {
      await saveBottle();
      final (status, body) = await send(
        'POST',
        '/api/photo',
        body: {'wine_id': '1', 'data': jpeg},
      );
      expect(status, 200);
      expect(body['photos'], ['1']);
      expect(File('$dataDir/photos/1.jpg').existsSync(), isTrue);
      expect(File('${tmp.path}/photos/1.jpg').existsSync(), isTrue);
      expect((await send('GET', '/api/catalog')).$2['photos'], ['1']);

      await send('POST', '/api/photo/delete', body: {'wine_id': '1'});
      expect(File('$dataDir/photos/1.jpg').existsSync(), isFalse);
      expect(File('${tmp.path}/photos/1.jpg').existsSync(), isFalse);
    });

    test('are refused for unknown wines, paths and non-JPEG data', () async {
      await saveBottle();
      for (final id in ['2', '../1', '1/../../x', '']) {
        final (status, _) = await send(
          'POST',
          '/api/photo',
          body: {'wine_id': id, 'data': jpeg},
        );
        expect(status, 400, reason: id);
      }
      final (status, _) = await send(
        'POST',
        '/api/photo',
        body: {
          'wine_id': '1',
          'data': base64Encode([1, 2, 3, 4, 5]),
        },
      );
      expect(status, 415);
      expect(Directory('$dataDir/photos').existsSync(), isFalse);
    });

    test('are removed when their wine is deleted', () async {
      await saveBottle();
      await send('POST', '/api/photo', body: {'wine_id': '1', 'data': jpeg});
      final (_, catalog) = await send('GET', '/api/catalog');
      final empty = {
        'version': catalog['version'],
        'tables': {for (final name in catalogFiles.keys) name: <Object>[]},
      };
      expect((await send('POST', '/api/save', body: empty)).$1, 200);
      expect(File('${tmp.path}/photos/1.jpg').existsSync(), isFalse);
    });

    test('are served by number only', () async {
      await saveBottle();
      await send('POST', '/api/photo', body: {'wine_id': '1', 'data': jpeg});
      final request = await client.open(
        'GET',
        '127.0.0.1',
        server.port,
        '/photo/1',
      );
      request.headers.host = 'localhost';
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.contentType?.mimeType, 'image/jpeg');
      await response.drain<void>();
      expect((await send('GET', '/photo/..%2Fwines.csv')).$1, 404);
    });
  });

  test('unknown paths are 404, not files from disk', () async {
    expect((await send('GET', '/../data/wines.csv')).$1, 404);
    expect((await send('GET', '/tool/editor/index.html')).$1, 404);
  });
}
