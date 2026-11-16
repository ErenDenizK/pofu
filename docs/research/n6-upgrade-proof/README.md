# N6: does a station's level show on the island?

Proof for step N6 of `docs/design/night-plan-2026-11-15.md` (rank 1: building changes nothing on screen).
Batch 123's tea-stall looks 1, 3 and 5 (cut-outs, the lead's picks) set on batch 117's erased Home base, at the
three rail stops. Nine frames at 1206 x 2622 (`stall<level>-<map|mid|near>.jpg`, q88), one sheet (`sheet.jpg`:
the nine frames, and the stall at 1:1 under each), and 1:1 crops in `crops/` (stall foot on the ground, stall
edge against the plate and the cart).

## How
`python3 -I tools/proof/upgrade_proof.py --art DIR --erase TAKE.webp --out DIR` (needs the island matte's model once).

- **Art.** pofu-art picks: look 1 = take 1, look 3 = take 2 (look 2 take 1, look 4 take 1, look 5 take 1, as
  recorded in each `review.yaml`; only 1, 3, 5 are drawn). Base: batch 117 `x-base-erase-l03-day`, pick 1 (stall and
  cart erased). Batch 117 is not on pofu-art `main`; it is on `origin/art/batch-117-station-erase-volume`.
- **Base.** The take re-renders the whole plate, so it is not used whole: the level 3 day plate (stage 7, island
  cut by `island_matte`) takes the take's pixels only where the old stall was (the diff of take and parent, closed,
  grown 8 px, feathered 3 px). The rim, the cart, the rope bridge and the islet stay the parent's, as the lead's
  review of that take asks (the take also drops the bridge). The island's alpha may only shrink inside the paste
  (the old counter hung over sky), never grow.
- **Ingest notes of 123, applied.** Chroma x0.65 and lightness +5 percent (CIELAB), alpha below 12/255 set to 0, a
  soft contact shade under the foot (drawn by the script; the app will draw its own). One scale (0.294 of the 1254 px
  canvas) and one foot anchor for all five looks, taken from look 1 against the plate's own stall, so the counter
  stays put from level to level. The pennant of look 3 is not cropped.
- **Placement and cameras.** The stall's slot is `teaStall` in `plate-home.json` (box 629..774 x 648..852 plate
  points, foot y 845); the stall is placed on the plate's own stall. Stops are the shipped rail, computed from the
  Swift: Map = `HomePlate.mapStop` at tier 0 (Home alone, 0.853 pt per unit), Mid = `islandStop` (0.9 widths, 1.096),
  Near = `homeStop` (1.40, top at 292 pt). The stall is 40, 52 and 66 pt wide at them. The sky is the sky set at one
  camera (`skyset_still`), the same in every frame; no Pofu, Mochi or chrome is drawn.

## The five checks of batch 123 (my own verdicts)
1. **Identity: pass.** Look 1 is the plate's own stall (stave counter, scalloped cream and yellow awning, white teapot),
   not a new design; set over the erased spot it reads as the same stall.
2. **The ladder: pass.** Counter, posts and teapot do not move between levels 1, 3 and 5 (one transform); each level
   only adds its named parts (lantern post and cloth table; stools and pennant; bulbs, pot, tray, small awning, flowers).
3. **In place: pass with two notes.** Light and softness match; graded chroma is close (awning 20 to 23 against the
   plate's 24.8, 9 to 18 percent under; staves 33 to 35 against the lead's 32). Notes: the take's grass beside the stall
   is slightly yellower than the parent's below it (a faint patch right of the counter in `crops/foot-*`), and the table
   of looks 2 to 5 stands on a tripod foot the contact shade does not cover, so it floats a little.
4. **Cut-out (`matte_check.py --kind prop`): fail.** On the five picks M1, M5 and M6 pass; M2 (edge width p95, limit 2)
   reads 2.55, 6.89, 3.40, 12.55, 2.77 for looks 1 to 5 and M4 (specks and holes) fails on all five (1084, 233, 476,
   375, 449). Not visible at 1:1 in the frames, but the cut-outs are not clean to the lead's gate.
5. **It reads at mid: partly.** At the Island stop (52 pt) level 1 against 5 is told apart at a glance (the second
   awning, the table, the bulbs); 1 against 3 reads from the lantern post, table and pennant; 3 against 5 is a
   close call. At the Map (40 pt) only level 5's extra awning and table show; levels 1 and 3 are nearly the same
   picture.

## Findings
- The upgrade is visible at Island and Home, thin at the Map: a station the size of 40 pt cannot carry a ladder there.
- The base is one island level (3); all three stall levels share it, so a level 5 stall on a level 3 island is the
  proof's choice, not a state the player can reach today.
- The Map frames show a pale vertical stripe in the top sky (the sky set's far layers at this scale); not about the stall.
