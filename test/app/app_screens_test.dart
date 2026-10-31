import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/app/app_databases.dart';
import 'package:gustaro/app/screens/about_screen.dart';
import 'package:gustaro/app/screens/add_bottle_screen.dart';
import 'package:gustaro/app/screens/legal_screen.dart';
import 'package:gustaro/app/screens/miss_screen.dart';
import 'package:gustaro/app/screens/my_bottles_screen.dart';
import 'package:gustaro/app/screens/onboarding_screen.dart';
import 'package:gustaro/app/screens/tasting_screen.dart';
import 'package:gustaro/app/screens/wine_screen.dart';
import 'package:gustaro/app/services.dart';
import 'package:gustaro/app/shell.dart';
import 'package:gustaro/gustaro_core.dart';
import 'package:gustaro/main.dart';

import '../support/fixture_catalog.dart';

/// Every iPhone width class the app has to work on, smallest first.
const screens = {
  'iPhone SE 1st gen': Size(320, 568),
  'iPhone SE 3rd gen': Size(375, 667),
  'iPhone 13 mini': Size(375, 812),
  'iPhone 17': Size(402, 874),
  'iPhone 17 Pro Max': Size(440, 956),
};

Future<void> loadFonts() async {
  for (final (family, files) in [
    ('Onest', ['Regular', 'Medium', 'SemiBold', 'Bold']),
    ('Domine', ['SemiBold', 'Bold']),
    ('Caveat', ['Bold']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$family-$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

Future<AppServices> makeServices() async {
  final services = AppServices(
    AppDatabases.forTesting(
      await openFixtureCatalog(),
      CatalogDatabase(NativeDatabase.memory()),
      UserDatabase(NativeDatabase.memory()),
    ),
  );
  return services;
}

/// The real app tree, so screens reach services the same way as in the app.
Widget app(AppServices services, Widget home, {double textScale = 1}) =>
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: GustaroMaterialApp(services: services, home: home),
    );

/// Drift's timers and sqlite run outside the fake clock, so async work needs
/// real time; this also settles animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> sized(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadFonts);

  final pages = <String, Widget Function()>{
    'shell (home)': () => const Shell(),
    'onboarding': () => OnboardingScreen(onDone: () {}),
    'wine page': () => const WineScreen(vintageId: 102),
    'add bottle': () => const AddBottleScreen(barcode: '4841000000999'),
    'miss, barcode': () => const MissScreen(
      outcome: NotInCatalogue(ScanSource.barcode),
      barcode: '4849999999999',
    ),
    'miss, label': () =>
        const MissScreen(outcome: NotInCatalogue(ScanSource.label)),
    'tasting': () => const TastingScreen(),
    'my bottles': () => const MyBottlesScreen(),
    'about': () => const AboutScreen(),
    'terms': () => const LegalScreen(title: 'T', asset: LegalScreen.terms),
    'privacy': () => const LegalScreen(title: 'P', asset: LegalScreen.privacy),
  };

  for (final MapEntry(key: screen, value: size) in screens.entries) {
    for (final textScale in [1.0, 1.3]) {
      for (final MapEntry(key: page, value: build) in pages.entries) {
        testWidgets('$page fits on $screen at text x$textScale', (
          tester,
        ) async {
          await sized(tester, size);
          final services = await tester.runAsync(makeServices);
          await tester.pumpWidget(
            app(services!, build(), textScale: textScale),
          );
          await settle(tester);
          // A layout overflow fails the test through FlutterError.
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  group('flows', () {
    testWidgets('every tab opens and fits, with recent scans', (tester) async {
      for (final size in [
        screens['iPhone SE 1st gen']!,
        screens['iPhone 17 Pro Max']!,
      ]) {
        await sized(tester, size);
        final services = await tester.runAsync(() async {
          final s = await makeServices();
          await s.recent.record(102);
          await s.recent.record(201);
          return s;
        });
        await tester.pumpWidget(app(services!, const Shell()));
        await settle(tester);
        expect(find.text('Your recent scans'), findsOneWidget);
        for (final tab in ['Explore', 'Wines', 'More', 'Home']) {
          await tester.tap(find.text(tab).last);
          await settle(tester);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a pushed screen reaches the services', (tester) async {
      await sized(tester, screens['iPhone 17']!);
      final services = await tester.runAsync(makeServices);
      await tester.pumpWidget(app(services!, const Shell()));
      await settle(tester);
      await tester.tap(find.text('Wines').last);
      await settle(tester);
      await tester.tap(find.text('Rară Neagră'));
      await settle(tester);
      await settle(tester);
      expect(find.text('Verified by the winemaker'), findsOneWidget);
      expect(find.text('Rară Neagră 2020'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('home shows no scores', (tester) async {
      await sized(tester, screens['iPhone 17']!);
      final services = await tester.runAsync(() async {
        final s = await makeServices();
        await s.recent.record(102);
        return s;
      });
      await tester.pumpWidget(app(services!, const Shell()));
      await settle(tester);
      expect(find.textContaining('Score'), findsNothing);
      expect(find.textContaining('rating'), findsNothing);
      expect(find.text('Did you like it?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('choosing Romanian shows the working-on-it prompt', (
      tester,
    ) async {
      await sized(tester, screens['iPhone 17']!);
      final services = await tester.runAsync(makeServices);
      await tester.pumpWidget(app(services!, const Shell()));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Language').first);
      await settle(tester);
      expect(find.text('English'), findsOneWidget);
      await tester.tap(find.text('Română'));
      await settle(tester);
      expect(find.text("We're working on it"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('onboarding cannot be finished without both consents', (
      tester,
    ) async {
      await sized(tester, screens['iPhone 17']!);
      final services = await tester.runAsync(makeServices);
      var done = false;
      await tester.pumpWidget(
        app(services!, OnboardingScreen(onDone: () => done = true)),
      );
      await settle(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      await tester.tap(find.text('Start exploring'));
      await settle(tester);
      expect(done, isFalse);
      await tester.tap(find.byType(Checkbox).first);
      await settle(tester);
      await tester.tap(find.text('Start exploring'));
      await settle(tester);
      expect(done, isFalse);
      await tester.tap(find.byType(Checkbox).last);
      await settle(tester);
      await tester.tap(find.text('Start exploring'));
      await settle(tester);
      expect(done, isTrue);
      final accepted = await tester.runAsync(
        () => services.settings.read(AppServices.legalKey),
      );
      expect(accepted, AppServices.legalVersion);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('add bottle: required fields, then saved and scannable', (
      tester,
    ) async {
      await sized(tester, screens['iPhone 17 Pro Max']!);
      final services = await tester.runAsync(makeServices);
      await tester.pumpWidget(
        app(services!, const AddBottleScreen(barcode: '4841000000029')),
      );
      await settle(tester);

      await tester.tap(find.text('Save bottle'));
      await settle(tester);
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Choose a type'), findsOneWidget);
      var index = await tester.runAsync(services.catalog.labelIndex);
      expect(index!.where((e) => !e.wine.isVerified), isEmpty);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), 'Crama Demo');
      await tester.enterText(fields.at(3), 'Cupaj');
      await tester.enterText(fields.at(4), '2021');
      await tester.ensureVisible(find.text('Red'));
      await tester.tap(find.text('Red'));
      await settle(tester);
      await tester.tap(find.text('Save bottle'));
      await settle(tester);
      await settle(tester);

      // The form was replaced by the new wine's page.
      expect(find.text('Added by you · not verified'), findsOneWidget);
      expect(find.text('Cupaj 2021'), findsOneWidget);

      final outcome = await tester.runAsync(
        () => services.scanner.resolveBarcode('4841000000029'),
      );
      expect(outcome, isA<ShowVintage>());
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a mistyped barcode is flagged', (tester) async {
      await sized(tester, screens['iPhone 17']!);
      final services = await tester.runAsync(makeServices);
      await tester.pumpWidget(
        app(services!, const AddBottleScreen(barcode: '4841000000013')),
      );
      await settle(tester);
      await tester.tap(find.text('Save bottle'));
      await settle(tester);
      expect(
        find.text("This barcode doesn't look right. Check the digits."),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('wine page: verified wine shows its source and records', (
      tester,
    ) async {
      await sized(tester, screens['iPhone 17']!);
      final services = await tester.runAsync(makeServices);
      await tester.pumpWidget(app(services!, const WineScreen(vintageId: 102)));
      await settle(tester);
      expect(find.text('Verified by the winemaker'), findsOneWidget);
      expect(find.text('Fetească Neagră 2020'), findsOneWidget);
      expect(find.text('13.5 %'), findsOneWidget);
      final recent = await tester.runAsync(services.recent.list);
      expect(recent!.single.vintageId, 102);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('delete my data clears bottles and recents', (tester) async {
      final services = await tester.runAsync(() async {
        final s = await makeServices();
        await s.recent.record(102);
        await s.myBottles.add(
          const NewBottle(
            wineryName: 'A',
            wineName: 'B',
            type: WineType.red,
            year: 2020,
          ),
        );
        await s.deleteAllData();
        return s;
      });
      final recent = await tester.runAsync(services!.recent.list);
      final index = await tester.runAsync(services.catalog.labelIndex);
      expect(recent, isEmpty);
      expect(index!.where((e) => !e.wine.isVerified), isEmpty);
    });
  });

  test('about screen version matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: $appVersion+'));
  });

  test('gtin check digit', () {
    expect(gtinCheckDigitValid('4006381333931'), isTrue);
    expect(gtinCheckDigitValid('4006381333932'), isFalse);
    expect(gtinCheckDigitValid('MD-1'), isNull);
  });

  test('legal texts never mention a collected data type we do not collect', () {
    final privacy = File(LegalScreen.privacy).readAsStringSync();
    expect(privacy, contains('does not collect your personal data'));
    expect(privacy.toLowerCase(), isNot(contains('firebase')));
  });
}
