import 'package:flutter/material.dart';

import '../../gustaro_core.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// One wine in a list.
class WineRow extends StatelessWidget {
  const WineRow({super.key, required this.entry, required this.onTap});

  final LabelIndexEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wine = entry.wine;
    final details = [
      wine.type.label(l10n),
      if (entry.vintages.length == 1)
        '${entry.vintages.single.year}'
      else
        l10n.winesYears(entry.vintages.length),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: BottleArt(height: 64, glow: false, wineId: wine.id),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wine.wineryName, style: GText.small),
                  const SizedBox(height: 1),
                  Text(
                    wine.name,
                    style: GText.cardTitle.copyWith(fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(details, style: GText.small),
                  if (!wine.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l10n.winesMineBadge,
                        style: GText.label.copyWith(color: GColors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SvgIcon('chevron', size: 20),
          ],
        ),
      ),
    );
  }
}
