# Product page header video

An optional looping video, plus a still poster, shown at the top of the App
Store product page. It is a brand showcase, not a sixth screenshot: the app
name, icon and Get button sit right below it, so it doesn't need to carry the
pitch. It should make someone feel what the app is like in a few seconds, and
stay calm enough to loop forever.

## Apple's requirements

Re-verify these at <https://developer.apple.com/app-store/asset-best-practices/>
and record the date in the plan.

- 3840 × 1646 px (21:9). 30 or 60 fps. 5–30 s. H.264, HEVC or ProRes in
  .mov, .m4v or .mp4. Plays muted and loops.
- Safe area: 1646 × 661 at (1097, 493), top-left. Anything essential goes
  here.
- A still poster: PNG or JPG, same size, no alpha. Use the loop's frame 0, so
  the switch from poster to video doesn't jump.
- On iPhone the header shows the full height but only about the central
  2565 px of width, which is about 1.558 × height. Back and share buttons
  overlay the top corners. The wings outside that crop appear only on wider
  displays, so nothing there may matter.
- Apple documents a dark-mode preview. Design for dark first and check light.

## Concept first, per app

Never reuse another app's header style by default. Before building, study the
app the same way step 1 does for screenshots, then decide what its header
should feel like:

- **Brand and personality.** Read the design system (fonts, colours, tone,
  motion rules, "never" lists) and the app icon. Is the app quiet and literary,
  playful, technical, or sporty?
- **A mascot or character.** If the app has one (in its assets, onboarding,
  empty states or icon), it is usually the hero. Animate it in the app's own
  style: a moving mascot gives a playful app its personality.
- **What the app holds.** Its core content types, or the moment it creates,
  are concrete material for motion. For example, a memory app can show its
  memory types being written. Real content beats abstract shapes.
- **Existing art.** Reuse the app icon artwork, illustrations, seed photos and
  brand colours before making anything new.

Write two or three concepts. Each gives a one-line idea, a storyboard with
timings, safe area versus wings, the assets, the build tool, and the risks.
Have the council review them (use the route from SKILL.md step 6, but brief
the members as creative directors). Then show the owner the recommended concept, as a
storyboard or poster mock, before building the video. Record the concept, the
council rounds and the owner's direction in `docs/app-store/header/brief.md`.

### Keep it simple

- One idea, one focal point. The lockup or hero (app mark, wordmark, mascot)
  stays in the safe area and stays put.
- Motion is slow and continuous: drift, settle, write-on, a page turn, a
  mascot's idle loop. No fast cuts, flashes or busy particle fields.
- At most a few short words besides the app name, at phone scale: 100 px of
  source is about 16 pt on a 402 pt iPhone. Text below about 90 px is
  decoration, not copy. No claims, prices or calls to action.
- Motion must still read at phone scale. An 8 px wobble is about 1.3 pt, which
  nobody sees.
- Follow the app's "never" rules. If the design system forbids gradient
  washes, sparkles or tracked caps, the header does too.
- A seamless loop. Every element's state must be a pure function of time
  modulo the loop length, so the last frame flows into frame 0.

## Assets

- **Image generation** (the route chosen in SKILL.md step 0) suits photographic or illustrative material: a
  scene, a texture, a painted mascot pose, the photos inside a depicted
  memory. Never use it for app UI, Apple assets, logos or text. Generate at the
  largest size, look at every image, and regenerate anything warped. Keep
  generated files in `docs/app-store/header/assets/`.
- Use the app's own vector or PNG art (icon layers, mascot sprites, Lottie
  files) in preference to generated stand-ins for the same thing.
- SF Symbols: Apple's licence limits their use outside apps. A header that
  depicts the app's own UI is the defensible case. Custom-drawn glyphs are
  safer for anything standalone.

## Build tools

Pick the tool that fits the concept. Each one writes numbered PNG frames at
3840 × 1646, which `scripts/header.swift` then encodes through one pipeline.

| Concept needs | Tool |
| --- | --- |
| Type, layout, UI-like pieces, photos, easing | Remotion or HyperFrames (HTML/CSS/React rendered by headless Chrome), exporting a PNG sequence |
| Depth, light, 3D objects, a camera move | three.js, rendered frame by frame in headless Chrome |
| A mascot with existing animation | The app's Lottie/Rive file, rendered to frames |
| Flat colour fields and a fixed lockup | The built-in turn scene in `header.swift` |
| Compositing, crops, previews | ffmpeg |

Render frames from a time value (frame / fps), never from wall-clock playback,
so every frame is deterministic. Render the loop's N frames, 0 to N−1. Frame N
equals frame 0 and is not written.

## Encode and check

```bash
swiftc -O <skill>/scripts/header.swift -o /tmp/header
/tmp/header docs/app-store/header/header.json            # poster, phone mock, video
/tmp/header docs/app-store/header/header.json --poster   # poster and mock only
/tmp/header docs/app-store/header/header.json --check    # upload gate
```

The `--check` gate validates the poster (PNG, exact size, opaque, 8-bit) and
the video (exact size, 30/60 fps, 5–30 s, H.264/HEVC/ProRes, yuv420p for H.264,
BT.709 tags). It must print `PASS`.

Spec for an external frame sequence:

```json
{
  "video": "docs/app-store/header/app-header.mp4",
  "poster": "docs/app-store/header/app-header-poster.png",
  "phoneMock": "docs/app-store/header/review/phone.png",
  "frames": "docs/app-store/header/frames",
  "fps": 30
}
```

Frames must be exactly the canvas size, and are sorted by file name. Loop
length is frame count ÷ fps. Alpha is flattened onto black. Keep the frame
folder out of git; it is a build product.

Spec for the built-in turn scene (a fixed mark and wordmark over a ground that
turns, page by page, through colours; Remeli v1 used it):

```json
{
  "video": "docs/app-store/header/app-header.mp4",
  "poster": "docs/app-store/header/app-header-poster.png",
  "phoneMock": "docs/app-store/header/review/phone.png",
  "mark": {"image": "path/to/icon-artwork.png", "crop": [211, 161, 602, 690], "height": 350, "top": 559},
  "wordmark": {"text": "AppName", "font": "serif", "size": 176, "color": "#F4F4F1", "baseline": 1095},
  "grounds": ["#0E0E0D", "#4A2545", "#1F4A3D", "#1D3F66"],
  "beat": 7, "turn": 5, "feather": 800, "direction": "rtl"
}
```

For pages that carry objects, use `pages` in place of `grounds`. Each page
holds a colour, up to a few object cutouts, and the index of its active label.
Remeli v2 used this layout: two keepsakes per memory type, one in each wing,
with a fixed lockup and type words in the centre.

```json
"labels": {"words": ["Note", "Detail", "Date", "Idea", "Moment"],
           "centers": [1299, 1590, 1880, 2144, 2474], "baseline": 1100,
           "font": "sans", "size": 88, "color": "#F4F4F1", "underline": [80, 8, 18]},
"pages": [{"color": "#1F4A3D", "active": 1, "objects": [
  {"image": "docs/app-store/header/assets/cup.png", "box": [700, 560, 470, 560]},
  {"image": "docs/app-store/header/assets/lemon.png", "box": [2680, 620, 480, 500]}]}],
"grow": [0.86, 1.0],
"shadow": {"opacity": 0.18, "blur": 24, "offset": [10, 10]}
```

- **Objects** are fitted to their `box` (`[x, y, w, h]`, top-left), centred
  at the bottom. They grow from `grow[0]` to `grow[1]` across their page,
  scaling about the bottom-centre contact point, and carry a soft contact
  `shadow`. Give a tall, thin object (a candle) a narrow box of its own so it
  isn't shrunk to fit a wide one.
- **The turn.** Only the colour wipes across with the soft edge. Each object
  swaps when the edge reaches its centre: the old one fades out, then the new
  one fades in. They never double-expose.
- **Labels.** The words stay fixed in place. An underline marks the page's
  `active` word and crossfades in place at the turn's midpoint; it never
  slides. Set the centres by measured word width, with equal gaps between
  words: equal centres crowd the long words. Keep the type words at 88 px
  (about 14 pt on iPhone) or larger.
- **Cutouts.** `scripts/cutout.swift <in> <out> [...]` uses Vision to lift the
  subject from an opaque photo. If the image already has real alpha, it only
  trims to the subject. Check the alpha at full size: an "it has a halo"
  report is often just a few faint specks, which the trim threshold ignores.

Apple's own headers keep the text still and change the graphics. Follow that
pattern: a fixed lockup and any fixed words, with motion only in the art.
Don't use portraits or people unless the app's brand is built on them.

`mark` and `wordmark` are also drawn over external frames when set, which
keeps the lockup pixel-identical across scenes. Leave them out when the frames
already contain them. Paths are relative to the working directory.

The pipeline already handles these, so don't rebuild them in other tools:

- **Banding.** It takes frames in 16-bit, then error-diffusion dithers to 8-bit
  BT.709 at CRF 12 with `tune grain` and `aq-mode=3`. Render dark gradients or
  soft edges in 16-bit (16-bit PNGs from your tool, if it can). CoreGraphics'
  `CGGradient` shades at 8 bits even in a 16-bit context, so draw soft colour
  edges as flat per-column fills.
- **Colour tags.** BT.709 primaries, transfer and matrix, TV range.
- **Size and the seam.** Faststart, no audio, and no doubled frame at the
  loop.

## Review

1. Look at the poster, the phone mock (red: safe area; grey: estimated
   buttons), and frames sampled across the loop. Watch the whole video, and
   watch the seam by joining the last second to the first.
2. Council video review: a new delegate per member each round. Give it the brief, the video,
   the poster, the phone mock and sampled frames, and the history. Ask for a
   score out of 10 and ranked fixes. Use the same budget and ledger rules as
   SKILL.md step 6.
3. Run `--check` after the final change.
4. After upload, the owner checks App Store Connect's own header preview for
   the crop and the button overlap. The mock is only an estimate.
