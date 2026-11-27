# Brief: PR 1b, the windmill's five levels on the island (2026-11-26)

Role: `.claude/agents/builder.md`. Step 1 of the main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main): stations grow on the
island. Section 6, row **1b** is your spec (branch `art/windmill-levels`,
owned files, acceptance, fallback). PR 1a (#520, merged) gave
`StationLooks.lights` and the nearest-lower fallback; build on it.

Art on pofu-art main (read it with `git -C /home/user/pofu-art show
origin/main:<path>`, never check out there):
- **Day looks:** `design/art/takes/batch-134-plot-pilot/x-plot-windmill-1..5`
  (picks in each review.yaml). Judge each at 1:1 before you use it.
- **Erased bases:** `design/art/takes/batch-117-station-erase-volume/`
  (merged 11-26, picks in review.yaml; day L1 and L2 have no usable
  take yet, batch 182 redoes them; use what is picked). Cut only the
  windmill's own area from an erased base and keep everything else from
  the shipped plate: batch 117's pier erases also took the rope bridge
  and filled the gap to the islet, so a whole-plate base is never used.
- **Night looks:** none yet (they come from relights of the day looks,
  plan row C5). Ship day only; say what night shows now (the plan's
  fallback rules apply). Write the C5 windmill row text in your hand-back
  so the lead can queue it.
- The tea stall (`tools/plate/station_looks.py`, `plate-home.json`
  `stations.tea-stall`, frames `path-stall-*`) is the worked example and
  the reference for cut quality.

Acceptance (plan row 1b): frames `path-mill-l1..l5`, `path-mill-i<stage>-l3`
for the stages the windmill stands on; 1:1 crops round the windmill show
no halo, no ghost of the painted mill, no colour step. Label the PR
`screens` once open (`gh api -X POST repos/ErenDenizK/pofu/issues/<n>/labels
-f 'labels[]=screens'`); fetch frames only with `tools/review/fetch_frames.sh`
(the screenshots ref is `screenshots/<branch with / as ->`). Add
`changes/art-windmill-levels.md` (user-visible). Own worktree from
`origin/main`; Swift tests only via `tools/swift/test-linux.sh`. At most
3 pushes after the PR opens.

Hand back: PR link, CI state, one sheet of l1..l5 plus 1:1 crops (paths),
defects you still see, the C5 row text. At most 15 lines.
