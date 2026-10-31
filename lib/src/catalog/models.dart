/// Plain domain models returned by the catalog. No drift or Flutter types
/// leak out of the data layer, so UI code only ever sees these.
library;

/// Stored as its name in the `wine.type` column. Add values here when the
/// catalogue needs them; existing rows keep working.
enum WineType { red, white, rose, orange, sparkling, dessert }

/// IDs from here up belong to bottles added on the device. The bundled
/// catalogue never reaches this range, so both can be merged without clashes.
const int myBottleIdBase = 1000000000;

final class WineSummary {
  const WineSummary({
    required this.id,
    required this.name,
    required this.wineryName,
    required this.type,
    this.region,
  });

  final int id;
  final String name;
  final String wineryName;
  final WineType type;
  final String? region;

  /// False for bottles the user added: they did not come from a winemaker.
  bool get isVerified => id < myBottleIdBase;
}

/// One verified vintage of a wine, as listed in the vintage picker.
final class VintageOption {
  const VintageOption({required this.id, required this.year});

  final int id;
  final int year;
}

/// One `barcode` row joined with the wine it points to.
final class BarcodeHit {
  const BarcodeHit({
    required this.wine,
    required this.vintageId,
    required this.bottleSizeMl,
  });

  final WineSummary wine;

  /// Null when the code identifies the product rather than a harvest year.
  final int? vintageId;
  final int? bottleSizeMl;
}

/// A wine as the label matcher sees it: names to match against and the
/// verified vintages to offer once the user confirms it.
final class LabelIndexEntry {
  const LabelIndexEntry({required this.wine, required this.vintages});

  final WineSummary wine;
  final List<VintageOption> vintages;
}

/// Everything the result screen shows. Technical specs are nullable because
/// winemakers do not publish every value for every harvest.
final class VintageDetails {
  const VintageDetails({
    required this.vintageId,
    required this.year,
    required this.wine,
    required this.region,
    required this.grapeVarieties,
    required this.abv,
    required this.acidityGL,
    required this.tanninsGL,
    required this.residualSugarGL,
    required this.language,
    required this.description,
    required this.sensoryNotes,
    required this.foodPairings,
  });

  final int vintageId;
  final int year;
  final WineSummary wine;
  final String? region;
  final List<String> grapeVarieties;

  /// Alcohol by volume, percent.
  final double? abv;
  final double? acidityGL;
  final double? tanninsGL;
  final double? residualSugarGL;

  /// Language the texts below are actually in (may be the fallback).
  final String language;
  final String? description;
  final String? sensoryNotes;
  final List<String> foodPairings;
}

/// Minimal info to render a recent-scan row.
final class VintageSummary {
  const VintageSummary({
    required this.vintageId,
    required this.year,
    required this.wine,
  });

  final int vintageId;
  final int year;
  final WineSummary wine;
}
