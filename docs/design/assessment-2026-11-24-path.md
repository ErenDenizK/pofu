# Whole-project assessment, round 2: the path (2026-11-24)

Round 2 of 2. Round 1 is [assessment-2026-11-23.md](assessment-2026-11-23.md);
the founder approved every pick in it (founder-input 44) and added one
thing: interfaces are tried in the app, but visual factors (a whole
screen's composition, single parts such as material, texture, icon and
ornament) may be prototyped with Codex so he can see them. This page
fixes the stages, their order and their acceptance, the division of work
and the Codex queue. The founder's page, in Turkish, is
[assessment-2026-11-24-tr.md](assessment-2026-11-24-tr.md). The briefs
are in `docs/studio/briefs/2026-11-24-*.md`; the Codex manifests are in
pofu-art, batches 157 to 160.

Basis: pofu `origin/main` 2230b67e (#509), pofu-art `origin/main`
192824e (#149), frames on `screenshots/main`, the scout's answers
(`docs/research/assessment-2026-11-23/scout-sprite-fallback.md` on the
lead branch). Marks as in round 1: **[seen]** means I opened the file or
the frame.

## 1. What round 1 got wrong

Five claims in round 1 do not hold. None changes the order; three make
the work smaller.

1. **"Two Home renderers both live" is not a player risk.** The sprite
   island shows only below island level 1, which no save has, or when
   the plate's data fails to load (scout, point 1). Time of day and
   weather never cause it. The sprite island is dead code for Home, not
   a look the player can hit. It moves from "risk" to "cleanup".
2. **The resident walk is not discarded.** The plate reads the hop,
   pose, breath and lean of `residentSteps`; only the walk offset
   (`dx`, `dy`) is unused there (scout, point 2;
   `IslandScene.swift:1483` and `:1237` [seen]).
3. **Residents are not baked into the painting.** Mochi and Fındık are
   their own layers, placed at `plate.residentFeet`
   (`IslandScene.swift:1313` [seen]; `plate-home.json` `characters`).
   So moving them between spots needs no new art.
4. **CI is not at its limit.** The macOS job took 31 to 36 minutes of 45
   in the last four full runs (scout, point 3). Round 1 said 44 to 46,
   from an unchecked raw file.
5. **Pofu has one voice cue in the bundle,** the hop (`pofu-hop.caf`).
   The unbundled proofs are five: chew, giggle, poke, sleepy sigh and
   sniff (`design/sound/proof/` [seen]).

One thing round 1 did not see: `x-board-dial-big` t2 and
`x-board-dial-fall` t2 are the same board [seen side by side]. Dial-big
has separate cushion tiles on a wider board and a mossy frame; dial-fall
has one fused slab. Round 3's quiet board, painted from dial-fall, is
therefore close to his pick already, and one small batch closes the gap.

## 2. The path

Five stages. A stage is done when its acceptance is met, not when its
PR merges.

### Stage 0: day 1 is runnable (in flight)

The pass pill on Home, the honor session cut, the corrected day-1
script. One builder, `feat/day1-pass-pill`.

*Done when:* the PR is merged on green CI, a path frame shows the pill
while a pass runs, and `docs/local/membership-day-1.md` case 10 names
the pill.

### Stage 1: the device days

- **Certain:** the work on our side is finished by stage 0. On the first
  day the membership is active he sits at the Mac for one to two hours,
  files the Family Controls (Distribution) request the same day, builds
  `PofuLive` and runs the cases. The lead is with him on the side
  channel; the stage-0 builder is on call for fixes only
  (brief 0).
- **Uncertain:** the date (about 11-27, perhaps 11-25); how long Apple
  takes over the Distribution request (weeks, by report); which cases
  fail. Nothing below waits on any of the three: stages 2 and 3 run on
  the free build and in CI frames. TestFlight is the only thing that
  waits on Apple.
- **Priority rule:** from the hour he sits down until the report is
  written, a failed case outranks everything else, and the on-call
  builder gets the next Swift build.

*Done when:* every one of the 28 cases has a written result in a dated
report under `docs/local/`; cases 1 to 11 and 17 (the gate's core:
permission, shield, pass, shield back, end early, survives a restart)
pass on his iPhone, after fixes if needed; the Distribution request is
filed. Cases that fail outside the core each get an issue and do not
hold the stage.

### Stage 2: the three surfaces

Starts the moment stage 0 merges, beside stage 1.

1. **The station card** (brief 1). The bottom sheet goes. Two native
   glass cards, both small and both hanging by the station: **Etiket**
   (a tag beside the station, with a tail) and **Hap** (a pill under the
   station that opens in place). He switches between them in Settings on
   his phone. *Done when:* both are in a build on his phone, he has
   named one, and the other is deleted. My pick is Etiket; it is the
   default.
2. **Home's composition** (brief 2). A data change on the existing
   plates: the island sits lower, and a young island is drawn larger.
   The island spans 33 % to 60 % of the screen's height today and the
   cloud runs from 60 % to the chrome [seen: `path-d21-0900`].
   *Done when:* the lead has picked one of three candidate framings in
   frames, it is merged, and the day-1, day-10 and day-21 Home frames
   show the island's middle between 50 % and 53 % of the height with
   Pofu's bubble clear of it.
3. **The stream board** (brief 3), in the dial-big direction with
   painted blocks. The rule that makes his pick a design and not a
   skin: **a piece that turns is a round dial set in its block; a piece
   that does not turn is a plain block.** The game already knows which
   pieces turn (`FlowTileKind.isTurnable`). The builder starts when the
   block kit (pofu-art batch 158) is delivered and the lead has picked
   takes. *Done when:* `path-game-flow-stage1`, its mid and solved
   frames are drawn with the kit, the board and its backdrop read as
   one picture in a 1:1 crop, the code-drawn tiles and ground method A
   are deleted, and he has played a board on his phone.

### Stage 3: life and sound

4. **Sound** (brief 4): ambience on for a player who never chose, and
   Pofu's five voice proofs in the bundle on the moments they were made
   for. Small; it starts as soon as an agent is free and does not wait
   for stage 2 to finish. *Done when:* a fresh install is not silent on
   his phone and each cue is heard at its moment.
5. **Life** (brief 5): Pofu and the two residents change spots by
   hopping, a few times a minute at most; no walk cycles. Three lines
   for every character whose card can open, written in Turkish first
   with the `pofu-story` skill. *Done when:* a frame sequence shows each
   of the three standing at two or more spots, never behind anything
   taller than itself, and every card that can open says a line.

### Stage 4: the voyage with the Gezgin, and music

Held until stage 1 is done and stage 2 is done. It then starts with a
spec, not a brief: one Fable round that turns #503, the A2 row frame,
the three Gezgin levels and "tap the Gezgin, or the button at the
bottom right" into a build order. Music is discussed with him at that
point. Codex prepares her art meanwhile (batch 160), so the spec starts
from pictures that exist.

### Stopped and held

- **Stopped:** concept rounds as rounds. Codex now gets small batches
  that each serve a named step. Interfaces from Codex. The honor
  session. New far-screen work.
- **Held:** the voyage in code (#503 stays a proposal). Batch 137 (the
  plot ladder). Batch 136 (the flow lawn) is superseded by batch 158 if
  the kit is accepted, and should then go to the log.
- **Not briefed, on purpose:** the cleanup of dead paths (the
  `!worldHome` Home, pay-for-minutes, the sprite island at Home). It is
  worth one builder for a day once stage 1 is done; before that it
  would only collide with device fixes.

### What the lead may decide alone

Everything in stages 0 to 3 except his three picks (the card, Home's
framing if the lead is unsure, the board once played). In particular:
merging the briefs' PRs, picking takes in Codex deliveries, choosing
Home's framing among the three candidates, the order of briefs 4 and 5
against brief 3 when the block kit is late, closing superseded PRs,
correcting `QUEUE.md`, marking `tracker.md` and `roadmap.md` stale, and
scheduling the cleanup. Stage 4's start and anything about music go to
him.

## 3. The division of work

At most three Claude agents at once; one Swift build at a time is the
real limit, so three is a ceiling and two is normal.

| Lane | Now | Then |
|---|---|---|
| A, on call | Stage 0 builder finishes | Brief 0: device-day fixes, nothing else, until stage 1 is done |
| B | Brief 1: station card | Brief 3: stream board, when batch 158 is picked |
| C | Brief 2: Home's composition | Brief 4: sound, then brief 5: life |

Briefs, in order. Briefs 1 and 2 touch different files and start
together the moment stage 0 merges.

| # | Brief | Role | Starts |
|---|---|---|---|
| 0 | `2026-11-24-0-device-day-fixes.md` | builder | when he sits at the Mac |
| 1 | `2026-11-24-1-station-card.md` | builder | when stage 0 merges |
| 2 | `2026-11-24-2-home-composition.md` | builder | when stage 0 merges |
| 3 | `2026-11-24-3-stream-board.md` | builder | when batch 158 is picked |
| 4 | `2026-11-24-4-sound.md` | builder | when lane C is free |
| 5 | `2026-11-24-5-life.md` | builder | after brief 4 |

Fable's remaining work: a frame review after briefs 1 to 3, and the
stage-4 spec.

## 4. Codex

His point 10 is the method. Codex paints what he needs to see before or
beside the build: one whole screen's composition (the board), and single
parts (the blocks, the level marks, the card's ornaments, the Gezgin).
Codex paints no glass and no interface. Each batch serves one step:

| Row | Batch | Jobs | Serves |
|---|---|---|---|
| D20 | `batch-157-board-dial-big` | 3 | Stage 2.3: his pick made quiet, the dial rule shown, the water arrived |
| D21 | `batch-158-board-kit-v3` | 12 | Stage 2.3: the pieces the app draws the board from |
| D22 | `batch-159-card-marks` | 8 | Stage 2.1: the level mark and two ornaments for the glass card |
| D23 | `batch-160-gezgin-source` | 7 | Stage 4: her three levels as cut-outs, asleep and awake, and her mooring |

Thirty jobs, then the standing rows (clouds, the hidden visitors). At
two concept jobs at once this lasts through the device days. The queue's
finished rows (D14, D17 to D19) move to the log in the same PR.

## 5. What he sees, and when

| When | What |
|---|---|
| Membership day | The gate on his own phone, the pass pill on Home |
| Within a day of stage 0 merging | Two station cards in a build, switched in Settings; Home's new framing |
| As Codex delivers (days) | One phone page: the quiet dial-big board; the block kit; the level marks; the Gezgin's three levels cut out |
| After the block kit is picked | The stream board playable in the new look |
| After that | A Home that is not silent, Pofu's voice, characters that change spots and speak |
| Later, with him | The voyage's spec and the first talk about music |

## 6. What needs him

Little, as round 1 is answered.

1. **The card.** On his phone: Etiket or Hap. *Pick: Etiket.*
2. **The level mark.** One page of three small marks from batch 159
   (a sprouting pot, a leaf, a small flower). *Pick: the leaf, the
   simplest shape at the size it has on the card. Not a seed: a seed
   already means the price.*
3. **The day.** The first day the membership is active, one to two
   hours at the Mac. No answer needed until it is active.
