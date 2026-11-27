# Brief: PR 1c resumes, the pond at 2.0 (2026-11-27)

Role: `.claude/agents/builder.md`. `docs/design/texture-budget-v1.md`
(main) PR table row **4**: 1c resumes on #528 (`art/station-levels`) at
2.0 texture px per plate point under rule v1 (tools #535, Swift #537 are
merged; `texture-budget.json` holds the 12 M px limit). #528 was parked
by the lead for two reasons; both must be fixed here:

1. **Density:** every look at 2.0 (the tea stall keeps 3.0); restore the
   windmill to 2.0 (#528 lowered it to 1.45). `plate_gate.py home` and
   `ingest.py check home` green under rule v1.
2. **The pond's defects** (from its builder's own list): a yellow lawn
   tuft at the bottom left of L1; cream path-stone blobs beside the deck
   in L3-L5; a lilac flower fragment at the bottom of L3; a ragged bottom
   rim where flowers cut holes; a thin pale-blue line under the lily and
   a faint blue streak above the mailbox (old water left by the base
   window); the lawn round the pond more olive than the plate's. Each
   one fixed or named in the hand-back with why it cannot be.

Rebase #528 onto `origin/main` first (it conflicts: #522, #529, #534 and
others touched `plate-home.json`, a ONE-line file: merge it by key, not
by text; keep `mooring` and the golden data). Keep its shared-base fix
(`cmd_bases` accumulating windows) and the windmill's island-8 base.
Every look checked over flat magenta at 1:1 (no sky, no base ground in
the look). Frames: `path-pond-l1..l5`, `path-pond-i8-l3`, `path-pond-i7-l3`,
`path-levels-i10/9/8/7`, and `path-mill-l1..l5` unchanged in place.
Label `screens` stays; frames only via `tools/review/fetch_frames.sh`.
Other builder: 2c voyage row (`PofuWorld/Voyage/`, `CameraRail.swift`,
`MapSlots.swift`, `PlaceControl.swift`). One full worktree; disk floor
5 GB. Swift tests via `tools/swift/test-linux.sh` only. #528 has used one
push; at most two more. Hand back once CI and frames are in: PR link,
CI, sheet + 1:1 crops (paths), each defect's state, the budget numbers.
At most 15 lines.
