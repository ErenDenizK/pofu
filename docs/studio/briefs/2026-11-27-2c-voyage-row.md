# Brief: PR 2c, the voyage row (2026-11-27)

Role: `.claude/agents/builder.md`. Main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main) section 6 row **2c**
is your spec (branch `feat/voyage-row`, owned files, change, acceptance,
fallback); ADR-0028 (`docs/adr/0028-the-far-view-is-a-voyage.md`, PR
#527, merging now) is the decision: the Map stop becomes the voyage row;
one island at 0.7 of the width, neighbours cut by the edges, a native
glass bar with the name, one state line and the verb "Yola çık"; she
stays moored while the player chooses; the island choice opens both by
tapping the Gezgin and from the bottom-right button (fi 44).

Since the plan: 2b merged (#529: `PofuWorld/Gezgin/`, data in
`world-map.json` `gezgin`); build on it. Art: batch 148 `x2-voy-row-big`
t1 is the layout reference only; batch 172 has her map-scale form; never
paint the bar. Pofu never stands behind anything taller than himself;
she is never shown from behind.

Acceptance as the row: `path-row-home`, `path-row-koke`,
`path-row-locked`; `VoyageRouteTests`. Label `screens`; frames only via
`tools/review/fetch_frames.sh`; 1:1 crops in the hand-back. Strings
written natively in Turkish and English. `changes/feat-voyage-row.md`.
Other builders: texture budget PR 1 (`tools/plate`, `ingest.py`) and PR
5 (`HomePlateCrop.swift`, `TodaySheet.swift`); do not touch their files.
One full worktree at most; disk floor 5 GB. Swift tests via
`tools/swift/test-linux.sh` only. At most 3 pushes after the PR opens.
Hand back once CI and frames are in: PR link, CI, sheet + 1:1 crops
(paths), defects you still see. At most 12 lines.
