# 0022. Plate-first islands: the painted plate is the final picture

- **Status:** Proposed
- **Date:** 2026-11-08

## Context

The founder says the islands still look pale against the concepts and asks
us to rethink, from zero, how island art is produced, starting with the next
unbuilt island, Revontuli. `docs/research/pale-assets.md` measured why: the
art is close to the references in lightness and mean chroma, but (1) runtime
layers lay a cream veil of about 35 % over an island at its stop (gain 0.64,
lift 0.32; darks 5.5 % to 0 %; chroma −76 % at night); (2) the island fills
17 % of the portrait frame under a sky and sea of half the reference's
chroma; (3) props have a third less peak chroma and a third of the accents.
Delivery at half resolution costs 38 % of the fine detail.

Causes 1 and 2 are runtime and camera: they can and should be fixed for the
old technique too. What only a production change fixes is shared light
(bounce, contact, occlusion painted together), accent density (a field, not a
pot) and detail. Çağlayan already draws one painted plate per stage, so the
real question is who owns the island's final pixels: the painting, or a
stack of grades, LUTs, fog and haze over neutral files (ADR-0018,
lock-light).

Forces: fidelity to the concept; positions that hold across stages (taps,
characters, upgrades); memory and battery; the founder's time running
Codex (decided by benefit, not by count); upgrade and decor flexibility;
animation and life.

## Options considered

1. **(a) Sprite assembly at its best** (the home today plus look pipeline v2
   and the home-flow layout work). Every part moves, levels up and relights
   alone; any order of upgrades works. Without the veil and with better
   framing it closes causes 1 and 2; it keeps the isolated light (no bounce
   or contact) and the one-object-per-sprite density.
2. **(b) Paint, then cut into layers** (`reference-look.md` §6.1, the shape
   of batch 68). Shared light in the base, but the cut brings the runtime
   stack back for every layer, cut edges need repair, 9 jobs per island
   (stages, two bares, life, upgrades).
3. **(c) Pure plate-first, no cut.** One painted plate per stage with
   everything in it; stage change by a diff-mask reveal; characters and life
   as sprites lit from the plate; code layers only for what moves; tap
   polygons; painted night. Highest fidelity, but an upgrade bought between
   stages needs a repaint of the plate.
4. **(e) Hybrid plate-first.** As (c) for the static island, plus: what moves,
   is placed or is upgraded is a sprite, and every such sprite is **cut from
   an edit of the island's own plate** (the upgrade painted in place, then
   extracted with its diff mask), so it carries the plate's light, snow and
   contact. Free order of upgrades, no full repaint, shared light kept.
5. **(d) 3D blockout plus AI paint-over.** Best registration and any camera,
   but a tool chain the team does not have and style drift between renders.
   Revisit only if Codex cannot keep stages registered.

The pilot (`docs/research/plate-pilot/plate-pilot.jpg`) shows (c)/(e) keep
the island within 0 to 1 dE2000 of the painting where today's path loses 13
to 21. That is partly circular (the stand-in plate is the concept); the real
test is batch 68's registered stages.

**Proofs of the risky mechanisms** (`plate-pilot/mechanisms.jpg`): a
character behind a painted spruce through an occluder mask; a sway mask that
moves only the tree (0 pixels outside its mask); a tap highlight on the
sauna's silhouette; character light sampled from the plate (gain 0.90/0.68/
0.77 in the sauna's lee against 0.93/0.73/0.80 on open snow). And one
failure: an existing sprite (the home bench) inserted with plate light and a
contact pad still reads foreign (no snow, wrong style). That is why (e) cuts
upgrades from plate edits instead of reusing sprites.

## How plate-first handles each concern

| Concern | Mechanism |
|---|---|
| Stage change | crossfade of two plates through a diff mask (`ingest.py diff`), revealed as a ring from the cure's source (the lantern, the falls), 2.4 s; Reduce Motion: a 0.3 s plain crossfade |
| Sway (trees, grass, flags, cloth) | a sway mask per object (polygon plus plate alpha, foot line fixed): a vertex or `distortionEffect` shift growing with height, 2 to 5 pt; proven, nothing outside the mask moves |
| Flicker (lanterns, windows, fire) | emissive masks (a light-only layer cut from the painted night plate minus the day plate): code modulates their glow and bloom |
| Water, steam, smoke, snow, aurora, wind | code layers on top: UV scroll or shimmer inside a water mask; smoke and snow particles; aurora light-on-black curtain cards (batch 53's `revontuli-aurora-1/-2`; the pilot's procedural curtain is a placeholder); wind drives the sway masks' amplitude |
| Practicals and day/night | each painted light is its own plate; the time of day crossfades between painted plates (or their LUT-fitted versions, below); emissive masks keep lights alive while the crossfade runs |
| Characters' shadows on the plate | contact pad in the plate's own shadow tone (ratio shadow/lit sampled under the feet); cast shadow: the sprite's silhouette sheared along the painted light direction (stored per plate), multiplied the same way |
| Plate objects' shadow on characters | the sprite's gain comes from the plate's light sampled at the feet each frame it moves (a coarse light map baked by `ingest.py`, 32 x 20); a character in the sauna's lee is darker and cooler |
| Occlusion (walking behind a tower) | occluder masks with a foot line: a character whose feet are above an occluder's foot line is drawn under that occluder's plate pixels redrawn on top; proven |
| Upgrades and decor | (e): Codex paints the upgrade into the island's stage plate as an edit; `ingest.py` cuts it out with its diff mask as a sprite with the plate's light, snow and contact; appears with the reveal; any order |
| Taps and feedback | hit polygons in plate pixels (`ingest.py polys`); the tapped object lifts 6 % with a warm rim on its silhouette only, 0.25 s; VoiceOver labels per polygon |
| Seasons | islands keep their own season (Revontuli is polar night); the home's seasons stay on the home's sprite path; if an island ever needs seasons, a fitted LUT plus code snow or leaves, painted only if the LUT fails |
| Wellbeing states | never a veil over the plate: wellbeing moves the sky, the sea, the amount of life and the aurora's strength, and at most a 10 % desaturation LUT on the plate |
| Reduce Motion | sway, shimmer and aurora drift stop; the plate is still; reveals become 0.3 s crossfades |
| Memory | one plate per light per stage, ASTC in the asset catalog: a 1536 x 1024 plate is about 1.6 MB on the GPU; two during a reveal, plus an 8-bit diff mask: under 6 MB per island; masks 8-bit at half size |
| Battery | a static texture; at rest only the code layers tick, and the settled state is 0 Hz (FramePolicy) |

## Painted light states: decided by evidence

`tools/plate/light.py` fits a LUT on one painted day pair and applies it to
another plate, against that plate's painted truth (dE2000 over 3 x 3 cell
means; `plate-pilot/light-fit.jpg`). The pairs are independent takes, so this
is a lower bound; registered pairs of one island will fit better.

| Light | Untouched day | Fitted LUT | Floor (two painted takes) | Seen on the sheet | Call |
|---|---|---|---|---|---|
| Golden | 13.8 | **5.7** | 2.4 | the palette, but no low warm key, rim or lit lanterns | fit, from one painted golden at stage 4 of the same island |
| Rain | 7.2 | **4.1** | 3.2 | close; rain is a colour shift plus FX | fit; the rain itself is code |
| Night | 13.9 | **6.5** | 4.8 | a blue day: no lit windows, no moon rim, no light pools | **paint every stage** |
| Cross-island (cl1 plates) | 4.4 / 17.0 | 11.1 / 12.9 | n/a | worse or barely better than nothing | a LUT is fitted per island, never shared |

Options, per island (jobs; Codex makes two takes per job):

| Option | Painted plates | Upgrade patches (3 upgrades) | Jobs |
|---|---|---|---|
| **L1 (recommended)** day and night at every stage, golden at stage 4; golden, dusk, dawn and rain fitted | 5 + 5 + 1 = **11** | day and night: 6 | 17 |
| L2 every light painted (day, golden, dusk, night) | 20 | 12 | 32 |
| Revontuli (its own polar night) | 5 night | 3 | 8 |

L2's extra 9 plates buy golden and dusk with real directional light; the
evidence says golden fitted from the island's own painted golden is close
(5.7 against a 2.4 floor, before registration). If the founder sees a flat
golden on the first island built, add golden per stage (+4 plates).

## Decision

Proposed: **(e) hybrid plate-first with L1**, piloted on Revontuli. The
painted plate is the final picture of the island; the runtime adds only light
and life on top and never grades, fogs or hazes it. Upgrades and placed
things are sprites cut from edits of the island's own plate. The island stop
frames the island larger (about 1.35 screen widths, the lawn at the frame's
middle). Independently of this ADR, the veil at island stops and the sky and
sea chroma are fixed for every island, so the founder compares (a) at its
best against (e), not against today's veil.

## Consequences

- Easier: the island on screen equals the concept; no per-island grade, LUT,
  fog or haze tuning; a settled island costs 0 Hz.
- Harder: stages and upgrade edits must register with the final (review rule:
  nothing moves); an upgrade is a Codex edit, not a free placement; lights
  that are not painted come from per-island fitted LUTs.
- Must do: the runtime and tooling in `docs/design/plate-islands.md`; change
  the prompt blocks from "muted, lifted toward cream" to "high-key with
  saturated accents and true darks" (a manifest change for the founder's next
  batch, not made here); keep L1/L2 open until the founder sees the first
  golden.
- Amends ADR-0018 and lock-light for plate-first islands only: plates are
  delivered at full resolution with `detail.keep 1.0` and are not graded at
  runtime. The home and sprite islands keep their rules until repainted.
