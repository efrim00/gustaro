import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Shows a legal text bundled with the app, so it reads offline. The files
/// use a tiny Markdown subset: `# `, `## `, `- ` and paragraphs.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.asset});

  static const terms = 'assets/legal/terms_en.md';
  static const privacy = 'assets/legal/privacy_en.md';

  final String title;
  final String asset;

  List<Widget> _render(String text) {
    final blocks = <Widget>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('## ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(trimmed.substring(3), style: GText.cardTitle),
          ),
        );
      } else if (trimmed.startsWith('# ')) {
        continue; // The app bar already shows the title.
      } else if (trimmed.startsWith('- ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('·  ', style: GText.body),
                Expanded(child: Text(trimmed.substring(2), style: GText.body)),
              ],
            ),
          ),
        );
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(trimmed, style: GText.body),
          ),
        );
      }
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder(
        future: rootBundle.loadString(asset),
        builder: (context, snapshot) {
          final text = snapshot.data;
          if (text == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              GLayout.gutter,
              8,
              GLayout.gutter,
              32,
            ),
            child: SafeArea(
              top: false,
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _render(text),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
