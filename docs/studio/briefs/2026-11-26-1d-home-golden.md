# Brief: PR 1d, Home's golden plates (2026-11-26)

Role: `.claude/agents/builder.md`. Step 1 of the main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main), section 6 row **1d**
is your spec (branch `art/home-golden`). Today golden hour borrows the
night plate at island levels 1 to 9 (only level 10 has a golden plate).

Art on pofu-art main (read with `git -C /home/user/pofu-art show
origin/main:<path>`): `design/art/takes/batch-87-home-golden/`, merged
11-26 with picks in review.yaml for IL3 to IL7 (IL1, IL2: no usable
take; IL8, IL9: none; batch 182 redoes those four later). Ingest IL3-IL7
only; the others keep the borrow (the plan's fallback). The review noted
IL3 golden adds a bloom on the sprout under the wheel: paste that patch
back from the IL3 day plate. Judge each take at 1:1 against the shipped
day plate of its level: the same island and layout, only the light.
Find how level 10's golden plate is wired (`plate-home.json`
`lightStages`, `World.xcassets`) and do the same.

Acceptance (plan row 1d): `path-d01-1800`, `path-d10-1800` against
`path-d21` at golden; add frames for one ingested level at 18:00 if none
covers it. Label the PR `screens` once open; fetch frames only with
`tools/review/fetch_frames.sh`. Add `changes/art-home-golden.md`. Another
builder is on `art/windmill-levels` (owns the windmill's looks and
`stations.windmill` in `plate-home.json`); touch only `lightStages` and
the golden imagesets there, and expect to merge after it. Own worktree
from `origin/main`; Swift tests via `tools/swift/test-linux.sh` only. At
most 3 pushes after the PR opens.

Hand back once CI and frames are in: PR link, CI state, one sheet of
the ingested levels at 18:00 with 1:1 crops (paths), defects you still
see. At most 12 lines.
