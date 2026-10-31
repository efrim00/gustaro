import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../gustaro_core.dart';
import 'photo_store.dart';

const _catalogAsset = 'assets/catalog.sqlite';

/// The databases the app uses: the bundled catalogue (replaced on every
/// launch from the app bundle), the bottles added on the device, and other
/// on-device user data. Only the first is ever overwritten.
final class AppDatabases {
  AppDatabases._(this.catalog, this.myBottles, this.user, this.photos);

  @visibleForTesting
  AppDatabases.forTesting(this.catalog, this.myBottles, this.user)
    : photos = PhotoStore();

  final CatalogDatabase catalog;
  final CatalogDatabase myBottles;
  final UserDatabase user;
  final PhotoStore photos;

  /// Copies the bundled catalogue out of the app bundle (SQLite cannot open
  /// a file inside it) and opens all databases. Throws if the catalogue
  /// was built for another schema version: better to fail than to show
  /// wrong data.
  static Future<AppDatabases> open() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);

    final catalogFile = File('${dir.path}/catalog.sqlite');
    final catalog = await _openCatalog(catalogFile);

    final myBottles = CatalogDatabase(
      NativeDatabase(File('${dir.path}/my_bottles.sqlite')),
    );
    final user = UserDatabase(NativeDatabase(File('${dir.path}/user.sqlite')));
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final photos = PhotoStore(
      directory: Directory('${dir.path}/bottle_photos'),
      cloudDirectory: Directory('${dir.path}/cloud_photos'),
      bundled: manifest
          .listAssets()
          .where((a) => a.startsWith('assets/photos/'))
          .toSet(),
    );
    return AppDatabases._(catalog, myBottles, user, photos);
  }

  /// The catalogue on the phone is kept between launches, because it may
  /// have been brought up to date from the server. The one shipped in the
  /// app replaces it only when the app's is newer (a new app version).
  /// Throws if the catalogue has another schema version than the app knows:
  /// better to fail than to show wrong data.
  static Future<CatalogDatabase> _openCatalog(File catalogFile) async {
    final data = await rootBundle.load(_catalogAsset);
    final bundled = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    int? localVersion;
    if (catalogFile.existsSync()) {
      final local = CatalogDatabase(NativeDatabase(catalogFile));
      try {
        final meta = await CatalogRepository(local).meta();
        if (meta?.schemaVersion == CatalogDatabase.currentSchemaVersion) {
          localVersion = meta?.dataVersion;
        }
      } on Object {
        localVersion = null;
      }
      await local.close();
    }

    final probe = File('${catalogFile.path}.bundled');
    await probe.writeAsBytes(bundled, flush: true);
    final bundledDb = CatalogDatabase(NativeDatabase(probe));
    final bundledMeta = await CatalogRepository(bundledDb).meta();
    await bundledDb.close();
    await probe.delete();

    if (shouldInstallBundled(
      localVersion: localVersion,
      bundledVersion: bundledMeta?.dataVersion ?? 0,
    )) {
      await catalogFile.writeAsBytes(bundled, flush: true);
    }

    final catalog = CatalogDatabase(NativeDatabase(catalogFile));
    final meta = await CatalogRepository(catalog).meta();
    if (meta?.schemaVersion != CatalogDatabase.currentSchemaVersion) {
      await catalog.close();
      throw StateError(
        'Bundled catalogue has schema ${meta?.schemaVersion}, '
        'app expects ${CatalogDatabase.currentSchemaVersion}. '
        'Rebuild it with tool/build_catalog.dart.',
      );
    }
    return catalog;
  }
}
