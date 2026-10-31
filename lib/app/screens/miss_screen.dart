import 'package:flutter/material.dart';

import '../../gustaro_core.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_bottle_screen.dart';

enum MissAction { readLabel }

/// "Not in our catalogue yet".
class MissScreen extends StatelessWidget {
  const MissScreen({super.key, required this.outcome, this.barcode});

  final NotInCatalogue outcome;
  final String? barcode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = barcode?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(GLayout.gutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - GLayout.gutter * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const Center(child: BottleArt(height: 150)),
                      const SizedBox(height: 28),
                      Text(
                        l10n.missTitle,
                        style: GText.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        outcome.canTryLabel
                            ? l10n.missBodyBarcode
                            : l10n.missBodyLabel,
                        style: GText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                      if (code.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.missCode(code),
                          style: GText.small,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 24),
                      if (outcome.canTryLabel) ...[
                        GButton(
                          label: l10n.missTryLabel,
                          onPressed: () =>
                              Navigator.pop(context, MissAction.readLabel),
                        ),
                        const SizedBox(height: 10),
                      ],
                      GButton(
                        label: l10n.missAddBottle,
                        style: outcome.canTryLabel
                            ? GButtonStyle.outline
                            : GButtonStyle.primary,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => AddBottleScreen(
                              barcode: code.isEmpty ? null : code,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: GColors.ink,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          l10n.missScanAgain,
                          style: GText.buttonSmall.copyWith(
                            decoration: TextDecoration.underline,
                          ),
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
    );
  }
}
