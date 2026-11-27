# Brief: the plate texture budget, so eight stations ship sharp (2026-11-27)

Role: `.claude/agents/spec.md`. Step 1 of the main-flow plan puts eight
Home stations at five levels on the island, by day, night and golden,
and the season system (`docs/design/season-system-v1.md`) multiplies
that by seasons. The 1c builder (PR #528, parked) hit the budget: Home's
largest state plus props measured 8.955 MB of 9 MB (`ingest.py check
home`), so adding the pond on stage 0 forced the pond to 0.8 and the
shipped windmill from 1.7 to 1.45 texture px per point. The station
looks were meant to be judged at 1:1 on a 1206 x 2622 frame (3x); 0.8
px/pt will read soft. Six stations remain.

Answer with evidence (file:line, measurements):
1. What the 9 MB is: where it is defined, what it counts (all levels'
   looks, or only those a state draws? bases? props? decoded RGBA or
   file bytes?), why 9 MB (a device memory limit, a widget or extension
   limit, a guess?), and whether the count matches what the app holds in
   memory at once (read the loader: `PlateCompositor`, `PlateImage`,
   asset catalog usage).
2. Options, each with its saving measured on the real assets: draw and
   load only the current level's look per station (and drop the rest);
   crop looks and bases tightly; lower-res bases where the look covers
   them; compressed GPU formats (ASTC via asset catalog) or HEIC; split
   plates; anything else. What each costs in code, in frames, in risk.
3. Decide: the budget rule the studio should use (what is counted, the
   limit and its reason) and the density every look ships at (target:
   at least the windmill's original 1.7 px/pt, more if the 1:1 crop
   needs it), with the code change as PRs that own separate files.

Read pofu `origin/main` (no Swift build needed unless you measure
memory; if you do, use `tools/swift/test-linux.sh`). Builders are on 2b
(`PofuWorld/Gezgin/`, `mooring`) and nobody else is in the Swift lane.
Deliver one pofu PR: `docs/design/texture-budget-v1.md` (English, with a
3-line summary at the top). Git identity: user.name "Eren Deniz
Kuyucaklıoğlu", user.email "109629701+ErenDenizK@users.noreply.github.com";
commits end with exactly `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>` and `Claude-Session:
https://claude.ai/code/session_01GwfTHREtdp7pj7j3uZDC2i`. PR body ends
with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`,
a blank line, the session URL. Open the PR with the GitHub MCP tool; do
not merge. Sparse worktree; disk floor 5 GB. Hand back: PR link and a
10-line summary.
