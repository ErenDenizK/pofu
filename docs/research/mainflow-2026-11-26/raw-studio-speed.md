# Raw facts: why the studio slowed (gathered 2026-11-26 19:11 UTC)

Scout, no judgement. Times are UTC from the GitHub API unless marked. PR data:
`gh api repos/ErenDenizK/{pofu,pofu-art}/pulls?state=all` (pofu: 500 PRs, #19-#518,
created 11-01..11-25, 479 merged; pofu-art: 169 PRs, #1-#169, 106 merged).
CI data: `repos/ErenDenizK/pofu/actions/runs` (2319 runs). "Wall" = `updated_at -
run_started_at` of a run (includes queue). Founder messages are numbered as in
`docs/product/founder-input.md` (fi N, lines 777-805); most carry a date, few a time.

## 1. Merges per day and the gaps (pofu / pofu-art)
- pofu merges per day: 11-01 22, 11-02 46, 11-03 48, 11-05 65, 11-06 90, 11-07 15, 11-08 12, 11-10 28, 11-11 12, 11-12 37, 11-13 21, 11-14 20, 11-15 12, 11-16 22, 11-17 2, 11-18..11-23 0, 11-24 6, 11-25 4, 11-26 0 (as of 19:11).
- pofu main: last merge before the gap #508, 11-17 22:45; next #509, 11-24 19:46 = 6.9 days. `gh api repos/ErenDenizK/pofu/commits?since=2026-11-18T12:30Z&until=2026-11-23T13:00Z` returns 0 commits on main. Newest pofu merge now: #517, 11-25 03:14 (about 40 h before this gather).
- pofu-art merges per day: 11-12 16, 11-15 11, 11-16 28, 11-17 3, 11-18 10, 11-19..11-22 0, 11-23 9, 11-24 12, 11-25 8, 11-26 5.
- Cause stated in the docs for 11-18..11-23: fi 39 (11-17) "his budget is short (visas ...) at most two or three agents"; fi 43 (11-23) "Codex idle since 11-19 ... His visas are over". Whether the lead did anything 11-18 12:16 to 11-23 14:07: local `git log --all` (pofu) shows no commit between 11-18 12:16 and 11-23 14:07, and the GitHub API shows no pofu-art commit 11-19 15:30 to 11-23 14:17; UNCHECKED: session activity that left no commit.
- now.md:7 "Founder last played: 11-14 (main 0cf03ca1)" (12 days before today). No device feedback after 11-14 is recorded in fi 26-46 except text answers.

## 2. Founder message to merged work
| fi (date) | asked for | work evidence | latency |
|---|---|---|---|
| 38 (11-16 11:44) | Fable: island progression | #503 created 11-16 12:20 (+36 min); fi 39 answers 11-17; #503 still `open` on 11-26 (pofu.tsv); #490 also open | open 10 d |
| 40, 41 (11-17 night) | concept round, four topics | pofu #508 merged 11-17 22:45; pofu-art #123 queue merged 22:35; deliveries #124-131 created 11-17 23:11..11-18 03:34, merged 11-18 11:56-57 (8-13 h after creation); sheets #133 merged 11:58 | brief to delivery 4.5-5 h Codex; merge 12 h after |
| his verdict on those sheets | fi 43 (11-23): "never reached the lead before" | sheets sent 11-18 11:58 -> verdict logged 11-23 | 5 days |
| 42 (11-18) | round 2 queue | #134 merged 11-18 12:16; deliveries #135-142 created 11-18 13:07-16:20; all merged 11-23 14:06 | 118-121 h created-to-merged |
| 43 (11-23) | assessment, two Fable rounds | #509 created 11-23 14:23, CI docs-only green at once, merged 11-24 19:46 (29.4 h, after fi 44 answers); #511 (round 2) 11-24 20:04 | 29.4 h |
| 44 (11-24) | build the path | #510 21:28, #512 22:16, #513 23:12, #515 00:00, #514 00:39, #518 02:22, #517 03:14 (all created 19:51..01:38) | 19:46 -> 03:14 = 7.5 h for 7 PRs |
| 45 (11-24 night) | keep Codex running | #154 queue merged 11-24 22:01; 161-165 (#157-161) merged 11-25 00:40; 166-169 (#164-167) created 11-25 01:10-02:27, merged 11-26 19:06 | 40-42 h created-to-merged |
| 46 (11-26) | main flow plan + studio-speed assessment | #164-167, #169 merged 11-26 19:06; briefs `fable-2026-11-26-mainflow-and-studio.md`, `gather-2026-11-26-*.md` exist | in progress |

## 3. PRs waiting after green
- pofu merged PRs since #420 (11-12): created-to-merged median 1.0 h, mean 2.0 h, p90 3.0 h, max 29.4 h (#509). Non-docs: median 1.5 h, p90 3.2 h. Before #420: non-docs median 0.9 h, mean 4.8 h, max 144 h.
- Time from last green PR run to merge (pofu, merged): #<=419 median 6.4 min, p90 143 min; #>=420 median 1.3 min, p90 16.8 min. Outliers: #509 1751 min, #504 171 min. (Method: merged_at minus latest successful pull_request run end before merge; docs-only PRs with no run excluded.)
- pofu-art `art(batch-*)` PRs (63 merged): created-to-merged median 4.7 h, mean 21.3 h, p90 118 h. Over 12 h: #135-142 (118-121 h), #145-148 (28-29 h), #164-167,#169 (40-42 h), #124,#125 (12-13 h). pofu-art chore/queue/design PRs (43): median 0.0 h.

## 4. Codex idle gaps
Method: pofu-art commits whose message has "OpenAI Codex" (934, 11-12 07:56 to 11-25 03:24); a gap = no such commit (a long job could run inside a gap; the commit is when it is visible). Gaps over 3 h:
- 11-12 16:57 -> 11-15 10:31 = 65.6 h; 11-15 14:53 -> 22:40 = 7.8 h; 11-16 18:04 -> 11-17 23:09 = 29.1 h; 11-18 03:33 -> 12:36 = 9.0 h; 11-19 00:31 -> 09:55 = 9.4 h; **11-19 15:29 -> 11-23 14:35 = 95.1 h**; 11-23 15:47 -> 11-24 20:23 = 28.6 h; **last Codex commit 11-25 03:24 -> now = 39.8 h**.
- Docs on those gaps: QUEUE.md rows #121/#122 "hold batch 136 / 137" (11-17 18:55, 22:15) fall in the 29.1 h gap; fi 43 "Codex idle since 11-19"; fi 46 "Codex idle ~16 h since 170" (the data above gives about 40 h at 19:11; the 16 h figure disagrees; its writing time is not in the entry).
- Batch 152 first run delivered nothing on quota: #140 closed unmerged (qlog:307).
- Queue state now: QUEUE.md D29-D33 (lines 104-108) delivered and merged 11-26 19:06; a new queue brief `docs/studio/briefs/codex-2026-11-26-mainflow-queue.md` exists (not read in detail).

## 5. Concept rounds vs shipped (pofu-art QUEUE-LOG.md:269-327; pofu PR bodies)
- Concept batches 138-156 (rounds 1-3, 11-17 to 11-24): 19 batches; delivered jobs: round 1 (138-145) 88, round 2 (146-153 + 152 rerun) 102, round 3 (154-156) 15 = 205 jobs. Explorations 157-165: 71 jobs; 166-170: 33 queued (D29-D33).
- Topics in the concept round: board, panel, voyage, island growth, pond, Gezgin, UI materials (D1-D8). Reached the app so far: board (batch 158 picks in #514, 161 in #514/#518), station card (#512 - body cites no batch number), sound/voice (#515, not art). Not in the app: voyage, Gezgin levels, island growth film, pond crowns (now.md: "stage 4 (Sefer) held"). Founder verdict on round 1 (fi 43): "Her sey cok cafcafli, extravaganza"; panel "no ladder"; round 2 panel "no ladder and no painted glass panel; no round 3 for the panel" (qlog:290).
- Board: batches 138, 144, 146, 152, 155, 157, 158, 161 (+163, 166-169 kits) = 8 batches before the shipped #514; delivered jobs 138:10, 144:8, 146:14, 152:15, 155:6, 157:2, 158:12, 161:4 = 71 jobs; then #518 (ring fix) the day after #514.
- Art PRs titled for the flow board / stream board since #81 (11-15): 19 of 49 merged `art(batch-*)` PRs (#81,93,101,104,114,117,124,130,135,146,147,151,152,157,159,164-167); PR numbers pulled by title regex, not by content.

## 6. Pushes per PR and CI (pofu)
- Pushes = distinct head SHAs among `pull_request` runs of the PR's branch (excl. shared branch `claude/exciting-cori-1t8br2`, used by 5 PRs incl. #481/#499 with 105 SHAs each). #19-#419 merged (n 391): mean 4.2, median 2, 166 with >=3. #420-#518 (n 83): mean 1.8, median 1, 21 with >=3, 9 with >=4. #509-#518 (n 10): mean 1.6.
- Runs 11-01..11-26: 2319; pull_request success 1046, cancelled 667, failure 123; push(main) success 252, cancelled 225, failure 5. Cancelled long (>20 min) runs 11-12..11-26: PR 6 (3.5 h), main push 18 (9.8 h). Failures long: 10 (6.4 h).
- Full run duration: pull_request success, all runs: median 4.0 min (path-filtered short runs), full runs ~35-40 min wall (samples: 38.2, 35.4, 39.7 min; run 45533970624: macOS job 31 min + path-frames job 13 min). Long (>20 min) successful PR runs 11-12..11-26: 125 = 82.5 wall-h; main push long successes 36 = 23.9 wall-h.
- Wall hours per day (all runs): 11-12 32.5, 11-13 34.0, 11-16 35.1, 11-17 1.2, 11-24 9.1, 11-25 5.8.
- Billing: `/actions/runs/{id}/timing` returns billable ms 0 for 3 sampled runs (public repo); real cost UNCHECKED.
- Label cancel friction: friction.md rows 11-14 (two same-second runs cancel each other); not re-measured.

## 7. Founder questions: small vs direction (fi 26-46)
- Small/process questions he answered or rebuked: fi 29 (merge pofu-art #64), fi 30 (#65), fi 31 (#67; "Bu tarz merge'leri bana sorma ... iş durmak zorunda kalıyor"), fi 36 (4th push on #479) then fi 37 "Bu tarz sorular için bir daha üretimi durdurma". 4 in 11-14..11-15; studio.md:41 now records the rule. Questions of that kind after 11-15 in fi: none found (UNCHECKED: side-channel messages not logged).
- Direction question sets: fi 34 (concept choices; "no answer by the check-in" 11-15 17:11, lead used defaults), #503 (6 items, answered fi 39 on 11-17, 1 day), #509 round-1 questions (answered fi 44 on 11-24; #509 created 11-23 14:23, merged 11-24 19:46), concept sheets (answered 11-23, 5 days).
- Permission-system stops needing him (friction.md): 11-12 merge of pofu-art refused; 11-12 third push refused; 11-12 worktree cleanup refused; 11-13 worktree removal refused; 11-15 `rm /swapfile` blocked; 11-24 commit trailer rewrite refused (force push). 6 rows.
- fi 46 (11-26): "mini game gibi ufak tefek seylere takildik ... Bu bizim icin oldurucu"; "only big-direction questions; always send a screenshot".

## 8. Mini-game (flow board) vs main flow, since 11-12 (#420-#518, 99 PRs)
- By title: flow/minigame 12 (11 merged; #507 open): #425, 457, 467, 476, 483, 486, 489, 501, 506, 507, 514, 518. Docs/chore 25. Other (world, Home, sky, Map, camera, UI, sound) 62, 54 merged. Flow PRs after the 11-17 gap: #514, #518 of the 10 merged 11-24/25 PRs (#510,#512,#513,#515,#516,#517 are not flow).
- Fable briefs naming the board: `fable-2026-11-16-minigame-overhaul.md`, `fable-2026-11-17-board-and-upgrade.md` (of 15 fable briefs listed in docs/studio/briefs, 22 files total).
- Founder-side: fi 39-40 give the board and the upgrade sheet most words (board drawing, "keycap"); batch 136 "not to be spent" until settled.
- Titles by regex only; PRs mixing flow with other work not split.

## 9. Lead bookkeeping (visible in git)
- Commits since 11-01 on this history: 1223 total; touching `docs/now.md` 187 (11-12 31, 11-13 36, 11-14 16, 11-15 26, 11-16 50, 11-17 8, 11-18 2, 11-23 3, 11-24 6, 11-25 7, 11-26 2); `founder-input.md` 63; `friction.md` 34; `docs/tracker.md` 4.
- PRs titled docs/chore: 146 of 500 pofu PRs (29%); of #420-518: 25 of 99. Titles naming now/founder-input/friction/tracker/status: 31 (mostly 11-02..11-16).
- The lead reuses branch `claude/exciting-cori-1t8br2` for 5 PRs.
- now.md is 57 lines (limit 60); "Updated 2026-11-25" while it is 11-26.
- Lead turns: UNCHECKED (transcripts not read).

## Doc errors noted
- fi 46 "Codex idle ~16 h since 170": data shows last Codex commit 11-25 03:24 (about 40 h before this gather).
- now.md:5-6 "Founder last played 11-14" vs fi 43/44 "tests more from 11-25": no later play recorded.

Friction: `gh auth status` showed a failed token but API calls worked; the contents API gave pofu-art files; commit author tz mixes (git log shows +03 on merge commits).
