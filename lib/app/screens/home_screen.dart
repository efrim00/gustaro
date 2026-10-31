import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../gustaro_core.dart';
import '../flows.dart';
import '../services.dart';
import '../shell.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/recent_card.dart';
import 'scan_screen.dart';
import 'tasting_screen.dart';
import 'wines_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _RecentItem {
  const _RecentItem(this.scan, this.summary);

  final RecentScan scan;
  final VintageSummary summary;
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppServices _services = Services.of(context);
  var _started = false;
  var _heroHidden = false;
  List<_RecentItem> _recent = const [];
  List<LabelIndexEntry> _wines = const [];

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
    final scans = await _services.recent.list();
    final summaries = await _services.catalog.vintageSummaries({
      for (final scan in scans) scan.vintageId,
    });
    final wines = await _services.catalog.labelIndex();
    final hidden = await _services.settings.read(AppServices.heroHiddenKey);
    if (!mounted) return;
    setState(() {
      _recent = [
        for (final scan in scans)
          if (summaries[scan.vintageId] case final summary?)
            _RecentItem(scan, summary),
      ];
      _wines = wines;
      _heroHidden = hidden == 'true';
    });
  }

  Future<void> _hideHero() async {
    setState(() => _heroHidden = true);
    await _services.settings.write(AppServices.heroHiddenKey, 'true');
  }

  void _openScanner() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const ScanScreen(),
    ),
  );

  void _openSearch() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const WinesScreen(standalone: true),
    ),
  );

  void _openSommelier() => showInfoSheet(
    context,
    title: context.l10n.sommelierSoonTitle,
    body: context.l10n.sommelierSoonBody,
    leading: const SvgIcon('sparkle_title', size: 26, color: GColors.red),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seen = {for (final item in _recent) item.summary.wine.id};
    final discover = _wines
        .where((e) => e.wine.isVerified && !seen.contains(e.wine.id))
        .take(8)
        .toList();
    final wineries = {
      for (final e in _wines)
        if (e.wine.isVerified) e.wine.wineryName,
    }.toList()..sort();
    const gutter = EdgeInsets.symmetric(horizontal: GLayout.gutter);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GLayout.gutter,
                  10,
                  GLayout.gutter,
                  0,
                ),
                child: _Header(
                  onNotifications: () => showInfoSheet(
                    context,
                    title: l10n.notificationsTitle,
                    body: l10n.notificationsBody,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(padding: gutter, child: StitchBand()),
              const SizedBox(height: 18),
              Padding(
                padding: gutter,
                child: _SearchRow(
                  onSearch: _openSearch,
                  onSommelier: _openSommelier,
                ),
              ),
              const SizedBox(height: 38),
              if (!_heroHidden) ...[
                _Hero(onHide: _hideHero),
                const SizedBox(height: 34),
              ],
              Padding(
                padding: gutter,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.recentOverline, style: GText.small),
                          const SizedBox(height: 2),
                          Text(l10n.recentTitle, style: GText.title),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_recent.isEmpty)
                Padding(
                  padding: gutter,
                  child: _RecentEmpty(onScan: _openScanner),
                )
              else
                _RecentPager(items: _recent),
              const SizedBox(height: 34),
              Padding(
                padding: gutter,
                child: Row(
                  children: [
                    const SvgIcon(
                      'sparkle_title',
                      size: 22,
                      color: GColors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.sommelierTitle, style: GText.title),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: gutter,
                child: Column(
                  children: [
                    for (final (i, prompt) in [
                      l10n.sommelierPrompt1,
                      l10n.sommelierPrompt2,
                      l10n.sommelierPrompt3,
                    ].indexed)
                      _PromptRow(
                        number: i + 1,
                        label: prompt,
                        onTap: _openSommelier,
                      ),
                    const SizedBox(height: 12),
                    _AskField(onTap: _openSommelier),
                  ],
                ),
              ),
              if (discover.isNotEmpty) ...[
                const SizedBox(height: 34),
                Padding(
                  padding: gutter,
                  child: _SectionTitle(
                    title: l10n.moreWinesTitle,
                    body: l10n.moreWinesBody,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 214,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: gutter,
                    itemCount: discover.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _WineTile(
                      entry: discover[i],
                      onTap: () => openWine(context, discover[i]),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: TextButton(
                      onPressed: () => ShellScope.of(context).goToWines(),
                      style: TextButton.styleFrom(
                        foregroundColor: GColors.red,
                        minimumSize: const Size(44, 44),
                      ),
                      child: Text(
                        l10n.commonSeeAll,
                        style: GText.buttonSmall.copyWith(color: GColors.red),
                      ),
                    ),
                  ),
                ),
              ],
              if (wineries.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: gutter,
                  child: _SectionTitle(
                    title: l10n.wineriesTitle,
                    body: l10n.wineriesBody,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: gutter,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final winery in wineries)
                        _WineryChip(
                          name: winery,
                          onTap: () => ShellScope.of(context).goToWines(winery),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 44),
              const Center(child: SvgIcon('footer_mark', size: 28)),
              const SizedBox(height: 10),
              Text(
                l10n.footerMade,
                style: GText.small,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Semantics(
          label: l10n.appName,
          image: true,
          child: SvgPicture.asset('assets/brand/logo_dark.svg', height: 38),
        ),
        const Spacer(),
        Builder(
          builder: (anchor) => RoundIconButton(
            semanticLabel: l10n.homeLanguage,
            onTap: () => showLanguageMenu(anchor),
            child: const Icon(Icons.language, size: 22, color: GColors.ink),
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          semanticLabel: l10n.homeNotifications,
          onTap: onNotifications,
          child: const SvgIcon('bell', size: 20),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onSearch, required this.onSommelier});

  final VoidCallback onSearch;
  final VoidCallback onSommelier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: l10n.homeSearchHint,
            excludeSemantics: true,
            child: Material(
              color: GColors.white,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: GColors.ink),
              ),
              child: InkWell(
                onTap: onSearch,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const SvgIcon('search', size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.homeSearchHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GText.bodyMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          semanticLabel: l10n.homeSommelier,
          filled: true,
          size: 56,
          onTap: onSommelier,
          child: const SvgIcon('sparkle', size: 22),
        ),
      ],
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.onHide});

  final VoidCallback onHide;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      (l10n.hero1Tag, l10n.hero1Title, l10n.hero1Body, TastingKind.basics),
      (l10n.hero2Tag, l10n.hero2Title, l10n.hero2Body, TastingKind.red),
      (l10n.hero3Tag, l10n.hero3Title, l10n.hero3Body, TastingKind.sparkling),
    ];
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return ColoredBox(
      color: GColors.red,
      child: SizedBox(
        height: 322 * scale,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 16,
              width: 28,
              child: ExcludeSemantics(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: SvgPicture.asset(
                        'assets/icons/hero_side.svg',
                        width: 1200,
                        height: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final (tag, title, body, kind) = slides[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 64, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: GColors.white, width: 2),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GText.label.copyWith(color: GColors.white),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GText.display.copyWith(color: GColors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GText.body.copyWith(color: GColors.white),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          GButton(
                            label: l10n.heroStart,
                            style: GButtonStyle.onRed,
                            height: 44,
                            expand: false,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TastingScreen(kind: kind),
                              ),
                            ),
                          ),
                          const SizedBox(width: 22),
                          SizedBox(
                            height: 44,
                            child: TextButton(
                              onPressed: widget.onHide,
                              style: TextButton.styleFrom(
                                foregroundColor: GColors.white,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                l10n.heroHide,
                                style: GText.button.copyWith(
                                  color: GColors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: GColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 46),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              right: 70,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.14,
                  child: Text(
                    'Noroc!',
                    style: GText.script,
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Row(
                children: [
                  for (var i = 0; i < slides.length; i++)
                    Semantics(
                      button: true,
                      label: l10n.heroSlide(i + 1),
                      selected: i == _page,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _pages.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == _page ? 28 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: i == _page ? GColors.white : null,
                              border: Border.all(color: GColors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPager extends StatefulWidget {
  const _RecentPager({required this.items});

  final List<_RecentItem> items;

  @override
  State<_RecentPager> createState() => _RecentPagerState();
}

class _RecentPagerState extends State<_RecentPager> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final items = widget.items.take(10).toList();
    final current = _page.clamp(0, items.length - 1);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 356 * scale,
          child: PageView.builder(
            controller: _pages,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: GLayout.gutter),
                child: RecentCard(
                  summary: item.summary,
                  scan: item.scan,
                  onOpen: () => openVintage(context, item.scan.vintageId),
                  onRemove: () async {
                    await services.recent.remove(item.scan.vintageId);
                    services.changed();
                  },
                  onLiked: (liked) async {
                    await services.recent.setLiked(item.scan.vintageId, liked);
                    services.changed();
                  },
                  onTaste: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TastingScreen(
                        kind: TastingKindFor.wine(item.summary.wine.type),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10, right: GLayout.gutter),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                color: GColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  context.l10n.recentCount(current + 1, items.length),
                  style: GText.label.copyWith(color: GColors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: GColors.ink)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 104,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: GColors.ink)),
              ),
              alignment: Alignment.center,
              child: const BottleArt(height: 112),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.recentEmptyTitle, style: GText.cardTitle),
                    const SizedBox(height: 4),
                    Text(l10n.recentEmptyBody, style: GText.small),
                    const SizedBox(height: 12),
                    GButton(
                      label: l10n.recentEmptyAction,
                      height: 44,
                      onPressed: onScan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.number,
    required this.label,
    required this.onTap,
  });

  final int number;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(number.toString().padLeft(2, '0'), style: GText.label),
          ),
          Expanded(
            child: Text(
              label,
              style: GText.button.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SvgIcon('chevron', size: 20),
        ],
      ),
    ),
  );
}

class _AskField extends StatelessWidget {
  const _AskField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.sommelierInput,
      excludeSemantics: true,
      child: Material(
        color: GColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: GColors.ink),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                const SizedBox(width: 18),
                const SvgIcon('sparkle_small', size: 18, color: GColors.red),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.sommelierInput,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GText.bodyMuted,
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: GColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const SvgIcon('send', size: 18),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GText.title),
      const SizedBox(height: 4),
      Text(body, style: GText.bodyMuted),
    ],
  );
}

class _WineTile extends StatelessWidget {
  const _WineTile({required this.entry, required this.onTap});

  final LabelIndexEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wine = entry.wine;
    return SizedBox(
      width: 158,
      child: Material(
        color: GColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: GColors.ink),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: BottleArt(height: 96, wineId: wine.id)),
                const Spacer(),
                Text(
                  wine.wineryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GText.small,
                ),
                const SizedBox(height: 2),
                Text(
                  wine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GText.cardTitle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WineryChip extends StatelessWidget {
  const _WineryChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GColors.white,
    shape: const RoundedRectangleBorder(side: BorderSide(color: GColors.ink)),
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Flexible(child: Text(name, style: GText.buttonSmall))],
        ),
      ),
    ),
  );
}
