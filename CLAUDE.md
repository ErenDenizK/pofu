# Working Agreement for AI Agents

This file is read by AI coding agents at the start of every session. It is
the project's persistent memory; keep it accurate and concise.

## Roles

- **Founder:** Eren Deniz Kuyucaklıoğlu (GitHub `ErenDenizK`). Sets the vision,
  makes major direction calls, tests on device (MacBook Pro M1 Pro with Xcode,
  iPhone 17). Communicates in Turkish, often by dictation.
- **Agent:** acts as the product, design, and engineering team. Plans before
  building, drives decisions, critiques its own work harshly, and asks the
  founder only about major direction changes. Presents radically different
  options with trade-offs when a direction is ambiguous.

## Non-negotiables

- **Language:** all code, comments, commits, PRs, issues, and docs in English.
  Talk to the founder in Turkish.
- **Commit identity:** author and committer are
  `Eren Deniz Kuyucaklıoğlu <109629701+ErenDenizK@users.noreply.github.com>`.
  Set it with `git config user.name` / `git config user.email` at the start
  of each session.
- **Process:** follow [`CONTRIBUTING.md`](CONTRIBUTING.md): Conventional
  Commits, one logical change per commit, every change through a PR, never
  push to `main` directly.
- **Decisions:** expensive-to-reverse decisions get an ADR in `docs/adr`.
- **Quality bar:** world-class product, design, and engineering. Never settle
  for average to please; say no when something is a bad idea.

## Where things are

- Vision and principles: `docs/product/vision.md`
- Roadmap and open questions: `docs/roadmap.md`
- Research: `docs/research/`
- Brand, character bible, naming: `docs/brand/`
- Decisions: `docs/adr/`
- Local Mac agent brief (Xcode, simulator, device, image generation):
  `docs/local-agent.md`

## Current state

- Product name: **Pofu** (ADR-0007). The repository is `ErenDenizK/pofu`
  (renamed from `rot`; GitHub redirects the old URLs).
- Phase 1 in progress. The soft gate v1 is merged (#14): `CheckInIntent`,
  the Hop! flow, Pofu's room, persistence, and minimal onboarding. **The
  gate comes first** (decision audit, `docs/product/decision-audit.md`):
  the automation has never fired on the founder's phone (he searched
  Shortcuts for the app instead of opening the Automation tab). Stage G of
  the iteration plan comes first: honest measurement, setup guide v2, and
  the Screen Time shield built **before** the membership, so the founder's
  7-day dogfood starts on membership day 1 (the manual automation is an
  optional early try). World and `PofuWorld` work waits; the game model in
  `PofuCore` and an 8-image art test may run meanwhile. XcodeGen project (`project.yml`, regenerate after
  pulling); `Packages/PofuKit` has `PofuCore`, `PofuScreenTime`,
  `PofuPersistence`, `PofuDesignSystem`, and `PofuCompanion`. CI must stay
  green. Keep `docs/product/economy.md` in sync with `PofuCore`.
- Design references: `docs/design/` (design language, art bible, prompt
  library, motion spec), `docs/product/ux/` (IA, flows), and the clickable
  prototype in `design/prototypes/ux/`. Decisions: ADR-0010 to ADR-0012.
- Visual system v1 (ADR-0018, founder-approved): balanced diorama, Glass++
  (native glass frame; painted domain icons at 28 pt or larger with vector
  twins below; seed jar and calm lantern as indicators), one continuous
  camera, cloud pass only for island arrivals. Glass++ production waits
  for the friends beta (ADR-0018 amendment). Work order and checks:
  `docs/design/iteration-plan.md` (stage G, then stage W). Prototypes stay
  rough until W4. Write ADRs only for decisions that cost weeks to undo;
  tunable numbers live in config and the game design.
- Game direction: Pofu's archipelago (`docs/product/game-design.md`,
  prototype in `design/prototypes/island-game/`). Seeds are world material
  and never buy screen time; a breathing break is the hard limit (ADR-0015,
  not yet in `PofuCore`); ADR-0016 archipelago; ADR-0017 Pofu never dies.
- Character: Pofu is an **illustrated fluffy hamster** (ADR-0010). The
  founder generates art with GPT Image under the art bible, **only on the
  founder's own OpenAI account** (sharing the uncle's account conflicts
  with OpenAI's terms and clouds ownership);
  the agent owns prompts, the pipeline, motion, and integration. The 3D
  Blender spike is parked as a reference.
- Without a local Swift toolchain, the compile and test loop is: push,
  then read the GitHub Actions results. The repo is **public** (since 2026-11-01),
  so Actions minutes are free; if it ever goes private again, macOS bills at
  10× (about 30 minutes a run) against 3,000 a month, so batch pushes. CI
  skips the macOS job when only `docs/`, `design/`, `tools/` or Markdown
  change. Public means: never commit secrets, team IDs, or private data. CI treats Swift warnings as errors.
- Founder's own target apps: Instagram, YouTube, TikTok. Goal: resist half
  of reflexive opens.
- The paid Apple Developer membership is not active yet; the founder is on a
  free account for about two weeks (from 2026-10-31). Family Controls cannot run on device until then; build against
  the simulated Screen Time service (ADR-0003).
- The agent environment is Linux without Xcode and cannot download a Swift
  toolchain (swift.org is blocked). PyPI and Ubuntu apt are reachable
  (`bpy` from PyPI works for Blender). Chromium and Playwright are
  preinstalled for rendering and inspecting prototypes.
- Cloud and local roles: this cloud session leads; a local Claude Code
  session on the founder's Mac (`/Users/edk/projects/pofu`) executes
  `docs/local-agent.md` and reports through `local/*` PRs. Remote Control
  from cloud to the Mac folder was attempted on 2026-11-01 and was not
  available.
- The founder has authorized the agent to merge PRs. Use merge commits for
  clean histories, and merge only with green CI.
