# Light standard

Status: **v2** (2026-11-07, [ADR-0021](../adr/0021-reference-light-targets.md)).
v1 ("true darks, never lifted blacks") is archived in
[`archive/light-standard-v1.md`](../archive/light-standard-v1.md): every
reference the founder likes failed it. Numbers:
[`design/art/light-standard.json`](../../design/art/light-standard.json);
the light itself (key direction, rim, fill, shadow hue, fog) is read from
[`design/art/colour-script.json`](../../design/art/colour-script.json) and is
never duplicated. Why the references look the way they do:
[reference look](../research/reference-look.md).

## Rules

1. **The reference envelope.** A high-key picture inside one envelope of
   soft air: values between a light mid-tone and cream (day L* p5 >= 50,
   p50 74-92, p98 >= 90); the darkest recesses are a mid-value in the
   shadow hue, never black; no dark outlines; colour lives in the
   halftones, lights bleach to cream.
2. **Night is a hue change, not a value drop.** Only the sky goes dark
   (L* 24-46); the island stays light (p50 66-88) with violet shadows and
   cream practicals whose glow spreads 3-4x the lamp.
3. **The cloud sea is a reflector:** the brightest large surface (L* >= 82
   by day, >= 70 at night); the island's underside takes its bounce.
4. **One soft texture scale.** Local contrast stays inside the cell's band;
   above it reads "too contrasty" (the Tam Çiçek night, 6.6, fails night).
5. **Sprites** (a transparent char, station, prop, decor or far-view piece)
   are painted under the **day** cell with no cast shadow, only contact
   occlusion; code relights and grades them. A manifest that asks a sprite
   for another cell is rejected. **Plates and concepts** (opaque) may paint
   any cell and seat objects on soft occlusion pads in the cell's shadow hue.
6. Layers: `subject` (the clearest forms), `near`, `far` (lighter and
   flatter, toward the fog colour). The key direction is never hard-coded
   (`style-anchor-v2` defers to the LIGHT block).

## Manifests

Every job (or `defaults`) of a **new** manifest carries
`light: {cell: day|dawn|golden|dusk|night, layer: subject|near|far}` for
every kind except `icon`, `ui`, `widget`, `appicon`; grandfathering as before
(`pipeline.light_required`). `compose_prompt` appends the block rendered by
[`tools/imagegen/light.py`](../../tools/imagegen/light.py): the hour, key,
fill, rim, shadow hue, the envelope and, at night, the hue-change rule.

## QA (`qa.check_light`)

Measured by `light.measure_light` at 800 px on the **subject region** (a
sprite's alpha, or x 20-80 %, y 30-90 % of an opaque take) and, for an
opaque take, on the whole frame:

| Check | Metric | Meaning |
|---|---|---|
| `light_values` | L p5 >= `p5_min`; p98 >= `p98_min` | darks stay a light mid-tone (eyes, under 5 % of a sprite, may go below); lights reach cream |
| `light_median` | L p50 inside `median` | the key's value |
| `light_contrast` | p75 local std of L (9 x 9) x 100 inside `lc_p75` | one soft texture scale; not mush |
| `light_sky` | mean L of the top eighth inside `frame.sky_L` | opaque takes |
| `light_sea` | mean L of the bottom eighth >= `frame.sea_L_min` | the cloud sea as reflector |
| `light_dark` | % below L* 30 under the top quarter <= `frame.dark_max` | only the sky is dark |

`warn` at the target, `fail` past `fail_slack`; `enforce: false` turns a
production fail into a warning; exploration jobs are advisory. An opaque
interior with no sky or sea will warn on the frame checks: read them as such.

## Calibration (2026-11-07)

Every liked reference passes its cell (`test_light.py` keeps it so):

| Image (cell) | p5 | p50 | p98 | lc | sky | sea | result |
|---|---|---|---|---|---|---|---|
| I1 summer, spring, autumn, rain, snow (day) | 56-64 | 78-86 | 95-97 | 4.2-5.7 | 74-91 | 89-92 | pass |
| I1 summer evening (golden) | 58 | 74 | 90 | 4.1 | 73 | 84 | pass |
| gezgin f2 night t1, t2; Revontuli stuck; I1 snow night (night) | 49-59 | 77-84 | 93-94 | 2.4-4.7 | 25-44 | 74-85 | pass |
| Tam Çiçek night t1 (night) | 49 | 73 | 93 | **6.6** | 36 | 83 | fails contrast |
| R1 `pofu-hamster-base` (day) | 59 | 89 | 98 | 4.7 | - | - | pass |
| earth band `island-main-band2` (day) | **26** | 64 | 89 | 2.5 | - | - | fails |
| game Home 22:30 before ADR-0021 (night) | **24** | **39** | 63 | 5.5 | 20 | **46** | fails |

## Fixing a take without regeneration

`tools/art/grade_take.py` moves a take into its cell x layer and writes
`<stem>--graded.<ext>` next to it: a toe lift of the darks to the floor,
tinted toward the take's own air colour and weighted by depth; a white point;
gamma to the median band; softening when local contrast is above the band
(or a little form back when it is below). A take already inside is left
alone. It cannot repaint a black fringe into a lit rim: the paint has to.

```sh
python3 -I tools/art/grade_take.py --cell day --layer subject TAKE.webp --sheet before-after.jpg
```
