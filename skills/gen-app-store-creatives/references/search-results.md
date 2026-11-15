# Search results video

An optional looping video, plus a still poster, that App Store search results
show in place of the screenshots (iOS 27 and later). Unlike the header, it
does carry the pitch: someone scrolling search results sees the app name, the
Get button and this card, and nothing else.

## Apple's requirements

Re-verify these at
<https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications>
and <https://developer.apple.com/app-store/asset-best-practices/>, and record
the date in the brief.

- 3:2, 1920 × 1280 to 3840 × 2560 px. 30 or 60 fps, 5–30 s, .mov, .m4v or
  .mp4. Plays muted and loops.
- Art safe area: 2168 × 1030 at (836, 765), top-left.
- A still poster: same size, no alpha. Use the loop's frame 0.
- Show the real interface. No pricing, URLs, logos or Apple recognitions.
- Apple publishes a sample video on the best-practices page. Watch it before
  designing.

## Layout

- **Fill the card.** On iPhone the search card shows the whole 3:2 frame at
  about 360–380 pt wide, so 100 px of source is about 9 pt. Content kept
  inside the art safe area leaves a wide empty border and reads small. Apple's
  sample fills the card too: its headline starts near the left edge and its
  phone runs off the bottom. At 3840 × 2560, a headline of about 280 px
  (about 25 pt on the card) with 300 px side margins and a 1180 px wide phone
  works. The tradeoff: a placement that crops to the safe area would clip the
  start of the headline. Record it in the brief.
- **Fixed text, moving graphics.** The headline and subhead stay still; only
  the phone's screen and the ground change. Reuse the hero screenshot's copy:
  the benefit as the headline, the trust line as the subhead.
- **Real screens.** Use raw captures, not composed screenshots, in a drawn
  bezel. Choose two to four screens whose subject reads at card size: faces,
  photos, names, large type. A search list or dense settings screen reads as
  grey texture.
- **A ground per screen.** Tie each ground colour to its screen (the person's
  colour, the screen's accent, or the app's neutral for an overview), and wipe
  it across in step with the screen change.
- **Transitions.** A navigation-style push: the next screen slides in over the
  old one, which moves at 0.3 of the speed, in about 0.8 s. A crossfade
  double-exposes the UI. Hold each screen about 5 s.

## Build

`scripts/search-results.swift` renders the frames from a spec. It draws the
ground (with flat per-column fills for the soft wipe edge, which avoids 8-bit
banding), the text, the bezel and the screens, and hard-links repeated hold
frames so the folder stays small. `scripts/header.swift` then encodes them:
give it `width`, `height` and `safeArea` in the same spec.

```json
{
  "video": "docs/app-store/search-results/app-search-results.mp4",
  "poster": "docs/app-store/search-results/app-search-results-poster.png",
  "frames": "/tmp/app-search-results/frames",
  "width": 3840, "height": 2560, "safeArea": [836, 765, 2168, 1030],
  "fps": 30,
  "grounds": ["#1F4A3D", "#0E0E0D", "#4A2545"], "feather": 240, "ink": "#F4F4F1",
  "headline": "Remember birthdays.\nSave gift ideas.",
  "headlineSize": 280,
  "subhead": "Private iCloud sync.\nNo account. No ads.",
  "subheadSize": 130,
  "textLeft": 300, "textTop": 600, "textWidth": 1900,
  "deviceLeft": 2360, "deviceTop": 200, "deviceWidth": 1180,
  "screens": ["path/to/raw/one.png", "path/to/raw/two.png", "path/to/raw/three.png"],
  "hold": 5.2, "fade": 0.8
}
```

- `grounds` has one colour per screen. `feather` is the wipe edge in px.
- The headline is New York semibold; the subhead is SF at 0.82 opacity.
  Change the fonts in the script if the app's design system uses others.
- Coordinates are top-left. A phone may run off the bottom edge; keep its top
  and the screen's subject on the card.
- Loop length is `(hold + fade) × screens`. The last push returns to the first
  screen, so the loop is seamless.

```bash
swiftc -O <skill>/scripts/search-results.swift -o /tmp/search-results
swiftc -O <skill>/scripts/header.swift -o /tmp/header
/tmp/search-results docs/app-store/search-results/search-results.json   # frames
/tmp/header docs/app-store/search-results/search-results.json           # poster and video
/tmp/header docs/app-store/search-results/search-results.json --check   # must print PASS
```

Keep the frames out of git; they are a build product.

## Review

1. Look at the poster and a frame from each screen at card size (about
   1140 px wide) as well as full size. Watch every transition and the seam.
2. Council video review: a new delegate per member each round. Give it the
   brief, the video, the poster, sampled frames, Apple's sample, and the
   history. Ask for a score out of 10 and ranked fixes. Use the budget and
   ledger rules from SKILL.md step 6.
3. Run `--check` after the final change.

## Localization and upload

Each locale needs its own render from its own raw captures and copy. Once an
app version is approved, upload them as standalone Asset Library submissions,
then publish them on the live version. An asset can't be submitted while it is
part of an active app submission.
