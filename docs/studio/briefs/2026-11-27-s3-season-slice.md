# Brief: S3, the first autumn slice (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `art/season-slice`. Desk: `[world]`.

Spec: `docs/design/season-system-v1.md` row **S3** (section 9), with
sections 3, 7 and 8 for method and limits. S1 (`feat/season-state`, #540)
and S2 (`tools/plate/season_gate.py`) are on main. The founder asked for
the season system first, one season first, 70-80 % on the first shot
(fi 48).

## Facts to check first (a false premise is a result)

- **Batch 194 picks** (pofu-art `design/art/takes/batch-194-season-slice-pilot/*/review.yaml`):
  - picked: `x-season-autumn-l10-day`, `-l10-night`, `-l10-bare-day`,
    `-l03-day`, `-l03-bare-day`; `x-plot-windmill-2..5-autumn`;
  - `x-look-tea-stall-5-autumn` was **skipped** (no pick). The stall's
    look 5 is therefore derived, like its other levels, not painted. Say
    so in the PR.
  - The winter takes (`x-season-winter-*`, `x-plot-windmill-5-winter`)
    are out of scope; leave them.

  The clone is /home/user/pofu-art; read blobs with
  `git cat-file blob origin/main:<path>`.
- Confirm that stage 0 is level 10 and stage 7 is level 3
  (`stageLevels`), and that `l03` means stage 7.
- Check that `season_gate.py report` runs on today's shipped plates
  before you trust its limits on autumn.

## Change

Exactly the spec row: ingest, season looks and bases, the `seasons`
block with `complete: false`, `plates.yaml`, frames.

Stay out of:
- `plate-home.json`'s `water` key (the pond water PR owns it) and
  `mooring`;
- `Plate/PlateRegionEffects.swift`.

The file is one line: resolve conflicts key by key.

## Acceptance

As the spec row, and also:
- a gate report pasted in the PR (measure and limit per picture);
- the spec's frames, plus `path-season-turn-*`;
- 1:1 crops of:
  - the windmill's foot at levels 2 and 5;
  - the stall's roof edge at levels 1 and 5;
  - one base window;
  - the lawn edge against the sky at night.

The 12 M px per state texture budget holds. Every existing `path-*`
frame stays byte for byte, because spring is unchanged. Every existing
test passes, via `tools/swift/test-linux.sh`.

## Process

- Your own worktree, at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Add a `changes/art-season-slice.md` line starting `[world]`.
- Disk floor is 5 GB: fetch frames only with
  `tools/review/fetch_frames.sh`, and remove `.build`, takes and frames
  when done.
- Do not merge.

Hand back: PR number, head SHA, CI result, the gate report, crops'
paths, the defects you can still see.
