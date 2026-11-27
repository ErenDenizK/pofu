# Brief: C2, the season air (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `feat/season-air`. Desk: `[world]`.

Spec: `docs/design/island-calendar-v1.md`, row **C2** in section 5
(sections 2-4 for what each season should feel like). C1 (#540, the
island year) and S3 (#549, the autumn plates at stage 0) are on main.

## Facts to check first (a false premise is a result)

The row was written before C1 and S3 merged, so its file list is a lead.
- **Files.** `Season` now lives in `PofuCore/Game/IslandYear.swift`.
  Check that every file the row names exists; `WorldLight.swift` may
  not. Name the real file for each job: weather odds, the weather layer,
  the fireflies and the ambience mix.
- **Weather and season.** How the world reads today's season, and how
  weather is picked now (odds, seed, where). Rain's streak tile is the
  model for snow.
- **The ambient tier and the off switches.** Find how rain obeys
  `FramePolicy`'s ambient tier, Reduce Motion and Low Power. The air
  must obey the same switches in the same way.
- **The screenshot pins.** Find how the screenshot tests pin season
  (spring) and how #549's `path-season-*` frames set autumn. Existing
  frames must stay byte for byte.
- **The reference.** Batch 25's `x-season-autumn` and `x-season-snow`
  t2 in pofu-art (clone at /home/user/pofu-art; read blobs with `git
  cat-file blob origin/main:<path>`). Use them for the size and density
  of the leaves and snow only, never their colours.

## Change

As the row says:
- leaves in autumn;
- snow in winter, as a sixth weather with its own odds per season;
- fireflies on summer nights only;
- a light tint per season, if the spec asks for one;
- the ambience mix per season.

Keep it calm. Pofu's island is a quiet place, and the air is felt more
than seen.

Stay out of:
- `PofuSound/Music/*` and `App/Rehearsal/*`, where the music room PR #556
  is open;
- `tools/plate/*`;
- the `stations` key in `plate-home.json`.

## Acceptance

- Frames `path-season-<s>-i3` and `-i10`, by day and `-night`, for
  autumn, winter and summer. Plus one still frame of each moving layer
  at three times, so the motion can be judged.
- 1:1 crops (1206 x 2622 frames): flakes and leaves are soft, never
  streaks, dots in a grid, or halos on the sky.
- Every other `path-*` frame unchanged, compared frame to frame against
  `screenshots/main` on CI frames.
- Unit tests for the weather odds per season and for the off switches.
- The render server's frame cost, if the tests measure one. If the
  particles cost frames, halve the count first.
- A `changes/feat-season-air.md` line starting `[world]`.

## Process

- Your own worktree at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- **Local Swift:** `tools/swift/test-linux.sh`. A stale swiftc may hold
  `/tmp/pofu-swift-build.lock`. If it waits more than 10 minutes, kill
  nothing: say so and lean on CI. Read your Swift diff twice before each
  push; the last Swift PRs lost pushes to errors only CI caught:
  - Swift Testing macros around mutating calls;
  - a `try` with no throwing call;
  - unused values;
  - Sendable issues;
  - iOS-only API outside `#if os(iOS)`.
- Disk floor 5 GB (5.7 GB free now): remove `.build` and frames when
  done.
- Do not merge.

Hand back:
- the PR number, head SHA and CI result;
- the files you named for each fact;
- the crops' paths;
- the defects you can still see.
