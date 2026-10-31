import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../gustaro_core.dart';
import '../flows.dart';
import '../native_bridge.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'miss_screen.dart';

/// Linear barcodes only, so a QR code on the label is not picked up first.
const _formats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.itf14,
  BarcodeFormat.codabar,
];

/// When to suggest the label instead of the barcode.
const _labelHintAfter = Duration(seconds: 6);

/// The camera screen. Finds a barcode automatically, and offers the label
/// or typing the code as fallbacks. With [captureOnly] it just returns the
/// code it read (used to fill in the Add a bottle form).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.captureOnly = false});

  final bool captureOnly;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _camera = MobileScannerController(formats: _formats);
  final _picker = ImagePicker();
  late final AppServices _services = Services.of(context);
  Timer? _hintTimer;
  var _showLabelHint = false;

  /// False while a result is on screen, so one bottle is handled once.
  var _active = true;
  String? _busyText;
  var _torch = false;

  @override
  void initState() {
    super.initState();
    _startHintTimer();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _camera.dispose();
    super.dispose();
  }

  void _startHintTimer() {
    _hintTimer?.cancel();
    _showLabelHint = false;
    _hintTimer = Timer(_labelHintAfter, () {
      if (mounted) setState(() => _showLabelHint = true);
    });
  }

  Future<void> _pause() async {
    _active = false;
    _hintTimer?.cancel();
    await _stopCamera();
  }

  Future<void> _stopCamera() async {
    try {
      await _camera.stop();
    } on MobileScannerException {
      // No camera to stop (no permission, or none on this device).
    }
  }

  Future<void> _resume() async {
    if (!mounted) return;
    setState(() {
      _busyText = null;
      _active = true;
      _torch = false;
      _startHintTimer();
    });
    try {
      await _camera.start();
    } on MobileScannerException {
      // The error is already shown by the scanner's error view.
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_active) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .nonNulls
        .where((value) => value.trim().isNotEmpty)
        .firstOrNull;
    if (code != null) unawaited(_handleCode(code));
  }

  Future<void> _handleCode(String code) async {
    await _pause();
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    if (widget.captureOnly) {
      Navigator.pop(context, code);
      return;
    }
    setState(() => _busyText = context.l10n.scanLooking);
    final outcome = await _services.scanner.resolveBarcode(code);
    await _show(outcome, barcode: code);
  }

  Future<void> _show(ScanOutcome outcome, {String? barcode}) async {
    if (!mounted) return;
    setState(() => _busyText = null);
    final action = await presentOutcome(context, outcome, barcode: barcode);
    if (action == MissAction.readLabel) {
      await _readLabel(ImageSource.camera);
    } else {
      await _resume();
    }
  }

  Future<void> _readLabel(ImageSource source) async {
    final reading = context.l10n.scanReading;
    await _pause();
    final XFile? photo;
    try {
      photo = await _picker.pickImage(source: source, maxWidth: 2400);
    } on PlatformException {
      await _resume();
      return;
    }
    if (photo == null) {
      await _resume();
      return;
    }
    if (!mounted) return;
    setState(() => _busyText = reading);
    final text = await NativeBridge.recognizeText(photo.path);
    // The photo was only needed to read the text.
    unawaited(File(photo.path).delete().catchError((_) => File(photo!.path)));
    final outcome = await _services.scanner.resolveLabel(text);
    await _show(outcome);
  }

  Future<void> _typeCode() async {
    await _pause();
    if (!mounted) return;
    final code = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const _ManualCodeSheet(),
    );
    if (code == null || code.isEmpty) {
      await _resume();
    } else if (widget.captureOnly) {
      if (mounted) Navigator.pop(context, code);
    } else {
      final outcome = await _services.scanner.resolveBarcode(code);
      await _show(outcome, barcode: code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = widget.captureOnly
        ? l10n.scanCaptureHint
        : _showLabelHint
        ? l10n.scanHintLabel
        : l10n.scanHint;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: GColors.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _camera,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _CameraError(
                error: error,
                onChoosePhoto: () => _readLabel(ImageSource.gallery),
              ),
            ),
            const IgnorePointer(child: _Viewfinder()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RoundIconButton(
                          semanticLabel: l10n.commonClose,
                          onTap: () => Navigator.pop(context),
                          child: const SvgIcon('close', size: 16),
                        ),
                        RoundIconButton(
                          semanticLabel: l10n.scanTorch,
                          onTap: () {
                            setState(() => _torch = !_torch);
                            unawaited(
                              _camera.toggleTorch().catchError((Object _) {}),
                            );
                          },
                          child: Icon(
                            _torch ? Icons.flash_on : Icons.flash_off,
                            size: 20,
                            color: GColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(GLayout.gutter),
                    child: Column(
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            hint,
                            textAlign: TextAlign.center,
                            style: GText.button.copyWith(color: GColors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (!widget.captureOnly) ...[
                              Expanded(
                                child: GButton(
                                  label: l10n.scanReadLabel,
                                  style: _showLabelHint
                                      ? GButtonStyle.primary
                                      : GButtonStyle.outline,
                                  onPressed: () =>
                                      _readLabel(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: GButton(
                                label: l10n.scanEnterCode,
                                style: GButtonStyle.outline,
                                onPressed: _typeCode,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_busyText != null)
              ColoredBox(
                color: const Color(0xCC111111),
                child: Center(
                  child: Text(
                    _busyText!,
                    style: GText.button.copyWith(color: GColors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ViewfinderPainter());
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = (size.width - 64).clamp(0.0, 340.0);
    final hole = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: width,
      height: width * 0.62,
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(hole),
      ),
      Paint()..color = const Color(0x8C000000),
    );
    const corner = 26.0;
    final paint = Paint()
      ..color = GColors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (final (x, y, dx, dy) in [
      (hole.left, hole.top, 1.0, 1.0),
      (hole.right, hole.top, -1.0, 1.0),
      (hole.left, hole.bottom, 1.0, -1.0),
      (hole.right, hole.bottom, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x + corner * dx, y)
          ..lineTo(x, y)
          ..lineTo(x, y + corner * dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onChoosePhoto});

  final MobileScannerException error;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: GColors.ink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                denied ? l10n.scanNoPermissionTitle : l10n.scanNoCameraTitle,
                textAlign: TextAlign.center,
                style: GText.title.copyWith(color: GColors.white),
              ),
              const SizedBox(height: 8),
              Text(
                denied ? l10n.scanNoPermissionBody : l10n.scanNoCameraBody,
                textAlign: TextAlign.center,
                style: GText.body.copyWith(color: GColors.white),
              ),
              const SizedBox(height: 20),
              GButton(
                label: denied ? l10n.scanOpenSettings : l10n.scanChoosePhoto,
                style: GButtonStyle.onRed,
                expand: false,
                onPressed: denied ? NativeBridge.openSettings : onChoosePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualCodeSheet extends StatefulWidget {
  const _ManualCodeSheet();

  @override
  State<_ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<_ManualCodeSheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _code.text.replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GLayout.gutter,
        4,
        GLayout.gutter,
        GLayout.gutter + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.scanManualTitle, style: GText.title),
          const SizedBox(height: 6),
          Text(l10n.scanManualBody, style: GText.bodyMuted),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(32)],
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          GButton(label: l10n.scanManualAction, onPressed: _submit),
        ],
      ),
    );
  }
}
