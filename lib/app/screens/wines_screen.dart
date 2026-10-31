import 'package:flutter/material.dart';

import '../../gustaro_core.dart';
import '../flows.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/wine_row.dart';

/// All wines, searchable and filterable by type. Used as a tab and, with
/// [standalone], as the search screen opened from Home.
class WinesScreen extends StatefulWidget {
  const WinesScreen({super.key, this.query, this.standalone = false});

  final TextEditingController? query;
  final bool standalone;

  @override
  State<WinesScreen> createState() => _WinesScreenState();
}

class _WinesScreenState extends State<WinesScreen> {
  late final _query = widget.query ?? TextEditingController();
  late final AppServices _services = Services.of(context);
  List<LabelIndexEntry>? _index;
  WineType? _type;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _services.revision.addListener(_load);
    _query.addListener(_onQuery);
    _load();
  }

  @override
  void dispose() {
    _services.revision.removeListener(_load);
    _query.removeListener(_onQuery);
    if (widget.query == null) _query.dispose();
    super.dispose();
  }

  void _onQuery() => setState(() {});

  Future<void> _load() async {
    final index = await _services.catalog.labelIndex();
    index.sort((a, b) {
      final byWinery = a.wine.wineryName.compareTo(b.wine.wineryName);
      return byWinery != 0 ? byWinery : a.wine.name.compareTo(b.wine.name);
    });
    if (mounted) setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final index = _index;
    final types = {...?index?.map((e) => e.wine.type)};
    final results = index == null
        ? const <LabelIndexEntry>[]
        : searchWines(
            index,
            _query.text,
          ).where((e) => _type == null || e.wine.type == _type).toList();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GLayout.gutter,
            GLayout.gutter,
            GLayout.gutter,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.standalone) ...[
                Text(l10n.winesTitle, style: GText.title),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _query,
                autofocus: widget.standalone,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.winesSearchHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: SvgIcon('search', size: 20),
                  ),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.commonClose,
                          icon: const SvgIcon('close', size: 16),
                          onPressed: _query.clear,
                        ),
                ),
              ),
            ],
          ),
        ),
        if (types.length > 1)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GLayout.gutter),
              children: [
                _TypeChip(
                  label: l10n.winesFilterAll,
                  selected: _type == null,
                  onTap: () => setState(() => _type = null),
                ),
                for (final type in WineType.values)
                  if (types.contains(type))
                    _TypeChip(
                      label: type.label(l10n),
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
              ],
            ),
          ),
        Expanded(
          child: index == null
              ? const SizedBox.shrink()
              : results.isEmpty
              ? _Empty(searching: index.isNotEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    GLayout.gutter,
                    8,
                    GLayout.gutter,
                    24,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => WineRow(
                    entry: results[i],
                    onTap: () => openWine(context, results[i]),
                  ),
                ),
        ),
      ],
    );

    if (widget.standalone) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.winesTitle)),
        body: SafeArea(top: false, child: ContentWidth(child: body)),
      );
    }
    return SafeArea(bottom: false, child: ContentWidth(child: body));
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottleArt(height: 110),
            const SizedBox(height: 16),
            Text(
              searching ? l10n.winesNoResults : l10n.winesEmptyTitle,
              style: GText.cardTitle,
              textAlign: TextAlign.center,
            ),
            if (!searching) ...[
              const SizedBox(height: 6),
              Text(
                l10n.winesEmptyBody,
                style: GText.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? GColors.ink : GColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: GColors.ink),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: GText.label.copyWith(
                  color: selected ? GColors.white : GColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
