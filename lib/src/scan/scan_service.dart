import '../catalog/catalog_repository.dart';
import 'label_matcher.dart';
import 'resolution.dart' as resolution;
import 'scan_outcome.dart';

/// Entry point for the camera screen: feed it what the scanner or OCR
/// produced and get back which screen to show. Create one per opened
/// catalogue; the label index is built on first use and cached.
class ScanService {
  ScanService(this._catalog, {this.labelConfig = const LabelMatchConfig()});

  final CatalogReader _catalog;
  final LabelMatchConfig labelConfig;
  Future<LabelMatcher>? _matcher;

  /// [rawValue] is the barcode's raw value as reported by the scanner.
  Future<ScanOutcome> resolveBarcode(String rawValue) async {
    final keys = resolution.barcodeLookupKeys(rawValue);
    final hits = await _catalog.findBarcodes(keys);
    final vintages = await _catalog.vintagesOf({
      for (final hit in hits) hit.wine.id,
    });
    return resolution.resolveBarcode(hits, vintages);
  }

  /// [ocrText] is the full text recognized on the label.
  Future<ScanOutcome> resolveLabel(String ocrText) async =>
      resolution.resolveLabel(ocrText, await (_matcher ??= _buildMatcher()));

  /// Call after the set of wines changed (a bottle was added or removed).
  void catalogChanged() => _matcher = null;

  Future<LabelMatcher> _buildMatcher() async =>
      LabelMatcher(await _catalog.labelIndex(), config: labelConfig);
}
