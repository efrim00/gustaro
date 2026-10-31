import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services.dart';
import '../theme/app_theme.dart';

/// An icon from the design's SVG set; [color] replaces its own colours.
class SvgIcon extends StatelessWidget {
  const SvgIcon(this.name, {super.key, this.size = 22, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

enum GButtonStyle { primary, dark, outline, onRed }

/// The design's square button.
class GButton extends StatelessWidget {
  const GButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = GButtonStyle.primary,
    this.icon,
    this.height = 56,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GButtonStyle style;
  final Widget? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (style) {
      GButtonStyle.primary => (GColors.red, GColors.white),
      GButtonStyle.dark => (GColors.ink, GColors.white),
      GButtonStyle.outline => (GColors.white, GColors.ink),
      GButtonStyle.onRed => (GColors.white, GColors.ink),
    };
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: Material(
          color: enabled ? background : GColors.line,
          shape: style == GButtonStyle.outline
              ? const RoundedRectangleBorder(
                  side: BorderSide(color: GColors.ink),
                )
              : const RoundedRectangleBorder(),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 10)],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GText.button.copyWith(
                        color: enabled ? foreground : GColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's 44pt round outlined button.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.size = 44,
    this.filled = false,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    child: Material(
      color: filled ? GColors.red : GColors.white,
      shape: CircleBorder(
        side: filled ? BorderSide.none : const BorderSide(color: GColors.ink),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// The cross-stitch band under the logo.
class StitchBand extends StatelessWidget {
  const StitchBand({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 21,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: double.infinity,
          child: Transform.translate(
            offset: const Offset(-10.39, 0),
            child: SvgPicture.asset(
              'assets/icons/band.svg',
              width: 672,
              height: 21,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Centres content and caps its width on large screens.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: GLayout.maxContentWidth),
      child: child,
    ),
  );
}

/// A wine's photo, or a bottle silhouette with the Gustaro mark when it has
/// none.
class BottleArt extends StatelessWidget {
  const BottleArt({
    super.key,
    this.height = 128,
    this.glow = true,
    this.wineId,
  });

  final double height;
  final bool glow;

  /// Shows this wine's photo when it has one.
  final int? wineId;

  @override
  Widget build(BuildContext context) {
    final id = wineId;
    final photo = id == null
        ? null
        : Services.maybeOf(context)?.photos.imageFor(id);
    if (photo != null) {
      return ExcludeSemantics(
        child: SizedBox(
          width: height * 0.8,
          height: height,
          child: Image(
            image: photo,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => BottleArt(height: height, glow: glow),
          ),
        ),
      );
    }
    final width = height * 0.31;
    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: height * 0.9,
              height: height * 0.9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x40D22B3B), Color(0x00D22B3B)],
                ),
              ),
            ),
          SizedBox(
            width: width,
            height: height,
            child: CustomPaint(painter: _BottlePainter()),
          ),
          Padding(
            padding: EdgeInsets.only(top: height * 0.3),
            child: SvgIcon(
              'bottle_glyph',
              size: width * 0.5,
              color: GColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final neck = w * 0.34;
    final left = (w - neck) / 2;
    final path = Path()
      ..moveTo(left, 0)
      ..lineTo(left + neck, 0)
      ..lineTo(left + neck, h * 0.2)
      ..cubicTo(left + neck, h * 0.29, w, h * 0.28, w, h * 0.38)
      ..lineTo(w, h * 0.96)
      ..quadraticBezierTo(w, h, w - w * 0.1, h)
      ..lineTo(w * 0.1, h)
      ..quadraticBezierTo(0, h, 0, h * 0.96)
      ..lineTo(0, h * 0.38)
      ..cubicTo(0, h * 0.28, left, h * 0.29, left, h * 0.2)
      ..close();
    canvas.drawPath(path, Paint()..color = GColors.ink);
  }

  @override
  bool shouldRepaint(_BottlePainter oldDelegate) => false;
}

/// Bottom sheet with a title, text and a single dismiss button.
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
  Widget? leading,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(
        GLayout.gutter,
        4,
        GLayout.gutter,
        GLayout.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading, const SizedBox(height: 12)],
          Text(title, style: GText.title),
          const SizedBox(height: 8),
          Text(body, style: GText.bodyMuted),
          const SizedBox(height: 20),
          GButton(
            label: sheet.l10n.commonGotIt,
            style: GButtonStyle.dark,
            onPressed: () => Navigator.pop(sheet),
          ),
        ],
      ),
    ),
  );
}

/// Dropdown of the three planned languages, anchored to [anchor]'s position.
/// Only English works so far; the others explain that.
Future<void> showLanguageMenu(BuildContext anchor) async {
  final l10n = anchor.l10n;
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(anchor).context.findRenderObject()! as RenderBox;
  final bottomLeft = box.localToGlobal(
    Offset(0, box.size.height + 6),
    ancestor: overlay,
  );
  final bottomRight = box.localToGlobal(
    Offset(box.size.width, box.size.height + 6),
    ancestor: overlay,
  );
  PopupMenuItem<String> item(String value, String label, {bool on = false}) =>
      PopupMenuItem(
        value: value,
        height: 48,
        child: Row(
          children: [
            Expanded(child: Text(label, style: GText.body)),
            if (on) const Icon(Icons.check, size: 20, color: GColors.red),
          ],
        ),
      );
  final picked = await showMenu<String>(
    context: anchor,
    position: RelativeRect.fromRect(
      Rect.fromPoints(bottomLeft, bottomRight),
      Offset.zero & overlay.size,
    ),
    color: GColors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    constraints: const BoxConstraints(minWidth: 190),
    shape: const RoundedRectangleBorder(side: BorderSide(color: GColors.ink)),
    items: [
      item('en', l10n.languageEnglish, on: true),
      item(l10n.languageRomanian, l10n.languageRomanian),
      item(l10n.languageRussian, l10n.languageRussian),
    ],
  );
  if (picked == null || picked == 'en' || !anchor.mounted) return;
  await showInfoSheet(
    anchor,
    title: l10n.languageSoonTitle,
    body: l10n.languageSoonBody(picked),
  );
}
