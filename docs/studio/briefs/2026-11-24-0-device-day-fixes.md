builder

# Brief 0: on call for the device days (2026-11-24)

Stage 1 of `docs/design/assessment-2026-11-24-path.md`. The founder runs
the Screen Time gate on his iPhone for the first time, case by case from
`docs/local/membership-day-1.md`. You fix what fails. You build nothing
else: no cleanup, no polish, no refactor.

## How it runs

- The lead relays each failed case to you: its number, what he saw,
  console lines and screenshots. You do not talk to the founder.
- One failed case is one branch and one PR (`fix/day1-case-<n>`), each
  from `origin/main`. Two cases with one cause share a PR; say so.
- The gate's code is iOS-only: it compiles only in CI and runs only on
  his phone. So before you push, write down what you expect him to see
  after the fix, in the PR body, as the case's "Expected" line. He
  re-runs the case; his result is the acceptance, not green CI.
- You get the next Swift build ahead of other agents. Ask the lead to
  pause them if `tools/swift/test-linux.sh` is waiting.

## Facts to open first

- The cases: `docs/local/membership-day-1.md:79-122`. Cases 1 to 11 and
  17 are the core; a failure there outranks any other case.
- The live service and the three extensions: `App/ScreenTime/`,
  `Packages/PofuKit/Sources/PofuScreenTime/`, `Extensions/`.
- `App/` and `Extensions/` have no test target. Logic you can move into
  `PofuScreenTime` gets a test there; the rest is proven by the case.
- Case 7b and case 22 are known unknowns (the extension writing to the
  App Group; the shield redrawing after `.defer`). If one fails, hand
  back what the device did before you design a way round it: the way
  round changes the gate's design and the lead decides it.

## Rules

- Seeds never buy screen time; Pofu never dies. A fix that needs either
  is not a fix.
- No new features for the free `Pofu` build or the Shortcuts path.
- At most three pushes per PR. Wait for CI with one background command.

## Acceptance

For each failed case: a merged PR, and the founder's re-run of that case
recorded as passed in the day's report under `docs/local/`. No frame is
needed unless the fix changes what is drawn; then one path frame and a
1:1 crop.

## Hand back

Per case: the cause in one sentence, the PR, what he should see. At most
15 lines in all.
