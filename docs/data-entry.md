# Entering wines

## The easy way: the catalogue editor (web page)

```bash
dart run tool/catalog_editor.dart
```

Opens http://localhost:8787 in your browser (stop it with Ctrl+C in the
terminal). It runs only on your Mac and only your Mac can open it.

- **+ New bottle**: one form for barcode, winery, wine, year, specs and
  Romanian texts. Existing wineries/wines autocomplete, typos get a "Did you
  mean…?", the barcode's check digit is verified as you type. If the wine or
  year already exists, only the new parts are added.
- **Left list**: click a winery or wine to edit it, add or edit years and
  barcodes, or delete (deleting a wine also deletes its years and barcodes).
- Every save is checked with the same rules as the build script, written to
  `data/`, and the app catalogue is rebuilt. If something is wrong, nothing is
  saved and the problem is shown.
- If you edit the CSV files in Excel while the page is open, reload the page
  before saving (it refuses to overwrite your Excel changes).

After changes, reinstall the app on the phone.

### Bottle photos

Every wine can have one photo. In the editor, add it on the **New bottle** form
or on the wine's page (**Photo**). Any picture works: the page shrinks it to a
JPEG. The original goes to `data/photos/<wine id>.jpg` (keep this folder in
git) and a copy to `assets/photos/<wine id>.jpg`, which the app bundles.
Reinstall the app to see new photos. Use a straight-on picture on a plain
background. Wines without a photo show the bottle drawing. Photos of wines
that are deleted are removed automatically.

In the app, bottles added on a phone can have a photo too (Add a wine bottle >
Photo); it stays on that phone.

## In the terminal: the bottle wizard

```bash
dart run tool/add_bottle.dart
```

It asks one question at a time (barcode, winery, wine, year, specs, Romanian
texts), then shows a summary and saves only after you confirm. Then it
validates everything and rebuilds `assets/catalog.sqlite`. It:

- recognises a winery or wine you already entered, even typed without
  diacritics, and asks "Did you mean …?" for near-misses (typos);
- picks the ID numbers for you;
- checks the barcode's last digit (check digit) to catch typos;
- for a new year of an existing wine, only asks for that year's data;
- asks whether the barcode is on **every year** of the wine. If unsure,
  answer yes: users then pick the year instead of maybe seeing the wrong one.

Press Enter to skip optional questions. Ctrl+C cancels without saving. After
adding bottles, reinstall the app on the phone.

Editing a bottle that is already entered is done in the files directly (below).

## Editing the files directly

The catalogue lives in six CSV files in `data/`. Edit them in any spreadsheet
(Excel, Numbers, Google Sheets), export as **CSV UTF-8**, then build:

```bash
dart run tool/build_catalog.dart
```

The script checks everything and prints `file row N: problem` for each error.
If there is any error it writes nothing. On success it replaces
`assets/catalog.sqlite`, which is bundled into the app on the next build.

Comma- or semicolon-separated files both work. Decimals can use a comma
(`13,5`). Lists inside one cell use `|` (`Fetească Neagră | Rară Neagră`).
Extra columns (e.g. your own `notes`) are ignored.

**Barcodes:** format the `code` column as **Text** before typing. Otherwise
the spreadsheet turns `4840000000010` into `4.84E+12`; the script catches this.

## Files

IDs are numbers you choose. **Never change or reuse an ID** once the app has
been used with it: phones remember recent scans by vintage ID.

| File | Columns | Required |
|---|---|---|
| `wineries.csv` | `id, name, region` | id, name |
| `wines.csv` | `id, winery_id, name, type, grape_varieties` | id, winery_id, name, type |
| `vintages.csv` | `id, wine_id, year, abv, acidity_g_l, tannins_g_l, residual_sugar_g_l` | id, wine_id, year |
| `barcodes.csv` | `code, wine_id, vintage_id, bottle_size_ml` | code, wine_id |
| `wine_translations.csv` | `wine_id, lang, description` | wine_id, lang |
| `vintage_translations.csv` | `vintage_id, lang, sensory_notes, food_pairings` | vintage_id, lang |

- `type`: `red`, `white`, `rose`, `orange`, `sparkling`, `dessert`.
- `abv` in %, the other specs in g/L. Leave empty if unknown.
- `vintage_id` in `barcodes.csv`: leave **empty** when the same barcode is on
  every year of that wine (the app then asks the user to pick the year). Fill
  it when the code is specific to one harvest.
- Same barcode on two different wines is allowed (the app shows a list); the
  script warns so you notice.
- `lang`: `ro`, `en`, `ru`. Every wine and every vintage needs a `ro` row.

The script refuses: missing required values, unknown IDs, a wine with no
vintage, two vintages of one wine with the same year, a barcode whose vintage
belongs to another wine, a missing `ro` translation.

## Example

`wineries.csv`
```
id,name,region
1,Crama Exemplu,Codru
```
`wines.csv`
```
id,winery_id,name,type,grape_varieties
10,1,Fetească Neagră,red,Fetească Neagră
```
`vintages.csv`
```
id,wine_id,year,abv,acidity_g_l,tannins_g_l,residual_sugar_g_l
101,10,2020,"13,5",5.8,,2.1
```
`barcodes.csv`
```
code,wine_id,vintage_id,bottle_size_ml
4840000000010,10,,750
```
`wine_translations.csv`
```
wine_id,lang,description
10,ro,Vin roșu sec din Codru.
```
`vintage_translations.csv`
```
vintage_id,lang,sensory_notes,food_pairings
101,ro,"Vișine, prune uscate, condimente.",Miel la grătar | Brânză maturată
```
