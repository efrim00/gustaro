# Gustaro

Scan a Moldovan wine bottle and see verified, winemaker-supplied information:
technical specifications, sensory notes and food pairings. Offline, no
accounts, no ratings.

Status: version 1.0, preparing for TestFlight and the 7 November 2026 expo. See
[docs/release-checklist.md](docs/release-checklist.md) and
[docs/expo-demo.md](docs/expo-demo.md).

## Setup

- Flutter stable (developed with 3.47 / Dart 3.13): `brew install --cask flutter`
- iOS builds: Xcode + CocoaPods (`brew install cocoapods`). Minimum iOS 15.5,
  iPhone only. Simulators work, except for the camera.
- Android: not supported yet. Label reading uses Apple Vision and needs an
  Android counterpart.

```bash
flutter pub get
```

## Run on your iPhone

One-time setup:
1. `open ios/Runner.xcworkspace`, select **Runner** → **Signing & Capabilities**,
   choose your Apple ID team (add it under Xcode → Settings → Accounts). If
   Xcode says the bundle ID is taken, change `com.gustaro.gustaro` to
   something unique.
2. On the iPhone: Settings → Privacy & Security → **Developer Mode** on.
3. Connect the iPhone by cable and trust the Mac.

Then:

```bash
flutter run --release
```

`--release` keeps the app working after unplugging. On first launch you may
need to trust the developer: Settings → General → VPN & Device Management.
With a free Apple ID the install expires after 7 days; run it again.

## Add and edit wines (local web app)

The catalogue editor is a web page that runs on your Mac. Use it to add
bottles and to edit or delete wineries, wines, years and barcodes.

**Start it.** Open a terminal in the project folder and run:

```bash
dart run tool/catalog_editor.dart
```

Your browser opens at http://localhost:8787. If it doesn't, open that address
yourself. Keep the terminal open while you work. The page stops working when
the terminal is closed.

**Use it.**
- **+ New bottle**: fill in the form and press **Save bottle**. Existing
  wineries and wines are suggested as you type, and the barcode is checked
  for typos.
- **List on the left**: click a winery or wine to edit it, add years or
  barcodes, or delete.
- Every save is checked, written to the files in `data/`, and the app
  catalogue (`assets/catalog.sqlite`) is rebuilt. If something is wrong,
  nothing is saved and the page tells you why.

**Stop it.** Press Ctrl+C in the terminal.

**Show the new wines in the app.** Reinstall it on the iPhone:

```bash
flutter run --release
```

Notes:
- Only your Mac can open the page; nothing goes online.
- If port 8787 is busy, start it on another one:
  `dart run tool/catalog_editor.dart --port 8788`
- If you edited the CSV files in Excel while the page was open, reload the
  page before saving.
- More detail, and the terminal alternative (`dart run tool/add_bottle.dart`):
  [docs/data-entry.md](docs/data-entry.md).

## Run the tests

```bash
flutter test
```

To render screens to PNGs for a visual check (written to `test/app/render/`):

```bash
flutter test test/app/render_screens_test.dart --update-goldens --dart-define=RENDER=true
```

## Regenerate drift code after changing a table

```bash
dart run build_runner build
```

Generated `*.g.dart` files are committed.

## Layout

```
lib/
  gustaro_core.dart          single import for the UI
  src/catalog/               drift schema, repository, domain models
  src/scan/                  normalizer, label matcher, pure resolution, ScanService
  src/mybottles/             bottles added on the device
  src/recent/                on-device recent scans and settings
  app/                       Flutter UI: theme, screens, widgets, native bridge
  l10n/                      UI strings (English for now)
assets/legal/                Terms and Privacy Policy shown in the app
tool/catalog_editor.dart     web page to add/edit wines (localhost only)
tool/add_bottle.dart         add a bottle by answering questions
tool/build_catalog.dart      CSV → assets/catalog.sqlite
tool/preflight.dart          checks before an App Store upload
tool/build_legal_site.dart   legal texts → site/*.html for hosting
data/                        catalogue source CSVs
test/                        unit + in-memory DB + build script tests
docs/                        data model, resolution flow, decisions, release, expo demo
```

See [docs/data-entry.md](docs/data-entry.md), [docs/resolution-flow.md](docs/resolution-flow.md),
[docs/data-model.md](docs/data-model.md) and
[docs/decisions.md](docs/decisions.md).
