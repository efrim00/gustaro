import 'catalog_repository.dart';
import 'models.dart';

/// Reads several catalogues as one: the bundled, verified wines plus the
/// bottles added on this device. IDs never clash (see [myBottleIdBase]).
class CombinedCatalog implements CatalogReader {
  CombinedCatalog(this._sources);

  final List<CatalogReader> _sources;

  @override
  Future<List<BarcodeHit>> findBarcodes(Set<String> codes) async => [
    for (final source in _sources) ...await source.findBarcodes(codes),
  ];

  @override
  Future<Map<int, List<VintageOption>>> vintagesOf(Set<int> wineIds) async => {
    for (final source in _sources) ...await source.vintagesOf(wineIds),
  };

  @override
  Future<List<LabelIndexEntry>> labelIndex() async => [
    for (final source in _sources) ...await source.labelIndex(),
  ];

  @override
  Future<VintageDetails?> vintageDetails(
    int vintageId, {
    String language = CatalogRepository.fallbackLanguage,
  }) async {
    for (final source in _sources) {
      final details = await source.vintageDetails(
        vintageId,
        language: language,
      );
      if (details != null) return details;
    }
    return null;
  }

  @override
  Future<Map<int, VintageSummary>> vintageSummaries(
    Set<int> vintageIds,
  ) async => {
    for (final source in _sources) ...await source.vintageSummaries(vintageIds),
  };
}
