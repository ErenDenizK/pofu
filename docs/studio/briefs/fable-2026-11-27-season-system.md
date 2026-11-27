# Brief: the season system, built so a season swaps cleanly (Fable, 2026-11-27)

Role: `.claude/agents/spec.md`. Read founder-input 49 first (the last
entry of `docs/product/founder-input.md` on the lead branch
`claude/exciting-cori-1t8br2`): his view on seasons, and his quality rule
(70-80 % on the first shot, then small steps; never start at 20-30).

The question: how a season enters the system the app ships today, so
that changing the season swaps every visible piece at once and in
harmony, together with island levels, station levels and the three
lights. Today (main): one painted Home plate per island stage and light
(`plate-home.json`, `painted`, `lightStages`); erased bases per stage
(batch 117 picks); station looks cut from aligned plot ladders (#521
windmill, batch 134; plot ladders for four more stations queued in
pofu-art D52-D55); looks per light (#520); golden plates IL3-7 (#522);
the island year (#526); your island-calendar-v1 C2-C5 and its grade test
(it failed). Evidence to weigh: batches 173-176 (station levels as
whole-plate edits) could not be cut (re-renders drift; see
`docs/studio/friction.md`, 2026-11-27); 177/178 are queued as level-10
look targets only.

Decide, with numbers: what is painted per season (plates, bases, looks;
how many images per season for Home), what is shared, what is derived
by code; the painting order that keeps everything aligned to one source
(one season first, the founder's way); how a station look painted in
spring stays consistent with autumn's base; the checks that catch a
mismatch before he sees it; what a season costs Codex and the Swift
lane. Prove the key claim on pixels before you rest the plan on it
(e.g. one station look over two seasons' bases, from existing takes or a
small Codex pilot you queue). Name the pictures he should see.

Deliver: one pofu PR (`docs/design/season-system-v1.md`, English, plus a
short Turkish section or page for him), and if you queue Codex work, one
pofu-art PR with manifests + Demand rows (validated with
`python3 -I tools/imagegen/run.py plan --manifest <file>`). Two builders
are running (1c pond, 2b Gezgin); do not touch their files. Disk floor 5
GB: sparse worktrees. Git identity: user.name "Eren Deniz
Kuyucaklıoğlu", user.email "109629701+ErenDenizK@users.noreply.github.com";
commit trailer: if your session's attribution rule conflicts with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, follow yours
and say so (the lead squash-merges). Open PRs with the GitHub MCP tool;
do not merge. Hand back once: PR links and a 10-line summary.
