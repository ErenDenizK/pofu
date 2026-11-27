# Brief: C1, the island year and the special days (2026-11-26)

Role: `.claude/agents/builder.md`. `docs/design/island-calendar-v1.md`
on main (#523), section 5 row **C1** is your spec (branch
`feat/island-year`, owned files, change, acceptance, fallback);
section 4 C1-C2 are the decisions, section 7 the table of days. Code
and tests only: no art, no visible change but one Rehearsal readout
line. A [now] decision (founder-input 48); his confirming card is out
with the default "7 days a season from the first day", so keep
`seasonDays` and the order in `tuning.json`, never in code.

Bayram dates: the spec's 2027+ dates were written from memory. Verify
every Ramazan and Kurban Bayramı date you put in `special-days.json`
against Diyanet's published calendar (web) and cite the source in the
JSON's comment field or the PR body; a date you cannot verify stays out
and the "under 365 days left" test tells us when to add it.

Two other builders are in CI on `art/windmill-levels` (#521) and
`art/home-golden` (#522); neither touches your files. Swift tests only
via `tools/swift/test-linux.sh` (it queues behind other builds). Own
worktree from `origin/main`; disk is tight (about 5.5 GB free): use a
sparse worktree if you can and delete build products you do not need.
No `changes/` line unless the readout counts; add one if it does. At
most 3 pushes after the PR opens.

Hand back once CI is in: PR link, CI state, the bayram sources, and
anything in the spec that proved wrong. At most 10 lines.
