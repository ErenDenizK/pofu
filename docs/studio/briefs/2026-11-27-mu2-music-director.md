# Brief: MU2, the music director (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `feat/music-director`.

Spec: `docs/design/music-system-v1.md`, row **MU2** in section 8, and the
sections it rests on (the director's inputs and outputs, cells and
stems, pauses, ducking). MU1 is on main (#525): the score, the band and
three Home day tunes under `design/music/`.

## Facts to check first (a false premise is a result)

- **Home's day tune is A** (`design/music/score/home/day-a.abc`).
  - The founder's card 5 went ahead on its default (fi 49), and that
    default was A.
  - Find which rendered stems MU1 produces for it, and whether
    `tools/music` can write the per-cell stems the director needs.
  - Name the files. If it cannot, say what is missing before you build.
- **The cue ducking rule:** the spec says the player ducks "with the cue
  rule that exists". Find that rule in `PofuSound` (`SoundEngine`,
  `Ambience*`) and name it.
- **The toggle:** `SoundPolicy` and the Settings screen. Find how
  sound is switched on today, and where `isMusicOn` belongs.
- **Size:** the spec has a size limit for bundled music. Check that the
  rendered stems fit it.

## Change

Build the MU2 row and nothing past it:
- `MusicDirector`: pure, deterministic and seeded. It takes the island,
  hour, weather, season, stage, wellbeing and a seed, and returns the
  next cell, its stems and the pause. Only Home's day tune is real now.
  Other states fall back as the spec says: silence or the ambience, but
  never a wrong tune.
- `MusicPlayer` on one `AVAudioEngine`, with the stems at one sample
  time.
- `isMusicOn` in `SoundPolicy`, the Settings toggle, its tuning values
  in `tuning.json`, and the wiring in `App/WorldSound.swift`.

Out of scope: the music room (MU3), night tunes and stingers (MU4), and
voyage music (MU5).

Stay out of files other open PRs own: `PofuWorld/Voyage/*`,
`PofuWorld/Plate/*`, and `tools/plate/*`.

## Acceptance

- `MusicDirectorTests`:
  - the same inputs and seed give the same sequence;
  - the pauses stay inside the spec's range;
  - no cell repeats back to back where the spec forbids it;
  - the fallback for every other island, hour, weather and season;
  - with music off, the director returns nothing.
- Every existing test, via `tools/swift/test-linux.sh`. iOS-only code
  (`AVAudioEngine`, `App/`) compiles only in CI, where warnings are
  errors.
- **Local Swift builds may be blocked.** A stale process may hold
  `/tmp/pofu-swift-build.lock`. If `test-linux.sh` waits on it for more
  than 10 minutes, do not kill anything: say so in your hand-back and
  lean on CI.
- A `changes/feat-music-director.md` line starting with `[music]`.

## Process

- Your own worktree.
- At most three pushes after the PR opens.
- Wait for CI with one background command.
- Disk floor is 5 GB: remove `.build` when you are done.
- Do not merge.

Hand back: the PR number, head SHA and CI result, the files you named
for each fact, the test list, and anything in the spec you found false.
