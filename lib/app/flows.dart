import 'package:flutter/material.dart';

import '../gustaro_core.dart';
import 'screens/miss_screen.dart';
import 'screens/wine_screen.dart';
import 'services.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

/// Shows what a scan resolved to. Completes when the user is back, with
/// what they asked for on the "not in catalogue" screen, if anything.
Future<MissAction?> presentOutcome(
  BuildContext context,
  ScanOutcome outcome, {
  String? barcode,
}) async {
  switch (outcome) {
    case ShowVintage(:final vintageId):
      await openVintage(context, vintageId);
      return null;
    case ChooseVintage():
      final id = await _pickVintage(context, outcome);
      if (id != null && context.mounted) await openVintage(context, id);
      return null;
    case ChooseWine():
      final next = await _pickWine(context, outcome);
      if (next == null || !context.mounted) return null;
      return presentOutcome(context, next, barcode: barcode);
    case NotInCatalogue():
      return Navigator.of(context).push<MissAction>(
        MaterialPageRoute(
          builder: (_) => MissScreen(outcome: outcome, barcode: barcode),
        ),
      );
  }
}

Future<void> openVintage(BuildContext context, int vintageId) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => WineScreen(vintageId: vintageId)),
    );

/// Opens a wine from a list: its page, or the year picker if it has several.
Future<void> openWine(BuildContext context, LabelIndexEntry entry) =>
    presentOutcome(
      context,
      entry.vintages.length == 1
          ? ShowVintage(entry.vintages.single.id)
          : ChooseVintage(wine: entry.wine, vintages: entry.vintages),
    );

Future<int?> _pickVintage(BuildContext context, ChooseVintage outcome) =>
    showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _VintageSheet(outcome: outcome),
    );

class _VintageSheet extends StatelessWidget {
  const _VintageSheet({required this.outcome});

  final ChooseVintage outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GLayout.gutter,
        4,
        GLayout.gutter,
        GLayout.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(outcome.wine.wineryName, style: GText.small),
          Text(outcome.wine.name, style: GText.cardTitle),
          const SizedBox(height: 16),
          Text(l10n.pickVintageTitle, style: GText.buttonSmall),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in outcome.vintages)
                    _YearChip(
                      year: v.year,
                      selected: v.id == outcome.preselectedVintageId,
                      onTap: () => Navigator.pop(context, v.id),
                    ),
                ],
              ),
            ),
          ),
          if (outcome.preselectedVintageId != null) ...[
            const SizedBox(height: 10),
            Text(l10n.pickVintageLabelRead, style: GText.small),
          ],
        ],
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.year,
    required this.selected,
    required this.onTap,
  });

  final int year;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? GColors.ink : GColors.white,
      shape: const RoundedRectangleBorder(side: BorderSide(color: GColors.ink)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 84,
          height: 52,
          child: Center(
            child: Text(
              '$year',
              style: GText.button.copyWith(
                color: selected ? GColors.white : GColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<ScanOutcome?> _pickWine(BuildContext context, ChooseWine outcome) {
  final l10n = context.l10n;
  return showModalBottomSheet<ScanOutcome>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(
        GLayout.gutter,
        4,
        GLayout.gutter,
        GLayout.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outcome.source == ScanSource.barcode
                ? l10n.pickWineBarcodeTitle
                : l10n.pickWineLabelTitle,
            style: GText.title,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: outcome.candidates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final candidate = outcome.candidates[i];
                return _CandidateTile(
                  wine: candidate.wine,
                  onTap: () => Navigator.pop(sheet, candidate.next),
                );
              },
            ),
          ),
          if (outcome.source == ScanSource.label) ...[
            const SizedBox(height: 12),
            GButton(
              label: l10n.pickWineNone,
              style: GButtonStyle.outline,
              onPressed: () =>
                  Navigator.pop(sheet, NotInCatalogue(outcome.source)),
            ),
          ],
        ],
      ),
    ),
  );
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.wine, required this.onTap});

  final WineSummary wine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GColors.white,
    shape: const RoundedRectangleBorder(side: BorderSide(color: GColors.ink)),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wine.wineryName, style: GText.small),
                  const SizedBox(height: 2),
                  Text(wine.name, style: GText.cardTitle),
                  const SizedBox(height: 2),
                  Text(wine.type.label(context.l10n), style: GText.small),
                ],
              ),
            ),
            const SvgIcon('chevron', size: 20),
          ],
        ),
      ),
    ),
  );
}
