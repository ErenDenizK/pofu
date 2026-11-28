# Feel and world: the look at proofs 1 to 4

Fable, 2026-11-15. The 1:1 look that `feel-and-world-v1.md` section 3 promises before the founder sees a proof. Judged on crops at device scale from the builders' stills (PRs #465, #463, #466) and on frames taken from the clips at two per second. I did not watch the clips play, so pacing and easing are not judged here. Founder-input 28 is taken as given: stations wear their own level, 120 Hz only under the finger, Codex order as proposed.

## One defect in three proofs

Every far and mid frame in proofs 1, 2 (mid 0.90) and 3 shows the island plate as a **rectangle**: straight vertical edges in the sky, cut clouds and repeated cloud shapes beside them, the lighthouse beam cut flat. The plate carries its own painted sky and is laid over another sky. The founder's complaint was "blending", and he will read this as the same fault whatever the proof is about. Scout fact 3 of v1 (are the plates matted to alpha?) is now blocking.

## Verdicts

| Proof | Fit to show? | Result |
|---|---|---|
| 1 Station looks | One still only | Upward holds. Downward fails by script |
| 2 Near and mid | Near: yes. Mid: after a fix. Dressing: no | Macro holds |
| 3 One camera | No, one fix away | The depth function removes the double exposure |
| 4 Water | Yes | The region shader stays inside the water |

**Proof 1.** At mid distance all three composites pass. At near they differ:

- *Rich look on an early plate* reads as painted there. Remaining: a smear at the roof's left edge, a faint ghost behind the kettle, and at night a green fringe on the left post. A feathered matte fixes these (Sonnet, hours).
- *Humble look on a late plate:* **the script cannot fill the hole.** Tea stall: a pale arc where the tiled roof was, smeared posts, a green blob hanging over the island's edge, sky showing through at night. Garden: a flat sky-coloured wedge where the island's rim should be, and an orphaned lamp globe. This is the risk v1 named.
- Fix: Codex erases the station from the plate (2 pilot jobs: tea stall and garden on the level 10 day plate), then Sonnet recomposites. The humble stills are not shown before that.

**Proof 2.** Pofu and Mochi stay sharp at half the screen, and the blurred ground reads as depth of field, not as a weak texture. The 4.5 frame is the best picture of the set: the village is legible behind him. The 2.7 cap is sharp everywhere with Pofu a sixth of the width, which is "close", not "near".

- Dressing frames (c): the old sprite props are flat and pale beside the plate, and their blurred foreground copies keep a dark outline and cover the lower third. The layout lesson stands: sharp props beside the feet work; large blurred foreground shapes do not.
- Night: the character sits under one flat violet wash, which at half the screen looks like a filter. Pass 2 must light near characters from the lamps.
- Mid: 0.90 has the rectangle and 1.15 cuts the harbor islet. Neither is the answer. Add a third still fitted to the island's own box (Sonnet, hours).

**Proof 3.** Clip a reproduces the complaint honestly: near 3.5 s the whale, the far isles and both neighbour islands are double-exposed. Clip b has no doubles, and whale, isles and clouds shrink with the island. It fails on two other things: the cloud floor is mirrored to fill the frame, which draws two horizontal bands behind the lower islands, and the rectangle. Fix (Sonnet, half a day): matte the island layer and replace the mirror with one tall seamless cloud floor. If a script cannot make that tile, it is one Codex job.

**Proof 4.** Frames are clean in all three. b moves the fall only; c moves the fall, the pool, the stream and the three basins, with no change outside the water. In all three the foam, the rainbow and the mill wheel are frozen, and beside moving water they become the stillest things on the island.

## What the founder is shown, and chooses

| File (under `proofs/`) | One line |
|---|---|
| `1/tea-rich-on-early-day-near.png` | A grand stall on a young island: what "wears its own level" looks like |
| `2/near_pofu_a_plate_cap2.7.png` | Near option A: everything sharp, Pofu small |
| `2/near_pofu_b_macro_4.5.png` | Near option B at a resting distance |
| `2/near_pofu_b_macro.png`, `2/near_mochi_b_macro.png` | Option B at its limit, on Pofu and on Mochi |
| `4/water-a-still.mp4`, `4/water-b-falldetail.mp4`, `4/water-c-region-shader.mp4` | Today; the fall alone; all water |

He chooses the near look (A or B) and the water (b or c). I recommend B and c. Mid and the camera wait for the fixes above.

## What changes in the plan

1. **Erase edits are needed, not conditional.** Budget the 20 jobs, after the 2-job pilot proves a recomposite at near.
2. **The matte is the first build step,** for the plates and for the island layer of the sky. One camera cannot hold while the island is a rectangle.
3. **Near gets a resting distance.** A double tap on a character lands at about 4.5; pinch goes on to 7.4. Proof 2 supports macro with dressing as mid-ground props only; blurred foreground props leave the plan.
4. **Mid is a fit to the island's box,** not a constant in screen widths.
5. **The sky needs one cloud floor tall enough for the Map.**
6. **Water adds two small items:** foam shimmer inside the mask and a turning wheel.

## Codex near-dressing pilot: three jobs

Common to all three: painted in the Home day plate's soft clay style and light (check the key direction against the plate before writing the prompt), not in the characters' fur-line style and not in the sprite island's flat style. Transparent background, no outline, no baked cast shadow (code draws the contact shadow), a flat base that sits on grass. Day only. References are 1:1 crops of the level 10 day plate. Each object is at least 400 px on its long side, because near needs 0.9 art px per device px.

| Job | Content | Reference crop |
|---|---|---|
| `near-tufts-daisies` | 4 objects: 2 grass tufts, 2 clumps of 3 to 5 daisies with leaves | The plate's white daisies and grass rim |
| `near-pebbles-clover` | 4 objects: 2 groups of 2 to 3 cream pebbles, 1 flat stepping-stone piece, 1 clover patch | The plate's stepping stones |
| `near-tea-stool` | 1 object: a tulip tea glass on its saucer on a low wooden stool | The rich stall's stools and glasses |

Accept when each object, placed beside Pofu in `near_pofu_b_macro.png` at 1:1 and again at 2.7, reads as part of the plate and not as a sticker.
