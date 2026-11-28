# Brief: byte-stable screenshot frames (2026-11-28)

Role: `.claude/agents/builder.md`. Branch `test/screens-stable`. Desk: `[world]`.
Start after N1b (`art/station-nights-painted`) and 3a (`art/near-ground`)
merge, because both add frames in `Tests/WorldScreenshots/`.

## Why

Every art PR checks that it changed no other frame by diffing CI frames
against a baseline. The same frames differ in PRs that do not touch them,
so builders write "probably animation noise" and the check proves
nothing. A scout traced the causes at 58f588fc:

- **`path-season-turn-*`.** The flip runs after a wall-clock
  `Task.sleep` against a 0.8 s cross-fade
  (`PlayerPathScreenshotTests.swift:187-198, 548-552`). The fade's
  driver in app code was not found.
- **`path-hop-instagram-1200`.** A `repeatForever` breath starts in
  `.task` (`HopView.swift:291-304`), and a time-based progress runs at
  `HopView.swift:340-347`.
- **`path-game-flow-*` and `path-game-garden-midround`.** `sceneTime`
  advances by the display link's dt (`FlowScene.swift:119-122`,
  `GardenScene.swift:114-116`), gated by fixed sleeps in the tests.
- **Not traced:**
  - `path-card-resident-moved`;
  - `path-stall-reveal-2400`;
  - `path-row-locked`;
  - the glass buttons at the right edge (x 975-1168), likely
    `.glassEffect` captured by `drawHierarchy`;
  - specks of a few dozen px.

## Change

- Give each animation above a time the test can set: a clock input, a
  paused `SKView` stepped with fixed dt, or a test-only switch for the
  idle breath. The app's behaviour must not change.
- Trace the four untraced families and fix the ones you can. For any
  you cannot, list it in a `KNOWN_UNSTABLE` set the diff tool reads, so
  builders stop chasing it.
- `tools/review/`: one script that diffs two screenshot branches and
  prints only frames outside the known set.

## Acceptance

- Two CI runs of the same commit (re-run the workflow, or
  `workflow_dispatch`) give byte-identical frames, except for the known
  set. Show the diff script's output.
- Every frame's content is unchanged against `screenshots/main` apart
  from timing: the same states, and no frame removed.
- A `changes/test-screens-stable.md` line starting `[world]`.

## Process

- Your own worktree.
- At most three pushes.
- Wait for CI with one background command.
- No local `.build`; disk is tight.
- Do not merge.

Hand back:
- the PR number, head SHA and CI result;
- the cause per family and its fix;
- the known set, with a reason for each frame in it.
