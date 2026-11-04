# Figma plugin: the app's screens as editable layers

Draws every screen of the app in the Figma file, using the app's own icons,
colours and texts, so the design in Figma matches what is built.

## Run it

1. Open the Figma file in **Figma desktop**.
2. **Plugins → Development → Import plugin from manifest…** and choose
   `figma_plugin/manifest.json` (only needed once per Mac).
3. **Plugins → Development → Gustaro app design**.

It clears and rebuilds the page **App (as built)**: colour variables, text
styles, components (buttons, tab bar, wine row, fields and more) and 23
screens (onboarding, Home, Explore, Wines, More, wine page, scan states, not
in catalogue, add a bottle, my bottles, tasting guide, about, terms, privacy).
Other pages are not touched. Run it again after the app changes; do not edit
that page by hand, because the next run replaces it.

## Update it after the app changes

```bash
dart run tool/build_figma_plugin.dart
```

This rewrites `figma_plugin/code.js` from `tool/figma/plugin_template.js`, the
app's SVG icons, `lib/l10n/app_en.arb` and the legal texts. Change a screen's
layout in the template. Texts, icons and legal pages follow the app by
themselves.

## Known approximations

- Domine SemiBold (used by the app for titles) is not in Figma's font list, so
  Domine Bold stands in. Install `assets/fonts/Domine-SemiBold.ttf` to match.
- Icons the app takes from Flutter's Material set (globe, person, glass,
  cocktail, document, shield, trash, info, plus, flashlight) are drawn as
  simple outlines in the same style.
- Wine names and numbers are sample data, as in the app's own renders.
