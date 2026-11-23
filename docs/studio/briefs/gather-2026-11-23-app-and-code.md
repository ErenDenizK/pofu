# Gather brief: the app and the code, raw facts (2026-11-23)

You collect raw facts for a whole-project assessment that Fable writes
next. You do not judge, propose or rank; Fable does. Every line you write
carries its evidence: `path:line`, a commit, a PR number or a command and
its output. A claim you could not check is marked UNCHECKED.

Read `origin/main` of ErenDenizK/pofu (main checkout `/home/user/pofu`,
read with `git show origin/main:<path>` or `git grep ... origin/main`; do
not check out branches there and do not build). No Swift builds, no
pushes, no PRs. Keep your context small: grep and read sections.

Write one file:
`/home/user/wt/lead-docs/docs/research/assessment-2026-11-23/raw-app-and-code.md`
(do not commit it; the lead does). Sections, each a list of short facts:

1. **Apple kits.** Which Apple capabilities the app waits for (Family
   Controls, ManagedSettings, DeviceActivity, anything else): entitlement
   files, extension targets, what is implemented, what is stubbed or
   mocked, what is behind a flag, the docs that describe the request and
   what changes the day it is granted. The free `Pofu` build and the
   Shortcuts path: what they do today.
2. **Systems inventory.** For each: character movement (Pofu, residents,
   visitors; note the walk loop whose result is discarded on the plate),
   navigation and screens (Home, Map, voyage, settings, onboarding),
   visitors, audio and music, haptics, the minigames (Flow board and
   others), the station sheet, seeds and the economy, stations and island
   levels, story and dialogue delivery. State: shipped / partial / stub /
   absent, with the files.
3. **Health.** Last ~15 CI runs on main (pass/fail, duration) via
   `gh api repos/ErenDenizK/pofu/actions/runs?branch=main&per_page=15`;
   test counts per package; TODO/FIXME/HACK counts by package; feature
   flags and env switches (e.g. `POFU_FLOW_GROUND`); dead or parallel code
   paths; the largest files.
4. **Open PRs** in pofu with age, size and what each is waiting on.
5. **Docs drift.** Where `docs/now.md`, `docs/studio.md` and the trackers
   disagree with the code (a few clear cases, not an audit).

At most ~250 lines. Hand back three lines: the file path, the five facts
you think matter most, and anything you could not check.
