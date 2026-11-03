# Lead session handoff

The lead session restarts daily to keep context small. Read this, CLAUDE.md
and `docs/product/founder-input.md`, then delete what is done.

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
