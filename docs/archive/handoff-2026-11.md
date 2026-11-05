# Lead session handoffs, November 2026 (archived)

Older entries of [docs/handoff.md](../handoff.md), newest first. History
only: the current state is in the [roadmap](../roadmap.md).

## 2026-11-05

**Done:** refit and poses merged (#156, #157); dependents and the
findik salvage READY (#158). **Game plan v1** (`docs/product/game-plan.md`):
one canonical, table-first plan (day by day, islands with a rising curve,
three engines, social from day 2, Book Two, screens). Founder got a Turkish
timeline image. Finding: code still runs the old station islands (Yıldız,
Kaplıca, Kitap); the plan retires them.

**Next:** founder's answers on game-plan section 9 (silence = the
recommendation); then the code list in its section 10, in order, starting
with `PofuCore` (harbor day 3, retire station islands, wonder-island model).
Hub questions not yet posted.

## 2026-11-04 (evening)

**Done:** reviewed and merged the art PRs #148 and #150-#153 (poses, workshop-1-lit,
three icons; review in the art-production-plan log). Most skips were size-only
(the model ignores pixel sizes in prompts), so #154 adds `qa.fit_to_guide`,
a downscale about the ground anchor. #155 queues `refit-2026-11-04` (re-promote
the bench, pier-1, lighthouse-1 and harbor-ferry-1 with no generation) and opens
batch-20-poses.

**Next:** refit (#156) and poses (#157) merged; the 12 dependents and the
findik-surprised salvage are READY (2026-11-05). Watch whether level edits of fitted parents come back oversized again.
The 2026-11-04 end-of-day list below still applies (founder runbook, harbor
scene, lore #135).

## 2026-11-04 (end of day)

**Done:** budget rules in CLAUDE.md (#139); vertical slice v0 plan
(`docs/archive/vertical-slice.md`) and its build: asset integration script
`tools/assets/integrate.py` (#140), home plate `island-main-l-v3` graded
soft at 0.6 (#142), garden minigame painted art (#143), harbor plate, goat,
Simit poses and a Rehearsal "Next day" button (#144); motion beats now
opt-in via the `beats` label (#145). Codex queue fed from a certainty list
(#141): decor pilot, workshop-1-lit, retry-2026-11-04 (ferries, icons by
the one-metaphor rule), poses pilot. Friend deck:
https://claude.ai/artifact/NcowKw7gZNUZX8nABwfncK (founder shares it).

**Next:**
1. Founder installs the slice on his iPhone (free Personal Team,
   `docs/development.md`); give him a one-page Turkish runbook when he
   is ready; collect his "felt wrong" list.
2. Known gap: the harbor is map-only (no walkable scene).
3. Review Codex PRs as they land (pilot first); loop 3 short doc only
   with a reason (rising curve, three minigames, social early).
4. Lore PR #135 waits for the founder.

## 2026-11-04 (from the 2026-11-03 night session)

**Budget first.** The founder's plan limit burned far too fast. Work at
about a third of the 2026-11-03 spend: at most two agents, no Opus
sub-agent unless a design judgement truly needs it, no new loop or deck
without asking, CI once per finished change. Measured costs for scale:
queue grooming 127k, product plan 129k, light standard 197k, design
loop 2 253k, rename ~280k, deck ~60k (lead).

**Done 2026-11-03 night:** merged art PRs #117, #122, #123, #128 (review
notes in `docs/design/art-production-plan.md`); queue groomed (#129: READY
left = decor pilot 4 jobs, workshop-1-lit 1 job); light standard (#134,
warn-only; finding: the in-app home plate `island-main-s` fails it, p2 61,
spread 31, haze 0.38); design loop 2 (#133, #136: cluster atmospheres, hour
rule, playable-island blocks, verbal three zooms, lore and plot ladder);
English rename: map (#130), Swift (#132); the assets layer
(`refactor/english-assets`) was finishing on CI when the session ended:
check whether its PR merged, else finish it. Content/docs ids layer not
started. Founder deck (loop 2, Turkish):
https://claude.ai/artifact/9Fk2X95f5qZRVqjyWSa8ck. Lore PR #135 stays open.

**Founder feedback on the deck** (founder-input, 2026-11-04 night) changes
the plan; it outranks loop 2 where they disagree:
- The curve must rise: each new island a little better than the last;
  not every island god-tier (Gezgin at 10 makes Revontuli look simple).
- Not every island needs a game: story, minigame or upgrade; home is the
  centre; about three minigames in total (matches the lead's "three
  engines" call, now smaller).
- Simplify Çağlayan; characters (Pofu, Mochi) need real turns.
- Open the social layer within the first days, not at the end; define
  what comes after day 50.
- Show islands as they would look and play in the game, not as prose.
- Haze grows toward the background and falls toward the centre.

**Next, in order (small, concrete):**
1. Art integration: a script that copies approved masters into the asset
   catalogs (inventory: 52 masters, ~6 groups in the app; Simit, the goat,
   İskele plate, batch-12 minigame art, icons, paper surfaces missing).
   Grade the home plate with `tools/art/grade_take.py` toward a depth-aware
   haze (background hazier, centre clearer), then a before/after shot.
2. Garden minigame with its painted art; İskele as the harbor district
   with Simit and the goat. Screenshots to the founder.
3. A short loop-3 doc (one Opus pass, ≤ 100k): the rising curve, three
   minigames, social layer early, post-day-50, Çağlayan simplified,
   character turns. No images, no deck; one mock-up screenshot per island
   type only if cheap.
4. Codex: keep only small production batches READY (decor pilot, then
   the four retry jobs with English ids and the icon semantics rule).

**Founder preferences:** he gives views, not orders; humans write
dialogue lines; review by screenshots and short videos; Opus for design
judgement, Sonnet for execution; local Swift install fails on Docker Hub
429 here, so Swift is proven in CI.
