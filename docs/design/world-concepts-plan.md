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
- **Now:** `r3b/sheet-worst-edges-4x.jpg` and the two life clips: edges and speed are not picture questions.
- **After the concepts:** the Map order, mid and near; the flat stills alone are the weaker half of the evidence.

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
edge standard, the far picture as a snapshot of mid (in the storyboard guide the Map's Home is not mid's).

**Limits.** No image exists yet. If the model redraws the islands in a paint-over (the first job tests
it), the locked jobs fall back to painting only the backdrop behind masked islands. Day only for now.

## Round 1 result (2026-11-15)
Codex delivered all 8 jobs (pofu-art PR #78). `concept_fit.py` ran on the 14 distance takes; picks and a
buildability ledger per job are in each `review.yaml` on that branch.

| Job | Fit | Shown | What the picture adds, and how it is built |
|---|---|---|---|
| Map, journey order, locked | both within 1 px | t1, as order A | No horizon line; cloud rows that shrink with distance; a bank and shadow under each station; hazed far isles. Grade, cloud kit, shader. All buildable |
| Map, Home first, locked | both within 1 px | t2, as order B | The same. t1 invents far isles. Home is largest in the palest air: the order fights the depth cues |
| Mid, locked | both within 1 px | t1 | Cloud bank round the foot, cast shadow on the cloud, cloud forms behind the controls. Cloud kit, shader. All buildable |
| Near, locked | t2 locked; t1 moved a control 34 px | t2 | Focal plane, contact shadow: shader. Sharp lawn, daisies, a soft foreground that hides the rim: new art. Re-laid stones and a lower windmill: not buildable |
| Near, free | free | t1 | Pofu 2.3 times larger, ground seen from near eye level: a painted near plate, not the 10.5 degree plate |
| Map and mid, free | cut by the crop | none | Composed for the whole 1024 px canvas, not the middle 706. Both free Maps chose order A; the free mid, refit, is the locked mid |
| Storyboard | judged by eye | t1 | Not a paint-over: beat 1 has no stations, beats 4 and 5 drop the camera to the ground. Shown as the mood of the move |

- **Recommendation:** Map order A (journey), mid locked t1, near locked t2 as the buildable target.
- **The paint-over held.** The model did not redraw islands in the Map and mid jobs; the fallback was not needed.
- **Near is the open question.** Every near picture the painter made (locked, free, storyboard 4 and 5) hides the
  rim, sharpens the lawn and lowers the camera. A zoom into the mid plate cannot give that. v2 1.5 and 5 need a
  decision: a near-resolution lawn and one soft foreground layer over the plate, or a painted near plate.
- **Tool:** the horizon reading sits at the search limit (180 px) on every take, because the line is gone, not
  moved. It should read `dissolved`, not `WARN`. A free job's guide needs the phone frame drawn as a border.
- **Key pilot (pofu-art PR #79):** no pick. The job was painted on il9, which is level 9, not level 1. On that
  plate the key fails its acceptance (the field is about 10 off #00FF00, edges p95 14 to 41 px from the source,
  the beam blended into the green) and the network matte passes M1 to M6 and M11. Key-colour masters do not go
  ahead. The edit did clear the hill mist cleanly: the next pilot is a mist-clear edit of the real il1 and il2,
  cut by the network matte.
