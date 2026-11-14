# Studio capacity facts, 2026-11-14

Facts only, gathered 2026-11-14 ~12:50 UTC by a scout for Fable. No advice. Repo commit: origin/main `3186e74d`.
Sources are the command or file in each row. "Now" means the moment of the reading; other agents were mostly idle.

## 1. Machine

| Fact | Value | Source |
|---|---|---|
| CPUs | 4 | `nproc` |
| Memory | 16,087 MB total; 857 used, 10,670 free, 15,230 available; swap 0 | `free -m`, `/proc/swaps` (empty) |
| cgroup memory limit | none visible: v1 `memory.limit_in_bytes` = 9223372036854771712 (unlimited); v2 files `memory.max/current/peak/events` do not exist in `/sys/fs/cgroup` | `cat /sys/fs/cgroup/memory/memory.limit_in_bytes`. No oom counts readable. |
| Disk `/`, `/home`, `/tmp` | one device `/dev/vda`: Size 252G, Used 38-39G, Avail 572M at first reading, 73M at last (99-100%) | `df -h / /home /tmp` |
| Effective allowance | Used + Avail is about 39G, not 252G (the per-session allowance is what binds) | `df -h` |

Big directories (`du -sh`):

| Path | Size |
|---|---|
| /home/user/pofu (main checkout) | 20-21G, of which `.git` 19G, `Packages/PofuKit/.build` 410M |
| /opt/swift (toolchain 6.2.1) | 3.2G |
| /home/user/wt-wave0, wt-home-nights, wt-bell-seen | 1.3G, 1.2G, 802M |
| /home/user/wt (pofu-art worktrees, 11 dirs) | 1.2G (lead-docs 768M, others 24-49M) |
| /home/user/wt-b77, wt-b79, wt-b76, wt-queue-paused | 334M, 36M, 24M, 53M |
| /home/user/pofu-art (own clone) | 157M |
| /tmp | 672M (many `swift*.log`, `/tmp/k2`, `/tmp/cg`) |
| /root/.cache | 253M (`pofu-upscale` 235M; swiftpm cache 408K) |
| /root/.claude | 349M (`projects` 341M = transcripts) |
| /root/.local | 273M |

## 2. Swift builds

| Fact | Value | Source |
|---|---|---|
| Lock | `flock /tmp/pofu-swift-build.lock swift test`; file exists, 0 bytes, made Nov 12 15:49 | `tools/swift/test-linux.sh` last line; `ls -la` |
| Job count | `-j 1` by default unless the caller passes `-j`/`--jobs` | `test-linux.sh` lines 12-14 |
| OOM workaround | the comment: two PofuWorld compiles at once, or `-j 4`, are killed at "15 GB, no swap"; lock + `-j 1` is the fix | `test-linux.sh` header comment |
| setup-linux.sh | no lock, job or memory lines (grep found none) | `grep -n -i "jobs\|lock\|oom\|memory\|swap\|-j" tools/swift/setup-linux.sh` |
| Swift install | friction row 2026-11-12: Docker Hub answered 429 three times; Swift 6.2.1 installed by hand from download.swift.org to /opt/swift | `docs/studio/friction.md` |

`.build` directories (all under `Packages/PofuKit/.build`):

| Worktree | Size | mtime |
|---|---|---|
| wt-wave0 | 476 MiB | 2026-11-14 12:40 |
| wt-home-nights | 423 MiB | 2026-11-12 18:05 |
| pofu (main) | 410 MiB | 2026-11-12 15:56 |
| Total | 3 dirs, 1,339,736 KB (about 1.28 GiB) | `find ... -name .build` + `du -sk` |

- No `.build` in wt-bell-seen or wt/lead-docs.
- Shared build cache: not found. Each `.build` is inside its worktree; `/root/.cache/org.swift.swiftpm` is 408K; `/root/.swiftpm` is 12K. No shared `--scratch-path` is set in the script.
- Timing evidence:
  - `wave0/build.log` (scratchpad): `[276/276] Compiling PofuWorld resource_bundle_accessor.swift`, file written 12:32; its log does not carry a duration.
  - `wave0/test.log` last write 12:37 and `test2.log` last write 12:41 (298 KB, 275 KB).
  - `/tmp/pw-build.log`: "Build complete! (4.61s)" (incremental, 25 steps).
  - `.build/debug.yaml` in main: 2026-11-12 15:51:19; `.build` dir mtime 15:56:07 (about 5 min of first build to the last write, unverified as one build).
  - No log in /tmp shows a wall time for a clean full build. I could not tell clean-build duration.

## 3. Repository

| Fact | Value | Source |
|---|---|---|
| Objects | loose 3,526 (100 MiB); in-pack 61,701; packs 57; size-pack 18.54 GiB; 1 garbage file `tmp_pack_Z2TmwQ` (77.5 MiB reported by count-objects) | `git count-objects -vH` |
| `.git` size | 19G; `.git/objects/pack` has 57 packs; largest packs 1.32 GB (Nov 12), 0.98 GB, 0.85 GB (Nov 14), 0.58 GB, 0.54 GB | `du -sh .git`; `ls -la objects/pack` |
| gc | `[gc] auto = 0` in `.git/config` | `.git/config` |
| LFS | git-lfs 3.4.1 installed; no `.gitattributes` on disk in the main checkout; not tracking anything found | `git lfs version`; `cat .gitattributes` |
| Refs | 161 heads on origin (ls-remote), 197 `refs/remotes` locally, 115 of them `screenshots/*` | `git ls-remote --heads origin`; `git for-each-ref` |
| Refspecs | `fetch = +refs/heads/*:refs/remotes/origin/*` and `fetch = ^refs/heads/screenshots/*` (negative) | `.git/config` |
| Tree at origin/main | 10,847 files, 767.1 MB | `git ls-tree -r -l origin/main` summed |
| design/art | 573.7 MB; Packages/PofuKit 99.0 MB; design/prototypes 32.9 MB; docs/product 21.0 MB | same, grouped by two path levels |
| Paths matching design/art, .xcassets, screenshots | 699.2 MB | same, grep |
| `git worktree add --no-checkout` | 0.009 s real; 8 KB on disk (then removed) | `time git worktree add` |
| Full checkout estimate | 767 MB working tree (sum of blob sizes) + index | `ls-tree` sum; checkout not done |
| This sparse worktree (`docs/research`) | 5.5 MB | `du -sh` |

Top 20 blobs on origin/main are all PNG, 3.9 to 6.2 MB each (6.2, 6.2, 6.0, 5.8, 5.7, 5.7, 5.5, 5.4, 5.3, 5.2, 5.1, 5.0, 4.8, 4.8, 4.8, 4.7, 4.3, 4.1, 4.0, 3.9 MB). 19 are
`Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets/world-{caglayan,home}-plate-*.imageset/*.png`; one is
`Tests/WorldScreenshots/PlateVariants/b-world-home-plate-day-0.png` (5.8 MB). (`git rev-list --objects origin/main | git cat-file --batch-check`)

## 4. Worktrees

`git worktree list` in /home/user/pofu shows 5 (main detached at `1364ac01`):

| Worktree | Branch | Merged into origin/main | Ahead of upstream | Dirty | Size |
|---|---|---|---|---|---|
| /home/user/pofu | detached HEAD | yes | n/a | 0 | 21G |
| wt-bell-seen | feat/bell-seen | no | 0 | 0 | 802M |
| wt-home-nights | feat/home-nights | no | 1 | 0 | 1.2G |
| wt-wave0 | feat/asset-wave0-home | no | 0 | 0 | 1.3G |
| wt/lead-docs | claude/exciting-cori-1t8br2 | no | 0 | 0 | 768M |

`/home/user/wt` holds 11 dirs: art-76..81, close-78-81, codex-one-word, fix-78, fix-79, lead-docs. All except lead-docs are worktrees of the other repo `/home/user/pofu-art` (their `.git` files point to `/home/user/pofu-art/.git/worktrees/...`), 24-49 MB each, branches `review/batch-*`, `chore/*`, `fix-79`. `wt-b76`, `wt-b77`, `wt-b79`, `wt-queue-paused` are also pofu-art worktrees (24M, 334M, 36M, 53M). The pofu-art ones were not checked for merged/unpushed.

## 5. CI (`gh api repos/ErenDenizK/pofu/actions/runs?per_page=30`)

- All 30 runs are workflow "CI". Events: pull_request and push (to main). Wall = `run_started_at` to `updated_at` (crude).
- Median wall time of all 30 runs: 3.1 min. Cause: most are docs-only runs where the macOS jobs are skipped or the run was cancelled.
- Full runs (macOS jobs run), all success: PR feat/bell-seen 38.4 and 40.6 min; PR fix/bell-cold-launch 35.0; PR feat/bell-sky 45.7; push main 40.3 and 42.3. Median of the four PR full runs: 39.5 min; of all six: 40.5 min.
- Not-full runs: docs/* and claude/exciting-cori PRs 2.2-3.7 min; 8 runs `cancelled` (new push superseded).

Per-job durations (`/actions/runs/{id}/jobs`):

| Job | runner | run 43593599299 (feat/bell-seen) | 43588942818 (feat/bell-seen) | 43461130250 (fix/bell-cold-launch) |
|---|---|---|---|---|
| Detect what changed | ubuntu | 3.4 m | 3.3 m | 3.2 m |
| Test PofuKit and build the app | **macos-26** | 27.8 m | 30.8 m | 27.6 m |
| Render the player-path frames | **macos-26** | 13.9 m | 11.8 m | skipped |
| Test the Python tools | ubuntu | skipped | skipped | skipped |
| Publish world screenshots to a branch | ubuntu | 7.0 m | 6.3 m | 3.9 m |

The two macOS jobs are "Test PofuKit and build the app" and "Render the player-path frames".

## 6. Session cost

- Env vars: no cost variable; `CLAUDE_CODE_CCR_EVENT_FLUSH_POLICY` mentions `cost_report_max_wait_ms` only. `/root/.claude` has no file with cost or usage in its name or JSON.
- `get_session` (lead session "Pofu 3", model claude-opus-5-5, effort high, created 2026-11-12 15:37Z, read 2026-11-14 12:52Z): `usage.cost_usd` 437.56; input 34,874; output 3,676,606; cache read 1,026,175,935; cache write 48,367,567 tokens. Context used 125,602 of 1,000,000.
- Sub-agent costs per session: not read. `docs/studio.md` states "the smallest agent costs $0.70 to $1".

## 7. Flow (`docs/studio.md`, `docs/studio/friction.md`)

Roles (studio.md, table near line 40): Founder; Lead (Opus 5.5, high); scout (Haiku); spec (Opus, high); builder (Sonnet or Opus); critic (fresh context); art-reviewer (Opus); Codex (paints in pofu-art); Fable 5.2 (consults, takes whole judgement work).

Parallelism rules quoted:
- "Sub-agents cannot start agents of their own, so the lead sequences them."
- "At most three builders at once (the machine's memory and your attention are the limits). Scouts and critics do not count."
- "Desks move in parallel when they do not need each other."
- Follow-up: continue the same agent under about 200,000 tokens; past that start fresh. Do it yourself up to about ten tool calls.
- CLAUDE.md: one Swift build at a time via `tools/swift/test-linux.sh`; push at most three times per PR; CI takes 30 to 60 minutes.
- studio.md line ~376: hygiene at a pause lists "merged worktrees still on disk".

Friction rows (24-line file; no row names disk or memory exhaustion; checked with grep for disk/memory/oom/space/restart):
- 2026-11-12 lead `tool`: Docker Hub 429 on Swift install; hand install to /opt/swift.
- 2026-11-12 PR 1 builder `tool`: "stopped and handed back while its Swift run queued behind two other builders' builds".
- 2026-11-12 critic `tool`: `git fetch origin screenshots/...` hit a stale ref lock; fetched by SHA.
- 2026-11-12 PR 2 builder `platform`: permission system refused its third push.
- No CI-wait or container-restart rows present. (CLAUDE.md says containers restart and lose unpushed work; that is a rule, not a friction row.)
