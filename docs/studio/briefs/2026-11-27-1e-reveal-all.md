# Brief: PR 1e, the reveal for every station (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `feat/reveal-all-stations`.

Spec: `docs/design/mainflow-plan-2026-11-26.md`:
- row **1e**;
- step 1's *Feel* line: "the reveal for every station, its sound, the
  resident's hop, the card's level mark".

Done when the founder builds a station from level 1 to 5 on his phone
and each level feels like a step.

## Facts to check first (a false premise is a result)

- The reveal today runs only for the tea stall
  (`PofuWorld/Scene/StationReveal.swift`; reference frame
  `path-stall-reveal-740`).
- The windmill's and the pond's looks are on main (#521, #528), so a
  reveal can be seen on three stations today.
- Find "the level mark (159)": batch 159 in pofu-art, or an asset in
  this repository. If it is not where you look, say where you looked.

## Files

The row's files: `StationReveal.swift`, `StationCard.swift`,
`App/WorldSound.swift`, plus the tests and screenshot tests for them.

Do not touch:
- `PofuWorld/Voyage/`, `Gezgin/`, `Camera/`, or `IslandScene.swift`
  beyond a one-line hook: the ride-polish PR is in them.
- `tools/plate/*`, `plate-home.json`, `station_looks.py`: the 1c-2 PR is
  in them.

If the reveal needs more of `IslandScene.swift`, stop and name the
lines.

## Acceptance

- `path-<station>-reveal-740` and `-1600` for the windmill and the pond
  (and the tea stall, unchanged), with 1:1 crops of the reveal at its
  peak.
- Stations without a level mark keep the dots.
- One sound per station kind. Existing sounds only; name what you
  mapped. No new audio files: that is the sound desk's.
- The resident's hop, if one is defined for that station. Name where
  none is.
- Every existing test passes, plus tests for the reveal on any station
  with looks.

## Process

- Your own worktree.
- Swift tests only through `tools/swift/test-linux.sh`, which waits
  behind other builds.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Add a `changes/feat-reveal-all-stations.md` line.
- Remove `.build` when you are done: disk floor 5 GB.
- Do not merge.

Hand back: PR number, head SHA, CI result, crops' paths, the defects you
can still see.
