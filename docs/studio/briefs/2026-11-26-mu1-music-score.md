# Brief: MU1, the score, the band and three Home tunes (2026-11-26)

Role: `.claude/agents/builder.md`. The music line's first PR
(`docs/design/music-system-v1.md` on main, #523; ADR-0029). Section 8,
row **MU1** is your spec (branch `feat/music-score`, owned files,
acceptance, fallback); sections 4-7 are the decisions, the bible v0 and
the lint rules. Per D11 the three Home day tunes are written by you with
care (you are the model the spec names for the first tune of a kind);
nothing is modelled on a named melody (D12).

Python only: no Swift build, so you run beside the Swift lane. Founder-
input 48 applies: this is an apply-now decision; his ear comes later
(gate 2), with the three audition files and a default.

Disk is tight (about 5 GB free): use a sparse worktree from `origin/main`
(`git worktree add --no-checkout`, then `git sparse-checkout set tools
design/music design/sound .github docs/design`), keep renders small
(mono or stereo m4a/caf as the spec says), delete scratch audio.

Acceptance: the spec's unittest command passes; the three audition files
and their piano rolls committed; CI's python-tools job green. Add
`changes/feat-music-score.md` (not user-visible in the app, but a new
line of work the studio reads). At most 3 pushes after the PR opens.

Hand back once CI is in: PR link, CI state, the three files' paths with
one line each on what you wrote (mode, tempo, shape), what the lint and
the rolls show, what you could not do. At most 12 lines.
