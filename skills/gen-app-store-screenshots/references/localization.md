# All-locales workflow

Read when the user chooses all supported app locales. Discover the list before
planning; generate localized sets only after the English set is stable.

## Discover and map

Inspect the shipping app target, not every resource in dependencies or tests:

- `.xcstrings` source language, translated values, plurals, and device variants.
- Bundled `*.lproj` resources, including `.strings`, `.stringsdict`, and
  localized storyboards; `Base.lproj` is not a language.
- Xcode `knownRegions`, development region, `CFBundleLocalizations`, and any
  app-specific localization library or in-app language selector.

Declarations identify candidates; inspect bundled resources and actual
translations to distinguish shipped languages from stale declarations.
Include the source language even when its keys are the displayed English.
Don't count third-party SDK translations as app support. Partial app
translations remain candidates: record gaps rather than silently dropping
them or treating them as complete. Preview key capture screens to confirm
language selection works.

Record **app language ID → evidence/coverage → simulator language and region
→ App Store Connect locale → status**. Check Apple's current
[store localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/)
when mapping. App languages and store metadata locales are different sets;
don't invent a region or expand one language into every regional variant.
Use the app's resources or existing store configuration as evidence. Resolve
genuinely ambiguous mappings with the user in the plan checkpoint.

Generate every supported app locale requested. If a language lacks a store
metadata slot, retain its app-language ID for local artifacts and mark it
as not directly uploadable. Don't relabel it as a different language.
For several app locales mapping to one store locale, keep separate local
artifacts and resolve the upload choice; never overwrite one with another.

## Build each locale

1. **Copy:** translate headline, subhead, and footnote for natural advertising
   copy, using the app's terms. Preserve claims and qualifications, not English
   syntax or line breaks. Choose breaks for the target language; shorten
   wording before reducing type. Verify regional price/currency claims
   rather than converting amounts by guesswork.
2. **Seed:** reuse cast, photos, and frame order. Translate user-written seed
   content and explicitly select formatting locale/time zone. Record intended
   untranslated names/brands. Don't silently substitute English for missing
   app translations; record a blocker or obtain approval for a scoped app
   translation fix.
3. **Capture:** select language and region through device controls or existing
   app launch arguments; relaunch as needed. Follow the main skill's device
   rules for settings, launches, and captures. Verify one screen's language,
   formatting, and direction before capturing all screens into
   `<set>/<locale>/<display>/raw/` under the screenshots root. Repeat for every
   selected regular and Duo display; do not reuse regular pixels for Duo.
4. **Spec:** copy the matching English set/display spec to
   `screenshots/<set>/<locale>/<display>/screenshots.json`. Set explicit `raw`
   and `out` to that target's `raw/` and `rendered/` paths relative to the app
   repo root. Keep the same frame slugs and one verified size per target spec.
   Retune crops and geometry against localized pixels, including both Duo
   displays when selected; English coordinates may point to different content.
5. **Fonts and direction:** select an installed font covering the script.
   Check all captions for missing glyphs and unwanted fallback. Inspect
   Arabic/Hebrew shaping, mixed-direction text, punctuation, and RTL UI order.
   Don't reverse strings or mirror captures manually. The compositor centres
   captions; adapt it if correct typesetting needs controls it doesn't expose.
6. **Verify:** run the main skill's export and visual checks, including
   overflow, untranslated UI/seed text, glyphs, and qualifications. Mark each
   set/locale/display cell captured, rendered, verified, or blocked in the plan.
   Run the upload gate on raw and rendered files and update the manifest.

## Review and finish

Use the main skill's Sol route/brief for translation accuracy, natural copy,
terminology, RTL/shaping, and layout. Include English/localized specs, app
translations, sheets/thumbnails, and full frames as needed. Don't repeat
English conversion scores.

Use one review round per batch, grouping locales so every frame fits within
the reviewer's input limits. Record which set/locale/display targets each batch covered; one
overloaded sheet is not evidence of full review. Apply valid fixes and
reverify outputs. Report unresolved translation uncertainty or missing review
coverage. Additional rounds require a user-set budget.

Restore original simulator language, region, appearance, and any status-bar
or clock overrides changed for the run. Report every discovered locale's
final state, including partial or blocked results.
