import 'package:flutter/material.dart';

import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/wines_screen.dart';
import 'services.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

/// Lets screens inside a tab switch tabs.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goToWines, required super.child});

  /// Opens the Wines tab, optionally with a search filled in.
  final void Function([String query]) goToWines;

  static ShellScope of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellScope>()!;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

/// The four tabs plus the always-available scan button.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _index = 0;
  final _winesQuery = TextEditingController();

  @override
  void dispose() {
    _winesQuery.dispose();
    super.dispose();
  }

  void _goToWines([String query = '']) {
    _winesQuery.text = query;
    setState(() => _index = 2);
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      goToWines: _goToWines,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            const ExploreScreen(),
            WinesScreen(query: _winesQuery),
            const MoreScreen(),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      ('nav_home', l10n.navHome),
      ('nav_explore', l10n.navExplore),
      ('nav_wines', l10n.navWines),
      ('nav_more', l10n.navMore),
    ];
    return ColoredBox(
      color: GColors.ink,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
              RoundIconButton(
                semanticLabel: l10n.navScan,
                filled: true,
                size: 56,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => const ScanScreen(),
                  ),
                ),
                child: const SvgIcon('camera', size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GColors.white : GColors.navInactive;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              MediaQuery.withNoTextScaling(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: GText.label.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
