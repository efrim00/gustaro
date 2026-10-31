import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Bottle photos. Catalogue wines ship as `assets/photos/<wine id>.jpg`;
/// photos of bottles added on this phone live in [directory] and never leave it.
class PhotoStore {
  PhotoStore({this.directory, this.bundled = const {}});

  final Directory? directory;
  final Set<String> bundled;

  static const _maxSide = 1200;

  File? _file(int wineId) =>
      directory == null ? null : File('${directory!.path}/$wineId.png');

  /// The photo of [wineId], or null when it has none.
  ImageProvider? imageFor(int wineId) {
    final file = _file(wineId);
    if (file != null && file.existsSync()) return FileImage(file);
    final asset = 'assets/photos/$wineId.jpg';
    return bundled.contains(asset) ? AssetImage(asset) : null;
  }

  /// Stores [bytes] (any format the platform decodes) as the photo of
  /// [wineId]. It is decoded and re-encoded, which drops all metadata such as
  /// the location a camera records, and bounded in size.
  Future<void> save(int wineId, Uint8List bytes) async {
    final file = _file(wineId);
    if (file == null) return;
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final tall = descriptor.height >= descriptor.width;
    final longSide = tall ? descriptor.height : descriptor.width;
    final shrink = longSide > _maxSide;
    final codec = await descriptor.instantiateCodec(
      targetHeight: shrink && tall ? _maxSide : null,
      targetWidth: shrink && !tall ? _maxSide : null,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw const FormatException('Cannot encode image.');
      await directory!.create(recursive: true);
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
      await FileImage(file).evict();
    } finally {
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  /// Deletes the photos of bottles added on this phone, except [keep].
  Future<void> prune({Set<int> keep = const {}}) async {
    final dir = directory;
    if (dir == null || !dir.existsSync()) return;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final id = int.tryParse(
        entity.uri.pathSegments.last.replaceFirst('.png', ''),
      );
      if (id == null || !keep.contains(id)) await entity.delete();
    }
  }
}
