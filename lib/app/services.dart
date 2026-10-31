import 'package:flutter/widgets.dart';

import '../gustaro_core.dart';
import '../l10n/app_localizations.dart';
import 'app_databases.dart';
import 'cloud_config.dart';
import 'photo_store.dart';

/// Everything screens need from the logic layer, created once at startup.
class AppServices {
  AppServices(AppDatabases databases)
    : _catalogDb = databases.catalog,
      photos = databases.photos,
      myBottles = MyBottlesStore(databases.myBottles),
      recent = RecentScansStore(databases.user),
      settings = SettingsStore(databases.user),
      catalog = CombinedCatalog([
        CatalogRepository(databases.catalog),
        CatalogRepository(databases.myBottles),
      ]) {
    scanner = ScanService(catalog);
  }

  /// English only for now; catalogue texts fall back to Romanian.
  static const language = 'en';

  /// Bump when the accepted legal texts change, to ask for consent again.
  static const legalVersion = '1';
  static const legalKey = 'legal_accepted_version';
  static const heroHiddenKey = 'hero_hidden';

  final CatalogDatabase _catalogDb;
  final CatalogReader catalog;
  final PhotoStore photos;
  final MyBottlesStore myBottles;
  final RecentScansStore recent;
  final SettingsStore settings;
  late final ScanService scanner;

  /// Ticks whenever recents or bottles change, so visible lists can refresh.
  final revision = ValueNotifier<int>(0);

  /// Deletes photos of bottles that are no longer on this phone.
  Future<void> prunePhotos() async {
    final index = await catalog.labelIndex();
    await photos.prune(
      keep: {
        for (final e in index)
          if (!e.wine.isVerified) e.wine.id,
      },
    );
  }

  /// Fetches a newer catalogue, if there is one. Quiet on purpose: with no
  /// signal the phone just keeps what it has.
  Future<void> syncCatalog() async {
    final directory = photos.cloudDirectory;
    if (directory == null) return;
    final result = await CatalogSync(
      db: _catalogDb,
      baseUrl: Uri.parse(gustaroApi),
      photosDirectory: directory,
    ).run();
    if (result == SyncResult.updated) {
      PaintingBinding.instance.imageCache.clear();
      changed(wines: true);
    }
  }

  void changed({bool wines = false}) {
    if (wines) scanner.catalogChanged();
    revision.value++;
  }

  Future<void> deleteAllData() async {
    await myBottles.clear();
    await photos.prune();
    await recent.clear();
    await settings.write(heroHiddenKey, 'false');
    changed(wines: true);
  }
}

class Services extends InheritedWidget {
  const Services({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Services>()!.services;

  static AppServices? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Services>()?.services;

  @override
  bool updateShouldNotify(Services oldWidget) => false;
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension WineTypeLabel on WineType {
  String label(AppLocalizations l10n) => switch (this) {
    WineType.red => l10n.typeRed,
    WineType.white => l10n.typeWhite,
    WineType.rose => l10n.typeRose,
    WineType.orange => l10n.typeOrange,
    WineType.sparkling => l10n.typeSparkling,
    WineType.dessert => l10n.typeDessert,
  };
}
