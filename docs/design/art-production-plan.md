# Art production plan: the living queue

The art line (Codex in the cloud, `AGENTS.md`, `tools/imagegen`) must never
idle (founder, 2026-11-02: "it's a factory; every time it's idle we lose
time"). This page is the queue it pulls from. The lead keeps it current;
Codex reads it at the start of every task.

## Standing rules

1. **The line never ends** (founder, 2026-11-05: "Codex sits idle. From now
   on it must never stop"). Codex works the `READY` rows in order; when none
   is left it takes the `BACKLOG` rows ([the backlog](#the-backlog)) in
   order; when the backlog is exhausted it starts again from its first row
   with fresh variations (new takes under new exploration ids `-v2`, `-v3`,
   ...; never the same prompt twice). When it opens a batch PR it starts the
   next batch at once on its own branch, never waiting for a review or a
   merge. There is no "queue empty" state and no stop after a batch.
2. **Iterate, then scale** (founder, 2026-11-02). Lock the method on a small
   pilot, learn from its mistakes, then run the batch. Every new batch has a
   **pilot of 2 to 5 jobs** in its own manifest (`batch-NN-<name>-pilot`,
   `status: open`); the rest of the batch is a second manifest
   (`batch-NN-<name>`, `status: blocked`) that opens only after the lead has
   reviewed the pilot. Pilots come first in the queue, so the line always has
   something new to try while the lead reviews. A job gated behind a pilot is
   skipped and Codex continues with other rows; the gate never stops the line.
3. **Do not regenerate to fix the old.** Existing assets are brought in line
   by the harmony grade (code, `tools/assets/harmony.py`, in progress on
   `feat/look-round-2`). Only an asset the grade cannot fix (wrong shape,
   wrong detail level, wrong content) is regenerated, and only after the
   lead names it here as an outlier.
4. **Explorations never ship.** An `EXPLORATION` batch is generated, posted
   and auto-picked, but never promoted; its takes, contact sheet and
   `review.yaml` are committed for deciding.
5. **A failed job skips, it does not stop the line** (`AGENTS.md`, Stop
   conditions, 2026-11-02): after its one retry it is recorded as skipped with
   its reason, its dependents are skipped, and Codex goes on to the next job and
   batch. Global stop only for account, sign-in, quota or usage-limit messages,
   three refusals or image-less answers in a row, or identity or upload
   corruption (a single refusal is skipped, never retried or rephrased).
   Before each batch Codex re-reads this queue.
6. **Publish before you generate.** Selected candidates that were never promoted
   (the 14 rig picks of batch 06, `pond-5-lit`, 4 UI takes of batch 11) are
   published from their retained takes first, without regenerating.
7. **Decor is checked against its guide.** A prop that attaches `decor-guide`
   is registered on the guide and gets a `decor_anchor` check (footprint width,
   height bar, ground line; a `decor: hang` piece uses the hang line), so the
   decor-bench failure of batch 08 (740 px wide against a 360 px footprint) is
   caught by QA, not by eye.

### How the lead marks a batch

- **READY:** its manifest is on `main` with `status: open`, and the queue row
  says `READY`. Codex may start it.
- **BLOCKED:** `status: blocked` with `blocked_on` naming the gate (usually
  "the lead's review of the pilot"). Codex never starts it.
- **Opening a batch** is one PR by the lead: flip `status` to `open`, drop
  `blocked_on`, apply what the pilot taught to the prompts, and change the
  row here to `READY`. The same PR merges the pilot's art.
- **BACKLOG:** an exploration manifest (`x-` ids, `status: open`, never
  promoted) listed in [the backlog](#the-backlog). Codex takes these when no
  `READY` row is left.
- **DONE:** merged; the row moves to the log at the bottom.

## The queue

Order is priority. Codex takes the first `READY` row nobody is working on
(an open PR or a pushed `art/<batch>/...` branch means someone is), and
**when its PR is open it continues to the next `READY` row automatically**;
when none is left it moves on to [the backlog](#the-backlog).

| # | Batch | Kind | Purpose | Needs | Jobs | State |
|---|---|---|---|---|---|---|
| 0a | `batch-33-home-showcase-pilot` | production | The home showcase, pilot ([home layout](../product/home-layout.md) §9): `path-lamp` (the lamp family), `hive-1` (the hive ladder root), `material-moss` (the material family), `door-mochi` (the earth-face door family, matched to the plate's round door). Review: each reads at 28 pt, matches tea-stall-1's finish, sits on its guide | main | 4 | **READY** |
| 0b | `batch-34-islands-in-game` | exploration | The founder's question (2026-11-05): the future islands as they look in the game camera, stuck and healed (Çağlayan simplified and warm, Revontuli, Emanet, Mehtap), Gezgin form 1 and form 2 docked at the harbor, home at IL5 and at Tam Çiçek ([home layout](../product/home-layout.md) §10). Never promoted; Çağlayan and Gezgin first | main | 12 | **READY** |
| 0c | `batch-33-home-showcase` | production | The rest of the showcase's "now" list: hive L2-L5, five materials, two doors, the hill gate, the guest stall, the harbor bell, the goat at work, the frogs | the lead's review of row 0a | 18 | BLOCKED on the pilot review |
| 1 | dependents | production | The refit pilot passed review (#156, clean edges). Run the skipped dependents from their own manifests: `batch-08-decor-pilot --only decor-lanterns decor-sailboat decor-mailbox`; `batch-21-harbor-ladders --only pier-2 pier-3 pier-4 pier-5 lighthouse-2 lighthouse-3 lighthouse-4 lighthouse-5`; `retry-2026-11-04 --only harbor-ferry-2`. Level edits must keep the parent's scale (station_anchor width bar); the guide fit does not touch edits, so report any edit that grows | main | 12 | **READY** |
| 2 | `findik-surprised` salvage | production | **No generation.** Takes 2 and 3 of #157 passed QA but their lossless master exceeds the 600 KB cap at 1024x1536. The lead approves Findik's parent canvas, 870x1306 (`findik-base`, set as `canvas` in batch-20-poses.yaml): re-post the retained originals at that canvas, pick and promote as usual | main | 1 | **READY** |
| 4 | `batch-11-ui` | production | What is still missing of ui-system-v2 section 6 after batches 11-13 and the retry: night variants of the faces, game layer extras, the remaining domain icons, surfaces. The lead lists the exact gaps when it writes the manifest | the light standard and the icon semantics rule | about 15 | BLOCKED, no manifest yet |
| 5 | `batch-08-decor` | production | The home decor kit (Ayçiçeği is the centre, so it ships); the lead lists the pieces after the pilot review | a passed row 1 | none yet | BLOCKED on the pilot review, no manifest yet |

Home stations: nothing else needs a painted night variant (tea stall, windmill and pond are merged, the workshop doorway is row 2; the garden and the simit cart carry no light-carrying part, their night is code).

Rows to come: the design-loop-2 concepts (batch-19) and the lead's production
batches are added above row 3 as `READY` by their own PRs.

## The backlog

Work for when no `READY` row is left, so the line never idles. Every batch
here is an **exploration**: `x-` ids, `status: open`, complete prompts, never
promoted (takes, contact sheet and `review.yaml` are committed under
`design/art/takes/<batch>/<id>/`). Codex takes the rows in order, one PR per
batch. The rows B-A to B-F (home growth, from [home progression](../product/home-progression.md)) come first, then B1 to B6. After the last row it starts again at the first row with fresh variations:
the manifest copied as `<batch>-v2` (then `-v3`, ...) with `x-<id>-v2` job
ids and a new angle, pose, camera, time of day or palette per job. The lead
adds rows at the bottom; it also reads the takes and promotes a concept into a
real production batch when one earns it.

| # | Batch | Purpose | Jobs | State |
|---|---|---|---|---|
| B-A | `batch-28-home-shops-concepts` | Home progression concepts (founder 2026-11-05): the hive (levels 1, 3, 5) and the three Book Two hilltop add-ons, Fanus's greenhouse, Çömlek's kiln and Mehtap's moon telescope (levels 1 to 3), on the station guide | 12 | BACKLOG |
| B-B | `batch-29-residents-at-work` | Each home resident at their fixed favourite station in a working pose (Mochi, Simit, the goat, the frogs, Fındık, Koke's sprout), plus five heart level-up moments | 11 | BACKLOG |
| B-C | `batch-30-decor-sets` | Decor sets on the decor guide: island gifts (4) and Liman (4), plus a composed corner for Bahçe, Ada hediyeleri, Liman and Sakinler | 12 | BACKLOG |
| B-D | `batch-30b-decor-seasons-1`, `batch-30c-decor-seasons-2` | The four season sets (Bahar, Yaz, Güz, Kış), four pieces each on the decor guide, plus a corner per set; two manifests so each stays at 10 jobs | 10 + 10 | BACKLOG |
| B-E | `batch-31-island-milestones` | Concept plates: the island at levels 1, 4, 7, 10, the closed hill gate, the Tam Çiçek ceremony night, the Tepe, the Altın Ada | 8 | BACKLOG |
| B-F | `batch-32-weekly-themes` | Eight small weekly themes for home: a visitor, a market stall, kites, a lantern night, a fishing day, rain boots, a picnic, a stargazing night | 8 | BACKLOG |
| B1 | `batch-22-gezgin-forms` | Gezgin, the cloud-whale Nazlı: form 1 (humble, tired, a mossy patch with bench and mooring post, lantern hook, scar shaped like a switched-off light) and form 2 (grown, lush island with grove and waterfall, hook and scar glowing); side views, three-quarter, docked at a pier, at night | 9 | BACKLOG |
| B2 | `batch-23-stickers` | Emoji and sticker sheets of Pofu and Mochi (happy, sleepy, surprised, proud, sulky, laughing, waving, tea, thinking, love) plus Simit, Fındık, the goat and duo stickers, transparent | 9 | BACKLOG |
| B3 | `batch-24-home-materials` | Upgrade props for the home stations on the decor guide: tea set, samovar, cushions, lantern, flower box, bench 2, mailbox 2, rope, crates, weather vane, boat 2 | 11 | BACKLOG |
| B4 | `batch-25-seasons` | Concept frames of Ayçiçeği in spring, summer, autumn, first snow, rain, summer evening, snow at night | 7 | BACKLOG |
| B5 | `batch-26-residents-concepts` | Concept portraits of Damla, Tuli, Boncuk, Nane and Yosun, each "first seen small" and "revealed grand" | 10 | BACKLOG |
| B6 | `batch-27-ui-materials` | Tileable surface materials (paper, linen, wood, glazed clay, frosted glass study, felt) and ornaments (ribbons, stamps, wax seals, tags) | 10 | BACKLOG |

Ideas for the next rows when the lead has none: more props and materials
(harbor kit, night lanterns), emoji packs for the other residents, empty-state
and onboarding vignettes, weather and sky studies, seasons for a wonder
island, paper-craft textures. Anything useful beats idling.

## Home upgrade ladder

Checked 2026-11-04 against `design/art/stations/<id>/` (the approved masters),
the level table in `docs/product/game-design.md` ("Idle production and
stations": "what each home and harbor level looks like") and the ladders in
`Packages/PofuKit/Sources/PofuCore/Game/Archipelago.swift`. The Swift data
holds only costs and rates per level, no visual description, so the
descriptions below come from the game design table. Every level is an edit
of the level before. Ids are the English ones (`tea-stall` was `cay`,
`bagel-cart` was `simit`; see `docs/development/rename-map.md` and
`tools/imagegen/legacy_ids.py`).

Legend: **yes** = approved master exists; **MISSING** = no master and no
job; a `lit` entry is the painted night overlay source.

| Station | L1 | L2 | L3 | L4 | L5 | Lit overlay |
|---|---|---|---|---|---|---|
| garden (home) | yes | yes | yes | yes | yes | none, night is code |
| tea-stall (home) | yes | yes | yes | yes | yes | `tea-stall-1-lit` yes; `-5-lit` dropped on purpose (batch-07) |
| pond (home) | yes | yes | yes | yes | yes | `pond-5-lit` yes |
| workshop (home) | yes | yes | yes | yes | yes | `workshop-1-lit` queued (row 2) |
| windmill (home) | yes | yes | yes | yes | yes | `windmill-5-lit` yes |
| bagel-cart (harbor) | yes | yes | yes | yes | yes | none, night is code |
| pier (harbor) | MISSING | MISSING | MISSING | MISSING | MISSING | none planned |
| lighthouse (harbor) | MISSING | MISSING | MISSING | MISSING | MISSING | beam is code; lamp room needs a lit edit at L2 |

**Home: the ladder is complete, 25 of 25 masters.** There is no missing
home level, so no home manifest is written (nothing to feed Codex). The only
open home art is `workshop-1-lit`, already READY as queue row 2. If the
founder's dogfood shows a level that does not read as an upgrade, that is a
regenerate-by-grade question per level, not a gap.

Missing harbor levels (manifest `batch-21-harbor-ladders`, queue row 3d). Descriptions from the game design table; a level without
one would say so (none lack one):

- pier-1: planks and posts over the clouds (the existing `harbor-island-s`
  plate already shows a short plank pier; the station sprite is separate).
- pier-2: adds a lantern post (`harbor-lamp-1` is a decor lamp, not a level).
- pier-3: the little ferry moors here (`harbor-ferry-1` and `harbor-ferry-2`
  are in retry row 3; the level sprite shows the moored ferry).
- pier-4: adds a bench and two tea glasses.
- pier-5: adds bunting from post to post.
- lighthouse-1: a striped tower.
- lighthouse-2: the lamp room is lit (needs the lamp-room glow as a painted
  edit; the beam itself is code).
- lighthouse-3: a balcony all around.
- lighthouse-4: a slow, warm beam at night (code and glow, the painted
  change is small or none).
- lighthouse-5: a flag and a garden at its foot.

Story link (`docs/product/story-delivery.md` section 4.3): the harbor pier
(first planks) lets the ferry dock, and tea-stall L3 and workshop L3 open
side beats; all three already have their masters, so story work is not
blocked on art.

Pilot: pier-1 and lighthouse-1, the rest gated on it.

**Order of work:** top to bottom. Rows 1 and 2 are re-runs by `--only` of
jobs that never produced a pick; every other earlier row is delivered and
lives in the Log. Batch 02 (Glass++ production) stays blocked until the
friends beta (ADR-0018 amendment).

## Review 2026-11-03 (lead)

Of batches 16 to 18 and the retry (#117, #122, #123, #128). Decisions only:

- **App icon:** direction A (Pofu's face on a dark sky) is recommended: the
  only one that says "Pofu" at small size. Pending the founder. Tinted
  variants of A were muddy brown: iOS tinted icons need a luminance-only
  master, not a brown recolour. B (lantern and sleeping Pofu) is too small
  at 60 px; C (sprout on an island) reads as a generic garden app.
- **Icon semantics rule:** one metaphor per action, and every icon passes a
  silhouette test at 28 pt before it is called done. `icon-plus` and
  `icon-skip` both used a sunflower, `icon-friend` reads "plant", and
  `icon-island` reads as a pie. Style is consistent, meaning is not: fixed by
  briefs (row 3), not by regenerating the family wholesale.
- **No regeneration for haze or contrast.** Batch 17 and 18 frames are
  washed out under one shared sky, cloud sea and daylight. That is fixed by
  grading and the coming light standard, not by new takes.
- **Kept:** batch 17 silhouettes (Çağlayan, Fanus, Gezgin, Mehtap crescent
  without the face, Revontuli, Çömlek-b, Koke-b, Çanlar-a, Leylek-a),
  batch 18 backdrop day, dusk and night (night strongest), Çağlayan pools as
  windows (best idea of the round) and the Pofu and Mochi duo. The
  water-cluster delta must be bolder.
- **Simit and the goat** (retry): on-model and kept.

## What the retry taught (2026-11-03)

Batches 11 to 14 skipped 3 + 6 + 14 + 9 jobs. Read from their `review.yaml`
files, none was bad art:

| Job | Check or gate | Value against threshold | Cause |
|---|---|---|---|
| ui-face-primary | palette_drift fail | mean dE 10.1-17.7, off-palette 28-85% (fail 4.5 / 10%) | (a)/(b) violet is in the `ui` palette, which the drift check did not hold |
| ui-jar-full | manual edit_stability > 0.9 | 0.77-0.79 (automated warn 0.75) | (b) refilling the window cannot keep 90% |
| ui-lantern-on | manual edit_stability > 0.9, palette_drift | 0.62-0.63; dE 2.3-3.1 | (a) lit glow is world-night colors, a region edit |
| game-bloom-right | manual centre shift, chroma fail on t4 | centre x 487-507 (front itself 501); chroma 60.5 | (b) edit-keep forbids moving the head; (a) saturated accent |
| 5 plot-tile glazes | edit_stability, edit_chroma, palette_drift | 0.00-0.02 kept; chroma x0.5-2.3; rose dE 6.4-7.1 | (a) a recolor changes every color by definition |
| ui-sheet-paper (pilot) | manual: bottom runs off canvas | 0 alpha on every border, 4 of 4 | (b) an image model draws an inset card |
| 13 other jobs of batch 13 | none (not generated) | pilot cascade | (b) the header skipped the batch though icons never attach the sheet |
| iskele-vapur-1 (pilot) | manual footprint and flat waterline; station_anchor warn | width 875-935 against 720 | (b) the brief said "fills the footprint" for a long hull and asked for a round hull and a flat waterline |
| simit-kitten (pilot) | palette_drift fail | mean dE 4.0-4.4, off-palette 8-9% (#DD8844, #CC7733) | (a)/(b) a honey tabby is not in Pofu's peach palette |
| 7 other iskele jobs | none (not generated) | pilot cascade | (b) props attached the ferry, the goat attached Simit |

Fixes: `LIMITS_BY_KIND["ui"]` (chroma p95 warn 56, fail 64, like characters);
`acceptance: {edit_mode: recolor | region}` (recolor swaps edit_stability and
edit_chroma for `edit_silhouette`, `edit_structure` and `edit_lightness`;
region relaxes edit_kept to 0.50/0.30 and adds `edit_silhouette`); a job
field `palettes:` that extends the drift palettes, with new locked palettes
`game-glazes` and `character-tabby` in `palettes.json`; rewritten briefs; no
pilot gate beyond real dependencies. Unchanged: every chroma, value, detail,
lock-load and drift threshold, the station and icon checks, and
edit_stability for ordinary edits. Re-measured on the old takes: glazes pass
the new shape and structure checks (IoU 0.94-1.00, r 0.83-0.97; terracotta
warns on lightness by 11-15 L), rose and lilac drift is 0.5-1.2 against
`game-glazes`, the kitten is 0.6-0.8% off-palette with `character-tabby`.

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
Run the queue forever: take the first READY batch nobody is on, in parallel auto mode, track all.
Start at the top of the queue; a row names its --only jobs when it is a re-run.
For every promoted master run `python3 -I tools/assets/harmony.py measure` and commit
the manifest in the same PR, or CI fails.
When you open a batch's PR, start the next batch at once on a new branch. When no READY
batch is left, take the BACKLOG rows in order; when the backlog is done, start again from
its first row with fresh variations (-v2, -v3, ...). A failed or refused job is skipped
and recorded, never retried or rephrased; go on with the next job.
Never start a BLOCKED batch, never promote an EXPLORATION batch, never merge.
Stop only on a global stop condition in AGENTS.md.
```

## Log

- 2026-11-05 (lead review): merged #156 (refit: decor-bench, pier-1, lighthouse-1, harbor-ferry-1 at x0.77-0.84, edges clean on dark and light grounds) and #157 (simit-sleepy, simit-surprised). The 12 dependents and the findik-surprised salvage open.

- 2026-11-04 (lead review): merged #148, #150-#153. Promoted `workshop-1-lit`, `simit-happy`, `mochi-surprised`, `icon-friend`, `icon-plus`, `icon-breath`. Skips kept: `icon-island` (palette drift), `ui-sheet-paper-night` (edit structure; a recolor profile is the fix, not a retry), `icon-skip` (refusal, stays blocked). Finding: the image model ignores pixel sizes in prompts (two retries each), so size moved to code (#154); the refit row re-promotes without regeneration.

- 2026-11-03 (queue groomed): every delivered row left the queue.
  Delivered and merged: batch-05-fixes (#82), batch-06-pofu-rig (#83, all 19
  jobs incl. Mochi and Findik eyes), batch-07-light (#84; `pond-5-lit`,
  `windmill-5-lit`; `workshop-1-lit` left, `cay-5-lit` dropped),
  batch-11-ui-pilot (#87, #94), batch-12-minigame-art (#97), batch-13-ui-rest
  (#98), batch-14-iskele (#99), batch-09 and batch-10 pilots (#91, #93),
  batch-15-explore (#100), batch-16-brand-explore (#110, #112, #122),
  batch-17-islands-v2 (#114, #123), batch-18-loop-1-concepts (#126, #128) and
  retry-2026-11-03 (#111, #117: 28 of 32 jobs). Batch-08-decor-pilot (#88,
  #95) produced no pick and was re-queued as row 1.
- 2026-11-03 (closed as superseded): `batch-10-island-concepts` (never
  written) by batches 17 and 18, which answer it under the uniqueness
  contract. `batch-15-explore` skipped jobs `x-appicon-layer-island`,
  `x-appicon-layer-sky` (app icon redone in batch 16), `x-winter-island`
  (batch 17 hub edits) and `x-res-sumi` (resident sheets wait for the story
  work); not re-queued. `batch-16` skipped salvage variants (`icon-b-tinted`,
  `icon-c-*`, `infographic`) are exploration only and not re-queued.
- 2026-11-02 (round 2): batch-05-fixes-pilot merged (#71); batch-06 pilot
  passed as composites (neutral against R1 dE 3.0); batch-07 pilot: cay-1-lit
  accepted, cay-5-lit failed `station_anchor` for its parent's own geometry
  (fixed: edits are anchored against their parent), night light is mostly
  code. batch-05-fixes, batch-06-pofu-rig, batch-07-light and the new
  batch-11-ui-pilot opened.
- 2026-11-02: queue created; batches 01, 03 and 04 merged; batch 03's
  skipped jobs moved to batch 05.
