# Brief: PR 1c, every station's levels on the island (2026-11-27)

Role: `.claude/agents/builder.md`. Main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main) section 6 row **1c**
is your spec (branch `art/station-levels`). PR 1b (#521, merged) is the
worked example: read its diff (`tools/plate/station_looks.py` per-station
specs, `plate-home.json` `stations.windmill`, `testRenderTheWindmillLooks`)
and its lessons: the takes are whole paintings, so looks are CUT (diff
against the lower level / erased base); keep the 9 MB budget (1b used
1.7 px per point); never run `ingest.py json` blind (it drops hand-added
`spots` and moves Fındık's x); patch `plate-home.json` surgically.

Art on pofu-art main (read with `git -C /home/user/pofu-art show
origin/main:<path>`): the six other stations (garden, bagel cart, pond,
workshop, lighthouse, pier) and the tea stall's remaining stages, painted
INTO the whole Home plate at levels 1-4: batches 176 (L1), 173 (L2),
174 (L3), 175 (L4); level 5 is the shipped plate. Erased bases: batch 117
(picks in review.yaml; day L1/L2 from batch 182). Also wire the
windmill's island-8 base (batch 117 l08 day and night have picks). Judge
every take at 1:1 and use the QA auto-pick unless it fails; record your
pick and why. A level whose cut fails is left out (1a's fallback draws
the level below). Day only: night looks come later (row C5).

Breadth first by level. Acceptance as the row: `path-<station>-l1..l5`
by day, and one whole-island sheet at mixed levels per island stage
(`path-levels-i<stage>`), judged whole: no station takes over the
island. Label `screens`; frames only via `tools/review/fetch_frames.sh`.
`changes/art-station-levels.md`. Disk is tight (about 5 GB): one full
worktree at most, delete scratch. Swift tests via
`tools/swift/test-linux.sh` only. At most 3 pushes after the PR opens.
Another builder runs step 2b (owns `PofuWorld/Gezgin/`, `mooring` in
`plate-home.json`): edit only `stations` there.

Hand back once CI and frames are in: PR link, CI, a sheet + 1:1 crops
(paths), which station/levels shipped and which were left out and why.
At most 15 lines.
