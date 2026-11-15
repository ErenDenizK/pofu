# World concepts: choosing the picture before the system

Fable, 2026-11-15. Answers founder-input 33. Extends `world-presentation-v2.md` (v2) and
`world-presentation-round3-look.md`. Manifest: pofu-art `batch-112-world-concept-frames` (pofu-art PR #75).

## The decision

He is right, and the round-3 stills show why. They pass C1 to C6 and are still not pictures: the Map
reads as two images stacked (a sky with two islands over a floor with one), mid's lower third is white
fog that only the chrome fills, near is one even blur under a sharp hamster. The rules place things;
nothing in them says where the light comes from, what the air does with distance, or where the eye
goes. That is what a concept frame decides, and no script can.

So the concepts are **the target for the look and a check on the system**, and the script proofs stay
as the statement of what can be placed. Neither replaces the other.

## What Codex paints (8 jobs, 2 takes each, day)

| Job | Kind | Asks |
|---|---|---|
| `x-concept-map-locked`, `-map-homefirst-locked` | paint-over of R1's two Map stills | Both orders as finished pictures, so the order is chosen between equals |
| `x-concept-mid-locked` | paint-over of `mid-level10` with chrome | The island in a place; a lower third worth looking at |
| `x-concept-near-locked` | paint-over of `near-rest` | A focal plane, not a blur; no foreground shapes |
| `x-concept-storyboard` | paint-over of a five-panel guide | Far to near as one camera move: Map, descent, mid, push-in, Pofu |
| `x-concept-map-free`, `-mid-free`, `-near-free` | fresh, same islands, chrome and canvas | Is there a better picture than the system's? |

- **Locked** frames move nothing, so whatever they show can be placed. **Free** frames may move
  everything but the art, the chrome and the canvas; one that wins changes v2.
- **One storyboard, five beats, far to near.** It passes through both rests and covers both everyday
  moves. Panels 2, 4 and 5 of its guide are cut at the rail's true cameras (0.895, 2.42, 4.5 pt/unit).
- **Canvas.** The tool paints 1024 x 1536; the phone frame is the middle 706 px, so a concept is at
  0.59 of device resolution. It is judged as a picture, never for edges or detail.

## What he looks at now, and what waits

- **Now:** `r3b/sheet-worst-edges-4x.jpg` and the two life clips. Edges and speed are not picture
  questions; no concept can change them.
- **After the concepts:** the Map order, mid and near. Showing him the flat Map stills first would
  ask him to choose an order from the weaker half of the evidence.

## Review, before anything reaches him

1. `tools/proof/concept_fit.py` (to write, half a day): crop x 159 to 865, scale to 1206 x 2622,
   paste the real chrome back with `composition.py`'s `Chrome`, and print how far each island box has
   moved from the guide. A locked take that moved a subject over 12 px is marked, not shown as locked.
2. I look at every take at device size and write a **buildability ledger**: each thing the picture
   adds is named as plate art, cloud kit, grade or shader, new art, or not buildable. A take whose
   beauty is mostly "not buildable" (a redrawn island, an invented building) is not shown.
3. He gets, per distance, one sheet on his phone: script proof, locked concept, free concept. Then
   the storyboard. He picks one frame per distance and may pick none.

## How the pick becomes the spec

- The picked frame is committed under `docs/design/assets/world-concepts/` with its ledger, and v2
  cites it as the target for that distance.
- **The match proof.** The round-3 script is re-rendered to match it, and the two are shown side by
  side. Measured on both: mean luminance and saturation per screen band, puff size by row, haze by
  depth (contrast of each island against Home's), blur radius by row. The gap that remains is stated
  as what will not be built. Swift starts from the match proof, not from the concept.
- Crops of the pick become the style references of the cloud kit and the near jobs.
- R4 (depth) is no longer tuned by model alone: its still must match the picked near frame.

## What changes in v2 if a concept beats the system

| If he picks | v2 changes |
|---|---|
| A locked frame | Positions stand. Section 2 gains a haze term per layer (tint and contrast by `k`), section 8's cloud kit is re-briefed from the pick, section 5's `N` and cap are fitted to it |
| The free Map | 1.3's world positions, tier frames and horizon are re-derived from the picture; C1 and C2 take its measured values; the tier rule (a frame never changes without an announcement) stays |
| The free mid | 1.4's fit, anchor and lip height follow it; the chrome boxes do not move |
| The free near | 1.5's rest framing follows it; if it uses a soft foreground, 5.3's ban on foreground dressing is lifted for one declared layer |
| A different camera height than 10.5 degrees | Not buildable on painted plates. Stated to him as such; the nearest buildable frame is the match proof |

What no concept changes: stations wear their own level, one camera, the chrome bands, C4 to C6, the
edge standard, and the rule that the far picture is a snapshot of the mid composite. The storyboard
guide already shows why that last one matters: the Map's Home is a different island from mid's.

## Limits

No image exists yet; whether the model holds a layout in a paint-over is what the first job tests.
If it redraws the islands, the locked jobs fall back to painting only the backdrop behind masked
islands (one more manifest). Day only: golden and night follow the pick.
