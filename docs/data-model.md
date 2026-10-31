# Data model

Defined once in `lib/src/catalog/catalog_database.dart` (drift). The data
build script will create snapshots from the same definitions.

All IDs are assigned in the source spreadsheet (not auto-increment) and must
stay **stable** across data versions and never be reused: recent scans on the
device store vintage IDs.

```
winery ─1:n─ wine ─1:n─ vintage
               │           │
               ├─1:n─ barcode (vintage_id nullable)
               ├─1:n─ wine_translation
               └───────────┴─1:n─ vintage_translation
meta (single row)
```

| Table | Columns | Notes |
|---|---|---|
| `winery` | `id`, `name`, `region?` | |
| `wine` | `id`, `winery_id`, `name`, `type`, `grape_varieties` | `type` ∈ red, white, rose, orange, sparkling, dessert. `grape_varieties` is a JSON array of strings |
| `vintage` | `id`, `wine_id`, `year`, `abv?`, `acidity_g_l?`, `tannins_g_l?`, `residual_sugar_g_l?` | Unique (`wine_id`, `year`). `abv` in %, others in g/L |
| `barcode` | `id`, `code`, `wine_id`, `vintage_id?`, `bottle_size_ml?` | `code` indexed (`barcode_code_idx`), **not unique**: collisions are allowed. NULL vintage = code identifies the product, not a harvest |
| `wine_translation` | `wine_id`, `lang`, `description?` | PK (`wine_id`, `lang`) |
| `vintage_translation` | `vintage_id`, `lang`, `sensory_notes?`, `food_pairings` | PK (`vintage_id`, `lang`). Notes and pairings are per vintage because they change by harvest. `food_pairings` is a JSON array of strings |
| `meta` | `data_version`, `schema_version`, `built_at` | One row. `built_at` is ISO-8601 UTC |

There is deliberately no rating or score column anywhere.

Language codes are ISO 639-1 (`ro`, `en`, `ru`). The prototype fills only
`ro`; `CatalogRepository.vintageDetails` falls back to `ro` when a language is
missing.

Foreign keys are enforced (`PRAGMA foreign_keys = ON`). Rules the schema cannot
express, which the build script must validate:

- a barcode's `vintage_id` belongs to its `wine_id`;
- every wine has at least one vintage;
- codes are trimmed.

On-device data lives in **separate** databases, so replacing the catalogue
never touches it:

- `user.sqlite` (`UserDatabase`): `recent_scan(vintage_id, viewed_at, liked)`,
  newest 50 kept, and `setting(key, value)`.
- `my_bottles.sqlite` (`CatalogDatabase`): bottles added in the app, in the same
  schema as the catalogue, with IDs from 1,000,000,000. The build script rejects
  catalogue IDs in that range.
