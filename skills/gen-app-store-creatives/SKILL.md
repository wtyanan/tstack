---
name: gen-app-store-creatives
description: Create or redesign iOS App Store creatives (regular iPhone screenshots, iPhone Duo screenshots, a product page header video and a search results video) from real simulator captures, with Swift renderers, reviews by a council of models the user picks, image generation through a route the user picks, and sets for every supported app locale.
---

# gen-app-store-creatives

Every frame sells one benefit, proves it with real UI, and reads at thumbnail
size. Make the first three screenshots carry the pitch.

Discover features and claims from the code. Follow the user's brief and brand
assets; reuse existing work when revising it. Replace old work only within
the requested scope.

Pipeline: **choose → explore → plan → plan review → build → verify → review
loop → localize → header video → search results video → document**. Run only
the stages the user's choices need. Everything lives in the repo, so a later
session can pick up where this one stopped:

- `docs/app-store/screenshot-plan.md`: the choices, the plan, the review
  history, and the recapture steps.
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
- `docs/app-store/header/` and `docs/app-store/search-results/`: each video,
  its poster, spec and `brief.md` (concept, review history, rebuild command).

Keep raw PNGs unedited after composing. Record per-locale capture, render,
verification, and review progress in the plan; resume from valid artifacts.

The renderers require macOS/Xcode and Swift/AppKit. Check simulator,
device-control, reviewer and image routes early. Report any blocked stage and
complete useful independent work; never label a self-review as a council
review.

## 0. Choose what to make

Ask before exploring, in one prompt, unless the user already answered. Wait
for every answer; silence is not a selection. Record the answers under
**Choices** in the plan.

1. **What to generate** (multiple choice, pick any): regular iPhone
   screenshots, iPhone Duo screenshots, header video, search results video.
2. **Locales** (single choice), only when screenshots or the search results
   video are selected: English only, or all supported app locales.
3. **Council reviewers**: which models review the plan, visuals,
   translations and videos. One model or several.
4. **Image generation**: which route makes portraits, photos and textures,
   or none (reuse existing assets only).

How to ask questions 3 and 4:

- **In T3 Code:** call `orchestrator_capabilities` first. For each provider,
  find its frontier models, the newest top tier (for example Claude Opus or
  Fable, GPT Sol, Muse Wonder, Astra; read the list rather than assuming
  these). Offer them as a multiple-choice council question, at most one or
  two per provider. If more fit than the question allows, offer the newest
  flagship per provider; the user can type another. For images, offer the
  image-capable routes you found (an image tool in this session, or a
  provider whose models generate images) plus "None". Ask all four questions
  in one question prompt.
- **Elsewhere:** ask questions 3 and 4 as typed input, in the same message as
  the multiple-choice questions. Accept model names as the user writes them,
  "none" for no council (self-review only, labelled as such), and "none" for
  no image generation.

The skill names no default reviewer or image model. If a chosen route turns
out to be unavailable, say so and ask again; never substitute silently.

Selection rules:

- **Duo never replaces the regular set.** Selecting Duo without regular
  screenshots is fine only when an approved regular set already exists;
  otherwise explain that the regular set is required and ask.
- **Videos need real captures.** The search results video shows the app's
  real screens. Reuse the regular set's raw captures when they exist, or
  capture the screens it needs under the step 4 rules.
- Steps 2 to 7 apply to the screenshot sets. Videos alone still need step 1
  and the plan's **Choices**, then go straight to steps 8 to 10.

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

When a header video is selected, also note what it could draw on: any mascot
or character, the app icon artwork, illustrations, and the app's core content
types.

### Locales and devices

Read [references/upload-requirements.md](references/upload-requirements.md)
before choosing dimensions. The plan must enumerate every set × locale ×
display target. If a requested simulator/runtime is unavailable, mark that
cell blocked; never fabricate Duo UI by resizing regular captures.

- **Regular only:** generate regular iPhone targets (plus other required
  device families the app supports), keeping raw and rendered exports for each.
- **With Duo:** generate `iphone-duo` sets for every chosen locale alongside
  the regular set. Duo includes native inner- and outer-display captures,
  separate specs, and rendered exports.

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

1. **Choices:** the step 0 answers.
2. **Positioning:** one sentence on who the app is for and why it beats the
   alternative.
3. **Frames, in order (default 4–6):** for each one, the benefit, the headline and
   subhead, the screen to capture, the state it needs, the proof crop to
   enlarge, and the background.
4. **Seed cast and data:** who and what appears on screen, and which images
   need to be generated.
5. **Visual direction:** the fonts and colours from the app's design system,
   a background for each frame, and a dark frame if the app supports one.
6. **Image generation:** each image to generate, with the prompt and where it
   is used.
7. **Locales:** English only, or the agreed locale list with App Store
   Connect codes, app language IDs, simulator locales, and translation coverage.
8. **Capture matrix:** regular/Duo choice, all set × locale × display targets,
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

## 3. Plan review

Before building anything, have the council review the plan. That is far
cheaper than fixing a captured set. Use the route and brief from step 6 with
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

### Image generation

Use the image route chosen in step 0 for what the app's own content needs,
and for nothing that pretends to be UI. With "None", reuse suitable assets
and report the images still missing.

- **Generate:** portraits of fictional people, photos for entries or posts,
  product shots, and optional decorative backgrounds or textures for a frame's
  canvas.
- **Never generate:** app UI, device frames, Apple assets, real people, brand
  logos, or awards.
- **Route:** call the chosen tool directly, or delegate to the chosen model
  when that is how the environment reaches it. Supply the plan's prompts,
  output paths, pixel sizes, and consistent style. Don't invent a tool route.
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

## 6. Council review loop

The council chosen in step 0 is the independent reviewer for every review
stage: the plan, the visuals, translations, and both videos. Each round, start
one new read-only delegate per member, in parallel, with the same brief. In
T3, use `delegate_task` with each member's provider and model, and high
reasoning effort in `target.options` when supported; follow the returned
`next` instruction. Elsewhere, use the harness's route to each model. Report
an unavailable member rather than substituting another model. Every brief must
stand alone:

```
You are an App Store Optimization creative reviewer. Read-only.
Stage: <plan / English visuals / localization / header / search results>. Round <N>.
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
  cap. Stop early when no member has material actionable fixes left.
- **Weigh each finding yourself.** Apply the true ones with the smallest
  change. Where members disagree, decide and record why. Record
  accepted/declined findings with reasons; reconsider earlier decisions when
  new evidence warrants it. Reject unsupported claims.
- **Fix at the source.** When reviews keep pointing at the same raw problem
  (the cast, a cut-off button, an open menu, a weak photo), recapture or
  generate a new image rather than patching it in the compositor.
- **Update only affected artifacts.** Rerender changed frames/sizes and
  rebuild sheets; reseed/recapture only when source state changed. Run step 5
  before each round and after the final fix, even when the budget is exhausted.
  Keep a ledger of each member's score, the findings, and the changes. Report
  remaining findings and don't claim approval of changes the council hasn't
  reviewed. Record which set/display targets each round covered; when Duo is
  selected, unreviewed Duo frames are a reported gap, not implied approval.

## 7. Localize

Skip for English-only work. Otherwise, follow
[references/localization.md](references/localization.md) for every discovered
supported app locale and selected device set after English layouts are stable. Complete the
per-locale matrix; report blocked locales explicitly. Use the bounded council
translation/layout review described there, without repeating conversion scores.

## 8. Header video

Only when selected. Read [references/header.md](references/header.md) first;
it holds Apple's spec, the build tools, the encoder's spec fields and the
review checklist. Work in `docs/app-store/header/`, and keep `brief.md`
current at every stage so a later session can resume.

1. **Verify the spec.** Re-check Apple's header requirements (size, fps,
   length, safe area, poster) and record the source and date in the brief.
2. **Study the app.** From step 1's inventory: the brand, tone and "never"
   rules in the design system, the icon artwork, any mascot or character,
   illustrations, and the core content types. A playful app with a mascot
   animates the mascot; a quiet app may need only a lockup and slow motion
   built from its own content. Never start from another app's header.
3. **Write two or three concepts.** Each gives a one-line idea, a storyboard
   with timings, what sits in the safe area versus the wings, the assets, the
   build tool, and the risks. Keep it simple: one focal point in the safe
   area, slow continuous motion, almost no text, and a seamless loop.
4. **Concept review.** One council round, briefed as creative directors
   (step 6 route). Pick the recommended concept and record the round.
5. **Owner approval.** Show the owner the recommended concept as a
   storyboard or poster mock and wait for approval before building. Record
   their direction in the brief.
6. **Assets.** Prefer the app's own art (icon layers, mascot sprites, Lottie
   files, seed photos). Make anything missing with the image route from
   step 0, under the step 4 image rules, and keep it in
   `docs/app-store/header/assets/`. Look at every image at full size; cut out
   objects with `scripts/cutout.swift` and check the alpha.
7. **Build.** Render frames with whatever fits the concept: the built-in
   scenes in `scripts/header.swift`, Remotion, HyperFrames, three.js, Lottie,
   CoreGraphics. Frames are a pure function of time, so the loop is seamless.
   Encode every frame through `scripts/header.swift`; keep the frames out of
   git.
8. **Verify.** Look at the poster, the phone mock (safe area and estimated
   buttons), sampled frames, and the whole video, and watch the seam by
   joining the last second to the first. Fix what you see before a review
   round.
9. **Council video review loop.** Step 6 rules: a new delegate per member each
   round, with the brief, video, poster, phone mock, sampled frames and
   history; same budget and ledger.
10. **Gate.** Run `header.swift <spec> --check` after the final change; it must
    print `PASS`.
11. **Localize** only when the header carries words and locales were selected:
    render each locale from its own spec, check its text fits the safe area,
    and cover it in the localization review.
12. **Hand off.** The brief records the concept, the owner's direction, each
    review round, and the rebuild command. Tell the owner to check App Store
    Connect's own header preview for the crop and button overlap after upload;
    the mock is only an estimate.

## 9. Search results video

Only when selected. Read [references/search-results.md](references/search-results.md)
first. Work in `docs/app-store/search-results/`, and keep `brief.md` current.

1. **Verify the spec.** Re-check Apple's search results requirements and
   watch Apple's sample video; record the source and date in the brief.
2. **Plan.** Reuse the hero screenshot's copy for the fixed headline and
   subhead. Pick two to four real screens whose subject reads at card size,
   and a ground colour for each.
3. **Captures.** Reuse raw captures from the regular set, or capture the
   needed screens under the step 4 rules.
4. **Build.** Fill the 3:2 card; the search card shows the whole frame, so
   content kept inside Apple's art safe area reads small. Render frames with
   `scripts/search-results.swift`, encode with `scripts/header.swift`.
5. **Verify.** Look at the poster and a frame from each screen at card size
   (about 1140 px wide) and full size; watch every transition and the seam.
6. **Council video review loop**, by the step 6 rules.
7. **Gate.** `--check` must print `PASS` after the final change.
8. **Localize** when locales were selected: each locale renders from its own
   raw captures and copy, and joins the localization review.
9. **Hand off.** The brief records the layout, its safe-area tradeoff, each
   review round, and the rebuild commands. Localized assets go up as
   standalone Asset Library submissions once a version is approved.

## 10. Document and hand off

- Bring `screenshot-plan.md` and each video's `brief.md` (steps 8 and 9) up to date with the
  final frame table, the score history per council member, the seed and
  image-generation notes, the locales built, and the exact recapture and
  rebuild steps, including the per-locale switch and any simulator quirks you hit.
- Report the scores, the changes, the verification results, and anything left
  undone, including blocked locales and required sizes. Link exports, raw
  captures, specs, and sheets. Don't imply simulator work happened if it didn't.
- Restore settings and clear overrides you introduced. Close only device
  sessions you opened. Commit or upload only when authorized by the user.

A council 10/10 is a review verdict, not measured conversion. Recommend an App
Store product page test for the hero frame.
