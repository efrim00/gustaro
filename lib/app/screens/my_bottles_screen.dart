import 'package:flutter/material.dart';

import '../../gustaro_core.dart';
import '../flows.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/wine_row.dart';
import 'add_bottle_screen.dart';

class MyBottlesScreen extends StatefulWidget {
  const MyBottlesScreen({super.key});

  @override
  State<MyBottlesScreen> createState() => _MyBottlesScreenState();
}

class _MyBottlesScreenState extends State<MyBottlesScreen> {
  late final AppServices _services = Services.of(context);
  List<LabelIndexEntry>? _bottles;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _services.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _services.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final index = await _services.catalog.labelIndex();
    if (!mounted) return;
    setState(() => _bottles = index.where((e) => !e.wine.isVerified).toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottles = _bottles;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myBottlesTitle)),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(GLayout.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: bottles == null
                      ? const SizedBox.shrink()
                      : bottles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const BottleArt(height: 110),
                              const SizedBox(height: 16),
                              Text(
                                l10n.myBottlesEmptyTitle,
                                style: GText.cardTitle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.myBottlesEmptyBody,
                                style: GText.bodyMuted,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: bottles.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) => WineRow(
                            entry: bottles[i],
                            onTap: () => openWine(context, bottles[i]),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                GButton(
                  label: l10n.moreAddBottle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddBottleScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
