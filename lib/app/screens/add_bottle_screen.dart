import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../gustaro_core.dart';
import '../flows.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'scan_screen.dart';
import 'wine_screen.dart';

/// GTIN-8/12/13/14 check digit. Null when [code] isn't such a number.
bool? gtinCheckDigitValid(String code) {
  if (!RegExp(r'^\d+$').hasMatch(code) ||
      ![8, 12, 13, 14].contains(code.length)) {
    return null;
  }
  final digits = code.codeUnits.map((c) => c - 48).toList();
  final check = digits.removeLast();
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    sum += digits[digits.length - 1 - i] * (i.isEven ? 3 : 1);
  }
  return (10 - sum % 10) % 10 == check;
}

/// Adds a bottle to this phone. Shows every catalogue field, so it also
/// demonstrates what Gustaro records about a wine.
class AddBottleScreen extends StatefulWidget {
  const AddBottleScreen({super.key, this.barcode});

  final String? barcode;

  @override
  State<AddBottleScreen> createState() => _AddBottleScreenState();
}

class _AddBottleScreenState extends State<AddBottleScreen> {
  final _form = GlobalKey<FormState>();
  late final _barcode = TextEditingController(text: widget.barcode);
  final _size = TextEditingController(text: '750');
  final _winery = TextEditingController();
  final _wine = TextEditingController();
  final _year = TextEditingController();
  final _region = TextEditingController();
  final _grapes = TextEditingController();
  final _abv = TextEditingController();
  final _acidity = TextEditingController();
  final _tannins = TextEditingController();
  final _sugar = TextEditingController();
  final _sensory = TextEditingController();
  final _pairings = TextEditingController();
  final _description = TextEditingController();
  WineType? _type;
  var _typeMissing = false;
  var _hasErrors = false;
  var _saving = false;
  Uint8List? _photo;
  final _picker = ImagePicker();
  final _scroll = ScrollController();

  int get _maxYear => DateTime.now().year + 1;

  @override
  void dispose() {
    _scroll.dispose();
    for (final controller in [
      _barcode,
      _size,
      _winery,
      _wine,
      _year,
      _region,
      _grapes,
      _abv,
      _acidity,
      _tannins,
      _sugar,
      _sensory,
      _pairings,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static double? _decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static List<String> _list(String text) => [
    for (final item in text.split(','))
      if (item.trim().isNotEmpty) item.trim(),
  ];

  static String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? context.l10n.addRequired : null;

  String? _validateDecimal(String? value, {double max = 1000}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final number = _decimal(text);
    if (number == null) return context.l10n.addInvalidNumber;
    if (number < 0 || number > max) return context.l10n.addInvalidAbv;
    return null;
  }

  String? _validateYear(String? value) {
    final year = int.tryParse((value ?? '').trim());
    return year == null || year < 1900 || year > _maxYear
        ? context.l10n.addInvalidYear(_maxYear)
        : null;
  }

  String? _validateBarcode(String? value) {
    final code = (value ?? '').replaceAll(' ', '');
    return gtinCheckDigitValid(code) == false
        ? context.l10n.addBarcodeTypo
        : null;
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ScanScreen(captureOnly: true),
      ),
    );
    if (code != null) _barcode.text = code.trim();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 2400);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } on PlatformException {
      // Camera or photos not allowed: the bottle can still be saved.
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final services = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _typeMissing = _type == null);
    final valid = _form.currentState!.validate();
    if (!valid || _type == null) {
      setState(() => _hasErrors = true);
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() {
      _hasErrors = false;
      _saving = true;
    });
    final code = _barcode.text.replaceAll(' ', '');
    final bottle = NewBottle(
      wineryName: _winery.text.trim(),
      wineName: _wine.text.trim(),
      type: _type!,
      year: int.parse(_year.text.trim()),
      barcode: code.isEmpty ? null : code,
      bottleSizeMl: int.tryParse(_size.text.trim()),
      region: _optional(_region),
      grapeVarieties: _list(_grapes.text),
      abv: _decimal(_abv.text),
      acidityGL: _decimal(_acidity.text),
      tanninsGL: _decimal(_tannins.text),
      residualSugarGL: _decimal(_sugar.text),
      sensoryNotes: _optional(_sensory),
      foodPairings: _list(_pairings.text),
      description: _optional(_description),
    );
    try {
      final id = await services.myBottles.add(bottle);
      final photo = _photo;
      if (photo != null) {
        try {
          final saved = await services.catalog.vintageDetails(id);
          if (saved != null) await services.photos.save(saved.wine.id, photo);
        } on Object {
          // The bottle is saved; only its picture could not be.
        }
      }
      services.changed(wines: true);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.addSaved)));
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => WineScreen(vintageId: id)),
      );
    } on BottleAlreadyAdded catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.addDuplicate),
          action: SnackBarAction(
            label: l10n.addDuplicateOpen,
            textColor: GColors.white,
            onPressed: () => openVintage(context, e.vintageId),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTitle)),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _form,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    GLayout.gutter,
                    4,
                    GLayout.gutter,
                    24,
                  ),
                  child: ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: GColors.surface,
                          child: Text(
                            l10n.addIntro,
                            style: GText.small.copyWith(
                              color: GColors.textSoft,
                            ),
                          ),
                        ),
                        _Section(l10n.addSectionPhoto),
                        _PhotoPicker(
                          bytes: _photo,
                          onPick: _pickPhoto,
                          onRemove: () => setState(() => _photo = null),
                        ),
                        _Section(l10n.addSectionBarcode),
                        _Field(
                          label: l10n.addBarcode,
                          help: l10n.addBarcodeHelp,
                          optional: true,
                          controller: _barcode,
                          keyboard: TextInputType.number,
                          validator: _validateBarcode,
                          formatters: [LengthLimitingTextInputFormatter(32)],
                          suffix: IconButton(
                            tooltip: l10n.addBarcodeScan,
                            onPressed: _scanBarcode,
                            icon: const SvgIcon('camera_small', size: 22),
                          ),
                        ),
                        _Field(
                          label: l10n.addBottleSize,
                          optional: true,
                          controller: _size,
                          keyboard: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                        _Section(l10n.addSectionWine),
                        _Field(
                          label: l10n.addWinery,
                          controller: _winery,
                          validator: _required,
                          capitalize: TextCapitalization.words,
                        ),
                        _Field(
                          label: l10n.addWineName,
                          controller: _wine,
                          validator: _required,
                          capitalize: TextCapitalization.words,
                        ),
                        Text('${l10n.addType} *', style: GText.label),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final type in WineType.values)
                              _Choice(
                                label: type.label(l10n),
                                selected: _type == type,
                                onTap: () => setState(() {
                                  _type = type;
                                  _typeMissing = false;
                                }),
                              ),
                          ],
                        ),
                        if (_typeMissing)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              l10n.addTypeRequired,
                              style: GText.small.copyWith(color: GColors.red),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _Field(
                          label: l10n.addYear,
                          controller: _year,
                          keyboard: TextInputType.number,
                          validator: _validateYear,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                        _Field(
                          label: l10n.addRegion,
                          hint: l10n.addRegionHint,
                          optional: true,
                          controller: _region,
                          capitalize: TextCapitalization.words,
                        ),
                        _Field(
                          label: l10n.addGrapes,
                          hint: l10n.addGrapesHint,
                          optional: true,
                          controller: _grapes,
                          capitalize: TextCapitalization.words,
                        ),
                        _Section(l10n.addSectionSpecs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                label: l10n.addAbv,
                                optional: true,
                                controller: _abv,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) => _validateDecimal(v, max: 100),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Field(
                                label: l10n.addAcidity,
                                optional: true,
                                controller: _acidity,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: _validateDecimal,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                label: l10n.addSugar,
                                optional: true,
                                controller: _sugar,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: _validateDecimal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Field(
                                label: l10n.addTannins,
                                optional: true,
                                controller: _tannins,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: _validateDecimal,
                              ),
                            ),
                          ],
                        ),
                        _Section(l10n.addSectionTasting),
                        _Field(
                          label: l10n.addSensory,
                          hint: l10n.addSensoryHint,
                          optional: true,
                          controller: _sensory,
                          lines: 3,
                        ),
                        _Field(
                          label: l10n.addPairings,
                          hint: l10n.addPairingsHint,
                          optional: true,
                          controller: _pairings,
                        ),
                        _Field(
                          label: l10n.addDescription,
                          optional: true,
                          controller: _description,
                          lines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: GColors.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GLayout.gutter,
                      10,
                      GLayout.gutter,
                      10,
                    ),
                    child: ContentWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasErrors)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l10n.addFixErrors,
                                style: GText.label.copyWith(color: GColors.red),
                              ),
                            ),
                          GButton(
                            label: l10n.addSave,
                            onPressed: _saving ? null : _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.bytes,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photo = bytes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addPhotoHelp,
            style: GText.small.copyWith(color: GColors.textSoft),
          ),
          const SizedBox(height: 10),
          if (photo != null) ...[
            Center(
              child: Image.memory(
                photo,
                height: 160,
                fit: BoxFit.contain,
                cacheHeight: 480,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: GButton(
                  label: l10n.addPhotoTake,
                  style: GButtonStyle.outline,
                  height: 48,
                  onPressed: () => onPick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GButton(
                  label: l10n.addPhotoChoose,
                  style: GButtonStyle.outline,
                  height: 48,
                  onPressed: () => onPick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (photo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRemove,
                child: Text(l10n.addPhotoRemove, style: GText.buttonSmall),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Text(title, style: GText.cardTitle),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.optional = false,
    this.help,
    this.hint,
    this.keyboard,
    this.validator,
    this.suffix,
    this.lines = 1,
    this.formatters,
    this.capitalize = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final bool optional;
  final String? help;
  final String? hint;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;
  final int lines;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization capitalize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: optional ? label : '$label *',
            ),
            style: GText.label,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
            textCapitalization: capitalize,
            minLines: lines,
            maxLines: lines == 1 ? 1 : lines + 3,
            validator: validator,
            inputFormatters: formatters,
            textInputAction: lines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              helperText: help,
              helperMaxLines: 2,
              helperStyle: GText.small,
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? GColors.ink : GColors.white,
      shape: const RoundedRectangleBorder(side: BorderSide(color: GColors.ink)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GText.buttonSmall.copyWith(
                  color: selected ? GColors.white : GColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
