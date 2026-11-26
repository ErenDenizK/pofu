# The Gezgin moored at Home (plan row 2b, ADR-0028)

Nazlı, the cloud whale, lies at Home's pier, beside the island, at her level. Code:
`PofuWorld/Gezgin/` (`GezginLayout.swift` pure and tested, `GezginView.swift` the views and the beat).
Data: `world-map.json` `gezgin` (when she is a shadow, when moored, her level, her motions) and
`plate-home.json` `mooring` (her place on the plate: body bottom centre and width, plate pixels).

## What she does

- **Presence.** Koke a hump on the horizon (`rumoured`): her shadow crosses the cloud under the island.
  Koke visitable (`arrived`): she is moored. Before the hump: nothing. Changing the rule is a data edit.
- **Level (D7).** 1 when moored; 2 when Koke is healed; 3 when Çağlayan is healed (`levelAt`; Çağlayan is the
  first main island in `docs/product/story-map/book-one.md`). Retune in `world-map.json`.
- **Pose.** Awake by day and at golden hour, asleep in the night plate. A tap wakes her (a stretch and a hop,
  her line, the app's chime); at night she stays awake `awakeSeconds`, then sleeps again.
- **Motion (D6).** One cut-out per level and pose; the eyes are the swap of the asleep and awake cut-outs
  (and a blink); a bob; the tail piece sways by 1.2 degrees about its root over the painted tail (a larger
  angle shows the painted tail under it). Motion runs in Ambient frames; a still frame is the rest pose.
- **Taps.** `HitTarget.Kind.gezgin`, her body's box (`Gezgin.tapBox`), only while moored and on Home's stops.

## Art and picks

Cut-outs by `tools/art/gezgin_cutouts.py` from pofu-art batches 160 (bodies: `x4-gez-lv1..3-awake`,
`-cut` = eyes shut) and 180 (`x8-gez-lv1..3-tail`, `-shadow`), the QA auto-picks recorded in each
`review.yaml`: bodies lv1 t1, lv2 t2, lv3 t2; tails lv1 t1, lv2 t1, lv3 t2; shadows lv1 t3, lv2 t2, lv3 t2.
All were drawn on the founder's uncle's ChatGPT plan, used with permission. Every piece is cut to one shared
box (760 x 583 px) so code stacks them without registration data. The row's reference for placement is
`x5-gez-moor-home-lv1` t1 (batch 164): her body at plate (765..1015, 925..1100).

Not used here: the front views (batch 171) and the lantern and map-scale states (batch 172) wait for the
voyage row (2c) and the ride (2d).
