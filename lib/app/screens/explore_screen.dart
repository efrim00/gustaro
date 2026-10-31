import 'package:flutter/material.dart';

import '../services.dart';
import '../shell.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GLayout.gutter),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.exploreTitle, style: GText.title),
              const SizedBox(height: 14),
              const StitchBand(),
              const SizedBox(height: 56),
              Center(child: BottleArt(height: 170)),
              const SizedBox(height: 32),
              Container(
                color: GColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  l10n.exploreSoonTag,
                  style: GText.label.copyWith(color: GColors.white),
                ),
              ),
              const SizedBox(height: 14),
              Text(l10n.exploreSoonTitle, style: GText.title),
              const SizedBox(height: 8),
              Text(l10n.exploreSoonBody, style: GText.bodyMuted),
              const SizedBox(height: 24),
              GButton(
                label: l10n.exploreSoonAction,
                style: GButtonStyle.outline,
                onPressed: () => ShellScope.of(context).goToWines(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
