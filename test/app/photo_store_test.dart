import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/app/photo_store.dart';

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFD22B3B),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('photos'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('saves, finds and shrinks a photo, then prunes it', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final store = PhotoStore(directory: Directory('${dir.path}/p'));
      expect(store.imageFor(1000000001), isNull);

      await store.save(1000000001, await _png(600, 3000));
      expect(store.imageFor(1000000001), isNotNull);

      final codec = await ui.instantiateImageCodec(
        File('${dir.path}/p/1000000001.png').readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      expect(image.height, 1200);
      expect(image.width, 240);

      await store.prune(keep: {1000000001});
      expect(store.imageFor(1000000001), isNotNull);
      await store.prune();
      expect(store.imageFor(1000000001), isNull);
    });
  });

  test('uses a bundled catalogue photo', () {
    final store = PhotoStore(bundled: {'assets/photos/7.jpg'});
    expect(store.imageFor(7), isNotNull);
    expect(store.imageFor(8), isNull);
  });
}
