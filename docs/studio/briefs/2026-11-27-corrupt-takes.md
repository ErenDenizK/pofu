# Brief: corrupt takes in batches 184 and 185; guard the auto-merge (2026-11-27)

Role: `.claude/agents/builder.md`. On pofu-art main, every committed
`.webp` in `design/art/takes/batch-185-caglayan-again/` (12 of 12) and
5 of 6 in `batch-184-rotor-pilot/` are not WebP files: they do not start
with `RIFF....WEBP`, each is about 150 KB of unreadable bytes. Their
`contact.jpg` files are valid and show the takes were generated fine, so
the encoding or upload of the committed files broke (both PRs, #184 and
#186, came from one Codex run on 2026-11-26 about 23:00-23:45). All other
batches from 164 to 192 are valid (the lead scanned them).

One pofu-art PR (branch `chore/takes-guard-1127`, sparse worktree from
`origin/main`), not merged:
1. **Find the cause** if the repository shows it (read the two PRs'
   commits, `AGENTS.md`'s commit steps and `tools/imagegen/` encode and
   ingest code; compare the broken bytes with what a base64 or text-mode
   mishandling would produce). Say what you found or that it is unknown.
2. **Guard:** `.github/workflows/merge-takes.yml` (merged in #189)
   leaves a PR for the lead unless every changed `.webp` starts with
   `RIFF` and has `WEBP` at byte 8, every `.jpg` starts with `FF D8 FF`
   and every `.png` with the PNG signature. Add the same check as a test
   or tool in `tools/imagegen/` (e.g. `check_takes.py`) and one line in
   `AGENTS.md` telling Codex to run it before pushing.
3. **Redo rows:** two Demand rows FIRST in Demand that re-run batch 185
   (all 6 jobs) and batch 184 (the 5 broken jobs) from their manifests as
   they stand on main, committing new takes over the broken ones, with
   the check of item 2 run before the push. Note in QUEUE-LOG that the
   first deliveries (#184, #186) were corrupt.

Git identity: user.name "Eren Deniz Kuyucaklıoğlu", user.email
"109629701+ErenDenizK@users.noreply.github.com"; commits end with exactly
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
`Claude-Session: https://claude.ai/code/session_01GwfTHREtdp7pj7j3uZDC2i`.
PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`,
a blank line and the session URL. Open the PR with the GitHub MCP tool.
Hand back: PR link, the cause (or unknown), the rows. At most 10 lines.
