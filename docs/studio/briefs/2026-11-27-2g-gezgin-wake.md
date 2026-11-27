# Brief: PR 2g, her cloud wake on the ride (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `art/gezgin-wake`.

Spec: `docs/design/mainflow-plan-2026-11-26.md`, step 2's art list ("a
cloud wake") and row 2d's fallback ("if the ride drops frames on the
render server, the cloud wake goes first"). The motion verb is
**drift** (`docs/design/motion-vocabulary.md` row 1): a cut-out
slides, fades and bobs. Nothing is painted mid-move.

The ride is on main with #541, #548 and #551 (the match cut, merged
today). Read #551's PR body: the handover now happens at 1.84 s.

## Facts to check first (a false premise is a result)

- **The art is pofu-art batch 198 `batch-198-gezgin-wake`.** The lead's
  picks are recorded in each job's `review.yaml`:
  - the long chain of seven puffs: t1;
  - the short cluster: t2.

  Each is a 1536 x 1024 transparent cut-out. Read the blobs with
  `git cat-file blob origin/main:<path>` in /home/user/pofu-art. Check
  both picks at 1:1 for a fringe or halo on their alpha edge.
- **The ingest path:** `tools/art/gezgin_post.py` (#548) and
  `tools/art/gezgin_cutouts.py`. Name which one fits a wake cut-out, and
  the density the Gezgin uses (3 px per point, plan row 2b).
- **Where she is drawn on the ride:** find the view and the pose she
  flies at, and the scale she has at each moment of the ride.

## Change

- Ingest both picks as world assets (for example
  `world-gezgin-wake-long` and `world-gezgin-wake-short`), with
  provenance.
- Draw the wake behind her tail while she flies:
  - it trails opposite to her heading;
  - it scales with her;
  - puffs fade out along the chain;
  - it is born softly at take-off and dies softly at mooring;
  - the short cluster marks take-off and landing, the long chain marks
    cruising.

  Your call within those lines; name what you chose.
- **Reduce Motion:** no wake. On the return ride, the same rules apply.
- Keep the ride's frame cost in mind. If the render server drops frames,
  the wake is the first thing cut (row 2d).

Stay out of: `Plate/*`, `tools/plate/*`, and `PofuSound/*`. MU2 runs
beside you and owns `App/WorldSound.swift`.

## Acceptance

- Frames: `voyage-0.0` to `-4.0` and `voyage-back-*` as they are on
  main.
- 1:1 crops:
  - the wake at take-off, mid-cruise and landing, with its alpha edge
    against the sky and against the cloud floor (no halo, no grey
    fringe);
  - the frames where it fades.
- The berth frames (`path-gezgin-koke`, `-caglayan`, `-moored-l2`)
  unchanged pixel for pixel.
- Tests:
  - the wake is absent under Reduce Motion and when she is moored;
  - its opacity is 0 at the ride's ends.
- Every existing test, via `tools/swift/test-linux.sh`.
- **The local Swift lock:** a stale process may hold
  `/tmp/pofu-swift-build.lock`. If `test-linux.sh` waits on it for more
  than 10 minutes, do not kill anything: say so and lean on CI.
- A `changes/art-gezgin-wake.md` line starting with `[gezgin]`. Use
  the desk tag that other Gezgin change lines use, if it differs.

## Process

- Your own worktree.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Disk floor is 5 GB: fetch only the frames you need with
  `tools/review/fetch_frames.sh`, and remove `.build` and the frames
  when you are done.
- Do not merge.

Hand back: the PR number, head SHA and CI result, the facts with their
file names, the crops' paths, and the defects you can still see.
