# Friction log

Every agent's hand-back ends with one `Friction:` line: what slowed it
down, or which rule misled it. `python3 -I tools/studio/friction.py` collects them; the lead adds those that are not "none" here, with a kind (`tool`,
`brief`, `rule`, `platform`), and handles each within a day. For the
lead's own slips, "Who" carries its context size and the turns since the
last compaction (`lead, 310k, 140 turns`), so that in two weeks this
table can say whether slips follow context size. The route reads
this log. A rule changes only when rows here back the change
(`docs/studio.md` section 11).

| Date | Who | Kind | Friction | Handled |
|---|---|---|---|---|
| 2026-11-12 | lead | `tool` | `tools/swift/setup-linux.sh` pulls Swift from Docker Hub, which answered 429 three times | installed 6.2.1 from download.swift.org to /opt/swift by hand; the script needs that fallback |
| 2026-11-12 | pofu-art builder | `platform` | the auto-mode classifier refused its `merge_pull_request` on pofu-art | the founder approved; the lead merged |
| 2026-11-12 | pofu-art builder | `tool` | `sync_to_art.py` has no path filter; a full sync would overwrite pofu-art's newer QA and run.py fixes | synced two files through scratch copies; port the fixes to pofu (now.md) |
| 2026-11-12 | PR 1 builder | `tool` | stopped and handed back while its Swift run queued behind two other builders' builds | continued with SendMessage |
| 2026-11-12 | spec | `brief` | the lead's brief called batch-76 "home bare v4" an IL1 candidate; it is a never-promote edit | the spec corrected it (its Correction 2) |
| 2026-11-12 | lead | `brief` | now.md said main's CI frames were never produced; they existed on `screenshots/main` | corrected |
| 2026-11-12 | previous lead session | `tool` | read sub-agents' transcript events as the lead's own tool calls | explained; transcript readers should tell sub-agent events apart |
| 2026-11-12 | PR 1 builder | `brief` | spec slip: RehearsalTime takes `SpendingRules().bedtime`, not `EconomyConfiguration().bedtime` | fixed in #407 |
| 2026-11-12 | critic | `tool` | nine of ten frames on `screenshots/*` are 460 x 1000 JPEGs, so 1:1 checks of new bubbles were not possible; `git fetch origin screenshots/...` hit a stale ref lock | fetched by SHA; full-size PNGs are only in the CI artifact |
| 2026-11-12 | lead | `brief` | three of four defects in the feedback brief came from fixtures, not the game (a critic judged CI test frames) | the builder checked each premise first and said so; briefs from frames should say "fixture or game?" |
| 2026-11-12 | PR 2 builder | `platform` | the permission system refused its third push to feat/home-nights; spec premises false: backdrops not byte-identical, `check home` counted sky layers, `isPresent` ignored stages at night | #406 merged at its green second push; the unpushed trims go to a new builder's own PR |
