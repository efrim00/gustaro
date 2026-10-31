// Checks that block or weaken an App Store submission.
//
//   dart run tool/preflight.dart
//
// Exits with code 1 if anything must be fixed first.
import 'dart:io';

import 'src/catalog_files.dart';

void main() {
  final problems = <String>[];
  final warnings = <String>[];

  for (final path in [
    'assets/legal/terms_en.md',
    'assets/legal/privacy_en.md',
  ]) {
    if (File(path).readAsStringSync().contains('[CONTACT_EMAIL]')) {
      problems.add('$path: replace [CONTACT_EMAIL] with a real address');
    }
  }

  final files = CatalogFiles.load('data');
  final wines = files.records('wines.csv');
  final vintages = files.records('vintages.csv');
  final texts = files.records('vintage_translations.csv');
  if (wines.length < 20) {
    warnings.add(
      'catalogue has only ${wines.length} wine(s); the expo demo needs real bottles',
    );
  }
  for (final v in vintages) {
    for (final column in ['abv', 'acidity_g_l', 'tannins_g_l']) {
      if (v[column] == '0') {
        warnings.add(
          'vintage ${v['id']}: $column is 0; leave it empty if unknown '
          '(the app would show 0)',
        );
      }
    }
  }
  for (final t in texts) {
    if ((t['sensory_notes'] ?? '').trim().toLowerCase() == 'test') {
      warnings.add('vintage ${t['vintage_id']}: sensory notes are test text');
    }
  }

  for (final w in warnings) {
    stdout.writeln('warning: $w');
  }
  for (final p in problems) {
    stderr.writeln('MUST FIX: $p');
  }
  if (problems.isNotEmpty) exit(1);
  stdout.writeln('No blocking problems.');
}
