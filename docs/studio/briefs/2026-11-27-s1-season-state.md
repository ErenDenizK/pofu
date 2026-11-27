# Brief: PR S1, the season state (2026-11-27)

Role: `.claude/agents/builder.md`. `docs/design/season-system-v1.md` on
main, section 9 row **S1**, is your spec (branch `feat/season-state`,
kind test). ADR-0030 is merged. Read sections 5 (D3, D4) and 8 (the two
app tests) of that page too; skip the rest.

What it is: the season becomes a third key on the painted state,
`(season, light, stage)`. Spring's key is today's, so no shipped asset
name and no `path-*` frame changes. No season data ships in S1.

Facts to check before you build (a false premise is a result):
- `PlateIsland.swift`, `HomePlate.swift`, `PlateCompositor.swift`,
  `WorldLook.swift` and `RehearsalPanel.swift` are where the row says,
  and every per-light table the row lists (`painted`, `harmony`,
  `lightMap`, `shadowMap`, `plateCrops`, `stations.lights`,
  `lookLevels`) exists under that name. Report any that does not.
- `world.season` exists (the island year, C1 #526). If it does not,
  stop and report.

Files you own: the row's list. Do not touch:
- `HomePlateDataTests.swift`, `PlayerPathScreenshotTests.swift`,
  `plate-home.json`, `tools/plate/*`: the pond PR #528 is in them;
- `PofuWorld/Voyage/`, `PofuWorld/Gezgin/`, `Camera/`, `Scene/`: the
  ride PR `feat/voyage-ride` is in them.

If S1 truly needs one of those, stop and say which line and why.

Acceptance (the row's): `SeasonStateTests` covers:
- spring's key equals today's names for all 26 states;
- an unlisted state resolves to spring for plate, base, look, occluder
  and Map cut;
- a listed state names none of spring's assets;
- `complete: false` without the override is spring.

Every existing `path-*` frame must stay byte for byte; say how you
checked it (CI's screenshot diff on the PR).

Fallback (the row's): if the Rehearsal season stepper fails to compile
in CI on the second push, drop it from S1 and say so.

Process:
- Your own worktree.
- Swift tests only through `tools/swift/test-linux.sh`, which waits
  behind other builds.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Add `changes/feat-season-state.md` only if a player can see a change.
  Rehearsal is not the player, so likely none; say which.
- Do not merge.

Hand back: PR number, head SHA, CI result, premises checked, what is
not done.
