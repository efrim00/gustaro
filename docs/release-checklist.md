# Release checklist (App Store / TestFlight)

Expo: 7 November 2026. Plan: upload Monday 2 November.

## 1. Must do before uploading

1. **Contact email.** Replace `[CONTACT_EMAIL]` in `assets/legal/terms_en.md` and
   `assets/legal/privacy_en.md`.
2. **Real wines.** Add the expo bottles with the catalogue editor, and fix the
   test entry (Chateau Cristi has `0` specs and "test" notes).
3. **Legal review.** The Terms and Privacy Policy are drafts. Have someone
   qualified check them, including Moldovan rules on promoting alcohol.
4. **Proofread** the English, especially the tasting guide in `lib/l10n/app_en.arb`.
5. **Test on the real iPhone 17 Pro Max**: barcode, label, Add a wine bottle.
6. **Host the Privacy Policy.** `dart run tool/build_legal_site.dart` writes
   `site/privacy.html`; any public URL works (e.g. GitHub Pages).
7. Run the checker, then build:

```bash
dart run tool/preflight.dart
```

```bash
flutter build ipa --release
```

The file is `build/ios/ipa/Gustaro.ipa`. Upload it with Apple's **Transporter**
app, or open `build/ios/archive/Runner.xcarchive` in Xcode → Distribute App.
Each new upload needs a higher build number (`version: 1.0.0+2` in `pubspec.yaml`).

## 2. App Store Connect

Create the app: Apps → + → New App. Platform iOS, name **Gustaro**, primary
language English, bundle ID `com.gustaro.gustaro`, SKU `gustaro`.

| Field | Value |
|---|---|
| Subtitle | Moldovan wines, verified |
| Category | Food & Drink |
| Privacy Policy URL | your hosted `privacy.html` |
| Copyright | 2026 Paul Efrim |
| Price | Free |
| App Privacy | **Data Not Collected** |
| Tracking | No |
| Encryption | Already answered in the app (no non-exempt encryption) |
| Age rating | Answer truthfully: alcohol references are frequent, because the app is about wine. Accept the rating Apple calculates. |

**Description**

> Scan a bottle of Moldovan wine and see what it is. Gustaro shows technical
> specifications, sensory notes and food pairings supplied directly by
> winemakers. No reviews, no scores.
>
> - Scan the barcode, or read the label if there is none
> - Works offline: the catalogue lives on your phone
> - Follow a short guided tasting
> - No account needed, and no personal data collected
>
> For adults of legal drinking age. Enjoy responsibly.

**Keywords:** `wine,moldova,scan,barcode,label,tasting,pairing,winery,sommelier`

**Screenshots:** required at 6.9" (1320×2868). Take them on the iPhone 17 Pro Max.

## 3. Review notes (paste into App Review Information)

> Gustaro identifies Moldovan wines. No account or login exists.
>
> Reviewers won't have a Moldovan bottle, so to try the main flow without one:
> tap the red camera button, tap "Type the code", enter <A REAL BARCODE FROM YOUR
> CATALOGUE>, tap "Look it up". The wine page opens. Any other number shows the
> "not in catalogue" screen.
>
> The Wines tab lists the catalogue. More → Add a wine bottle stores a bottle on
> the device only; nothing is uploaded. The camera reads barcodes and labels on
> the device with Apple's Vision framework. The app makes no network requests.
>
> Explore and the sommelier are marked as upcoming features.

## 4. Timing

| Route | Review | Risk |
|---|---|---|
| Direct install from Xcode to the expo iPhone | none | Safest. Works today once the phone is paired. |
| TestFlight, internal testers | none (minutes after processing) | Up to 100 people on your App Store Connect team. |
| TestFlight, external testers | Beta App Review, often about a day | Needs a privacy policy URL. |
| App Store | App Review, usually 1–2 days, can be longer | A rejection could cost days. |

**Have the direct install or internal TestFlight ready as the backup.** Don't
depend on App Review finishing by Thursday.

## 5. Most likely review questions

- **"In the works" placeholders** (Explore, sommelier). Apple dislikes unfinished
  features (guideline 2.1). If rejected, hide the Explore tab and the sommelier
  section; both are one-line changes.
- **A very small catalogue** can read as minimum functionality (4.2). More real
  wines is the fix.
- **Alcohol.** The app must not encourage excessive drinking (1.4.3). It has an
  18+ gate and responsible-use notes.
