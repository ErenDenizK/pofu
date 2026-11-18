# World presentation v2: the look at proof round 3

Fable, 2026-11-15. The 1:1 look that `world-presentation-v2.md` section 10 promises. Judged on crops at device scale from R1 (PR #471), R2, R3 (PR #470, commit caf23dee, the `r3b` run) and R5, and on frames taken from the clips two seconds apart. I did not watch the clips play. R4 (depth) does not exist yet; it waits on Codex jobs.

## Verdicts

| Proof | Fit to show? | Why |
|---|---|---|
| R1 composition | **Not yet.** Four Map stills and mid level 10 are, after the fix pass | Mid level 1 has a hard vertical seam in the sky right of the island and a ghost of the level-10 fence beside it. The horizon band repeats the same dark lozenge every 150 pt. The whale sits behind Çağlayan (journey, stage 3), behind Home's lighthouse (Home on top) and under the gear (mid). A far isle sits on Koke's slot. All but the dashes are my numbers or the old matte, not the builder |
| R2 life | **No** | The lip slides about 100 px in two seconds: a conveyor, not a calm sea. The horizon dashes slide with it, which makes the repeat easier to see. At 7 s a wisp smears Home's top-left lawn edge |
| R3 edges | **Yes**, the 4x sheet, with three residuals named | Tendril, hill horizon, hydrangea and tree are clean on day and night. No haze band. Residuals: the string-light cord is gone, so the bulbs float; the lamp room's dome is stepped; pale chips beside the blossom |
| R5 props | **No, and he need not see it** | Placeholder sprites under a debug banner; nothing here is his to decide. It did its job: the slots are wrong in two places |
| R4 depth | Not made | Uses the corrected camera elevation below |

## Where I was wrong, and where the output is

- **C1 at the Map was my error.** I fixed Home's foot at 0.80 and then tested the centre of box plus chip against 0.66 to 0.72. A smaller Home on the same foot has a lower centre, so my own tier-2 table gives 0.749. C1 at the Map is now Home's foot, 0.79 to 0.81; both journey frames pass.
- **C1 for Home on top was undefined.** I wrote the range for the order I preferred and the script applied it to the other. Home on top gets its own: box centre 0.30 to 0.36. Stages 1 to 3 measure 0.33 to 0.34 and pass; tier 2 (0.229) fails rightly, with Home pushed into the far isles.
- **C2 was drawn with no margin.** Map stage 1 fails at 0.206 only because a veiled slot has no chip; the run is the gap that holds the horizon, which is the distance cue, not emptiness. That one run may reach 0.21. Mid level 1 fails by 3 pt (0.143) because its box starts 4 pt lower than level 10's; the limit is 0.15.
- **The backdrop lanes were my error.** I put the far isles and the whale in y 62 to 200 and tier 1 from y 181, tier 2 from y 84. New rule C6: at rest no backdrop feature comes within 24 pt of a subject, slot or chrome box. In the tier-1 journey frame they move into the horizon gap (y 350 to 450), where they also fill the one hollow band.
- **The tier-2 frame is not ready in either order.** Home at 156 pt with 100 pt neighbours and a 123 pt empty band reads thin, and its islands do not exist. It is redrawn after he picks the order; he does not see it now.
- **The life speeds were my error; the builder is right.** 16 pt/s on the largest layer crosses the screen in 25 s. Now: horizon 0.5, floor 1.5, 3 and 5 pt/s, puffs 2 to 5, nothing but birds over 8. The swell and the bobs carry the life.
- **The life metric was my error too.** The share of changed pixels counts moving textured area, not speed, so it cannot tell calm from busy; today's Map passing at 12 % shows it. Speeds are now checked on the layer list; the pixel test keeps only "each third at least 4 %" and "Still is 0"; the mean frame-to-frame change is printed and gets a range only after he has judged the clips. I will not guess a second range.
- **Scout facts.** Top inset 59 pt, not 62: the bands move 3 pt, no proof changes. Camera elevation 10.5 degrees from the lawn ellipse, not my 20 (the code comment's 17 does not fit the ellipse either). Depth per plate row doubles, so R4's aperture is retuned there. A scout confirms 10.5 on a second ellipse (the pond rim) before R4: half an hour.
- **The outputs' own faults:** the old matte in R1 and R2 (ghosts, the seam), the tiled horizon, crude birds, the wisp's path, two prop slots.

All of the above is corrected in `world-presentation-v2.md` (1.1, 1.2, 1.3, 1.4, 3, 4.2, 5.1, 6.1) in this commit.

## M5 and M11

- **M5, confirmed.** The ring now starts one device pixel outside the shape. The first pixel holds any edge's anti-aliasing, and M2 and M3 already guard it. The values (0.0001 to 0.0002 against 0.0078) show the change is not what makes it pass.
- **M11, confirmed and adopted as a spec rule.** 4.1 said a matte never holds haze and nothing tested it. Two notes for the builder: the file header says "not in a patch of 16 px or more", which reads as an exemption while the code fails such patches, so reword it; and it sees only sky-coloured haze, so pink cloud mist still needs the eye.
- **One gap the sheet shows:** M2 has only an upper bound, so a one-bit stepped edge (the lamp room) passes. Added: the 5th percentile of the band width is at least 0.7 px.
- **No check sees a lost object** (the cord). A cheap one, source detail just outside the matte that differs from the local sky, is worth adding with the cord fix.

## The fix pass (before he sees anything)

One Sonnet builder per row, no Codex, no Swift, one re-render each; about one agent-day in all.

| Fix | Who | Cost |
|---|---|---|
| R1: use the `r3b` mattes for Home; move the far isles and whale to C6 lanes; horizon band: offset and mirror alternate tiles and fade the top two rows to 30 % contrast; `composition_check.py` takes the new C1, C2, C6 | R1 builder | 0.4 day |
| R2: new speeds; wisps cross only below the lawn line; birds as three soft marks or none; re-render the Map and mid clips; meter as in section 3 | R2 builder | 0.3 day |
| R3: recover the cord with a declared thin-structure region (alpha from colour distance to the local sky); soften the dome edge to pass the new M2 floor; drop blossom chips under 64 px; run all 20 Home plates, not two | R3 builder | 0.3 day |
| R5: lantern 12 pt clear of the wheel's foot at levels 6 and 10; pots 12 pt clear of the mailbox at level 10; rule: a slot keeps 12 pt from any painted object's foot | R5 builder | 15 minutes |

The tiled horizon is only hidden by this; the cure is Codex's cloud jobs, already counted in section 10.

## What the founder sees, after the fix pass (8 files)

Re-rendered under the same names in `/tmp/claude-0/-home-user/ab6e36fd-b860-546d-a17d-cd7bb5d5a61b/scratchpad/proofs/`:

1. `r1/map-journey-stage1.png` and 2. `r1/map-homefirst-stage1.png`: day one, side by side.
3. `r1/map-journey-stage3.png` and 4. `r1/map-homefirst-stage3.png`: both neighbours open. These four are his one choice, the order.
5. `r1/mid-level10.png`: mid with chrome. Clean today; level 1 is not shown.
6. `r2/life-map-stage3.mp4` beside 7. `r2/life-map-today.mp4`: alive, and still calm?
8. `r3b/sheet-worst-edges-4x.jpg`: the edges. Any edge he can find is a fail.

Not shown: tier 2, near (the lawn is featureless blur until R4), mid life, props.

## The key colour for Codex

Adopt it **for new masters only, after a one-job pilot**; do not repaint what ships.

- **Gain on new art:** the background is known and flat, so the colour solve is exact, the haze class (M11) cannot occur, and a thin cord on a flat key survives. That is the residual list above.
- **Why not everything:** the `r3b` mattes already pass on the two plates tested. Repainting 20 Home plates plus Koke and Çağlayan is over 22 jobs, and each repaint risks changing art he has approved and breaking registration across stages (M10), to remove three residuals a builder can fix in 0.3 day. An existing plate is re-keyed only if it still fails `matte_check.py` after the fix pass.
- **Why a pilot first:** the islands are green. #00FF00 is far from the lawn's yellow-green in saturation, and magenta and blue are worse (pink earth, lilac flowers, sky, ponds), but an image model may shade the key, cast a ground shadow on it or spill green onto the pink earth. One master on the key, through `matte_check.py`, at day and night. Cost: one Codex job and half an agent-day. The last art batch built on an unchecked claim was 54 jobs.

## Recommendation

Launch the fix pass now and show him the eight files after it, about a day later. The order choice blocks nothing the fix pass needs, both orders are already rendered, and he reads a seam or a sliding floor as the verdict on the whole direction. My own read for the lead, not to steer him: the journey order is the stronger picture, Home grounded on the sea with the road rising behind it; Home on top keeps a top-heavy screen.
