# Compositor reference

`scripts/compose.swift` uses AppKit/CoreText on macOS. Run from the app repo
root; `<skill>` is the installed skill's absolute directory. Follow the
workspace's shell wrapper rules when running these commands.

```bash
swift <skill>/scripts/compose.swift docs/app-store/screenshots/regular/en-US/dynamic-island-medium/screenshots.json
swift <skill>/scripts/compose.swift docs/app-store/screenshots/regular/en-US/dynamic-island-medium/screenshots.json 01-search
swift <skill>/scripts/compose.swift docs/app-store/screenshots/regular/en-US/dynamic-island-medium/screenshots.json --sheet docs/app-store/screenshots/regular/en-US/dynamic-island-medium/review
swift <skill>/scripts/compose.swift docs/app-store/screenshots/regular/en-US/dynamic-island-medium/screenshots.json --check
```

The first command renders all frames at every configured size; positional
filters select frame slugs or raw basenames, and an unmatched filter fails.
`--sheet` reads already rendered frames at the widest configured size and
writes `sheet.png` plus `thumbs.png` (the first three frames). Rebuild sheets
after changing exports. `--check` validates a one-size spec's raw list (unique
frame `raw` names in order) and rendered list: PNG data, exact size, no alpha,
8-bit RGB, 1–10 frames, and no extra visible files in either folder. It exits
non-zero on any failure; it does not check content, locale slots, or whether
the spec's chosen size appears in Apple's accepted-size table.

```json
{
  "raw": "docs/app-store/screenshots/regular/en-US/dynamic-island-medium/raw",
  "out": "docs/app-store/screenshots/regular/en-US/dynamic-island-medium/rendered",
  "sizes": {"1206x2622": [1206, 2622]},
  "theme": {"headlineFont": "serif", "headlineSize": 128},
  "frames": [
    {
      "slug": "01-search",
      "raw": "search",
      "headline": "Find their\ncoffee order.",
      "subhead": "Search everything you've\nsaved about them.",
      "background": "#6E1F2E",
      "breakout": [40, 585, 1100, 300]
    }
  ]
}
```

This is a schema example; replace its copy, dimensions, and crop with values
verified for the app. Paths are relative to the **working directory**, not
the spec file. Each `raw` basename resolves to `<spec.raw>/<frame.raw>.png`.
Exports go to `<spec.out>/<size key>/<slug>.png`; keep slugs unique and ordered.
Set `raw`, `out`, and `sizes` explicitly for every target. Use one size per
spec, keyed `<width>x<height>`, so native captures, crops, and exports
correspond to the same display; the rendered upload folder is
`rendered/<width>x<height>/`.

Do not rely on the script's legacy path/size defaults in this workflow. Layout uses a
**1320 × 2868 design canvas with top-left coordinates**, scaled by output
width. Different aspect ratios change available height, so inspect each one.
Raw rectangles use the capture's actual pixels, also from the top-left.

| Field | Meaning |
| --- | --- |
| `theme.headlineFont` | `serif`, `sans`, `rounded`, or an installed PostScript font name. |
| `theme.headlineSize` | Headline size on the design canvas; default 128. |
| `theme.light`, `theme.dark` | When supplied, each requires `canvas`, `ink`, and `secondary` hex colours. |
| `background` | Frame canvas hex colour; text colours switch by luminance. Inspect actual contrast. |
| `dark` | Selects dark theme/bezel; pair with a real dark-mode capture. |
| `footnote` | Optional pricing/trust qualification. |
| `breakout` | `[x, y, width, height]` of real raw pixels to enlarge. Keep the whole rect inside the capture. |
| `breakoutWidth`, `breakoutTop` | Canvas width and top; default width 1220, positioned over the original region. |
| `cover` | `{"rect": [x, y, width, height], "color": "#RRGGBB"}` fills the original region to avoid duplicate content beneath a breakout. Never use to hide source defects. |
| `deviceWidth`, `deviceTop` | Canvas geometry. Default width 1092 bleeds below the canvas; around 960 can show the whole screen depending on text/capture ratio. Top is constrained below captions. |

The renderer outputs opaque, 8-bit sRGB PNGs. It draws a bezel and uses one
headline font per spec, system fonts for subheads/footnotes, centred text,
and fixed caption widths. It does not generate decorative backgrounds,
translate text, or detect overflow. For other layouts or typography controls,
extend the compositor deliberately rather than inventing unsupported fields.

## Duo geometry

Use separate specs for inner and outer displays, with the matching native
capture and accepted output dimensions from the upload requirements. The
canvas still has design width 1320; available design height is
`outputHeight * 1320 / outputWidth`, much shorter than a regular phone.
Retune headline size, device top/width, and breakouts for that height; ensure
the caption, UI proof, and any required footnotes fit. Preserve capture aspect
ratio. A correct-size PNG with hidden or clipped proof is not a finished frame.
Inspect each display's own full-size frames and aspect-correct review sheets.
