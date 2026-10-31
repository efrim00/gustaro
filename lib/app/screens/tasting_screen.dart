import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../gustaro_core.dart';
import '../../l10n/app_localizations.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum TastingKind { basics, red, sparkling }

extension TastingKindFor on TastingKind {
  static TastingKind wine(WineType type) => switch (type) {
    WineType.red => TastingKind.red,
    WineType.sparkling => TastingKind.sparkling,
    _ => TastingKind.basics,
  };
}

/// A short five-step tasting guide.
class TastingScreen extends StatefulWidget {
  const TastingScreen({super.key, this.kind = TastingKind.basics});

  final TastingKind kind;

  @override
  State<TastingScreen> createState() => _TastingScreenState();
}

class _TastingScreenState extends State<TastingScreen> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<(String, String)> _steps(AppLocalizations l10n) {
    final bodies = switch (widget.kind) {
      TastingKind.basics => [
        l10n.tasting1Look,
        l10n.tasting1Swirl,
        l10n.tasting1Smell,
        l10n.tasting1Sip,
        l10n.tasting1Finish,
      ],
      TastingKind.red => [
        l10n.tasting2Look,
        l10n.tasting2Swirl,
        l10n.tasting2Smell,
        l10n.tasting2Sip,
        l10n.tasting2Finish,
      ],
      TastingKind.sparkling => [
        l10n.tasting3Look,
        l10n.tasting3Swirl,
        l10n.tasting3Smell,
        l10n.tasting3Sip,
        l10n.tasting3Finish,
      ],
    };
    final titles = [
      l10n.tastingLook,
      l10n.tastingSwirl,
      l10n.tastingSmell,
      l10n.tastingSip,
      l10n.tastingFinish,
    ];
    return [for (var i = 0; i < 5; i++) (titles[i], bodies[i])];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _steps(l10n);
    final last = _page == steps.length - 1;
    return Scaffold(
      backgroundColor: GColors.red,
      appBar: AppBar(
        backgroundColor: GColors.red,
        foregroundColor: GColors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          l10n.tastingTitle,
          style: const TextStyle(color: GColors.white),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(GLayout.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: i == steps.length - 1 ? 0 : 6,
                          ),
                          color: i <= _page
                              ? GColors.white
                              : const Color(0x55FFFFFF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.tastingStep(_page + 1, steps.length),
                  style: GText.label.copyWith(color: GColors.white),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: steps.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 56),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].$1,
                              style: GText.script.copyWith(fontSize: 56),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              steps[i].$2,
                              style: GText.display.copyWith(
                                color: GColors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  l10n.tastingResponsible,
                  style: GText.small.copyWith(color: GColors.white),
                ),
                const SizedBox(height: 12),
                GButton(
                  label: last ? l10n.tastingDone : l10n.tastingNext,
                  style: GButtonStyle.onRed,
                  onPressed: () {
                    if (last) {
                      Navigator.pop(context);
                    } else {
                      _pages.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
