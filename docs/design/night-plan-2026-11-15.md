# Night plan, 2026-11-15: where Pofu stands, what runs tonight, tomorrow and after

Fable's answer to `docs/studio/briefs/fable-2026-11-15-night-plan.md`
(founder-input 35). Three parts: the assessment, the plan, the Codex
queue. The queue itself is on the pofu-art branch `chore/queue-fable-night`
(three commits, no PR yet): `QUEUE.md`, `QUEUE-LOG.md`, seven manifests
(batches 123 to 129) and their reference crops. Every manifest passes
`run.py plan`; the imagegen tests pass (185).

What I looked at, so the reader knows what is checked and what is not:
the code at `origin/main` fd34edcd for every claim marked with a file; ten
player-path frames of `screenshots/main` and three Map frames of
`screenshots/feat-map-journey` at 1206 x 2622 (whole, and 1:1 crops of the
flow board and the Home chrome); the picked targets and match frames;
every Home station cropped from its first plate and from the level 10
plate; the four night plates WP4 could not matte. **Not seen:** WP4's
frames (CI has not rendered `feat/plate-mattes`), any delivery of batches
118 to 122, and the app on a device.

## 0. Findings that change the work

1. **Batch 121 could not run as queued.** `run.py plan` reported all seven
   jobs as `missing reference x-flow-stone-c-t1`: the jobs attached the
   stone and a sibling by bare job id, which `plan` reads as a file alias.
   By `AGENTS.md` Codex records that as a closure gap and skips the batch,
   so the founder's A/B pilot would not have been painted tonight. Fixed
   on the queue branch (`approved:<id>`); row 0-d1 is unchanged. This is
   my one change to the two bridge rows.
2. **The queue emptied by design, not by accident.** Every Stock row had
   reached its `-v3` (batch 31 its `-v4`), which the queue's own rule
   calls done, and the standing step was paused. With no Demand row left
   the loop's last step is "Kuyrukta iş kalmadı". Thirty rows still read
   READY after delivery. The rewritten queue has a Standing work section
   in Stock's place, and the delivered rows are in the log.
3. **The plates already contain the upgrade ladder.** Cropping each
   station from the plate where it first appears and from level 10 shows
   the same station humble and rich (the tea stall: a tub and an awning,
   then stools, lanterns, a second awning; the workshop: a plank shed,
   then tiles, a lit window, a brass cog). "Upgrades do not show" is not a
   missing design. It is that the picture follows the island's level and
   not the station's. The art job is therefore small and safe: paint each
   station alone, starting from the plate's own painting.
4. **The A/B pilot asks about two of the flow screen's nine code-drawn
   parts.** At 1:1 the grass and rock are the smaller problem. The channel
   is a flat brown vector, the water a flat blue one, the source a blue
   ball, the board hangs on a blank gradient under a brown bar, and the
   source cell is a bare peach square with a dashed rectangle where
   every other stone is a keycap (`path-game-flow-stage1`). Batch 124
   paints the rest.
5. **The Door is not on the look-truth path.** No `path-*` frame shows
   the Hop screen, the moment the product exists for. It appears only as
   an old `20-gate-*` frame at 460 px. Add it to the player path before
   anybody judges the polished build.
6. **The glass skin hides art that already ships.** The default skin is
   glass (`PofuSkin.swift:44`) and painted chrome is drawn only in the
   crafted skin (`PofuSkinEnvironment.swift:25`), so the seed in "Topla"
   is a flat code glyph although `paint-icon-seed.png` is in the bundle.
   ADR-0018 already allows painted art inside glass. This is a builder
   job with no art in it.

## 1. The assessment, ranked by what the player feels

| # | What he feels | Why (checked) | What closes it |
|---|---|---|---|
| 1 | **Building changes nothing.** The name levels up, the picture stays | The plate is chosen by island level; `upgradeArt` has no caller outside tests (`PlateIsland.swift:206`) | Looks: batches 123 and 129, then WP8 and WP10. A proof on screen first (step N6) |
| 2 | **Resisting leaves no mark.** The jar, the pots and the lantern are not on the painted Home | `IslandScene.swift:849, 947`: props only when `plate == nil` | WP5, the next builder after WP4 |
| 3 | **The everyday screen is a crop.** The island's sides are cut, the lower third is chrome on fog, Pofu is 47 pt | `path-d05-0900`; framing 1.15 widths | WP7 (mid and near), after WP6 |
| 4 | **The world has no weight.** One flat cloud sheet with a hard horizon; on the new Map the islands hang in bare sky | WP6 frames, days 1, 6, 13, beside `match-map.jpg` | The cloud kit (126), then WP9 |
| 5 | **The minigames are empty rooms.** Flow is a wireframe on a gradient; Garden is finished pieces on a gradient; neither has a start | Finding 4; no `.intro` phase in `GardenGameView` | 121, 124, the target frames of 127, one builder (N4) |
| 6 | **The interface is two apps.** Glass controls on Home, cream paper sheets for the station and Today, a cream onboarding, Apple's symbols where Pofu's icons belong | `path-sheet-station`, `path-sheet-today`, `path-onboarding-welcome` | The UI grammar (Fable), fed by 122 and 127; icons 128; N5 now |
| 7 | **Little moves.** Water is baked and still, the sky below level 10 is a JPG, only hops came back | `PlateHomeViews.swift:104-106`; app-state facts section 4 | WP9, WP13; after the items above |
| 8 | **Edges.** A pale band and ghosts under the island on some levels | WP4's own PR body: six states on the old matte | WP4, batches 116 and 125 |
| 9 | **Sound is thin, music absent.** 20 cues; Flow borrows the Garden's | `SoundCue.swift`; music waits for his word | A cue pass with the minigame builder; music after his talk |

Ranks 1 and 2 are the game's own promise (let an app go, the island
grows), and both are invisible today. They come before polish.

### What worked and what did not on the art line

| Works | Fails |
|---|---|
| One whole object per job, the plate's own painting attached (78, 111) | Sheets and grids (90, 105, 106, 111's fringe) |
| A small edit of a picked parent (83, 116) | An edit that must keep a whole plate's pixels (108, 113, 82) |
| Erase, then paste only the region back through a mask (108, 117) | Key colour (113) |
| A paint-over locked to a real frame (112: within 1 px) | Free compositions (112: Home 1.9 times too large) |
| A seamless material in a fixed style contract (114 c) | Pieces that must meet at a pixel (77, 79); wrap checks on soft cloud (109) |
| The shipped sheet attached as the style (88 A) | Style in words (88 B); `prop-style-v2`'s rim (an orange band, 90) |
| | Relighting a plate to golden or night (87, 93 to 104) |

Consistency, the founder's three words. **Shared light:** every new job
names its light in the prompt and overrides the style block where the
block is wrong (top-down pieces); no light reference is attached to an
edit, because takes copy moons and whales out of them. **References:**
two at most, each with a role that says what it is for, and the plate's
own crop as the identity. **Variants against repetition:** asked for as
separate jobs with a named difference (three small puffs, three towers,
two beds), never as "four variants on a sheet".

## 2. The plan

Limits: three builders at most, on disjoint files; one Swift build at a
time; the disk had 5.0 GB free when this was written, under the 8 GB rule
in `now.md`, so **N0 comes first** and builders share one checkout's build
products.

### Now: tonight and tomorrow, in order

| # | Step | Who | Waits on | Judged by |
|---|---|---|---|---|
| N0 | Free the disk: remove merged worktrees and stale build directories, then `/tmp/claude-0/fable-night` | lead | nothing | 8 GB free |
| N1 | Open and merge the pofu-art PR from `chore/queue-fable-night`; tell the founder "çalış hazır" | lead | nothing | `plan` green on 121 to 129 (it is) |
| N2 | WP4 (#480), one fix round, then merge. Scope below | builder, Sonnet (the one in flight) | nothing | 1:1 rim crops on the six frames the spec names; no state where the matte cuts painted content |
| N3 | WP6 (#479), one fix round, then merge. Scope below | builder, Opus (the one in flight) | nothing | Days 1, 6 and 13 beside `match-map.jpg`; Home never under half the width |
| N4 | Flow in paint, part 1 (`feat/flow-painted-board`, `PofuGames` only): the channel and the water filled from textures under the carved mask; grass, rock, spring, outlet, wheel and gate from named art with today's drawing as the fallback; the ground of method B as a debug switch; the source cell drawn as a stone like the others | builder, Sonnet | nothing to build; batches 121 and 124 to judge | In-app frames A and B side by side at 1206 x 2622 with 1:1 crops, sent to the founder |
| N5 | Painted glyphs inside glass (`feat/glass-painted-glyphs`): the glass skin draws the shipped painted seed, close and duo icons; no surface changes | builder, Sonnet, when N2 or N3 frees a slot | nothing | `path-d05-0900` crop of "Topla" and the place control, before and after |
| N6 | The upgrade proof: batch 123's picks set on batch 117's erased base with `tools/proof`, at Map, mid and near, levels 1, 3 and 5 | lead (a Sonnet agent runs the script), Fable judges | batch 123 delivered | The five checks in 123's header; then shown to the founder |
| N7 | Morning review of the night's deliveries, in this order: 121 (feeds N4), 123 (feeds N6 and gates S1), 122, 124, 125, 126, 127, 128. Record picks on the branches; ingest what a builder waits for | lead | deliveries | Each manifest's REVIEW block, at 1:1 |
| N8 | WP5, the props come back (`feat/home-props-back`) | builder, Sonnet | N2 merged; batch 111 pick 1 cleaned of fringe | The jar and pots on `path-d16-pots-1500`; a resisted reach leaves a pot |
| N9 | The Door on the player path: a `path-hop-*` frame in `PlayerPathScreenshotTests` | folded into N5's builder | nothing | The frame exists on `screenshots/main` |
| N10 | UI grammar (the approved brief `fable-2026-11-14-ui-grammar.md`), now with pictures to choose from | Fable | batches 122 and 127 reviewed | `docs/design/ui-grammar-v1.md` and the founder's picks |
| N11 | Founder's picks, sent as frames in Turkish | founder | N4 (A or B), N7 (122, 127), N6 | his answers, section 4 |

**WP4's fix round (N2).** Do not polish the backdrop fill. Levels 1 to 9
draw a static backdrop JPG and level 10 draws the sky set
(`PlateHomeViews.swift:102-106`), so the smeary fill exists only because
two sky paths exist. Merge the mattes; treat the fill as a stopgap and
open the follow-up below. For every state where the matte cuts painted
content, list the state and ship its old matte (the spec's own fallback)
rather than lose paint. Day levels 1 and 2 take batch 116's accepted takes
as the plate source (the spec said mist clear was not an input; with the
picks in hand it should be). Night levels 1, 2, 8 and 9 wait for batch
125. What lies on those plates is the cloud that hides the hill: it
becomes a cloud-kit layer of its own (`x-cloud-hill-cap`, batch 126) that
breathes and lifts when the hill opens, which is WP12's reveal for free.

**WP6's fix round (N3).** From its three frames: (a) the two cloud towers
are the same picture side by side, which is the repetition the founder
named; show one until batch 126's towers land. (b) Home shrinks to about
40 percent of the width and sits in the lower half under an empty sky on
days 1 to 6; before the first wonder island the Map fits Home alone,
large, and each unlock re-balances (founder-input 32.1). (c) The wonder
islands float above the cloud horizon in bare sky; until the cloud beds
land, raise the horizon haze so the band is not a hard line and keep the
islands' feet in it. Then merge: journey order is right, and it is data.

### After, in order

| # | Step | Who | Waits on | Judged by |
|---|---|---|---|---|
| A1 | One sky at every level: levels 1 to 9 draw Home's sky set; `world-home-backdrop-*` retires. First check why only level 10 has a sky set | builder, Opus | N2, N3 merged | Home frames at levels 2, 5, 9: no fill under the rim |
| A2 | WP7 rail: mid and near, ADR-0027 | builder, Opus | N3 | `match-mid.jpg`, `match-near.jpg` |
| A3 | WP8 looks data, starting with the tea stall | builder, Sonnet | N6 passed; N2 | tests; one station swaps looks in a frame |
| A4 | WP9 cloud floor and life, with batch 126's forms | builder, Sonnet | N3; 126 reviewed | The Map and mid beside the match frames; a 12 s clip |
| A5 | Flow in paint, part 2: the backdrop, a start card, the glass HUD from the picked target, Flow's cues, Flow through the frame policy (it runs a fixed 30) | builder, Sonnet | 124 and 127 picks; N10 | `path-game-flow-*` beside `x-target-flow` |
| A6 | The Garden's scene and start card, the same way | builder, Sonnet | A5's pattern | `path-game-garden-*` beside `x-target-garden` |
| A7 | WP10 compositor, WP12 reveals, WP11 near lens, WP13 water, in the spec's order | builders as the spec names | A2, A3, A4 | the spec's frames |
| A8 | Sheets and onboarding rebuilt from the grammar and the picked targets; #453 closed or rebased onto it | builder, Sonnet | N10 | the picked targets |
| A9 | The pofu-art backlog: 30 open PRs. Merge the reviewed ones; close the Stock variations unmerged (their branches keep the takes) | lead | nothing | the PR list fits one screen |
| A10 | Music | founder first | his word | |

Fable's own work is N6's judgement, N10, and the review of 123 before the
standing looks are trusted. Everything else is builders and the lead.

## 3. The Codex queue

On pofu-art `chore/queue-fable-night`. About 115 jobs: at the line's
measured pace (about 50 jobs in seven hours on 11-15) that is roughly 16
hours, so the lead refills Standing work within a day.

| Row | Batch | Jobs | What | Gate |
|---|---|---|---|---|
| 0-d1 | 121 flow banks A/B | 7 | Kept. Manifest fixed (finding 1) | founder picks from N4's frames |
| 0-d2 | 122 far camera UI | 3 | Kept as written | founder picks |
| 0-n1 | 123 tea stall ladder pilot | 5 | The tea stall at its five levels, as cut-outs: look 1 from the plate's own crop, each next look a small edit | The pilot of the looks: N6 |
| 0-n2 | 124 minigame scenes pilot | 8 | Flow's water and channel bed (seamless materials), spring, outlet, wheel, gate (single cut-outs, top-down light), and the scenes behind the Flow and Garden boards | lead, in an in-app frame |
| 0-n3 | 125 home night clear | 4 | Night levels 1, 2, 8, 9 without the cloud on the island (116's method) | `matte_check` M2, M11 |
| 0-n4 | 126 cloud kit volume | 10 | Two island beds, two more towers, five puffs, the hill cap; one form per job, nothing wraps | lead, on the app's sky |
| 0-n5 | 127 screen targets | 5 | Flow, Garden, an upgrade, Today and the welcome, painted over real frames | founder picks; feeds N10 |
| 0-n6 | 128 duo icons, single | 18 | Sheets 3 and 4 one icon per job (106's sheets failed `detail_budget`) | lead, at 22 pt |
| S1 | 129 home station looks | 35 | **The standing job.** Seven stations at five levels, breadth first | see below |
| S2 | 126 `-v2`, `-v3` | 20 | More clouds, each a new silhouette | none: more different clouds are always used |

**Why the looks are the standing job.** They are the founder's first
complaint, the app needs all forty, each is one object from the plate's
own painting (the safest kind of job this line has), and a delivered look
is used as it is whatever else is decided. The order is breadth first:
look 1 of all seven stations, then look 2 of all seven. Look 1 is needed
under any recipe, so if the pilot's review changes how the ladder edits
are briefed, at most the later rungs are repainted.

**The risk I am taking, stated.** S1 can start before anybody has judged
123, because nobody is awake to judge it. The cost if the recipe is wrong
is about 28 edit jobs; the cost of gating it is an idle line, which the
founder ruled out. The lead can stop it with one edit (`BLOCKED`) after
N6. The pond and the pier sit in the ground more than a building does and
are the likeliest to fail; they run last in each rung and skip alone.

**Left out on purpose.** Night looks (a day-to-night recolour fails QA
every time on this line; the lead writes that batch after the day looks
are picked, or the app grades them). Near-dressing volume (107's tufts
need 119's ragged-base result, unreviewed). Golden and night plate cells
(closed for good). Another round of the key colour.

**Queue hygiene done.** The return queue, the asset-system pilots, rows
0-b1 to 0-c8 and every Stock row moved to `QUEUE-LOG.md` with the pull
request that holds each. Batch 84 (three hidden visitors never run) is a
BLOCKED row: the demo hides those residents. `AGENTS.md` names Standing
work where it named Stock.

## 4. Where the founder chooses

One line each; my pick first. Asked in Turkish with frames, not from this
table.

1. **Flow board ground, A or B:** B, one ground, the stones set into it
   (judged on N4's frames; A if B's lawn shows a seam).
2. **Far camera interface (122), quiet, card or path:** quiet, the world
   carries the selection; unseen, so this pick is from the brief only.
3. **Sheets: glass over the dimmed island, or cream paper as today:**
   glass (the targets of 127 show it); it follows his glass decision.
4. **The first screens inside the painted world, or the cream pages:**
   inside the world.
5. **Upgrade look:** his yes or no on N6's proof before 35 more are
   trusted.
6. **Music:** after his first session on the polished build, as he said.

## 5. Corrections for the lead

- `now.md`: "no new builders under 8 GB" is in force (5.0 GB free).
- The brief's research files are on `main` now (#481 merged).
- `flow-stone-style-v1` says "the attached hamster"; no flow job attaches
  one. Harmless so far; fix the block when it is next synced.
- Batch 119's manifest names a wrap script that is not in pofu-art; 124's
  tiles ask for batch 114's manual check instead.
- `batch-124`'s wheel is drawn from straight above because the app spins
  it; if the game means a side-on wheel, re-brief that one job.
