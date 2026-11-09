---
name: gen-app-store-screenshots
description: Use when the user wants App Store screenshots for an iOS app made from scratch or redone for ASO. It explores the codebase for the core features, drafts a screenshot plan that GPT Sol reviews, builds the set from real simulator captures plus GPT-generated imagery where it helps, and refines it in a Sol review loop.
---

# gen-app-store-screenshots

Screenshots are ads, not a UI tour. Most people see only the first three
frames in search results and decide in a second. Every frame sells one
benefit, proves it with real UI, and reads at thumbnail size.

Start from the code alone. Don't use existing screenshots, store listings or
marketing as a reference. If an old set exists, it gets replaced.

Pipeline: **explore → plan → Sol plan review → build → verify → Sol review
loop → document**. Everything lives in the repo, so a later session can pick
up where this one stopped:

- `docs/app-store/screenshot-plan.md`: the plan, the review history, and the
  recapture steps.
- `docs/app-store/screenshots/screenshots.json`: the compositor spec.
- `docs/app-store/screenshots/raw/`: the captures.
- `docs/app-store/seed/`: the seed images.

## 1. Explore the codebase

Find what the app does and why someone would download it. Read the screens
and navigation, data models, paywall and free-tier limits, onboarding,
settings (privacy, sync, accounts, ads), the design system (fonts, colours,
tone), and any PRD or design docs. Fan out with parallel `Explore` agents when
the app is large.

The output is a short feature inventory. List each feature with the screen
that shows it, the data it needs to look alive, and any proof point it
carries, such as a price, a privacy fact, or a platform. Ask the user only
what the code can't answer, such as the audience, competitors, or what
reviews praise.

## 2. Draft the plan

Write `screenshot-plan.md` with these parts:

1. **Positioning:** one sentence on who the app is for and why it beats the
   alternative.
2. **Frames, in order (4–6):** for each one, the benefit, the headline and
   subhead, the screen to capture, the state it needs, the proof crop to
   enlarge, and the background.
3. **Seed cast and data:** who and what appears on screen, and which images
   need to be generated.
4. **Visual direction:** the fonts and colours from the app's design system,
   a background for each frame, and which frame is dark.
5. **Image generation:** each image to generate, with the prompt and where it
   is used.

Copy rules:

- **Frame 1 is the hero.** Give the single biggest reason to download. Frames
  1–3 must carry the whole pitch on their own.
- **One idea per headline.** Use short common words, 2–3 lines of 2–4 words,
  and line breaks you choose on purpose. Be specific: "Find their coffee
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

Run up to 2 rounds, then show the user the plan Sol and you agreed on. Build
only after the user confirms it.

## 4. Build

### Seed data

The screens need rich, realistic, varied data. Empty states, "Test User 1"
and a one-note cast kill conversion.

- Add a debug-only seed behind a launch argument (`#if DEBUG`, never in
  release). It should wipe the local store, insert the cast, and exit with a
  marker the agent can wait for. Turn off cloud sync and grant paid features
  for the run.
- Make dates relative to launch day, so "today", "this week" and anniversaries
  render right on any capture day.
- Cast people of different genders, ages and backgrounds. No one person
  should appear in every frame.

### GPT image generation

Use GPT image generation for what the app's own content needs, and for nothing
that pretends to be UI.

- **Generate:** portraits of fictional people, photos for entries or posts,
  product shots, and optional decorative backgrounds or textures for a frame's
  canvas.
- **Never generate:** app UI, device frames, Apple assets, real people, brand
  logos, or awards.
- **Route:** in T3, call `delegate_task` to a GPT model with image generation.
  Brief it with the prompts from the plan, the exact output paths, the pixel
  sizes, and a consistent photographic style. Outside T3, use the OpenAI
  Images API (`gpt-image-*`) with a key from `request_secret`.
- Look at every image before using it. Regenerate any with warped hands or
  faces, garbled text, or a style that doesn't match the set.
- Keep the images in `docs/app-store/seed/`. Copy them into the app container
  before seeding, not into the bundle.

### Capture

Use one dedicated simulator at the hero size. An iPhone Pro Max captures 6.9"
(1320 × 2868) natively. In T3, drive it through the device tools
(`device_open`, then its `agent-device` command). Use `xcrun simctl` only for
install, `status_bar`, `defaults`, `get_app_container` and `addmedia`. If
another session holds the simulator, ask before closing it.

- **Status bar:** `simctl status_bar <udid> override --time 9:41
  --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularBars 4
  --operatorName ""`. Apply it again after every boot.
- **12-hour clock:** if it shows "09:41", run `defaults write -g
  AppleICUForce24HourTime -bool false` and `defaults write -g
  AppleICUForce12HourTime -bool true` inside the simulator, then shut it down,
  boot it again, and override the status bar again.
- **Capture at 3×** (`screenshot <path> --pixel-density 3`) into `raw/`.
- **Keyboards:** show one only when typing is the point. To dismiss it,
  scroll the content. If a hardware keyboard hides the software one, tapping
  another control can bring it back.
- **Cursor:** a blinking caret lands in about half the captures. Capture in a
  loop until a pixel probe at the caret's spot reads background.
- Leave no menus, alerts, debug text, or partly scrolled names under the
  navigation buttons.

Rate each capture Great, Usable, or Retake. Fix a Retake by recapturing,
never by painting over UI.

### Compose

`scripts/compose.swift` in this skill renders every frame at every size from
the spec. Run it from the repo root:

```bash
swift <skill>/scripts/compose.swift docs/app-store/screenshots/screenshots.json [slug ...]
swift <skill>/scripts/compose.swift docs/app-store/screenshots/screenshots.json --sheet /tmp/aso
```

```json
{
  "sizes": {"6.9": [1320, 2868], "6.3": [1206, 2622]},
  "theme": {"headlineFont": "serif", "headlineSize": 128},
  "frames": [
    {"slug": "01-find-their-coffee-order", "raw": "search",
     "headline": "Find their\ncoffee order.", "subhead": "Search everything you’ve\nsaved about them.",
     "background": "#6E1F2E", "breakout": [40, 585, 1240, 300]}
  ]
}
```

These defaults can be overridden: `raw` and `out` (both under
`docs/app-store/screenshots/`) and the `theme.light` and `theme.dark` colours
(`canvas`, `ink`, `secondary`). `headlineFont` is `serif`, `sans`, `rounded`,
or a PostScript name. Frame fields:

| Field | Use |
|---|---|
| `background` | Hex canvas colour. Ink flips light or dark by luminance. |
| `dark` | Dark canvas and bezel, for a dark-mode capture. |
| `footnote` | Small third line for a pricing or trust fact. |
| `breakout` | Raw-pixel rect `[x, y, w, h]`, redrawn enlarged over the device. This is the proof shot. |
| `breakoutWidth`, `breakoutTop` | Size and canvas y of the breakout. By default it is 1220 wide and centred on its place on the screen. |
| `cover` | `{"rect", "color"}`: fill raw pixels with the screen's flat background, so the card under a breakout, or fragments below it, don't show twice. |
| `deviceWidth`, `deviceTop` | The 1092-wide default bleeds off the bottom. About 960 shows the whole screen, for frames whose bottom button matters. |

Design rules:

- Give the frames 1–3 distinct saturated backgrounds and 1 dark frame for
  rhythm. Never use plain white.
- Use at most one breakout per frame. Make it the exact proof of the headline,
  framed with padding, not clipped at a rounded edge. If it covers the
  original, `cover` the leftover parts.
- A breakout floating over unrelated UI reads as detached. Overlap the
  original's position or use a whole-screen frame instead.
- Use the app's real fonts and colours, and the drawn bezel. Don't use Apple
  device-frame assets.

## 5. Verify

- Check every PNG with `sips -g pixelWidth -g pixelHeight -g hasAlpha`. It
  must be the exact size with `hasAlpha: no`. App Store Connect rejects
  anything else.
- Build the sheet, then open `sheet.png` and `thumbs.png` and look at every
  frame yourself. Look for doubled content, seams, clipped text, carets,
  keyboards, and status-bar drift. Fix what you see before you spend a
  review round.

## 6. Sol review loop

GPT Sol is the independent ASO reviewer for both the plan (step 3) and the
set. In T3, call `orchestrator_capabilities` once and pick the latest Sol,
unless the user named one. Each round is a new `delegate_task`
(`role: "review"`, high effort, read-only). Children get no history, so every
brief must stand alone:

```
You are an App Store Optimization screenshot reviewer. Round <N>. Read-only.
App: <one paragraph: what it does, audience, pricing, privacy facts>.
Files: contact sheet <sheet.png>, thumbnail simulation <thumbs.png>,
full frames <out>/<hero size>/*.png, spec <screenshots.json>, plan <plan.md>.
History: <scores so far>. Last round's findings and what changed: <ledger>.
Constraints: UI is real captured pixels; generated images are seed content
only; copy must be true of the app; recapture is costly, so prefer copy and
geometry changes.
Deliver: overall and per-frame scores /10, then ranked fixes with exact copy
and geometry (raw-pixel or canvas coordinates). Say explicitly if the set is
10/10, meaning no change you'd expect to measurably lift conversion. Don't
invent fixes.
```

- **Budget:** 3 rounds by default. Run more only when the user sets a higher
  cap. Stop early at 10/10, or when a round returns no fixes worth making.
- **Weigh each finding yourself.** Apply the true ones with the smallest
  change. Decline a fix that contradicts an earlier one, and say why. Push
  back on any copy that isn't true of the app.
- **Fix at the source.** When a review keeps pointing at the same raw problem
  (the cast, a cut-off button, an open menu, a weak photo), recapture or
  generate a new image rather than patching it in the compositor.
- **Re-run steps 4–5 before every round.** Keep a ledger of each round's
  score, findings, and what changed.

## 7. Document and hand off

- Bring `screenshot-plan.md` up to date with the final frame table, the score
  history, the seed and image-generation notes, and the exact recapture
  steps, including any simulator quirks you hit.
- Report the scores, the changes, the verification results, and anything left
  undone, such as other sizes, localized sets or iPhone Duo.
- Ask before committing. Clear the status bar override and close any device
  session you opened.

Sol's 10/10 is a review verdict, not measured conversion. Recommend an App
Store product page test for the hero frame.
