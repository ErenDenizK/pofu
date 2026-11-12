# Friction log

Every agent's hand-back ends with one `Friction:` line: what slowed it
down, or which rule misled it ("none" is a valid answer). The lead copies
each line here, dated. Every 3 to 4 days a rule review weighs this log with
the numbers (`tools/studio/session_cost.py`, pushes per PR, red CI, rework,
critic findings). A rule changes only when an incident recorded here backs
the change; "no change" is a valid outcome. Agreed with the founder
2026-11-12.

| Date | Who | Friction | Handled |
|---|---|---|---|
| 2026-11-12 | lead | `tools/swift/setup-linux.sh` pulls Swift from Docker Hub, which answered 429 three times | installed 6.2.1 from download.swift.org to /opt/swift by hand; the script needs that fallback |
| 2026-11-12 | pofu-art builder | the auto-mode classifier refused its `merge_pull_request` on pofu-art | the founder approved; the lead merged |
| 2026-11-12 | pofu-art builder | `sync_to_art.py` has no path filter; a full sync would overwrite pofu-art's newer QA and run.py fixes | synced two files through scratch copies; port the fixes to pofu (now.md) |
| 2026-11-12 | PR 1 builder | stopped and handed back while its Swift run queued behind two other builders' builds | continued with SendMessage |
| 2026-11-12 | spec | the lead's brief called batch-76 "home bare v4" an IL1 candidate; it is a never-promote edit | the spec corrected it (its Correction 2) |
| 2026-11-12 | lead | now.md said main's CI frames were never produced; they existed on `screenshots/main` | corrected |
| 2026-11-12 | previous lead session | read sub-agents' transcript events as the lead's own tool calls | explained; transcript readers should tell sub-agent events apart |
| 2026-11-12 | PR 1 builder | spec slip: RehearsalTime takes `SpendingRules().bedtime`, not `EconomyConfiguration().bedtime` | fixed in #407 |
| 2026-11-12 | critic | nine of ten frames on `screenshots/*` are 460 x 1000 JPEGs, so 1:1 checks of new bubbles were not possible; `git fetch origin screenshots/...` hit a stale ref lock | fetched by SHA; full-size PNGs are only in the CI artifact |
| 2026-11-12 | lead | three of four defects in the feedback brief came from fixtures, not the game (a critic judged CI test frames) | the builder checked each premise first and said so; briefs from frames should say "fixture or game?" |
| 2026-11-12 | PR 2 builder | the permission system refused its third push to feat/home-nights; spec premises false: backdrops not byte-identical, `check home` counted sky layers, `isPresent` ignored stages at night | #406 merged at its green second push; the unpushed trims go to a new builder's own PR |
