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
| 2026-11-12 | lead, 389k, ~300 turns | `brief` | told the founder to switch on the frame meter for Friday before a scout checked; it has no switch | the founder was told; a Rehearsal-panel switch is queued before Friday |
| 2026-11-12 | side channel | `platform` | relayed the founder asking whether the Fable route had started, after it had merged and he had accepted it | answered "done" with the dates; the founder may not see the lead's messages promptly |
| 2026-11-12 | PR 6 builder | `tool` | ended its turn "waiting for CI" with no background command, so nothing would wake it | resumed with SendMessage; briefs keep saying "one background command" |
| 2026-11-12 | frame-meter builder, Map builder | `tool` | a background wait stops at 10 to 30 minutes against a 30 to 60 minute CI, so builders hand back with CI pending and re-notify on each timer | the lead waits on CI with one background command (90 min timeout) and stops a builder whose report is in |
| 2026-11-12 | Koke builder | `tool` | `preblur.py app` cannot run whole: it deletes other generators' imagesets and re-encodes 21 PNGs; `test-linux.sh` was OOM-killed twice building PofuTuningTests | restored by hand, Koke outputs only; preblur needs a per-asset target; OOM watched |
| 2026-11-12 | visitors builder | `platform` | the disk filled (145 MB free): eighteen worktrees of about 1.2 GB each; the builder's cleanup was refused by the permission system | the founder approved; the lead removed 11 merged, clean worktrees (12 GB free); from now on the lead removes a builder's worktree when its PR merges |
| 2026-11-12 | Map builder | `tool` | swift-frontend reached 12-13 GB in a 14.3 GB cgroup and was OOM-killed about six times | a separate `--target PofuWorld` build with `-Xswiftc -no-emit-module-separately` worked; test-linux.sh should take that flag |
| 2026-11-12 | visitors builder (1st) | `platform` | resumed by SendMessage after its first hand-back, it no longer had its brief and stopped | a fresh builder with the full brief; resume only agents that are mid-task |
| 2026-11-12 | visitors builder | `tool` | `preblur.py app` drifts goat, mochi and simit PNGs and deletes shadow imagesets; harmony and shadows must be re-run by hand; nothing says so (second report today) | reverted by hand twice; preblur gets a per-asset, deterministic target (route §5.3 tools) |
| 2026-11-13 | lead | `platform` | the container restarted overnight: three background waits and the path-frames builder stopped | resumed each builder by message with its PR state; builders commit and push early |
| 2026-11-13 | Çağlayan fix builder | `tool` | offline skyset_render matched CI except the app's 1 pt tile overlap, so a hairline showed only after CI | a builder fixes the overlap in SkySetView; offline render should mirror the app |
| 2026-11-13 | path-job builder | `tool` | #422's path-frames job restored the main job's cache and failed on main with a stale module (`PlayerPath` not in scope); its own PR run had passed | #426: the path job restores only its own cache; publish no longer skips world frames when it fails |
| 2026-11-13 | lead | `platform` | the disk fell to 2.9 GB again: `git fetch origin` pulls every `screenshots/*` branch (13 GB of .git), plus agents' crops in the scratchpad | negative refspec `^refs/heads/screenshots/*` on origin (fetch frames by SHA); scratchpad cleared of finished agents' crops |
