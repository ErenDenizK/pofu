# Art production plan: the living queue

The art line (Codex in the cloud, `AGENTS.md`, `tools/imagegen`) must never
idle (founder, 2026-11-02: "it's a factory; every time it's idle we lose
time"). This page is the queue it pulls from. The lead keeps it current;
Codex reads it at the start of every task.

## Standing rules

1. **Pull, don't wait.** When Codex opens a batch PR, it immediately starts
   the next `READY` batch in the queue below, in order, on its own branch.
   It never waits for a review or a merge to start the next ready batch.
2. **Iterate, then scale** (founder, 2026-11-02). Lock the method on a small
   pilot, learn from its mistakes, then run the batch. Every new batch has a
   **pilot of 2 to 5 jobs** in its own manifest (`batch-NN-<name>-pilot`,
   `status: open`); the rest of the batch is a second manifest
   (`batch-NN-<name>`, `status: blocked`) that opens only after the lead has
   reviewed the pilot. Pilots come first in the queue, so the line always has
   something new to try while the lead reviews.
3. **Do not regenerate to fix the old.** Existing assets are brought in line
   by the harmony grade (code, `tools/assets/harmony.py`, in progress on
   `feat/look-round-2`). Only an asset the grade cannot fix (wrong shape,
   wrong detail level, wrong content) is regenerated, and only after the
   lead names it here as an outlier.
4. **Explorations never ship.** An `EXPLORATION` batch is generated, posted
   and auto-picked, but never promoted; its takes, contact sheet and
   `review.yaml` are committed for deciding.
5. **Stop conditions are unchanged** (`AGENTS.md`): two failing takes on the
   same check stop the job, and the PR says why.

### How the lead marks a batch

- **READY:** its manifest is on `main` with `status: open`, and the queue row
  says `READY`. Codex may start it.
- **BLOCKED:** `status: blocked` with `blocked_on` naming the gate (usually
  "the lead's review of the pilot"). Codex never starts it.
- **Opening a batch** is one PR by the lead: flip `status` to `open`, drop
  `blocked_on`, apply what the pilot taught to the prompts, and change the
  row here to `READY`. The same PR merges the pilot's art.
- **DONE:** merged; the row moves to the log at the bottom.

## The queue

Order is priority. Codex takes the first `READY` row nobody is working on
(an open PR or a pushed `art/<batch>/...` branch means someone is), and
**when its PR is open it continues to the next `READY` row automatically**,
until none is left.

| # | Batch | Kind | Purpose | Needs | Jobs | State |
|---|---|---|---|---|---|---|
| 1 | `batch-05-fixes` | production | simit-3..5, workshop-3..5 (pilot passed, #71) | main | 6 | **READY** |
| 2 | `batch-06-pofu-rig` | production | The rest of the rig (eyes, mouths, cheeks puff-1 and puff-3, paws, `pofu-ears-droop`, matted fur) and Mochi's and Fındık's blink and happy eyes (pilot passed as composites) | pilot on main | 19 | **READY** |
| 3 | `batch-07-light` | production | Night light, painted only for light-carrying stations: workshop doorway (L1), windmill windows (L5), pond lanterns (L5). cay-1-lit accepted; cay-5-lit dropped | main | 3 | **READY** |
| 4 | `batch-11-ui-pilot` | production · PILOT | The hybrid UI's look-dev (ui-system-v2 section 6, 12 of the 14 pilot items; the two cheek stages are `pofu-cheeks-puff-2` and `-3` in row 2): seed icon, jar, lantern on a post, three pots, crafted primary face, disc, paper tag and panel | main | 12 | **READY** |
| 5 | `batch-08-decor-pilot` | production · pilot | Four decor pieces, one per Ayçiçeği decor spot (bench, lantern string, toy sailboat, mailbox) | main | 4 | **READY** |
| 6 | `batch-09-explore-pilot` | EXPLORATION · pilot | Painted seed icon at 28–60 pt, App Store key art A, a Home ideation board | main | 3 | **READY** |
| 7 | `batch-10-island-concepts-pilot` | EXPLORATION · pilot | Establishing shots of Çağlayan, Ayna, Revontuli | main | 3 | **READY** |
| 8 | `batch-10-island-concepts` | EXPLORATION | Their signature moments (Damla at the falls, Pekmez and the seed falling up, Tuli painting the aurora), attaching the picked pilot takes | review of #6 | 3 | BLOCKED, manifest after #6 |
| 9 | `batch-11-ui` | production | The rest of ui-system-v2 section 6 (night variants, secondary and pressed faces, game layer, domain icons, surfaces) | review of #4 | about 32 | BLOCKED, no manifest yet |
| 10 | `batch-08-decor` | production | The rest of a decor kit | the decor mechanic decided (archipelago system, PR #64) and review of #5 | — | BLOCKED, no manifest yet |

Row 9 is the scale-up of row 4; row 8 of row 7; row 10 of row 5. Rows 1 to
3 were the scale-ups of the passed pilots (batch-05, 06 and 07).
Batch 02 (Glass++ production) stays blocked until the friends beta
(ADR-0018 amendment).

## What batch 03 taught

Measured by the lead on the takes and masters on `main` (2026-11-02):

- **simit-2 and workshop-2 never failed on art.** An edit is drawn on the
  approved master, which is already on the station anchor, and `post` moved
  it again by the chain root's registration (simit-1 dx +110 px, workshop-1
  dx −110 px), so every take sat 110 px off its parent and was cut at the
  canvas edge. Fixed in `tools/imagegen` (edits are never registered
  again). Re-checked on the same takes: simit-2 keeps 100 % of its parent
  and passes every check; workshop-2 keeps 90–94 %. Batch 05 salvages them
  instead of regenerating.
- **garden-5's prompt was impossible.** garden-4's arch already reaches the
  height bar (top y 147), and the prompt asked for a sunflower taller than
  the arch. It now grows inside the arch.
- **Every chain faded.** Median chroma per level: çay ocağı 31 → 22 → 18 →
  14 → 11; windmill 28 → 14 → 11 → 8 → 7; garden 25 → 18 → 13. Each level
  re-drew the soft-locked parent and was locked again; every step stayed
  under `edit_stability`'s tolerance. The default is now `lock-light`
  (near-neutral, about 1 ΔE per level), and a new `edit_chroma` check fails
  any edit below 0.70 of its parent's chroma (warns below 0.85). This is
  why the windmill reads very pale and the çay ocağı reads cold: not their
  hue (every çay pixel is still a warm hue) but lost chroma, which the
  harmony grade restores per level in code.
- **The large island is squashed:** earth depth 0.168 of its width against
  0.205 for the small island. `island-main-l-v3` deepens only the earth
  body (target 0.22–0.26); the lawn stays identical, so the terrace, islet
  and bridge still fit.
- **Fındık is the most saturated resident** (median chroma 19 against Mochi
  9 and Pofu 12). Harmony grades him first; he is regenerated only if his
  detail level, not his color, is still out of family.

## Harmony scores the takes (when it lands)

The harmony system (`tools/assets/harmony.py`, another agent, not built
here) measures each asset against the family. When it lands:

1. `post` adds its distance to the QA report, and the auto-pick becomes
   "passes QA, then the lowest harmony distance, then the lowest lock load".
2. The lead runs it over every master on `main` and lists outliers in this
   page; only listed outliers get a regeneration job.
3. The chain fade above is its first job: a per-level chroma gain for the
   çay ocağı, windmill, pond and garden chains.

## Pofu's reactions are a rig

Founder: "You want 12 expressions, but can you really combine them as an
animation?" Full-frame painted poses cannot be tweened, and swapping them
reads as a slideshow. So Pofu is a **layered rig** in R1's exact framing
(1024 × 1536):

- **How parts are made:** every image is an edit of R1 that changes one
  region and lines up with R1 everywhere else (`edit_stability` checks it).
  The lead cuts each region out with soft masks drawn once on R1
  ([`tools/rig`](../../tools/rig/README.md): `rig.py sheet` renders every
  expression as the app will draw it, with seam scores) and the app
  composites it over the clean plate.
  The model is never asked for an isolated part: an edit keeps R1's light,
  fur and registration; an isolated part does not.
- **The clean plate** (`pofu-rig-clean`) has no ears and no front paws, so
  ears can flick and rotate and paws can move without holes.
- **Code does the motion** (ADR-0011, `companion-motion.md`): breathe,
  blink, squash and stretch, hop, lean, ear flicks, half-lids, catchlight
  gaze and sparkle (on `pofu-eyes-matte`), the cheek-pouch blend.
- **New idea (founder, 2026-11-02): the pouches fill with seeds.** Real
  hamsters carry sunflower seeds in their cheeks. Pofu's pouches blend from
  R1 → `pofu-cheeks-puff-1` → `pofu-cheeks-puff-2` as uncollected seeds
  accumulate; collecting empties them with a little hop. A glanceable
  "there is something to collect" without a badge.

| Reaction | Parts (edits of R1) | Code |
|---|---|---|
| Happy | eyes-happy | small bounce |
| Proud | eyes-happy + mouth-smirk | chin up, a hop |
| Sulky / jealous (playful) | mouth-pout (+ eyes-side for jealous) | half-lid, lean away, a puff of air |
| Surprised | mouth-o | small jump, eyes scale up a touch |
| Sleepy | eyes-closed + ears-droop | slow breath, z's |
| Eating seeds | paws-seed + mouth-chew + cheeks-puff-1 | chew cycle between chew and R1's smile |
| Waving | paws-wave | paw swing on a damped spring |
| Breathing calmly | eyes-closed + paws-belly | belly rises and falls with the orb |
| Unwell (soft, never sick) | mouth-worried + ears-droop + fur-matted | flattened, slow breath, unwell grade |
| Giggling | eyes-happy + mouth-open | quick shake |
| Curious peek | mouth-o + eyes-side | lean in from the edge |
| Celebrating | eyes-happy + mouth-open + paws-up | hop with squash |

Pilot (`batch-06-pofu-rig-pilot`): the clean plate, eyes-happy,
eyes-closed, mouth-pout and cheeks-puff-2. The lead composites the neutral
rig and happy, sleepy and sulky, checks the seams at 1× and 3×, then opens
`batch-06-pofu-rig`. Mochi and Fındık get blink and happy eyes there; their
working poses already exist.

## Day and night: code first

The rule: **code does light; paint does shape.**

| Code (no art) | Painted (an edit of the day master) |
|---|---|
| The night grade (`WorldGrade` night, golden hour) | Fire inside the çay ocağı's burner |
| Glow halos, bloom, light pools on the lawn | Lit window interiors (windmill L5, workshop), where a dark hole becomes a lit room |
| Flicker, steam, smoke, fireflies | A lantern's flame where its shape changes (decor, pond lanterns) |
| String-light bulbs glowing (a glow sprite per bulb) | — |
| Amber tea glasses, warm counter light (a tint under a mask) | — |

**Method:** the lit edit changes only the light-carrying part. The lead
turns it into an **emissive overlay** by difference against the day master
(registered pixel for pixel) and the app draws it above the night grade, so
the fire stays warm while the world goes blue. `batch-07-light-pilot`
paints the burner at L1 and L5 to test whether one overlay serves all five
levels; if it does, every later station needs one lit edit, not five.

**The çay ocağı's warmth:** measured, it is faded (median chroma 11 at L5
against 31 at L1), not cold in hue. The harmony grade restores it; the
re-take is in `batch-07-light` only if the restored L5 still reads cold
to the founder.

## Explorations

ADR-0018's amendment holds: the painted icon family, the seed jar, the
calm lantern and painted widgets are produced after the friends beta.
Before that, look-dev only:

- **Icons:** SF Symbols for system actions; painted icons only for domain
  concepts (seed, calm, wellbeing, breathing break), explored at 28, 44 and
  60 pt with legibility notes per take (does it read at 28 pt on light and
  dark glass, which shape carries it).
- **Key art:** App Store poster compositions with no painted text (A: the
  quiet island; B: Pofu close, the phone face down; C: the archipelago at
  golden hour).
- **UI ideation boards:** painted moods of a screen, for inspiration only.
  **The UI direction is now a hybrid of native Liquid Glass and custom
  painted elements, specified separately**; the boards never become UI
  assets and never paint glass.
- **Island concepts:** Çağlayan, Ayna and Revontuli (archipelago system,
  PR #64), two paintings each, before production plates exist.

## Decor spots

Decor spots (archipelago system section 5, PR #64) are not decided, so the
kit starts with a pilot of four pieces the prototype will certainly use,
one per Ayçiçeği spot: a bench (lawn), a paper lantern string (the çay
ocağı's awning), a toy sailboat (the pond edge), a mailbox (the door). All
are drawn on `design/art/templates/decor-guide.png` (the station guide's
scale; footprint half a station's width; a magenta hang line), so any piece
fits any spot of its family on any island. Placement keeps every object
inside the island's lawn (code: socket anchors, never free placement).

## The Codex start message

Paste this into a new Codex task:

```text
Read AGENTS.md and docs/design/art-production-plan.md.
Run the queue: take the first READY batch nobody is on, in parallel auto mode, track all.
Start with batch-05-fixes, then batch-06-pofu-rig, batch-07-light and batch-11-ui-pilot.
For every promoted master run `python3 -I tools/assets/harmony.py measure` and commit
the manifest in the same PR, or CI fails.
When you open a batch's PR, start the next READY batch at once on a new branch, until none is left.
Never start a BLOCKED batch, never promote an EXPLORATION batch, never merge.
Stop and report on any stop condition in AGENTS.md.
```

## Log

- 2026-11-02 (round 2): batch-05-fixes-pilot merged (#71); batch-06 pilot
  passed as composites (neutral against R1 dE 3.0); batch-07 pilot: cay-1-lit
  accepted, cay-5-lit failed `station_anchor` for its parent's own geometry
  (fixed: edits are anchored against their parent), night light is mostly
  code. batch-05-fixes, batch-06-pofu-rig, batch-07-light and the new
  batch-11-ui-pilot opened.
- 2026-11-02: queue created; batches 01, 03 and 04 merged; batch 03's
  skipped jobs moved to batch 05.
