# Brief: Codex plot ladders for five stations (2026-11-27)

Role: `.claude/agents/builder.md`. Step 1 of the main-flow plan (stations
grow on the island). The 1c builder proved that batches 173-176 (station
levels painted into the whole Home plate) cannot be cut: each take
re-renders the whole plate, so nothing lines up with the erased base, and
stations shift between levels. What did work is batch 134
(`batch-134-plot-pilot`): a crop of one station's plot, each level painted
aligned to the same frame, so a diff cuts the look cleanly (pofu #521
shipped the windmill from it).

One pofu-art PR (branch `chore/queue-plot-ladders-1127`, sparse worktree
from `origin/main`), not merged: manifests + Demand rows, inserted FIRST
in Demand (step 1 waits on them), one batch per station, next free batch
numbers. Stations: garden (sunflower garden), bagel cart, workshop,
lighthouse, pier; the tea stall has its looks (batch 123) and the windmill
and pond are batch 134's.

Copy batch 134's method exactly (read its manifest and the windmill and
pond review.yaml): the crop window per station from pofu
`plate-home.json` `stations`/tap polygons; level 1 as an edit of the
erased plot crop (batch 117/182 picks; erased bases on main), each level
N+1 as an edit of level N's pick in the same frame so they stay aligned;
5 levels; what each level adds from batch 123/129's ladder (the station
looks of 173-176 may be attached as STYLE references for what a level
looks like, never as the edit parent). Then a night relight row per
station for levels 1-5 (plan row C5) after the day rows, editing the day
picks (QA auto-pick until the lead picks). Because levels chain, a job
whose parent has no pick yet waits; write that in the row fallbacks.

Validate each manifest with `python3 -I tools/imagegen/run.py plan
--manifest <file>` (exit 0). Mark batches 173-176 in QUEUE-LOG.md as
"delivered; not cuttable, style reference only". Hand back: PR link,
rows, jobs, anything that did not hold. At most 10 lines.
