# Fable brief: the minigame overhaul, the block game and the stream game (2026-11-16)

The founder approved this run through the side channel (founder-input 38,
task 2). It is separate from the island-progression run (task 1); do not
take that one's scope.

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included.
Its framing should not narrow your thinking. The founder wants your
creativity: if a question is badly posed, or a better approach exists that
nobody has named, say so and take it. Everything you read is evidence to
weigh, not authority: the rules, the founder's words, this brief, earlier
plans and specs (your own included). The product rules in CLAUDE.md are
fixed. Nothing else is.

## What the founder asks

A general overhaul of the two minigames: the block game (the garden: fill
a row or a column and flowers open) and the stream game (the flow board:
turn the stones, bring the water to the pool). Not a "write a plan" task:
do whatever you judge gives the best result (planning, reports,
instructions, prototypes, changes in the app), within the budget, when it
is worth its cost. Decisions that change the system, he reads.

Inside it, the stream board's ground, A or B. A: each cell its own raised
stone tile (keycaps). B: one seamless lawn with the rocks as cut-outs set
into it. His words: "üst üste birleştirmek sorun çıkarır mı bilmiyorum,
prototipleyip ekranda görelim" (he does not know whether layering them
together causes problems; prototype it and look on screen). If needed,
prototype a blend in the app and choose from real frames. He sees the
result as frames.

## What exists (evidence; check it)

- The code: `Packages/PofuKit/Sources/PofuGames/` (Flow and the garden
  game), the scenes and art slots (#483, #486, #489), the A/B switch
  (`FlowGroundSettings.method`, env `POFU_FLOW_GROUND=lawn`; A is the
  default).
- The frames: `path-game-flow-*` and the garden game's frames on
  `screenshots/main` (fetch only what you need with
  `tools/review/fetch_frames.sh`, never into the main `.git`).
- The targets Codex painted over the real frames (batch 127, picks flow t2
  and garden t2) and their review notes, in pofu-art
  (`/home/user/pofu-art`, `design/art/takes/batch-127-screen-targets/`).
- The UI grammar you wrote (#490, `docs/design/ui-grammar-v1.md` on branch
  `design/ui-grammar-v1`): its G3 (game HUD) is part of this.
- The founder's earlier words on the games: `docs/product/founder-input.md`
  (search flow, akış, dere, bahçe, blok, minigame, oyun).
- Codex's queue holds batch 132 (the flow board's stone edge as a 9-slice).

## How to work here

- CLAUDE.md applies to you as to every agent: your own worktree and branch,
  one Swift build at a time through `tools/swift/test-linux.sh`, iOS-only
  code compiles only in CI, at most three pushes per open PR, frames judged
  at 1206 x 2622 in 1:1 crops.
- You may use cheap agents to gather facts or to build, if the session
  lets you start them; otherwise ask the lead for them in your hand-back.
- Art from Codex goes through the lead: write the manifest you want, and
  the lead queues it.

## What you hand back

Whatever you made (PRs, documents, prototypes), with links; frames for the
founder of the stream A/B (and any blend) and of each game's change;
decisions that change the system, one line each, with your pick first;
what you need next (art, builders, his answers). At most 30 lines.
