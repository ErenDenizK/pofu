# World concepts: choosing the picture before the system

Fable, 2026-11-15. Answers founder-input 33; extends `world-presentation-v2.md` (v2). Manifest:
pofu-art `batch-112-world-concept-frames` (pofu-art PR #75), first in Codex's Demand queue.

## The decision

He is right, and the round-3 stills show why. They pass C1 to C6 and are still not pictures: the Map
reads as two images stacked (a sky with two islands over a floor with one), mid's lower third is white
fog that only the chrome fills, near is one even blur under a sharp hamster. The rules place things;
nothing in them says what the light and the air do or where the eye goes. A concept frame decides
that, and no script can. So the concepts are **the target for the look and a check on the system**;
the script proofs stay as the statement of what can be placed. Neither replaces the other.

## What Codex paints (8 jobs, 2 takes each, day)

- **Four locked paint-overs** of R1's stills: the Map in both orders (so the order is chosen between
  two finished pictures), mid level 10 with chrome, near at rest. Nothing moves; only light, air,
  cloud and focus are painted, so whatever they show can be placed.
- **Three free paintings** (Map, mid, near): the same islands, chrome and canvas, composed fresh.
  They ask whether a better picture exists than the system's; one that wins changes v2.
- **One storyboard, five beats, far to near:** Map, descent, mid, push-in, Pofu. It passes through
  both rests and covers both everyday moves. Its guide's panels are cut at the rail's true cameras.
- **Canvas:** the tool paints 1024 x 1536, so the phone frame is the middle 706 px: 0.59 of device
  resolution. A concept is judged as a picture, never for edges or detail.

## What he looks at now, and what waits

- **Now:** `r3b/sheet-worst-edges-4x.jpg` and the two life clips. Edges and speed are not picture
  questions; no concept changes them.
- **After the concepts:** the Map order, mid and near. The flat Map stills alone would ask him to
  choose an order from the weaker half of the evidence.

## Review, before anything reaches him

1. `tools/proof/concept_fit.py` (to write, half a day): crop x 159 to 865, scale to 1206 x 2622,
   paste the real chrome back, print how far each island box moved from the guide. A locked take
   that moved a subject over 12 px is not shown as locked.
2. I look at every take at device size and write a **buildability ledger**: each thing the picture
   adds is plate art, cloud kit, grade or shader, new art, or not buildable. A take whose beauty is
   mostly not buildable (a redrawn island, an invented building) is not shown.
3. He gets one sheet per distance on his phone: script proof, locked concept, free concept; then the
   storyboard. He picks one frame per distance, or none.

## How the pick becomes the spec

- The pick and its ledger are committed under `docs/design/assets/world-concepts/`; v2 cites it.
- **The match proof:** the script is re-rendered to match the pick and shown beside it. Measured on
  both: luminance and saturation per band, puff size by row, haze by depth, blur radius by row. The
  gap left is stated as what will not be built. Swift starts from the match proof, not the concept.
- Crops of the pick become the style references of the cloud kit and near jobs; R4's depth still
  must match the picked near frame.

## What changes in v2 if a concept beats the system

| If he picks | v2 changes |
|---|---|
| A locked frame | Positions stand. Section 2 gains haze per layer (tint and contrast by `k`); the cloud kit (8) is re-briefed from it; `N` and the blur cap (5) are fitted to it |
| The free Map | 1.3's positions, tier frames and horizon are re-derived from it; C1 and C2 take its values |
| The free mid | 1.4's fit, anchor and lip height follow it; the chrome boxes do not move |
| The free near | 1.5's rest framing follows it; a soft foreground lifts 5.3's ban for one declared layer |
| A camera height other than 10.5 degrees | Not buildable on painted plates; he is told so, and the match proof is the nearest frame |

Unchanged by any concept: stations wear their own level, one camera, the chrome bands, C4 to C6, the
edge standard, and the far picture as a snapshot of mid (the storyboard guide shows why: the Map's
Home is a different island from mid's).

**Limits.** No image exists yet. Whether the model holds a layout in a paint-over is what the first
job tests; if it redraws the islands, the locked jobs fall back to painting only the backdrop behind
masked islands (one more manifest). Golden and night follow the pick.
