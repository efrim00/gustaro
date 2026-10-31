import 'dart:async';

import 'package:flutter/material.dart';

import '../../gustaro_core.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// The result screen: official specs, sensory notes and pairings.
class WineScreen extends StatefulWidget {
  const WineScreen({super.key, required this.vintageId});

  final int vintageId;

  @override
  State<WineScreen> createState() => _WineScreenState();
}

class _WineScreenState extends State<WineScreen> {
  late final AppServices _services = Services.of(context);
  late final Future<VintageDetails?> _details = _load();

  Future<VintageDetails?> _load() async {
    final details = await _services.catalog.vintageDetails(
      widget.vintageId,
      language: AppServices.language,
    );
    if (details != null) {
      await _services.recent.record(widget.vintageId);
      _services.changed();
    }
    return details;
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.wineDeleteTitle, style: GText.cardTitle),
        content: Text(l10n.wineDeleteBody, style: GText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.commonCancel, style: GText.buttonSmall),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(
              l10n.commonDelete,
              style: GText.buttonSmall.copyWith(color: GColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _services.recent.remove(widget.vintageId);
    await _services.myBottles.remove(widget.vintageId);
    await _services.prunePhotos();
    _services.changed(wines: true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          final details = snapshot.data;
          if (details == null) {
            return Center(
              child: Text(context.l10n.wineNotFound, style: GText.bodyMuted),
            );
          }
          return _Body(details: details, onDelete: _delete);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.details, required this.onDelete});

  final VintageDetails details;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = details;
    final wine = d.wine;
    final origin = d.region == null
        ? wine.type.label(l10n)
        : l10n.wineOrigin(wine.type.label(l10n), d.region!);
    String number(double value) =>
        value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
    final specs = <(String, String)>[
      if (d.abv != null) (l10n.wineAlcohol, '${number(d.abv!)} %'),
      if (d.acidityGL != null)
        (l10n.wineAcidity, '${number(d.acidityGL!)} g/L'),
      if (d.residualSugarGL != null)
        (l10n.wineSugar, '${number(d.residualSugarGL!)} g/L'),
      if (d.tanninsGL != null)
        (l10n.wineTannins, '${number(d.tanninsGL!)} g/L'),
    ];
    final description = d.description?.trim() ?? '';
    final notes = d.sensoryNotes?.trim() ?? '';
    final hasText =
        description.isNotEmpty || notes.isNotEmpty || d.foodPairings.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(GLayout.gutter, 0, GLayout.gutter, 32),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: BottleArt(height: 190, wineId: wine.id)),
              const SizedBox(height: 18),
              Center(child: _SourceBadge(verified: wine.isVerified)),
              const SizedBox(height: 14),
              Text(
                wine.wineryName,
                style: GText.body.copyWith(color: GColors.textSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '${wine.name} ${d.year}',
                style: GText.title.copyWith(fontSize: 28, height: 1.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(origin, style: GText.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              const StitchBand(),
              if (specs.isNotEmpty) ...[
                _Heading(l10n.wineSpecs),
                _SpecGrid(specs: specs),
              ],
              if (d.grapeVarieties.isNotEmpty) ...[
                _Heading(l10n.wineGrapes),
                Text(d.grapeVarieties.join(', '), style: GText.body),
              ],
              if (notes.isNotEmpty) ...[
                _Heading(l10n.wineSensory),
                Text(notes, style: GText.body),
              ],
              if (d.foodPairings.isNotEmpty) ...[
                _Heading(l10n.winePairings),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pairing in d.foodPairings)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: GColors.ink),
                        ),
                        child: Text(pairing, style: GText.label),
                      ),
                  ],
                ),
              ],
              if (description.isNotEmpty) ...[
                _Heading(l10n.wineAbout),
                Text(description, style: GText.body),
              ],
              const SizedBox(height: 26),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                wine.isVerified ? l10n.wineSourceVerified : l10n.wineSourceMine,
                style: GText.small,
              ),
              if (hasText && d.language != AppServices.language) ...[
                const SizedBox(height: 4),
                Text(l10n.wineLanguageNote, style: GText.small),
              ],
              if (!wine.isVerified) ...[
                const SizedBox(height: 20),
                GButton(
                  label: l10n.wineDelete,
                  style: GButtonStyle.outline,
                  onPressed: () => unawaited(Future.sync(onDelete)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: verified ? GColors.ink : GColors.white,
      foregroundDecoration: verified
          ? null
          : BoxDecoration(border: Border.all(color: GColors.red)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        verified ? l10n.wineVerified : l10n.wineUnverified,
        style: GText.label.copyWith(
          color: verified ? GColors.white : GColors.red,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 10),
    child: Text(text, style: GText.cardTitle),
  );
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.specs});

  final List<(String, String)> specs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value) in specs)
              Container(
                width: width,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: GColors.ink),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GText.small),
                    const SizedBox(height: 2),
                    Text(value, style: GText.cardTitle),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
