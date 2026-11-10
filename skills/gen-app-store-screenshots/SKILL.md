---
name: gen-app-store-screenshots
description: Create or redesign iOS App Store screenshots from real simulator captures, with a Swift compositor, Sol plan and visual reviews, optional iPhone Duo capture sets, and sets for every supported app locale.
---

# gen-app-store-screenshots

Every frame sells one benefit, proves it with real UI, and reads at thumbnail
size. Make the first three frames carry the pitch.

Discover features and claims from the code. Follow the user's brief and brand
assets; reuse existing work when revising it. Replace an old set only within
the requested scope.

Pipeline: **explore → choose locales/devices → plan → Sol plan review → build →
verify → Sol review loop → localize → document**. Everything lives in the
repo, so a later session can pick up where this one stopped:

- `docs/app-store/screenshot-plan.md`: the plan, the review history, and the
  recapture steps.
- `docs/app-store/screenshots/<set>/<locale>/<display>/screenshots.json`:
  one compositor spec per capture target, with explicit `raw`, `out`, and size.
- Under that same target directory: `raw/` for native unedited captures,
  `rendered/<width>x<height>/` for upload exports, and `review/` for sheets
  outside upload folders.
- `<set>` is `regular` or `iphone-duo`; `<display>` identifies the verified
  App Store slot, such as `dynamic-island-medium`, `duo-inner`, or `duo-outer`.
- `docs/app-store/seed/`: shared seed images.
- `docs/app-store/upload-manifest.json`: verified requirements, target mapping,
  raw/rendered file lists, dimensions, and validation results.

Keep raw PNGs unedited after composing. Record per-locale capture, render,
verification, and review progress in the plan; resume from valid artifacts.

The compositor requires macOS/Xcode and Swift/AppKit. Check simulator,
device-control, and Sol delegation availability early. Image generation is
optional when existing seed assets suffice. Report any blocked stage and
complete useful independent work; don't label a self-review as Sol.

## 1. Explore the codebase

Find what the app does and why someone would download it. Read the screens
and navigation, data models, paywall and free-tier limits, onboarding,
settings (privacy, sync, accounts, ads), the design system (fonts, colours,
tone), and any relevant product docs.

The output is a short feature inventory. List each feature with the screen
that shows it, the data it needs to look alive, and any proof point it
carries, with source paths for pricing/privacy claims. Ask the user only
what the code can't answer, such as the audience, competitors, or what
reviews praise.

### Choose locales and devices

Unless the user already chose, ask **English only or all supported app
locales?** Also ask **Regular iPhone screenshots only, or regular plus iPhone
Duo?** Bundle these independent choices in one prompt before drafting the plan,
and wait for both answers. Use English/regular-only when the user explicitly
has no preference; silence is not a selection.

- **No Duo:** generate only regular iPhone targets (plus other required device
  families the app supports), keeping raw and rendered exports for each.
- **Yes Duo:** generate **both** `regular` and `iphone-duo` sets for every chosen
  locale. Duo includes native inner- and outer-display captures, separate
  specs, and rendered exports; it never replaces the regular set.

Read [references/upload-requirements.md](references/upload-requirements.md)
before choosing dimensions. The plan must enumerate every set × locale ×
display target. If a requested simulator/runtime is unavailable, mark that
cell blocked; never fabricate Duo UI by resizing regular captures.

For all locales, read [references/localization.md](references/localization.md)
now and discover shipped languages. Include the mapping and coverage in the
plan. Ask again only for an ambiguity that affects the output.

Check device families, orientations, SDK, and submission date against the
current Apple requirements. A regular-only choice cannot waive a mandatory
Duo slot: explain the conflict at the plan checkpoint and leave submission
readiness blocked until resolved. All selected raw and rendered PNGs must pass
the upload gate. The bundled renderer needs per-target geometry for the wider
Duo displays; don't stretch a regular layout or crop away the feature proof.

## 2. Draft the plan

Write `screenshot-plan.md` with these parts:

1. **Positioning:** one sentence on who the app is for and why it beats the
   alternative.
2. **Frames, in order (default 4–6):** for each one, the benefit, the headline and
   subhead, the screen to capture, the state it needs, the proof crop to
   enlarge, and the background.
3. **Seed cast and data:** who and what appears on screen, and which images
   need to be generated.
4. **Visual direction:** the fonts and colours from the app's design system,
   a background for each frame, and a dark frame if the app supports one.
5. **Image generation:** each image to generate, with the prompt and where it
   is used.
6. **Locales:** English only, or the agreed locale list with App Store
   Connect codes, app language IDs, simulator locales, and translation coverage.
7. **Capture matrix:** regular/Duo choice, all set × locale × display targets,
   matching device/runtime and native dimensions, orientation, exact accepted
   export dimensions, App Store slot, English variant, and reproduction commands.
   Record the Apple source URLs, verification date, and SDK/deadline conditions.

Copy rules:

- **Frame 1 is the hero.** Give the single biggest reason to download. Frames
  1–3 must carry the whole pitch on their own.
- **One idea per headline.** Use short common words, usually 2–3
  lines, with breaks chosen for the language. Be specific: "Find their coffee
  order." beats "Search your notes."
- **Write what the user gets, not what the app does.** Paint a moment, state
  an outcome, or kill a pain.
- **The subhead adds proof or trust,** not a second feature. A privacy,
  pricing or "no account" selling point goes in the first three frames.
- **No two frames make the same promise.**
- **Every claim must be true of the shipped app.** Pricing footnotes must
  match the real free tier.

## 3. Sol plan review

Before building anything, have GPT Sol review the plan. That is far cheaper
than fixing a captured set. Use the review route and brief from step 6 with
these inputs: the plan file, the feature inventory, and the paths to the
paywall and main screens. Ask for a score out of 10, ranked changes to the
benefits, frame order, copy and capture choices, and anything the plan claims
that the code doesn't support.

Run up to **2 plan rounds**. Resolve material findings, then present the
concrete plan for user confirmation unless they already authorized proceeding
without that checkpoint. Record any unresolved findings.

## 4. Build

### Seed data

Use realistic, varied data that makes each benefit visible. Avoid placeholder
names and empty states unless an empty state is itself the feature being sold.

- Prefer existing fixtures. If needed, add a `#if DEBUG` seed behind a launch
  argument, with a completion marker and explicit locale inputs. Reset only a
  dedicated screenshot store on a disposable simulator, never existing user
  data. Disable cloud sync/live writes; keep mock paid access debug-only.
  Show only features customers can actually obtain in the released app.
- Keep relative dates deterministic for the run and format dates/numbers in
  the selected locale. Translate seed-written titles, notes, and messages.
- Use fictional, varied data appropriate to the product. Reuse the same cast
  and photos across locales.

### GPT image generation

Use GPT image generation for what the app's own content needs, and for nothing
that pretends to be UI.

- **Generate:** portraits of fictional people, photos for entries or posts,
  product shots, and optional decorative backgrounds or textures for a frame's
  canvas.
- **Never generate:** app UI, device frames, Apple assets, real people, brand
  logos, or awards.
- **Route:** prefer an available image-generation tool. Delegate only when
  that is the environment's supported image route. Supply the plan's prompts,
  output paths, pixel sizes, and consistent style. If unavailable, reuse
  suitable assets or report the missing images; don't invent a tool route.
- Look at every image before using it. Regenerate any with warped hands or
  faces, garbled text, or a style that doesn't match the set.
- Keep the images in `docs/app-store/seed/`. Copy them into the app container
  before seeding, not into the bundle.

### Capture

Use dedicated simulators matching the matrix; record model, runtime, display
state (Duo inner/outer), and actual PNG dimensions. Capture every target from
its real UI layout; reuse seed assets, not a different display's captured pixels.
In T3, use `device_list`, then `device_open` with host/device IDs. Use the
returned `agent-device` command for launches, input, navigation, settings, and
captures; inspect with `device_screenshot`. Read command help rather than
assuming screenshot flags or density. Use `simctl` only for operations device
tools cannot perform, such as install support, status-bar overrides, or seed
asset copying. Follow the environment's device failure guidance; don't take
over another session. Outside T3, use available simulator-control tooling.

- Record language, locale, appearance, and override settings before changing
  them; restore settings you change, including on an interrupted run.
- Set a consistent status bar, for example 9:41 with full battery and signal.
  Reapply after boot. Keep clock/date formatting natural for each locale.
- Capture one screen first and verify native dimensions before calculating
  raw-pixel crop rectangles. Keep captures unedited and separate from exports.
- Wait for seed completion, images, and animations. Avoid accidental keyboards,
  menus, alerts, debug text, and clipped names.
- Inspect carets when relevant. Retry a bounded number of times, then dismiss
  focus or change the capture state rather than looping indefinitely.

Rate captures **Usable** or **Retake**, with a reason. Recapture source defects.
Each target's raw files must be native, opaque, and accepted dimensions for its
slot. If capture tooling adds alpha, use another native export route; don't
silently alter raw pixels and call them untouched captures.

### Compose

Read [references/composition.md](references/composition.md) for commands,
spec fields, defaults, and coordinate systems of `scripts/compose.swift`.
Use app fonts/colours with readable contrast and visual distinction across the
opening frames. A dark frame requires a real dark-mode capture.

Use at most one breakout per frame, tied to its original UI position and
padded around the proof. A whole-screen frame is preferable to a detached
crop. Use `cover` only to avoid duplicate content under a breakout, never to
hide a defect in the source capture. Use the drawn bezel, not Apple assets.

## 5. Verify

Run the mandatory gate in [references/upload-requirements.md](references/upload-requirements.md)
on **both raw and rendered** files for every matrix cell. Save the results in
the upload manifest. Any failing or unchecked cell blocks an upload-ready claim.

- Run `compose.swift <spec> --check` for every target spec; it must print
  `PASS`. Confirm frame order matches the plan and retain the raw captures.
- Build the sheet, then open `sheet.png` and `thumbs.png` and look at every
  frame yourself. Look for doubled content, seams, clipped text, carets,
  keyboards, and status-bar drift. Fix what you see before you spend a
  review round. Inspect each distinct export aspect ratio at full size too.
  Check claim accuracy and intended fictional data. These checks do not prove
  App Store acceptance.

## 6. Sol review loop

GPT Sol is the independent ASO reviewer for both the plan (step 3) and the
set. In T3, call `orchestrator_capabilities` once before delegation and select
an available Sol unless the user named one. Each review/re-check is a new
`delegate_task`, read-only, with high reasoning effort in `target.options`
when supported. Follow the returned `next` instruction. Outside T3, use an
available Sol route. Report an unavailable model rather than silently
substituting another reviewer. Every brief must stand alone:

```
You are an App Store Optimization screenshot reviewer. Read-only.
Stage: <plan / English visuals / localization>. Round <N>.
App: <one paragraph: what it does, audience, pricing, privacy facts>.
Inputs: <absolute paths to plan, feature inventory, and relevant source>.
Visual stages also include, for every selected set/display: <sheet.png>,
<thumbs.png>, full frames, and spec.
Localization also includes: locale mapping, English spec, app translations.
History: <scores so far>. Last round's findings and what changed: <ledger>.
Constraints: real captured UI; truthful claims; approved visual system.
Include raw captures or relevant source paths to investigate source defects.
Deliver: ranked fixes with evidence and exact copy/geometry where useful
(identify raw-pixel or canvas coordinates). Identify blockers first. For plan
and English visuals, give a score /10; include per-frame visual scores.
Say when no material actionable findings remain; don't invent fixes.
Scores are subjective judgments, not measured conversion.
```

- **Budget:** 3 rounds by default. Run more only when the user sets a higher
  cap. Stop early when no material actionable fixes remain.
- **Weigh each finding yourself.** Apply the true ones with the smallest
  change. Record accepted/declined findings with reasons; reconsider earlier
  decisions when new evidence warrants it. Reject unsupported claims.
- **Fix at the source.** When a review keeps pointing at the same raw problem
  (the cast, a cut-off button, an open menu, a weak photo), recapture or
  generate a new image rather than patching it in the compositor.
- **Update only affected artifacts.** Rerender changed frames/sizes and
  rebuild sheets; reseed/recapture only when source state changed. Run step 5
  before each round and after the final fix, even when the budget is exhausted.
  Keep a score/findings/change ledger. Report remaining findings and don't
  claim approval of changes Sol hasn't reviewed. Record which set/display
  targets each round covered; when Duo is selected, unreviewed Duo frames
  are a reported gap, not implied approval.

## 7. Localize

Skip for English-only work. Otherwise, follow
[references/localization.md](references/localization.md) for every discovered
supported app locale and selected device set after English layouts are stable. Complete the
per-locale matrix; report blocked locales explicitly. Use the bounded Sol
translation/layout review described there, without repeating conversion scores.

## 8. Document and hand off

- Bring `screenshot-plan.md` up to date with the final frame table, the score
  history, the seed and image-generation notes, the locales built, and the
  exact recapture steps, including the per-locale switch and any simulator
  quirks you hit.
- Report the scores, the changes, the verification results, and anything left
  undone, including blocked locales and required sizes. Link exports, raw
  captures, specs, and sheets. Don't imply simulator work happened if it didn't.
- Restore settings and clear overrides you introduced. Close only device
  sessions you opened. Commit or upload only when authorized by the user.

Sol's 10/10 is a review verdict, not measured conversion. Recommend an App
Store product page test for the hero frame.
