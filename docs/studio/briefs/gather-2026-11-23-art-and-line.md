# Gather brief: the art, the frames and the production line, raw facts (2026-11-23)

You collect raw facts for a whole-project assessment that Fable writes
next. You do not judge, propose or rank; Fable does. Every line carries
its evidence (path, PR, commit, command). Unchecked claims are marked
UNCHECKED.

Sources, read-only:
- pofu-art at `/home/user/pofu-art` (read `origin/main` with `git show`
  and `git ls-tree`; run `git fetch -q origin` first; do not check out
  branches there, do not push).
- pofu at `/home/user/pofu` (`origin/main` only). For the frames, list
  the `screenshots/main` branch through REST, never by fetching it:
  `gh api 'repos/ErenDenizK/pofu/git/trees/screenshots/main?recursive=1'`.
- `gh api` REST on ErenDenizK/pofu-art and ErenDenizK/pofu (PR lists).

Write one file:
`/home/user/wt/lead-docs/docs/research/assessment-2026-11-23/raw-art-and-line.md`
(do not commit it). Sections, short facts:

1. **Concept rounds.** Batches 138-145 (round 1) and 146-153 (round 2):
   per batch, jobs, delivered takes, skipped/failed jobs and why (batch
   152 hit `usage_limit_reached` and delivered nothing, PR #140 closed).
   The review sheets that exist (`design/review/concept-round-1/`).
2. **What is in the app.** Which art in pofu's app bundle came from Codex
   and which is code-drawn or placeholder: Home plates, stations, Pofu,
   residents, visitors, the Gezgin, the Flow kit, icons, menus, UI.
   Name the asset catalog paths.
3. **The queue.** `QUEUE.md` rows by state (READY/BLOCKED/DONE), what
   each BLOCKED row waits on; the last ~10 `QUEUE-LOG.md` entries; how
   many Codex runs ended on quota since 11-15.
4. **Drift and risk.** Manifests that exist only in pofu-art and not in
   pofu (`tools/imagegen/manifest/`), the sync script and its `--prune`
   risk; open stale pofu-art PRs (#59-#90 era) and whether their content
   was superseded; repo size.
5. **Frames.** What `screenshots/main` holds (names, rough count, newest
   date) from the listing only.

At most ~200 lines. Hand back three lines: the file path, the five facts
that matter most, and what you could not check.
