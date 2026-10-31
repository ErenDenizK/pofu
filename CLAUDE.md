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

## Current state

- Product name: **Pofu** (ADR-0007). The repository is still named `rot`.
- Phase 0 (Foundation). Engineering foundation in place: XcodeGen project
  (`project.yml`, regenerate after pulling), the `Packages/PofuKit` package
  (`PofuCore`, `PofuScreenTime`, `PofuDesignSystem`), and CI that must stay
  green. See `docs/development.md` and the economy rules in
  `docs/product/economy.md` (keep code and doc in sync). The app is a
  placeholder.
- Character: Pofu is an **illustrated fluffy hamster** (ADR-0010). The
  founder generates art with GPT Image (ChatGPT Pro) under the art bible;
  the agent owns prompts, the pipeline, motion, and integration. The 3D
  Blender spike is parked as a reference.
- Without a local Swift toolchain, the compile and test loop is: push,
  then read the GitHub Actions results. CI treats Swift warnings as errors.
- Founder's own target apps: Instagram, YouTube, TikTok. Goal: resist half
  of reflexive opens.
- The paid Apple Developer membership is not active yet; the founder is on a
  free account for about two weeks (from 2026-10-31). Family Controls cannot run on device until then; build against
  the simulated Screen Time service (ADR-0003).
- The agent environment is Linux without Xcode and cannot download a Swift
  toolchain (swift.org is blocked). PyPI and Ubuntu apt are reachable
  (`bpy` from PyPI works for Blender). Chromium and Playwright are
  preinstalled for rendering and inspecting prototypes.
- The founder has authorized the agent to merge PRs. Use merge commits for
  clean histories, and merge only with green CI.
