# App Store Connect upload gate

Check Apple's live [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
and [upload instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots)
before planning and again before handoff. Record source URLs and checked date
in `docs/app-store/upload-manifest.json`. Current rules take precedence over
the examples below; never infer accepted upload dimensions from marketing
display names or a simulator's point size.

## Targets verified on 2026-11-10

| Set / display | Accepted portrait pixels used by this workflow | Landscape |
| --- | --- | --- |
| Regular / Dynamic Island medium | 1206 × 2622 (also accepts 1179 × 2556) | Swap width/height |
| Regular / Dynamic Island large | 1320 × 2868 (also accepts 1260 × 2736 or 1290 × 2796) | Swap width/height |
| Duo / outer | 1398 × 2034 | 2034 × 1398 |
| Duo / inner | 2007 × 2853 | 2853 × 2007 |

Use native regular captures matching their corresponding accepted size. The
regular set includes the required medium slot and a Dynamic Island large slot
by default; without it, Apple requires the older Face ID large slot instead.
The optional Duo set includes both inner and outer targets. Use the app's
supported orientation; don't create a second orientation merely to fill a slot.
For iPad apps, include the currently required iPad targets as an additional
family; consult the live table rather than guessing those dimensions.

Apple currently lists a required Dynamic Island medium screenshot and, for
iPadOS apps, a required 13-inch iPad screenshot. Duo screenshots become
required starting April 2027 for apps using the iOS 27.1 SDK or later. Recheck
the effective rule for the actual submission date/SDK. If a regular-only
choice conflicts with a mandatory target, resolve it explicitly before
claiming submission coverage. Apple also documents scaling fallback rules;
record any relied-upon fallback instead of silently assuming coverage.

## Mandatory checks for every selected target

Build a manifest entry for each set × locale × display with device/runtime,
display state, orientation, accepted pixel dimensions, upload slot, spec path,
ordered raw/rendered file lists, and pass/fail results. Include blocked cells
with the reason rather than omitting them. Validate **both** lists;
`compose.swift <spec> --check` automates file-format/dimension checks, the
frame limit, and folder contents for one target. It compares dimensions to
the spec, not Apple's live table: independently verify that the spec's size
is accepted for the named slot, then inspect the remaining requirements:

1. Every file decodes as an actual PNG, is opaque with **no alpha channel**,
   and has exactly one accepted width/height pair for its intended slot.
   Use 8-bit RGB/sRGB for consistent exports. File suffix alone proves nothing.
   Inspect with ImageIO or equivalent; `sips` can report pixel dimensions,
   format, colour space, bit depth, and alpha on macOS. Fail on decode errors.
2. Keep 1–10 ordered images per upload slot and locale. Raw and rendered
   alternatives must each stay within that limit; they are alternative sets,
   not 20 files to combine. Retain extra takes outside upload lists/folders.
3. Each planned frame has a matching native raw capture and rendered output.
   Verify the complete matrix, unique paths/slugs, language, display state,
   and source dimensions. Duo must use its own captures and geometry.
4. Inspect every frame for correct UI, readable copy, clipping, glyphs,
   truthful claims, and content compliant with Apple's linked review guidelines.
   Do not call a set upload-ready on the strength of dimensions alone.
5. Upload directories contain only the intended image sequence. Specs, sheets,
   thumbnails, scratch files, and stale exports stay outside. Record the exact
   App Store Connect locale/device well for each list, including languages
   that have no supported metadata slot and therefore cannot be uploaded.

Mark a target passed only when all applicable checks pass. Missing captures,
unsupported locale slots, failed checks, or unresolved required families block
full submission readiness; report them by target. Keep original raw files even
if an export fails. Never resize, flatten, or repaint a capture silently and
claim it is the native original.

The local gate establishes conformance to the checked asset requirements,
not evidence that an upload happened or a guarantee of Apple's content review.
Only perform an actual App Store Connect upload when the user authorized it;
when performed, record its success/errors separately from local validation.
