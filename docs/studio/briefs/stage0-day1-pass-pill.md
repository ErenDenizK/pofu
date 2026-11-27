builder

# Brief: stage 0, make membership day 1 runnable (2026-11-24)

The founder approved this (founder-input 44, his answers to the
assessment). The membership may open as early as 11-25; this must be
merged before he sits at the Mac. Read
`docs/design/assessment-2026-11-23.md` sections 2.1, 2.2 and 4 first.
They are evidence: check every claim in the code before you build.

## The problem (as the assessment found it; verify it)

In the shipped world Home (`FeatureFlags.worldHome` is true), nothing
opens the Passes sheet or the Earn sheet. Their openers sit in
`HomeView`'s `topBar`/`bottomActions`, which are drawn only when
`worldHome` is false (`HomeView.swift` ~214, 383, 390). `endPass` has no
other caller. So on the live build, a running pass can be neither seen
nor ended early, and day-1 case 10 in `docs/local/membership-day-1.md`
cannot be run.

## What to build

1. **A running pass gets a place on the world Home:** a small glass pill
   that shows which app is open and the minutes left, and ends the pass
   when tapped (with whatever confirmation the existing end-pass flow
   uses). It is visible only while a pass runs. It is the first piece of
   the founder's "glass object" language, so keep it small and quiet,
   consistent with the glass skin already in the app. Turkish and
   English strings written natively. Place it so it does not cover Pofu
   or the island's center; show it in a frame.
2. **Cut the honor session** (the "Kazan" earn sheet). The founder
   decided it goes. Remove its player-facing paths and delete its code
   where it is contained; where removing it would ripple into the
   economy or the tests in a way that is more than a cut, stop at the
   seam and report it. Seeds never buy screen time: do not touch that
   rule.
3. **Correct the day-1 script** `docs/local/membership-day-1.md`:
   - case 10 uses the pill;
   - remove HealthKit and Associated Domains from the capability list
     (in `docs/roadmap.md` too), because nothing uses them;
   - say plainly that the live build is a different app, so his island
     starts again;
   - add a step to file the Family Controls (Distribution) request the
     same day, for every bundle identifier that needs it (check the
     project for the list).

## Rules

- Your own worktree:
  `git -C /home/user/pofu worktree add /home/user/wt/stage0 -b feat/day1-pass-pill origin/main`.
  About 8 GB of disk is free; mind it.
- Swift only through `tools/swift/test-linux.sh`, after
  `tools/swift/setup-linux.sh`. iOS-only code compiles only in CI.
- Push at most three times. Open the PR with
  `mcp__github__create_pull_request`; `gh pr create` fails. Wait for CI
  with one background command. Add `changes/feat-day1-pass-pill.md`.
- Judge the pill in a real frame at 1206 x 2622, in a 1:1 crop. If the
  player-path frames do not show a running pass, add or extend one so
  CI renders it.

## Hand back

PR link, CI state, a crop of the pill, what you cut and what you left at
the seam. At most 15 lines.
