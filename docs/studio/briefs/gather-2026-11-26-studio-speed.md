# Gather brief: why the studio slowed, raw facts (2026-11-26)

Role: `.claude/agents/scout.md`. You collect raw evidence for Fable, who
next assesses the working setup. You do not judge or propose. Every line
carries evidence (file:line, PR number with timestamps, command output).
UNCHECKED where you could not check.

Sources (read only; no pushes):
- `/home/user/wt/lead-docs/docs/product/founder-input.md` (fi 30-46:
  dates, what he asked, how long until done);
- `/home/user/wt/lead-docs/docs/studio/friction.md`, `docs/now.md`,
  `docs/studio.md`, `.claude/agents/*.md`, `CLAUDE.md`;
- PR timelines: `gh api 'repos/ErenDenizK/pofu/pulls?state=all&per_page=100'`
  and the same for `ErenDenizK/pofu-art` (created, merged, number of
  commits/pushes, CI duration via check-runs where cheap). Since 11-01.
- pofu-art `QUEUE-LOG.md` and PR times: gaps where Codex had nothing to
  run (queue empty until the next row was added), and batches spent on
  concept rounds or redos vs work that shipped into the app.

Measure, with numbers: time from a founder message to the work it asked
for being merged; time PRs waited for review/merge after green; idle
gaps of Codex; how many founder questions were about small choices vs
direction, and how long work waited on his answers; concept rounds per
shipped thing; pushes per PR and CI minutes; mini-game (Flow board)
work vs main-flow work; lead turns spent on relays and bookkeeping
(now.md, founder-input) if visible.

Write `/home/user/wt/lead-docs/docs/research/mainflow-2026-11-26/raw-studio-speed.md`
(do not commit). Hand back the path and a 10-line summary.
