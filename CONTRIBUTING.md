# Contributing

This document defines how work enters the codebase. It applies equally to
human contributors and AI agents working on the project.

## Language

Everything committed to this repository is written in **English**: code,
comments, commit messages, pull requests, issues, and documentation.
User-facing strings are the only exception; they live in String Catalogs and
are authored natively in each supported language (English and Turkish at
launch), never machine-translated from one another.

## Branching model

Trunk-based development with short-lived branches.

- `main` is always releasable. Direct pushes to `main` are not allowed.
- Every change happens on a branch and lands through a pull request.
- Branch names use the form `<type>/<short-kebab-description>`, where `type`
  matches the Conventional Commit type of the main change:

  | Prefix      | Use for                                   |
  |-------------|-------------------------------------------|
  | `feat/`     | New user-facing functionality             |
  | `fix/`      | Bug fixes                                 |
  | `docs/`     | Documentation only                        |
  | `refactor/` | Code changes that neither fix nor add     |
  | `test/`     | Adding or improving tests                 |
  | `chore/`    | Tooling, dependencies, repository hygiene |
  | `ci/`       | Continuous integration                    |
  | `design/`   | Design system, assets, visual work        |

  Two operator branches are also allowed: `local/<topic>` for the local Mac
  agent's reports ([local agent brief](docs/local-agent.md)) and
  `art/<batch>` for image pipeline rounds ([`AGENTS.md`](AGENTS.md)).

## Commit messages

We follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

```
<type>(<optional scope>): <imperative summary, max 72 chars, no period>

<body: what and why, wrapped at 72 columns>

<footer: BREAKING CHANGE, Refs #123, Co-Authored-By trailers>
```

Rules:

- Use the imperative mood: "add shield extension", not "added" or "adds".
- One logical change per commit. A reviewer should be able to read the
  history as a narrative.
- The body explains **why**. The diff already shows what.
- Reference issues in the footer (`Refs #12`, `Closes #12`).
- Scopes map to modules or areas: `app`, `shield`, `monitor`, `report`,
  `widget`, `economy`, `mascot`, `design-system`, `onboarding`, `adr`,
  `research`.

## Pull requests

- Keep pull requests focused and reviewable; prefer several small PRs to one
  large PR.
- Fill in the pull request template completely.
- A PR must pass CI before merge.
- Merge strategy: **create a merge commit** when every commit on the branch
  is a clean, self-contained Conventional Commit. This preserves the
  narrative history and per-commit authorship. **Squash and merge** only
  when the branch contains work-in-progress or fixup noise that should not
  reach `main`.
- Delete the branch after merge.

## Versioning and releases

- [Semantic Versioning](https://semver.org/) for the marketing version
  (`MAJOR.MINOR.PATCH`); the build number increments monotonically.
- Every release is tagged `vMAJOR.MINOR.PATCH` and has a matching
  `CHANGELOG.md` entry following [Keep a Changelog](https://keepachangelog.com/).

## Architecture decisions

Any decision that is expensive to reverse (framework choice, data model,
backend, third-party dependency, monetization mechanics) is recorded as an
Architecture Decision Record in [`docs/adr`](docs/adr/README.md) before or
together with the code that implements it.
