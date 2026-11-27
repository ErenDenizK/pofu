# Brief: S2, the season gate (2026-11-27)

Role: `.claude/agents/builder.md`. `docs/design/season-system-v1.md` on
main (#530) section 6 (pull requests) row **S2** is your spec (branch
`tools/season-gate`, owned files, acceptance, fallback); section 8 lists
the checks S1-S5 and S8 with their limits; section 3 gives the method and
the numbers you must reproduce (golden 0.40 and 0.69, windmill fit 6.2).
Python only, no Swift build: you run beside the Swift lane (two builders
are on 1c pond and 2b Gezgin; do not touch their files).

Add the gate to CI's `python-tools` job if its tests run there. Sparse
worktree (`tools/`, `design/art/plates/`, the images the tests need);
disk floor 5 GB. At most 3 pushes after the PR opens. Hand back once CI
is in: PR link, CI, each check's reproduced number vs section 3, what
ships without a limit. At most 10 lines.
