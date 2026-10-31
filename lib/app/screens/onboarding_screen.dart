import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

/// First launch: what Gustaro is, then the age check and consent. The app
/// cannot be entered without both.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  var _page = 0;

  static const _intro = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
  );

  Future<void> _finish() async {
    await Services.of(context).settings
        .write(AppServices.legalKey, AppServices.legalVersion);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      (l10n.onb1Title, l10n.onb1Body),
      (l10n.onb2Title, l10n.onb2Body),
      (l10n.onb3Title, l10n.onb3Body),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: GColors.red,
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              bottom: 0,
              right: 16,
              width: 28,
              child: _SideStitch(),
            ),
            SafeArea(
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GLayout.gutter,
                        16,
                        64,
                        0,
                      ),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/brand/logo_white.svg',
                              height: 40,
                            ),
                            const Spacer(),
                            if (_page < _intro)
                              TextButton(
                                onPressed: () => _pages.animateToPage(
                                  _intro,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOut,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: GColors.white,
                                  minimumSize: const Size(44, 44),
                                ),
                                child: Text(
                                  l10n.onbSkip,
                                  style: GText.buttonSmall.copyWith(
                                    color: GColors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: [
                          for (final (i, (title, body)) in slides.indexed)
                            _Slide(title: title, body: body, showNoroc: i == 0),
                          _LegalPage(onStart: _finish),
                        ],
                      ),
                    ),
                    if (_page < _intro)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          GLayout.gutter,
                          GLayout.gutter,
                          64,
                          GLayout.gutter,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i <= _intro; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  width: i == _page ? 28 : 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: i == _page ? GColors.white : null,
                                    border: Border.all(color: GColors.white),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            SizedBox(
                              width: 120,
                              child: GButton(
                                label: l10n.onbNext,
                                style: GButtonStyle.onRed,
                                onPressed: _next,
                              ),
                            ),
                          ],
                        ),
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

class _SideStitch extends StatelessWidget {
  const _SideStitch();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
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
  );
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.title,
    required this.body,
    required this.showNoroc,
  });

  final String title;
  final String body;
  final bool showNoroc;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.only(left: GLayout.gutter, right: 64),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showNoroc) ...[
              Transform.rotate(
                angle: -0.14,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Noroc!',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: 'Caveat',
                    fontWeight: FontWeight.w700,
                    fontSize: 56,
                    color: GColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              style: GText.title.copyWith(
                color: GColors.white,
                fontSize: 36,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: GText.body.copyWith(color: GColors.white, fontSize: 17),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

class _LegalPage extends StatefulWidget {
  const _LegalPage({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<_LegalPage> {
  var _adult = false;
  var _agreed = false;
  final _terms = TapGestureRecognizer();
  final _privacy = TapGestureRecognizer();

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  void _open(String title, String asset) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LegalScreen(title: title, asset: asset),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _terms.onTap = () => _open(l10n.onbTerms, LegalScreen.terms);
    _privacy.onTap = () => _open(l10n.onbPrivacy, LegalScreen.privacy);
    const white = TextStyle(color: GColors.white);
    const link = TextStyle(
      color: GColors.white,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: GColors.white,
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          GLayout.gutter,
          GLayout.gutter,
          64,
          GLayout.gutter,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - GLayout.gutter * 2,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  l10n.onbLegalTitle,
                  style: GText.title.copyWith(
                    color: GColors.white,
                    fontSize: 36,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.onbLegalBody,
                  style: GText.body.copyWith(
                    color: GColors.white,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 28),
                _Check(
                  value: _adult,
                  onChanged: (v) => setState(() => _adult = v),
                  child: Text(l10n.onbAge, style: GText.body.merge(white)),
                ),
                const SizedBox(height: 14),
                _Check(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v),
                  child: Text.rich(
                    TextSpan(
                      style: GText.body.merge(white),
                      children: [
                        TextSpan(text: l10n.onbTermsPrefix),
                        TextSpan(
                          text: l10n.onbTerms,
                          style: link,
                          recognizer: _terms,
                        ),
                        TextSpan(text: l10n.onbTermsAnd),
                        TextSpan(
                          text: l10n.onbPrivacy,
                          style: link,
                          recognizer: _privacy,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                GButton(
                  label: l10n.onbStart,
                  style: GButtonStyle.onRed,
                  onPressed: _adult && _agreed ? widget.onStart : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.value,
    required this.onChanged,
    required this.child,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 44,
        height: 44,
        child: Transform.translate(
          offset: const Offset(-10, -10),
          child: Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: GColors.white, width: 1.5),
                checkColor: WidgetStateProperty.all(GColors.red),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? GColors.white
                      : Colors.transparent,
                ),
              ),
            ),
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => onChanged(!value),
          child: child,
        ),
      ),
    ],
  );
}
