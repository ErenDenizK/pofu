# Asset pipeline

`process_assets.py` turns raw AI-generated PNGs into validated, consistently
framed assets in an Xcode asset catalog. It enforces the measurable rules of
the [art bible](../../docs/design/art-bible.md); the human still judges the
rest (species, expression, charm).

It does **not** touch the Xcode project. Output goes to a folder you choose;
copying an approved catalog into `App/Resources` is a deliberate, reviewed
step.

## Setup

Python 3.10 or newer, Pillow, and numpy. No network access and no model
downloads are needed.

```sh
python3 -m venv .venv
.venv/bin/pip install -r tools/assets/requirements.txt
.venv/bin/python -I tools/assets/process_assets.py selftest
```

(On a machine where Pillow and numpy are already installed, plain
`python3 -I` works.)

## The inbox convention

Save every generation you want to keep as `<kind>__<name>[--<variant>].png`
in an inbox folder (`design/art/inbox/` is git-ignored for exactly this):

| Kind | What | Alpha | Minimum source | Output |
|---|---|---|---|---|
| `char` | Pofu poses and expressions | required | 1024 px | 320 × 320 pt; one shared scale, feet on one ground line (92 % down), feet centered |
| `sprite` | Props and stickers (seed, wheel, tea glass) | required | 512 px | 96 × 96 pt, trimmed, 6 % padding |
| `badge` | Achievement medallions | required | 1024 px | 120 × 120 pt, trimmed, 3 % padding |
| `scene` | Background plates | none | 1024 px | 440 pt wide, aspect kept; warns above 1× upscale at @3x, fails above 1.5× |
| `icon` | App icon | must be opaque | 1024 px | `AppIcon.appiconset` (1024 × 1024); `--dark` and `--tinted` variants |

Examples: `char__pofu-content.png`, `char__pofu-curious.png`,
`badge__first-resist.png`, `scene__meadow-day.png`,
`icon__app-icon--dark.png`. Files that do not match are skipped and listed.

Override any value per kind with `--config overrides.json`, for example
`{"char": {"point_size": [280, 280]}}`.

## Process an inbox

```sh
python3 -I tools/assets/process_assets.py process \
  --inbox design/art/inbox \
  --out build/PofuArt.xcassets
```

For every file the tool:

1. **Validates** the minimum resolution and, for sprites, transparency. App
   icons must be fully opaque.
2. **Keys out a flat background** if a sprite arrived without alpha
   (`--key auto`, the default; `--key off`; or `--key '#00FF00'`). Only
   background connected to the image border is removed, so cream fur inside
   the silhouette survives, and semi-transparent fringes are unmixed from
   the background color so there is no peach halo on a violet screen. If
   keying leaks into the silhouette (a white character on a near-white
   background), the file **fails**: regenerate on transparency or chroma
   green.
3. **Warns about a painted ground shadow.** The app draws contact shadows
   itself so they can squash with a hop.
4. **Reports palette drift**: the CIELAB distance of each solid pixel from
   the nearest mix of two locked colors in
   [`design/tokens/pofu-tokens.json`](../../design/tokens/pofu-tokens.json).
   Mixes count as on-palette because painted shading is a mix. Calibrated on
   the concepts: the approved hamster scores mean ΔE 1.5 (ok); the lilac
   chinchilla scores 5.3 (fail).

   | Status | Mean ΔE | p95 ΔE | Off-palette pixels (ΔE > 12) |
   |---|---|---|---|
   | ok | ≤ 2.5 | ≤ 9 | ≤ 3 % |
   | warn | ≤ 4.5 | ≤ 14 | ≤ 10 % |
   | fail | above | above | above |

5. **Trims and normalizes** (see the table above), resampling once from the
   source to each of @2x and @3x in premultiplied alpha.
6. **Exports** image sets with `Contents.json` files Xcode accepts, grouped
   in namespaced folders (`Character/`, `Badges/`, `Stickers/`, `Scenes/`).

A JSON report is written next to the catalog (`PofuArt-report.json`) with
every check, the keying details, and the registration geometry. The exit
code is 1 if any file failed; failed files are not exported unless you pass
`--allow-failures`.

### Companion art (base image and lid plate)

The companion motion system animates one base image plus a lid plate (the
eyes painted out with fur) and a set of rig landmarks. Process the two as
one character group, for example `char__pofu-content.png` and
`char__pofu-content--lids.png`: they share a silhouette, so they get the
identical scale and placement and stay pixel-aligned. Measure the rig
landmarks on the normalized output, not on the raw generation. The
companion package loads plain PNGs from its resources, so copy the `@3x`
file out of the image set rather than the catalog.

## Slice a sprite sheet

GPT Image draws short animations as one grid (see the
[prompt library](../../docs/design/prompt-library.md)). `slice` cuts the
grid, registers the frames, and writes an image sequence plus a manifest.

```sh
python3 -I tools/assets/process_assets.py slice \
  --sheet design/art/inbox/sheet__pofu-blink.png \
  --name pofu-blink --grid 4x4 --frames 12 --fps 12 \
  --out build/animations
```

- **Cutting** snaps each grid line to the emptiest column or row within 8 %
  of the even position, so slightly uneven layouts still cut cleanly
  (`--no-snap` disables it). Stray slivers of neighbouring cells are
  dropped by keeping the largest figure in each cell.
- **Registration.** `--register feet` (default) puts every frame's feet
  center and ground line on the same canvas point, so in-place loops
  (blink, breathe, cheeks filling) do not jitter. `--register cell` keeps
  the figure where it was drawn in its cell, for frames that genuinely
  leave the ground. Prefer `feet` and let the app animate the hop path with
  a spring.
- **Consistency report.** Each frame gets a palette drift score and is
  compared with the sequence median: mean color shift above ΔE 4 or a width
  change above 12 % is flagged (scale drift or an extreme squash; you
  decide).
- **Output.** `<out>/<name>/<name>-00.png …` at source resolution, or
  `@2x`/`@3x` files with `--point-height 120`. `manifest.json` records fps,
  loop, duration, canvas size, the anchor point (feet) in pixels and unit
  coordinates, the source cell of every frame, and every check.

Know the limit: a 4×4 sheet in a 1024 px image gives 256 px cells, enough
for about 85 pt at @3x. Use sheets for small or medium animations
(celebration bursts, stickers, widgets) and as key-pose plans; hero-size
frames come from single 1024 px edits.

## Palette card

```sh
python3 -I tools/assets/process_assets.py palette-card \
  --palettes character --out build/palette-character.png
```

Renders the locked palette as unlabeled swatches to attach to prompts as a
color reference. There is deliberately no text: image models copy text.

## Why not automatic background removal

ML matting tools such as `rembg` download their models from GitHub
releases at first run, which the agent environment blocks, and add a
large dependency for a problem we can avoid upstream: GPT Image can output
transparent PNGs, and the chroma-green fallback keys cleanly with the
built-in keyer. If a future asset genuinely needs matting, run it on the
Mac and feed the result in as a transparent PNG.

## Self-test

```sh
python3 -I tools/assets/process_assets.py selftest
```

Uses the approved concept crop in `docs/brand/assets/concepts/` and fixtures built from
it: keying keeps the cream face, a leak through a gap in the rim fails, a
channel-swapped hamster fails the drift check, two character frames at
different sizes and positions come out with one ground line and one scale,
badges are centered and padded, icons with transparency fail, scene
upscaling is reported, a jittered 3×3 sheet slices into perfectly
registered frames, and `cell` registration preserves a hop. About 20 s.
