import 'package:flutter/material.dart';

import '../../gustaro_core.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// A recently viewed wine with the "Did you like it?" question. The answer
/// stays on the device; Gustaro has no scores.
class RecentCard extends StatelessWidget {
  const RecentCard({
    super.key,
    required this.summary,
    required this.scan,
    required this.onOpen,
    required this.onRemove,
    required this.onLiked,
    required this.onTaste,
  });

  final VintageSummary summary;
  final RecentScan scan;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final ValueChanged<bool?> onLiked;
  final VoidCallback onTaste;

  String _when(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seen = scan.viewedAt.toLocal();
    final days = today
        .difference(DateTime(seen.year, seen.month, seen.day))
        .inDays;
    return switch (days) {
      <= 0 => l10n.recentScannedToday,
      1 => l10n.recentScannedYesterday,
      < 7 => l10n.recentScannedDays(days),
      < 14 => l10n.recentScannedLastWeek,
      _ => l10n.recentScannedEarlier,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wine = summary.wine;
    final origin = wine.region == null
        ? wine.type.label(l10n)
        : l10n.wineOrigin(wine.type.label(l10n), wine.region!);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: GColors.ink)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 112,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: GColors.ink)),
                    ),
                    alignment: Alignment.center,
                    child: BottleArt(height: 128, wineId: wine.id),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 6, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1, right: 6),
                                child: SvgIcon(
                                  'camera_small',
                                  size: 16,
                                  color: GColors.red,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _when(context),
                                  style: GText.label.copyWith(
                                    color: GColors.red,
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: l10n.recentHide,
                                excludeSemantics: true,
                                child: InkResponse(
                                  onTap: onRemove,
                                  radius: 22,
                                  child: const SizedBox(
                                    width: 36,
                                    height: 28,
                                    child: Center(
                                      child: SvgIcon('close', size: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            wine.wineryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GText.small.copyWith(
                              color: GColors.textSoft,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${wine.name} ${summary.year}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GText.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            origin,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GText.small.copyWith(
                              color: GColors.textSoft,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: GColors.ink)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: scan.liked == null ? _question(context) : _answered(context),
          ),
        ],
      ),
    );
  }

  Widget _question(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Text(l10n.feedbackQuestion, style: GText.button),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GButton(
                label: l10n.feedbackNo,
                style: GButtonStyle.outline,
                height: 52,
                icon: const SvgIcon('thumb_down', size: 20),
                onPressed: () => onLiked(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GButton(
                label: l10n.feedbackYes,
                height: 52,
                icon: const SvgIcon('thumb_up', size: 20),
                onPressed: () => onLiked(true),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: onTaste,
            style: TextButton.styleFrom(foregroundColor: GColors.ink),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.feedbackNotTasted,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' ${l10n.feedbackTasteNow}',
                    style: const TextStyle(color: GColors.red),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GText.buttonSmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _answered(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SvgIcon(
            scan.liked! ? 'thumb_up' : 'thumb_down',
            size: 20,
            color: GColors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              scan.liked! ? l10n.feedbackLiked : l10n.feedbackDisliked,
              style: GText.buttonSmall,
            ),
          ),
          TextButton(
            onPressed: () => onLiked(null),
            style: TextButton.styleFrom(foregroundColor: GColors.ink),
            child: Text(
              l10n.feedbackChange,
              style: GText.buttonSmall.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
