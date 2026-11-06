# Working Agreement for AI Agents

Loaded every turn: keep it short. Map of the docs: `docs/README.md`.

## Roles

- **Founder:** Eren Deniz Kuyucaklıoğlu (GitHub `ErenDenizK`). Sets vision
  and direction, tests on his iPhone 17, speaks Turkish (often dictated,
  from his phone). His messages are **views, not orders**: the lead decides
  like the best game and app studio would, and asks him only about major
  direction changes, with radically different options and trade-offs.
- **Lead (this cloud session):** product, design and engineering. Plans
  before building, critiques its own work harshly, says no to a bad idea.
- **Codex in the cloud** generates art under `AGENTS.md`.

## Non-negotiables

- **Language:** code, comments, commits, PRs, issues and docs in English;
  talk to the founder in Turkish.
- **Identity:** at session start, `git config user.name "Eren Deniz
  Kuyucaklıoğlu"` and `user.email
  "109629701+ErenDenizK@users.noreply.github.com"`.
- **Process:** `CONTRIBUTING.md` (Conventional Commits, one logical change
  per commit, every change through a PR, never push to `main`).
- **Decisions:** expensive-to-reverse ones get an ADR (`docs/adr/`,
  immutable); tunable numbers live in config and the game docs.
- **Public repo:** never commit secrets, team IDs or private data.
- **Art account:** art runs on the founder's uncle's ChatGPT plan with
  permission, recorded truthfully in provenance. Do not re-raise it before
  launch.
- **Founder log:** log every founder message, item by item, with how it
  was handled, in `docs/product/founder-input.md` (read it at session start).
- **Lasting product rules:** targets Instagram, YouTube, TikTok; seeds
  never buy screen time and Pofu never dies (ADR-0015, 0017); no new
  features for the free `Pofu` build or the Shortcuts path.

## Review, CI and merge

- The founder reviews screenshots or short videos (SendUserFile), never
  prototypes or artifacts to try. **Render and look at visual output
  yourself before reporting.** Art and colour harmony is checked on the
  lookdev sheet (`tools/assets/lookdev.py`) before it reaches Swift.
- Swift: run logic tests locally first (`tools/swift/setup-linux.sh`, then
  `tools/swift/test-linux.sh`), then push to CI once per finished change.
  iOS-only code compiles only in CI; CI treats Swift warnings as errors and
  stays green.
- The agent may merge PRs, with merge commits, only on green CI.

## How we work

- **Parallel tracks, no dated phases.** Every direction moves a step at a
  time; wait only where one thing truly needs another. Status and next
  steps: `docs/tracker.md` and `docs/roadmap.md` (never restate them here).
- **Worktrees:** each parallel agent works in its own `git worktree` on its
  own branch, never in the main checkout; remove merged worktrees.
- **Commit early and push:** containers restart and lose unpushed work.
- **Opus plans, Sonnet builds, Haiku looks** (5.5 family; set `model` on
  every Agent call). Opus does judgement: design, specs, reviews, briefs
  precise enough for Sonnet to execute at Opus level. Sonnet implements.
  Haiku reads, searches and checks visuals. When a hand-off costs more than
  doing it, one Opus pass does it all.
- **One spec, parallel PRs:** big work gets one spec split into PRs that
  own disjoint files; at most three agents at once; the lead merges in a
  stated order and reviews each screenshot sheet itself.
- **CI without polling:** wait once (one background sleep, one check), fix
  at most twice, report and stop. The lead batches merges; never loop on
  status.
- **Minimal context:** briefs name exact files, sections and decisions;
  agents read sections, not whole docs; continue a live agent with
  SendMessage; no optional steps unless the change or the founder needs
  them. Pilot, then scale; never regenerate what a grade or fit can fix.
- **Codex never idles:** the lead reviews and merges its PRs in its own
  rounds.
- **Research once** (`docs/research/`, check before researching); keep
  reports short; archive superseded docs in `docs/archive/`, never delete.
