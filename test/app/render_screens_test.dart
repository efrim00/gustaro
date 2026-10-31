// Renders real screens to PNGs for visual review:
//   flutter test test/app/render_screens_test.dart --update-goldens --dart-define=RENDER=true
// Skipped in normal test runs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/app/screens/add_bottle_screen.dart';
import 'package:gustaro/app/screens/miss_screen.dart';
import 'package:gustaro/app/screens/onboarding_screen.dart';
import 'package:gustaro/app/screens/tasting_screen.dart';
import 'package:gustaro/app/screens/wine_screen.dart';
import 'package:gustaro/app/shell.dart';
import 'package:gustaro/gustaro_core.dart';

import 'app_screens_test.dart' as harness;

const render = bool.fromEnvironment('RENDER');

Future<void> loadAssets() async {
  await harness.loadFonts();
  final icons = File('assets/fonts/OFL.txt');
  expect(icons.existsSync(), isTrue);
  // Icon fonts for Material icons.
  final bytes = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter'}'
    '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytesSync();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> shot(
  WidgetTester tester,
  String name,
  Size size,
  Widget home, {
  Future<void> Function(WidgetTester)? before,
  bool seed = true,
}) async {
  await harness.sized(tester, size);
  final services = await tester.runAsync(() async {
    final s = await harness.makeServices();
    if (seed) {
      await s.recent.record(102);
      await s.recent.record(201);
    }
    return s;
  });
  await tester.pumpWidget(harness.app(services!, home));
  await harness.settle(tester);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  if (before != null) await before(tester);
  await harness.settle(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('render/$name.png'),
  );
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(loadAssets);
  const max = Size(440, 956);
  const se = Size(375, 667);

  Future<void> tab(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).last);
    await harness.settle(tester);
  }

  final cases = <String, (Size, Widget, Future<void> Function(WidgetTester)?)>{
    'max_home': (max, const Shell(), null),
    'se_home': (se, const Shell(), null),
    'max_more': (max, const Shell(), (t) => tab(t, 'More')),
    'max_explore': (max, const Shell(), (t) => tab(t, 'Explore')),
    'max_wines': (max, const Shell(), (t) => tab(t, 'Wines')),
    'max_wine': (max, const WineScreen(vintageId: 102), null),
    'se_wine': (se, const WineScreen(vintageId: 102), null),
    'max_add': (max, const AddBottleScreen(barcode: '4841000000029'), null),
    'max_miss': (
      max,
      const MissScreen(
        outcome: NotInCatalogue(ScanSource.barcode),
        barcode: '4849999999999',
      ),
      null,
    ),
    'max_onboarding': (max, OnboardingScreen(onDone: () {}), null),
    'se_onboarding': (se, OnboardingScreen(onDone: () {}), null),
    'max_tasting': (max, const TastingScreen(), null),
  };
  for (final MapEntry(key: name, value: (size, home, before))
      in cases.entries) {
    testWidgets(name, skip: !render, (tester) async {
      await shot(tester, name, size, home, before: before);
    });
  }
}
