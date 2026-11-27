# Brief: MU3, the music room (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `feat/music-room`. Desk: `[music]`.

Spec: `docs/design/music-system-v1.md`, row **MU3** in section 8: a
"Müzik odası" panel in Rehearsal mode. In it he chooses the island,
hour, weather and season and hears what the director would play, and
every stinger is a button.

MU2 is on main (#552). Read its PR body:
- `MusicDirector` is pure and seeded, and `MusicPlayer` plays on one
  `AVAudioEngine`;
- only Home's day tune (A) is real;
- 23:00-06:00 is silent, and 17:00-23:00 has no tune until MU4.

## Facts to check first (a false premise is a result)

- **Rehearsal mode:** find what it is and where its panels live
  (`App/Rehearsal/`). Note how a panel is added and reached, and whether
  it ships only in debug or test builds. Name the files.
- **The player's API:** check whether `MusicPlayer` can be driven by a
  state the room picks, rather than by the world's live state, without
  changing `PofuSound`. If it cannot, state the smallest change needed.
- **Stingers:** none exist yet (MU4). The room shows the stinger section
  with its buttons disabled, labelled as coming. Never fake a sound.

## Change

- One panel: island, hour (a slider), weather, season, stage and
  wellbeing.
- It shows what the director answers: the cell, its stems, the pause,
  or the silence and its reason (bedtime, no tune, music off).
- Play / stop for that state.
- Respect the Settings music switch. Explain it in one line when it is
  off.
- User-facing strings in Turkish and English, each written natively in
  its language, never translated from one another.

Stay out of `PofuWorld/*` and `tools/plate/*`. The tea stall PR is open
there.

## Acceptance

- A unit test for whatever state mapping lives outside `App/`.
- CI green; `App/` compiles only in CI, where warnings are errors.
- A short screen recording is not possible here. Instead, add the
  panel's screenshot if the repo's screenshot tests cover Rehearsal
  panels; if they don't, say so.
- A `changes/feat-music-room.md` line starting `[music]`.
- **Local Swift tests:** `tools/swift/test-linux.sh` may wait on a
  stale `/tmp/pofu-swift-build.lock`. After 10 minutes, kill nothing:
  say so and rely on CI.
  - The last three Swift PRs each lost pushes to compile errors or
    failing tests that only CI found.
  - Read your Swift diff twice before each push. Look for Swift Testing
    macros around mutating calls, `try` with no throwing call, unused
    values, and Sendable issues.

## Process

- Your own worktree.
- At most three pushes after the PR opens.
- Wait for CI with one background command.
- Do not merge.

Hand back: PR number, head SHA, CI result, the files you named for each
fact, and what he will see and hear when he opens the room.
