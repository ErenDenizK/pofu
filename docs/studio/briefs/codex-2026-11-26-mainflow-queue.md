# Brief: a long Codex queue for the main flow (2026-11-26)

Role: `.claude/agents/builder.md`. Founder-input 46 (2026-11-26): Codex
has been idle about 16 hours (its queue ended with batch 170). While Fable
plans the main flow, the line must not stop. Write a long queue of SAFE
work: directions he has already approved, nothing that needs a new choice
from him. Batches 166-170 are delivered and merged; the next free batch
number is 171 (check `tools/imagegen/manifest/` on pofu-art main).

## What he asked for, in his words' order

1. **The Gezgin's source drawings and levels.** Batch 160 painted her
   three levels (asleep and awake) and 164 her moorings. Find what a
   finished Gezgin still needs (the stage 4 spec in pofu
   `docs/design/assessment-2026-11-24-path.md` and
   `docs/studio/briefs/2026-11-24-*`): e.g. front and three-quarter views
   of each level, sail and lantern states, at the map scale and at the
   near scale, as cut-outs. Never from behind (fi 44).
2. **Home's station levels, painted INTO the island.** Each station's
   five levels as they look on the island itself, by editing the shipped
   Home plate at that station's spot (the in-place edit method of
   batches 123/129 and 117: an edit keeps what is there where it is, and
   changes only the station). Read pofu `PofuWorld` for the station list
   and spots, and the plates in `docs/state/plates.yaml`. Breadth first:
   level 2 of every station, then level 3, and so on.
3. **Home's themes.** The approved theme idea (search pofu docs for
   "theme" / "tema": ADRs, story map, night plan, assessment) painted as
   whole-island variants of the shipped Home plate, same frame, same
   layout, only season/time/material changes the doc names.
4. Anything else a path step needs that you find while reading, only if
   it is already approved.

Aim for 60-100 jobs in 6-10 batches, so the line runs a day or more.
Calm, simple concept-art feel, few things in frame; he disliked flashy.
Codex paints no glass, panel, card, button or text.

## How

- Own worktree:
  `git -C /home/user/pofu-art fetch origin && git -C /home/user/pofu-art worktree add /home/user/wt/art-mainflow -b chore/queue-mainflow-1126 origin/main`.
- Follow `AGENTS.md` and `QUEUE.md`; batches 157-170 are the nearest
  examples. Parents must be on main (`approved:` with the QA auto-pick
  where no founder pick exists).
- Validate each manifest: `python3 -I tools/imagegen/run.py plan --manifest <file>` (exit 0).
- Add Demand rows after D33 (move D29-D33 to `QUEUE-LOG.md` as delivered:
  pofu-art #164-#167, #169), all READY, keeping the night rule (two
  concept jobs at once; on a quota wall record the skip and go on).
- One PR in pofu-art. Commit trailer exactly as your brief's system
  reminder gives it; no model name in commits or PR.

## Hand back

The PR link, one line per batch with what it serves and job count, and
what you left out and why. At most 15 lines.
