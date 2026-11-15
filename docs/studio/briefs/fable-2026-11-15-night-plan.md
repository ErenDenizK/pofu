# Fable brief: the state of Pofu and the plan for tonight, tomorrow and after (2026-11-15)

The founder approved this run through the side channel (founder-input 35).

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included.
Its framing and options should not narrow your thinking. The founder wants
your creativity: if a question is badly posed, or a better approach exists
that nobody has named, say so and take it. Everything you read is evidence
to weigh, not authority: the rules, the founder's words, this brief, and
earlier plans and specs (your own included). The product rules in
CLAUDE.md are fixed. Nothing else is.

## What the founder wants

A full assessment, now and looking forward, and from it two things he can
run without being asked anything more. The art line must not stop while
he sleeps: Codex's queue had no new work from about 21:20 tonight. The
lead has queued two pilots as a bridge (pofu-art #91):
- `batch-121-flow-banks-ab`: the flow board's grass and rock, as keycaps
  or as one seamless ground. He picks from in-app frames.
- `batch-122-far-camera-ui`: the far camera with its interface, painted
  over today's real Map frame.

Three areas, as he named them:

1. **Technical.** What the app and the world presentation still need
   after #474 to #478:
   - WP1 to WP3 are merged.
   - WP4 (mattes and backdrop, #480) is open; the lead's first look found
     the backdrop fill under the island smeary at 1:1, painted content cut
     by the matte, and 6 of 21 states still on the old matte.
   - WP6 (the Map in journey order) is open.
2. **Production.**
   - Every visual the app needs and does not have.
   - Every place still drawn in code, flow cells included. He wants no
     code-drawn pictures in the game; native glass is not that.
   - The plan for each.
   - Which methods worked and which did not.
   - Codex's consistency: shared light, references, variants against
     repetition (one boulder five times on one board).
3. **App.** What stands before the polished build he will judge as a user:
   - UI grammar (your own approved brief,
     `fable-2026-11-14-ui-grammar.md`, has not run yet);
   - minigame interfaces;
   - upgrades ("upgrades don't show");
   - motion;
   - sound (music waits for his word).

## What you read

Raw facts, gathered tonight by cheap agents. Facts, not judgements;
check what matters:
- `docs/research/night-2026-11-15-code-drawn.md`: every code-drawn visual.
- `docs/research/night-2026-11-15-codex-history.md`: every batch since
  about 60, its verdict, what shipped, what worked.
- `docs/research/night-2026-11-15-app-state.md`: the eight areas, from UI
  grammar to the days 1-21.

The source of truth:
- the code at origin/main;
- the player-path frames at 1206 x 2622: fetch only what you need with
  `tools/review/fetch_frames.sh`, never into the main `.git` (it filled
  the disk three times);
- pofu-art's `QUEUE.md`, `AGENTS.md` and manifests (a checkout at
  /home/user/pofu-art: fetch and read with `git show origin/main:...`).

The founder's own words, items 22 to 35 of
`docs/product/founder-input.md`, especially:
- 26 (his first phone session);
- 28;
- 32 (his notes on the proofs);
- 33 (far, mid and near are design and choreography);
- 35 (this run).

The plans in flight:
- `docs/design/world-presentation-build-spec.md`;
- `world-presentation-v2.md` and `feel-and-world-v1.md` on the
  `design/feel-and-world` branch;
- `docs/design/asset-system-v1.md`.

## What you hand back

One document, `docs/design/night-plan-2026-11-15.md`, with three parts:

1. **The assessment.** Short, ranked by what the player feels.
2. **The plan.**
   - **Now** (tonight and tomorrow) and **after**, in order.
   - Each step names who does it: the lead, a builder (which model),
     Fable, Codex, or the founder (only his picks).
   - Each step names what it waits on and how it will be judged.
   - At most three builders run at once on disjoint files. The disk has
     about 6 to 9 GB free, so builders share it. One Swift build at a time.
3. **The Codex queue itself,** ready for the lead to commit to pofu-art
   as written.
   - Ordered READY Demand rows for tonight and tomorrow, with pilot gates
     where a method is unproven.
   - For each batch, a manifest in the format of the existing ones
     (header with why, order, fallbacks, review checks; jobs with
     `prompt`, `attach` and `notes`; `ui` jobs carry no `light`). Check
     each with `python3 tools/imagegen/run.py plan --manifest <file>` from
     the pofu-art checkout. Write the files into a branch of pofu-art
     named `chore/queue-fable-night`, push it, and do not open a PR: the
     lead will.
   - **One long-running standing job of real work,** so the queue never
     empties again. It should be something the app truly needs that can
     absorb any amount of Codex time and still be useful when the lead
     next looks, replacing the "paint the next null plate cell" step that
     was paused (pofu-art #64).
   - What Codex does well and badly, from the history, should shape
     every row.

Say where the founder must choose, with the option you would pick. He
answers in Turkish, from his phone; keep questions to one line each.
