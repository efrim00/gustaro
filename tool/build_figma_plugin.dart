// Builds figma_plugin/code.js: a Figma plugin that draws every app screen as
// editable layers, using the app's own icons, colours and texts.
//
//   dart run tool/build_figma_plugin.dart
//
// Then in Figma desktop: Plugins > Development > Import plugin from manifest,
// choose figma_plugin/manifest.json, and run it. See figma_plugin/README.md.
import 'dart:convert';
import 'dart:io';

/// SVG file in assets -> component name in Figma.
const _assetNames = {
  'assets/icons/band.svg': 'pattern/band',
  'assets/icons/hero_side.svg': 'pattern/hero-side',
  'assets/brand/logo_dark.svg': 'logo/dark',
  'assets/brand/logo_white.svg': 'logo/white',
  'assets/icons/bell.svg': 'icon/bell',
  'assets/icons/bottle_glyph.svg': 'icon/bottle-mark',
  'assets/icons/camera.svg': 'icon/camera',
  'assets/icons/camera_small.svg': 'icon/camera-small',
  'assets/icons/chevron.svg': 'icon/arrow',
  'assets/icons/close.svg': 'icon/close',
  'assets/icons/diamond.svg': 'icon/diamond',
  'assets/icons/footer_mark.svg': 'icon/footer-mark',
  'assets/icons/nav_explore.svg': 'icon/nav-explore',
  'assets/icons/nav_home.svg': 'icon/nav-home',
  'assets/icons/nav_more.svg': 'icon/nav-more',
  'assets/icons/nav_wines.svg': 'icon/nav-wines',
  'assets/icons/search.svg': 'icon/search',
  'assets/icons/send.svg': 'icon/send',
  'assets/icons/sparkle.svg': 'icon/sparkle',
  'assets/icons/sparkle_small.svg': 'icon/sparkle-small',
  'assets/icons/sparkle_title.svg': 'icon/sparkle-title',
  'assets/icons/thumb_down.svg': 'icon/thumb-down',
  'assets/icons/thumb_up.svg': 'icon/thumb-up',
};

/// Icons the app takes from Flutter's Material set: drawn here as simple
/// outlines in the same style (24px, 2px strokes).
String _outline(String body) =>
    '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" '
    'xmlns="http://www.w3.org/2000/svg" stroke="#111111" stroke-width="1.8" '
    'stroke-linecap="round" stroke-linejoin="round">$body</svg>';

final _drawn = {
  'icon/back': _outline('<path d="M15 4L7 12L15 20" stroke-width="2"/>'),
  'icon/globe': _outline(
    '<circle cx="12" cy="12" r="9"/><path d="M3 12H21"/>'
    '<path d="M12 3C9 6 9 18 12 21C15 18 15 6 12 3Z"/>',
  ),
  'icon/person': _outline(
    '<circle cx="12" cy="8" r="4"/><path d="M4 20C4 16 8 14 12 14C16 14 20 16 20 20"/>',
  ),
  'icon/glass': _outline(
    '<path d="M8 3H16V9C16 11.5 14.5 13 12 13C9.5 13 8 11.5 8 9V3Z"/>'
    '<path d="M12 13V20M8 21H16"/>',
  ),
  'icon/cocktail': _outline(
    '<path d="M4 4H20L12 13L4 4Z"/><path d="M12 13V20M8 21H16"/>',
  ),
  'icon/document': _outline(
    '<path d="M6 3H14L19 8V21H6V3Z"/><path d="M14 3V8H19M9 13H16M9 17H16"/>',
  ),
  'icon/shield': _outline(
    '<path d="M12 3L20 6V12C20 16.5 16.5 20 12 21C7.5 20 4 16.5 4 12V6L12 3Z"/>'
    '<path d="M12 11V16M12 8V8.5"/>',
  ),
  'icon/trash': _outline(
    '<path d="M4 7H20M9 7V4H15V7M6 7L7 21H17L18 7M10 11V17M14 11V17"/>',
  ),
  'icon/info': _outline(
    '<circle cx="12" cy="12" r="9"/><path d="M12 11V17M12 7.5V8"/>',
  ),
  'icon/plus-large': _outline(
    '<path d="M12 5V19M5 12H19" stroke-width="2.2"/>',
  ),
  'icon/flash': _outline('<path d="M7 2V13H10V22L17 10H13L17 2H7Z"/>'),
};

const _colors = {
  'ink': '#111111',
  'white': '#FFFFFF',
  'red': '#D22B3B',
  'text-muted': '#5C5C5C',
  'text-soft': '#4A4A4A',
  'line': '#E6E6E6',
  'surface': '#F5F5F5',
  'nav-inactive': '#9A9A9A',
  'ok': '#1B7F3B',
};

/// name, family, style, size, line height in % (0 = font default), spacing.
/// Domine SemiBold is not in Figma's font list: Bold stands in for it.
const _textStyles = [
  ['Gustaro/Display', 'Onest', 'SemiBold', 25, 120, -0.5],
  ['Gustaro/Title', 'Domine', 'Bold', 25, 120, -0.25],
  ['Gustaro/Card title', 'Domine', 'Bold', 20, 120, 0],
  ['Gustaro/App bar', 'Domine', 'Bold', 18, 120, 0],
  ['Gustaro/Body', 'Onest', 'Regular', 15, 147, 0],
  ['Gustaro/Small', 'Onest', 'Regular', 13, 135, 0],
  ['Gustaro/Label', 'Onest', 'SemiBold', 13, 130, 0],
  ['Gustaro/Button', 'Onest', 'SemiBold', 17, 120, 0],
  ['Gustaro/Button small', 'Onest', 'SemiBold', 15, 120, 0],
  ['Gustaro/Script', 'Caveat', 'Bold', 36, 100, 0],
];

void main() {
  final svgs = <String, String>{};
  for (final MapEntry(key: path, value: name) in _assetNames.entries) {
    svgs[name] = _read(path);
  }
  svgs.addAll(_drawn);

  final arb = jsonDecode(_read('lib/l10n/app_en.arb')) as Map<String, dynamic>;
  final l10n = {
    for (final MapEntry(key: k, value: v) in arb.entries)
      if (!k.startsWith('@') && v is String) k: v,
  };

  final data = {
    'colors': _colors,
    'textStyles': _textStyles,
    'svgs': svgs,
    'l10n': l10n,
    'terms': _read('assets/legal/terms_en.md'),
    'privacy': _read('assets/legal/privacy_en.md'),
  };

  final template = _read('tool/figma/plugin_template.js');
  const marker = '/*DATA*/ null';
  if (!template.contains(marker)) {
    stderr.writeln('Template has no $marker placeholder.');
    exit(1);
  }
  final out = File('figma_plugin/code.js')
    ..createSync(recursive: true)
    ..writeAsStringSync(template.replaceFirst(marker, jsonEncode(data)));
  stdout.writeln('Wrote ${out.path} (${out.lengthSync() ~/ 1024} KB)');
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path (run from the project folder).');
    exit(1);
  }
  return file.readAsStringSync();
}
