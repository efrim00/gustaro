// Turns the in-app legal texts into plain web pages, so they can be hosted
// for the App Store's required Privacy Policy URL.
//
//   dart run tool/build_legal_site.dart
import 'dart:convert';
import 'dart:io';

void main() {
  Directory('site').createSync();
  for (final (source, target) in [
    ('assets/legal/privacy_en.md', 'site/privacy.html'),
    ('assets/legal/terms_en.md', 'site/terms.html'),
  ]) {
    File(target).writeAsStringSync(_page(File(source).readAsLinesSync()));
    stdout.writeln('Wrote $target');
  }
}

String _page(List<String> lines) {
  const escape = HtmlEscape(HtmlEscapeMode.element);
  final body = StringBuffer();
  var title = 'Gustaro';
  var inList = false;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final isItem = line.startsWith('- ');
    if (inList && !isItem) {
      body.writeln('</ul>');
      inList = false;
    }
    if (line.startsWith('## ')) {
      body.writeln('<h2>${escape.convert(line.substring(3))}</h2>');
    } else if (line.startsWith('# ')) {
      title = line.substring(2);
      body.writeln('<h1>${escape.convert(title)}</h1>');
    } else if (isItem) {
      if (!inList) body.writeln('<ul>');
      inList = true;
      body.writeln('<li>${escape.convert(line.substring(2))}</li>');
    } else {
      body.writeln('<p>${escape.convert(line)}</p>');
    }
  }
  if (inList) body.writeln('</ul>');
  return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Gustaro · ${escape.convert(title)}</title>
<style>
  body { margin: 0 auto; max-width: 680px; padding: 32px 20px 64px; color: #111;
    background: #fff; font: 17px/1.55 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
  h1 { color: #d22b3b; font-size: 32px; }
  h2 { font-size: 20px; margin-top: 32px; }
</style>
</head>
<body>
$body</body>
</html>
''';
}
