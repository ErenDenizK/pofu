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
- Content graph and Pofu Atlas board (every decision, idea and generated
  asset gets a node): `content/`, see `content/README.md`
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
  the iteration plan comes first. Done: honest measurement and setup guide
  v2 (#32), the Screen Time gate as a separate `PofuLive` target with
  three extensions (#34), and gate v2 (#41: the speaking shield, honest
  reach counting, "Açmam lazım", onboarding with a live demo). Next: the
  founder's 7-day dogfood from membership day 1 (`docs/local/membership-day-1.md`). **Build for the
  membership (founder, 2026-11-02):** new work targets the Screen Time
  product; the free `Pofu` target and the Shortcuts path get no new
  features. After membership day 1, collapse `Pofu` and `PofuLive` into one
  app target with the entitlements. During the wait (membership after
  2026-11-24) the cloud builds code-only stage W work: the game model is in
  `PofuCore/Game` (#46, #48), the native island is `PofuWorld` (#49), and
  the free build gets **Rehearsal mode** (an in-app replica of the shield
  and simulated reaches driven by the same code paths), so the founder can
  feel the whole loop on his iPhone before the membership. XcodeGen project (`project.yml`, regenerate after
  pulling); `Packages/PofuKit` has `PofuCore`, `PofuScreenTime`,
  `PofuPersistence`, `PofuDesignSystem`, `PofuCompanion`, and `PofuWorld`
  (the island scene; its art is baked by
  `design/prototypes/interactions/tools/preblur.py app`, and CI uploads
  simulator screenshots as `world-screenshots`). CI must stay
  green. Keep `docs/product/economy.md` in sync with `PofuCore`.
- Design references: `docs/design/` (design language, art bible, prompt
  library, motion spec), `docs/product/ux/` (IA, flows), and the clickable
  prototype in `design/prototypes/ux/`, superseded in part), the app and
  game boundary (`docs/product/app-game-boundary.md`, accepted direction),
  gate v2 (`docs/product/ux/gate-v2.md`), and the interaction spec
  (`docs/design/interaction-spec.md`). Their "proposed changes" sections are
  integrated after the gate week. Decisions: ADR-0010 to ADR-0018.
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
  founder generates art with GPT Image under the art bible, through Codex
  in the cloud. By the founder's decision (2026-11-02) it runs on his
  uncle's ChatGPT plan with permission, recorded truthfully in provenance;
  before launch, get a written assignment or regenerate shipped masters on
  his own plan (roadmap Phase 6). Do not re-raise this before then;
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
- The paid Apple Developer membership is not active yet; expected **after
  2026-11-24**. Family Controls cannot run on device until then; build against
  the simulated Screen Time service (ADR-0003).
- The agent environment is Linux without Xcode and cannot download a Swift
  toolchain (swift.org is blocked). PyPI and Ubuntu apt are reachable
  (`bpy` from PyPI works for Blender). Chromium and Playwright are
  preinstalled for rendering and inspecting prototypes.
- Roles: this cloud session leads. The founder works from his phone and no
  longer runs a local Claude session (2026-11-02); `docs/local-agent.md`
  stays as a reference. Art is generated by **Codex in the cloud** under
  `AGENTS.md`. The Mac is needed only to build `PofuLive` to the iPhone
  from Xcode on membership day 1, until TestFlight is approved.
- **How the founder reviews work (2026-11-02):** everything ships native, so
  do not send him web prototypes or artifacts to try. Test in the agent
  environment (Playwright, renders) and send him screenshots or short videos
  with SendUserFile. Web prototypes remain an internal tool for deciding,
  never the founder's review surface; feel is tuned natively on his iPhone.
- The founder has authorized the agent to merge PRs. Use merge commits for
  clean histories, and merge only with green CI.
