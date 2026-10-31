import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_databases.dart';
import 'app/screens/onboarding_screen.dart';
import 'app/services.dart';
import 'app/shell.dart';
import 'app/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Onest', 'Domine', 'Caveat'], text);
  });
  runApp(const GustaroApp());
}

class GustaroApp extends StatefulWidget {
  const GustaroApp({super.key});

  @override
  State<GustaroApp> createState() => _GustaroAppState();
}

class _GustaroAppState extends State<GustaroApp> {
  AppServices? _services;
  var _accepted = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final services = AppServices(await AppDatabases.open());
      final accepted = await services.settings.read(AppServices.legalKey);
      setState(() {
        _services = services;
        _accepted = accepted == AppServices.legalVersion;
      });
      unawaited(services.syncCatalog());
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return GustaroMaterialApp(
      services: services,
      home: _failed
          ? const _StartupError()
          : services == null
          ? const _Splash()
          : _accepted
          ? const Shell()
          : OnboardingScreen(onDone: () => setState(() => _accepted = true)),
    );
  }
}

/// The app's MaterialApp. [services] are provided above the Navigator, so
/// every route can reach them. Tests use this too, to run the same tree.
class GustaroMaterialApp extends StatelessWidget {
  const GustaroMaterialApp({
    super.key,
    required this.services,
    required this.home,
  });

  final AppServices? services;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gustaro',
      debugShowCheckedModeBanner: false,
      theme: buildGustaroTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Respect larger text settings up to what the layouts are built for.
        final scaled = MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: child!,
        );
        final current = services;
        return current == null
            ? scaled
            : Services(services: current, child: scaled);
      },
      home: home,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: GColors.red);
}

class _StartupError extends StatelessWidget {
  const _StartupError();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.errorTitle,
              style: GText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.errorBody,
              style: GText.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
