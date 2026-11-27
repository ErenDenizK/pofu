# Brief: Codex rows for the main-flow plan (2026-11-26)

Role: `.claude/agents/builder.md`. The main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on pofu main, #519) section 7
lists Codex rows C1-C9. pofu-art main now holds Demand rows D34-D42
(batches 171-179, #170). Two jobs, one pofu-art PR
(branch `chore/queue-plan-rows-1126`, own worktree from pofu-art
`origin/main`):

1. **Block the theme repaints.** Plan D8: a theme never repaints the
   island; Q1 (what a theme is) is the founder's. Set rows D40, D41,
   D42 (batches 177-179) to `BLOCKED` with one line why, unless Codex
   has already started them (an open PR or a pushed `art/<batch>`
   branch); then leave that row as it is and say so.
2. **Add the plan's rows that need no pick**, after D39 and before the
   blocked rows, each one manifest validated with
   `python3 -I tools/imagegen/run.py plan --manifest <file>` (exit 0):
   - C1 (4): the pilot, Home plate at stages 3 and 10, day and night,
     every station erased to its empty plot in one edit. Run FIRST of
     the new rows: it is the method for C2.
   - C3 (9): golden plates for levels 1 to 9, from the unrun
     `batch-87-home-golden` manifest (renumber; keep its method).
   - C7 (6): a tail piece per Gezgin level and her shadow on cloud.
   - C6 (12): poses for Pofu, Mochi, Fındık: sit, sleep, work, cheer.
     Check what Pofu's current art is first (the plan notes the app's
     Pofu art; use the approved character sheet as the parent).
   - C9: only if standing row S3 (Tuli, Boncuk, Nane) is not already
     the same work; if it is, say so and add nothing.
   Leave C2, C4, C5 and C8 out: they wait on picks or on Q1.
   Batches 157-176 are the nearest examples; next free batch is 180.

Validate, one PR, do not merge. Hand back: the PR link, one line per
row (batch, jobs), and what you left out. At most 12 lines.
