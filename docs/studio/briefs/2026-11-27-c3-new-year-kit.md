# Brief: PR C3, the New Year kit (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `feat/special-day-kit`.

Spec: `docs/design/island-calendar-v1.md`:
- decision row **C3**: a special day is a kit, never a repaint;
- PR row **C3**: files, change, acceptance, fallback.

It must be on `main` by 20 December. C1, the island year with
`SpecialDays`, is merged (#526); S1 (#540) is merged too, so read
`PlateIsland.swift` as it stands.

## Facts to check first (a false premise is a result)

- The kit's art is pofu-art batch 183 (`batch-183-yilbasi-kit`), all
  takes valid. The clone is /home/user/pofu-art; read blobs with
  `git cat-file blob origin/main:<path>`.
  - Four cut-outs: potted pine, parcels, snowman, star lantern. The pine
    and the lantern each also have a lit take.
  - Two previews: `x10-ny-preview-day` and `-night`.
- No lead pick exists. Pick each job's take yourself at 1:1 and record
  why in the PR body. A take with snow in the air, a glow on the alpha,
  or a second object is not used.
- `SpecialDays` names New Year (check its key), and `PlateProp` is the
  mechanism that draws the jar today.

## Others in the same files

- PR #543 (`art/station-levels-2`) edits `plate-home.json`'s `stations`
  key and `tools/plate/*`. You own only `props`. `plate-home.json` is
  one line, so a git conflict on it is resolved key by key. Never
  regenerate the whole file from your branch.
- The ride-polish PR is in `Voyage/`, `Gezgin/`, `Camera/` and
  `IslandScene.swift`. Stay out of them. If the kit needs a scene hook,
  name the line.

## Acceptance (the row's)

- `path-newyear-i3`, `-i10`, `-night` and `-fireworks-0.0..2.0`.
- 1:1 crops of each prop's foot and edge, by day and lit at night.
- Reference: batch 183's previews, for where the props stand and how
  calm the island stays. Fireworks are calm and few, never a flashing
  screen; respect Reduce Motion (a still glow instead).
- Pofu's line comes from T-01 of `docs/brand/pofu-voice.md`, in Turkish
  and English, each written natively.
- Tests: the kit draws only when `SpecialDays.active` names it; lit at
  night; fireworks only 22:00-01:00 on the night itself.
- Fallback as the row says.

## Process

- Your own worktree.
- Swift tests only through `tools/swift/test-linux.sh`.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command; loops under 600 s, re-run,
  are fine.
- Add a `changes/feat-special-day-kit.md` line.
- Disk floor is 5 GB: remove `.build` when you are done.
- Do not merge.

Hand back: PR number, head SHA, CI result, picks with reasons, crops'
paths, the defects you can still see.
