import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Keep in step with `version` in pubspec.yaml (a test checks this).
const appVersion = '1.0.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreAbout)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GLayout.gutter),
        child: SafeArea(
          top: false,
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                SvgPicture.asset('assets/brand/logo_dark.svg', height: 56),
                const SizedBox(height: 8),
                Text(l10n.moreVersion(appVersion), style: GText.small),
                const SizedBox(height: 20),
                const StitchBand(),
                const SizedBox(height: 20),
                Text(l10n.aboutBody, style: GText.body),
                const SizedBox(height: 24),
                GButton(
                  label: l10n.aboutLicenses,
                  style: GButtonStyle.outline,
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                    applicationVersion: appVersion,
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
