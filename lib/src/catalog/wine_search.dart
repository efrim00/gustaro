import '../scan/text_normalizer.dart';
import 'models.dart';

/// Wines whose winery, name or a vintage year contain every word of [query].
/// Ignores case and diacritics; an empty query returns everything.
List<LabelIndexEntry> searchWines(List<LabelIndexEntry> index, String query) {
  final words = tokenize(query);
  if (words.isEmpty) return index;
  return [
    for (final entry in index)
      if (_matches(entry, words)) entry,
  ];
}

bool _matches(LabelIndexEntry entry, List<String> words) {
  final haystack = normalizeForMatching(
    '${entry.wine.wineryName} ${entry.wine.name} ${entry.wine.region ?? ''} '
    '${entry.vintages.map((v) => v.year).join(' ')}',
  );
  return words.every(haystack.contains);
}
