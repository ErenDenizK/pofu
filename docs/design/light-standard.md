# Light standard

Status: v1, **enforced for production batches** (the lit-ladder pilot shipped,
#231); exploration jobs stay advisory. Originally warn-only (2026-11-03); the
`enforce` flag lives in `design/art/light-standard.json`.

Why: the approved island master and every concept take so far are washed.
They sit in a high, milky value band (L 60 to 98) with no true dark anywhere,
so the island has no weight, depth does not read, and the colour script's light
has nothing to act on. ADR-0018's "less contrasty" meant soft local colour and
soft edges, not lifted blacks. This file is the rule; the numbers are in
[`design/art/light-standard.json`](../../design/art/light-standard.json); the
light itself (key direction, rim, fill, shadow hue, fog) is read from
[`design/art/colour-script.json`](../../design/art/colour-script.json) and is
never duplicated.

## Rules

1. **Sprites** (a transparent char, station, prop, decor or far-view piece) are
   painted under the **day** cell. They carry **no baked cast shadow**, only
   contact occlusion where forms touch. Code relights and grades them for the
   hour and draws contact shadows. A manifest that asks a sprite for another
   cell is rejected.
2. **Plates and concepts** (opaque) may paint any cell. They paint a contact
   shadow in the cell's shadow hue, opposite the key.
3. **Haze is depth, not a filter.** The subject plane uses the full value
   range (true darks in recesses, clean highlights, no atmosphere); contrast
   falls only with layer distance (`subject`, `near`, `far`). "Gentle" and
   "less contrasty" mean soft local colour, never lifted blacks or a milky veil.
4. The key direction is never hard-coded. `style-anchor-v1` hard-codes "upper
   left" and stays for old batches; new jobs use `style-anchor-v2`, which
   defers to the LIGHT block.

## Manifests

Every job (or `defaults`) of a **new** manifest carries

```yaml
light: {cell: day, layer: subject}   # cell: day|dawn|golden|dusk|night; layer: subject|near|far
```

for every kind except `icon`, `ui`, `widget`, `appicon` (those must not declare
one). External jobs are exempt. `pipeline.py` fails without it. Old batches are
grandfathered by `pipeline.light_required`: batch number 20 and up, a
`retry-YYYY-MM-DD` from 2026-11-04, or an explicit `light_standard: true` in
the manifest (batch 19 may opt in early). `compose_prompt` appends the block
rendered by [`tools/imagegen/light.py`](../../tools/imagegen/light.py) before
the output line; it names the hour, the key colour and direction, the fill, the
rim, the shadow hue and where shadows fall, and the layer's value rule.

## QA (`qa.check_light`)

Measured by `light.measure_light` on the **subject region** at 800 px: the alpha
of a sprite, or the lower middle (x 20-80 %, y 30-90 %) of an opaque plate.

| Check | Metric | Meaning |
|---|---|---|
| `light_values` | L p2 at most `p2_max`; p98 at least `p98_min`; spread (p98 - p2) at least `spread_min` | the value range |
| `light_median` | L p50 inside the cell's band | night stays dark, day stays bright |
| `light_haze` | dark-channel p10 (min over RGB, 9 px) at most `haze_max` | no true dark anywhere means a wash |
| `light_contrast` | p75 of local std of L (9 x 9 window) x 100, at least `lc_p75_min` | detail separation |

It generalises `NIGHT_PROFILE` and **replaces `value_floor`** (and
`night_lightness`) for jobs that declare `light`. Limits are `warn` at the
target and `fail` at the target plus `fail_slack` (p2 +18, p98 -10, spread -18,
haze +0.12, contrast -0.6, median +-8). Layers relax the subject numbers: near
(p2 +6, p98 -2, spread x0.85, haze +0.05), far (p2 +18, p98 -6, spread x0.55,
haze +0.18, contrast x0.5). `python3 -I tools/imagegen/light.py FILE --cell day`
prints the measurements and grades for any image.

## Calibration (measured 2026-11-03)

Day / subject targets: p2 <= 22, p98 >= 90, spread >= 60, median 55-90, haze
<= 0.20, local contrast >= 3.5. The starting points held: R1 passes every one.

| Image | L p2 | p50 | p98 | spread | haze | local contrast |
|---|---|---|---|---|---|---|
| R1 `pofu-hamster-base` (approved) | 16.2 | 88.8 | 97.6 | **81.4** | 0.08 | 4.7 |
| `island-main-s` master (approved) | 61.3 | 84.3 | 92.6 | 31.3 | 0.38 | 2.4 |
| `island-main-s--lock-light` | 53.6 | 83.1 | 93.0 | 39.5 | 0.22 | 3.1 |
| `island-main-l` | 65.5 | 85.0 | 92.5 | 27.1 | 0.48 | 1.8 |
| batch 18 `cl1-backdrop-day` t1 | 64.9 | 87.9 | 95.8 | 30.9 | 0.40 | 3.0 |
| batch 18 `cl1-backdrop-dusk` t1 | 65.4 | 85.3 | 93.6 | 28.2 | 0.37 | 3.2 |
| batch 18 `cl1-backdrop-night` t1 | 60.5 | 76.3 | 90.8 | 30.3 | 0.41 | 3.4 |
| batch 18 `cl1-caglayan-pools` t1 | 58.6 | 88.7 | 98.4 | 39.8 | 0.51 | 3.0 |

Findings:

- **The approved island master fails the day-subject cell** (p2 61, spread 31,
  haze 0.38); only R1 passes. The standard therefore says the island is washed;
  it has no value below L 53 even after the lock. Fixing it is a grade (below)
  or a re-paint under the new prompt, not a threshold change. Grandfathered:
  nothing re-checks old masters.
- The batch 18 "dusk" and "night" backdrops are painted in day values (median 85
  and 76), so those hours are wrong at the source; the grade can darken them,
  but a re-paint under the LIGHT block is the real fix.
- Thresholds are the lead's starting points unchanged; the measurements above
  are the evidence that they separate R1 from everything washed.

## Fixing a take without regeneration

`tools/art/grade_take.py` moves a take toward its cell x layer targets and
writes `<stem>--graded.<ext>` next to it (never over it):

1. depth-weighted dehaze (dark-channel prior with the take's own haze colour;
   a plate's far top keeps its atmosphere, the subject plane loses it; skipped
   when haze is already within limit);
2. a lit-too-bright dusk or night comes down first (gamma toward the median band);
3. black and white points on CIELAB lightness only (a and b are kept, a deeper
   tone gets a little chroma back), only when the take misses the target;
4. the median band, a gentle S-curve if the spread is short, and a depth-weighted
   local contrast lift if p75 contrast is short.

```sh
python3 -I tools/art/grade_take.py --cell day --layer subject TAKE.webp --sheet before-after.jpg
python3 -I tools/art/grade_take.py --spec TAKE.webp:dusk:subject --spec OTHER.webp:day:near --sheet s.jpg
```

Graded copies are review material: do not commit them until the lead has
reviewed the sheet.

### Pilot (4 batch 18 takes, `--cell` as the file name says; day for the pools)

| Take | Before p2 / p98 / spread / median | After |
|---|---|---|
| `cl1-backdrop-day` t1 | 64.9 / 95.8 / 30.9 / 88 | 16.6 / 91.4 / 74.8 / 70 |
| `cl1-backdrop-dusk` t1 (as dusk) | 65.4 / 93.6 / 28.2 / 85 | 8.8 / 79.4 / 70.6 / 49 |
| `cl1-backdrop-night` t1 (as night) | 60.5 / 90.8 / 30.3 / 76 | 6.6 / 75.3 / 68.7 / 32 |
| `cl1-caglayan-pools` t1 | 58.6 / 98.4 / 39.8 / 89 | 17.7 / 97.1 / 79.4 / 72 |

All four reach their cell's targets. The grade restores weight and depth
(true darks, a hazy far ring against a clear home island) and does not
oversaturate; it cannot change the painted hour, so the dusk grade is a
darker day, not a sunset.
