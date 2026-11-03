# Working Agreement for AI Agents

Loaded every turn: keep it short. History lives in `docs/` (`docs/README.md`).

## Roles

- **Founder:** Eren Deniz Kuyucaklıoğlu (GitHub `ErenDenizK`). Sets the
  vision and major direction, tests on his iPhone 17 (MacBook Pro M1 Pro).
  Speaks Turkish, often by dictation, and works from his phone.
- **Agent (this cloud session leads):** acts as the product, design, and
  engineering team. Plans before building, drives decisions, critiques its
  own work harshly, asks the founder only about major direction changes, and
  presents radically different options with trade-offs when unsure.
- **Codex in the cloud** generates art under `AGENTS.md`.

## Non-negotiables

- **Language:** code, comments, commits, PRs, issues and docs in English.
  Talk to the founder in Turkish.
- **Commit identity:** author and committer are
  `Eren Deniz Kuyucaklıoğlu <109629701+ErenDenizK@users.noreply.github.com>`;
  set `git config user.name` / `user.email` at the start of each session.
- **Process:** [`CONTRIBUTING.md`](CONTRIBUTING.md): Conventional Commits,
  one logical change per commit, every change through a PR, never push to
  `main`.
- **Decisions:** expensive-to-reverse decisions get an ADR in `docs/adr`
  (ADRs are immutable). Tunable numbers live in config and the game design.
- **Quality bar:** world-class; say no to a bad idea.
- **Public repo:** never commit secrets, team IDs, or private data.
- **Art account:** art runs on the founder's uncle's ChatGPT plan with
  permission, recorded truthfully in provenance. Do not re-raise this before
  launch (roadmap Phase 6).

## Review and merge

- The founder reviews screenshots or short videos (send with SendUserFile),
  never web prototypes or artifacts to try. Test in the agent environment
  (Playwright, renders); feel is tuned natively on his iPhone.
- The agent may merge PRs, with merge commits, only on green CI. CI treats
  Swift warnings as errors and must stay green.
- No Swift toolchain here: push, then read the GitHub Actions results
  ([cloud environment](docs/development.md#the-cloud-agent-environment)).

## Where things are

- Docs index: `docs/README.md`. Vision: `docs/product/vision.md`. Roadmap and
  status: `docs/roadmap.md`. Work order: `docs/design/iteration-plan.md`.
- Founder input log (read at session start; add to it whenever he gives
  input): `docs/product/founder-input.md`.
- ADRs `docs/adr/`, research `docs/research/`, brand `docs/brand/`, game
  `docs/product/game-design.md` (keep `economy.md` in sync with `PofuCore`).
- `content/` holds asset and island nodes used by the art pipeline (the Atlas
  board is retired, 2026-11-02).
- Pofu Hub (https://claude.ai/artifact/Qua2VFg3iSJ9V1HJgR8RS9, source
  `design/hub/index.html`) is back as a simple panel for questions, status and
  roadmap (not retired). Open questions carry comparable options and a
  recommendation; the founder ticks one or ignores it, and unanswered
  questions proceed with the recommendation. Update `status/now` and
  `roadmap/main` in its db; no reviews, ideas or dictation.

## Current state (2026-11-02)

- **Pofu** (ADR-0007), repo `ErenDenizK/pofu`. Phase 1: gate v2 (Screen
  Time, `PofuLive`), the game model (`PofuCore/Game`), the island
  (`PofuWorld`) and Rehearsal mode are built; art runs as a queue.
- **Next:** the founder's 7-day dogfood from membership day 1 (expected after
  2026-11-24; `docs/local/membership-day-1.md`). Until then the cloud builds
  code-only work. New work targets the Screen Time product; the free `Pofu`
  target and the Shortcuts path get no new features. Details:
  `docs/roadmap.md#status-2026-11-02`.
- Targets: Instagram, YouTube, TikTok; goal: resist half of reflexive opens.
- Lasting principles: seeds never buy screen time and Pofu never dies
  (ADR-0015, ADR-0017); the visual system is ADR-0018 (balanced diorama,
  native glass plus painted elements). Build setup: `docs/development.md`.

## Agent operations (efficiency, 2026-11-02)

Same output, far less waste. Rules for the lead and its sub-agents:

- **Owners, not crowds.** At most four background agents at once, one per
  stream: world/look, game/minigames, art queue, docs/research. Continue a
  live owner with SendMessage instead of spawning a fresh agent that must
  re-read the repo.
- **Model routing (founder, 2026-11-02).** Always the 5.5 family: Opus 5.5
  plans and judges, Sonnet 5.5 implements, Haiku 5.5 reads, searches and
  summarizes. Set `model` on every Agent call; Opus sub-agents only for
  planning or design judgement.
- **Less CI.** Prove logic locally first (Python sims, a local Swift
  toolchain when available); push to CI once per finished change, not to
  debug.
- **Optimize before the next big round.** No new large round of work
  starts until the workflow review in `docs/development.md` is done.
- **Tight briefs, short reports.** A brief states the goal, decisions made,
  files, and what done means. Reports: at most 200 words plus paths; details
  live in the PR.
- **Pilot, then scale.** Every art batch and every new system starts with a
  2 to 4 item pilot; scale only after review. Never regenerate what the
  harmony system or a grade can fix.
- **Research once.** Findings go to `docs/research/` and are linked, not
  redone. Check there first.
- **CI budget.** Batch pushes; an agent gets at most three red CI rounds
  before it reports back instead of looping.
- **The lead looks at contact sheets and montages** (`tools/review/`), not
  every file, and sends the founder only finished visuals.
- **Clean up.** Remove merged agents' worktrees; keep the disk lean.
