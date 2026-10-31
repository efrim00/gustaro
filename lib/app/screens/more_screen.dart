import 'package:flutter/material.dart';

import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'add_bottle_screen.dart';
import 'legal_screen.dart';
import 'my_bottles_screen.dart';
import 'tasting_screen.dart';

/// The account panel. There are no logins yet, so it holds what belongs to
/// this phone, plus adding a bottle.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _clearData(BuildContext context) async {
    final l10n = context.l10n;
    final services = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.moreClearTitle, style: GText.cardTitle),
        content: Text(l10n.moreClearBody, style: GText.body),
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
    await services.deleteAllData();
    messenger.showSnackBar(SnackBar(content: Text(l10n.moreClearDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GLayout.gutter),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.moreTitle, style: GText.title),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: GColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: GColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.moreGuest, style: GText.cardTitle),
                        const SizedBox(height: 2),
                        Text(l10n.moreGuestBody, style: GText.small),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _AddBottleCard(
                onTap: () => _push(context, const AddBottleScreen()),
              ),
              const SizedBox(height: 12),
              _Row(
                icon: Icons.wine_bar_outlined,
                label: l10n.moreMyBottles,
                onTap: () => _push(context, const MyBottlesScreen()),
              ),
              _Row(
                icon: Icons.local_bar_outlined,
                label: l10n.moreTastingGuide,
                onTap: () => _push(context, const TastingScreen()),
              ),
              Builder(
                builder: (anchor) => _Row(
                  icon: Icons.language,
                  label: l10n.moreLanguage,
                  value: l10n.languageEnglish,
                  onTap: () => showLanguageMenu(anchor),
                ),
              ),
              _Row(
                icon: Icons.description_outlined,
                label: l10n.moreTerms,
                onTap: () => _push(
                  context,
                  LegalScreen(title: l10n.moreTerms, asset: LegalScreen.terms),
                ),
              ),
              _Row(
                icon: Icons.privacy_tip_outlined,
                label: l10n.morePrivacy,
                onTap: () => _push(
                  context,
                  LegalScreen(
                    title: l10n.morePrivacy,
                    asset: LegalScreen.privacy,
                  ),
                ),
              ),
              _Row(
                icon: Icons.info_outline,
                label: l10n.moreAbout,
                onTap: () => _push(context, const AboutScreen()),
              ),
              _Row(
                icon: Icons.delete_outline,
                label: l10n.moreClearData,
                destructive: true,
                onTap: () => _clearData(context),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.moreResponsible,
                style: GText.small,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBottleCard extends StatelessWidget {
  const _AddBottleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: GColors.red,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                color: GColors.white,
                child: const Icon(Icons.add, color: GColors.ink, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.moreAddBottle,
                      style: GText.button.copyWith(color: GColors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.moreAddBottleBody,
                      style: GText.small.copyWith(color: GColors.white),
                    ),
                  ],
                ),
              ),
              const SvgIcon('chevron', size: 20, color: GColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? GColors.red : GColors.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: GColors.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GText.buttonSmall.copyWith(color: color),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: GText.bodyMuted),
              const SizedBox(width: 6),
            ],
            if (!destructive) const SvgIcon('chevron', size: 20),
          ],
        ),
      ),
    );
  }
}
