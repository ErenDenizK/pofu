# AGENTS.md: Brief for OpenAI Codex (and any other coding agent)

This file is read by OpenAI Codex at the start of every session in this
repository, the way Claude Code reads [`CLAUDE.md`](CLAUDE.md). It is
consistent with `CLAUDE.md` and [`CONTRIBUTING.md`](CONTRIBUTING.md); if
they ever disagree, `CLAUDE.md` wins and you say so in your PR.

## Who and what

- **Product:** Pofu, an iOS app with an illustrated fluffy hamster
  companion that helps people resist reflexive opens of Instagram,
  YouTube and TikTok. The repository is still named `rot`.
- **Founder:** Eren Deniz Kuyucaklıoğlu (GitHub `ErenDenizK`). He sets
  the vision, approves art, and tests on his Mac and iPhone. He speaks
  Turkish, often by dictation.
- **Lead:** a Claude session in the cloud plans the work, writes
  manifests and prompts, reviews and merges PRs.
- **Your job (Codex on the founder's Mac):** operate the image pipeline
  in [`tools/imagegen/`](tools/imagegen/README.md): generate takes,
  run post-processing and QA, show the founder the contact sheet, record
  his picks, promote approved takes, and open a PR. You do not change
  app code, Swift, ADRs, or `CLAUDE.md`.

## Non-negotiables

- **Language:** everything in the repository (code, comments, commits,
  PRs, docs, review notes) is in English. Talk to the founder in
  **Turkish**. Write his decisions into review notes in English, quoting
  him if useful.
- **Commit identity:** set it at the start of every session:

  ```sh
  git config user.name "Eren Deniz Kuyucaklıoğlu"
  git config user.email "109629701+ErenDenizK@users.noreply.github.com"
  ```

  Do not add a `Co-Authored-By` trailer for Codex. End every commit
  message with exactly this trailer line:

  ```text
  Generated-With: OpenAI Codex
  ```

- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/),
  imperative, one logical change per commit, for example
  `design(art): add batch-01 round 1 masters (island, Mochi)`.
- **Branches and PRs:** branch `art/<batch>` (for example
  `art/batch-01-slice`), one PR per round, into `main`. **Never push to
  `main`. Never merge.** The lead reviews and merges.
- **Secrets:** never commit or print an API key, `~/.codex/auth.json`,
  anything from `~/.codex`, `.env` files, or tokens.

## The account rule (read twice)

Production art is generated **only on the founder's own OpenAI
account**: his own ChatGPT plan through Codex, or his own API key through
the `openai-api` backend. OpenAI's terms forbid using someone else's
account, and every master must name its generating account owner.

- `tools/imagegen/config.yaml` → `account.owner` and `account.kind` must
  be filled in before anything is generated. If they are empty, or you
  are not sure the signed-in account is the founder's own, **stop and
  ask him** (in Turkish).
- **Codex path (`account.kind: chatgpt-plan`):** `codex login` with
  "Sign in with ChatGPT" as the founder. **Never set `OPENAI_API_KEY`**
  (it would switch Codex to API billing); the pipeline refuses to run if
  it is set.
- **API path (`account.kind: api`):** the key lives in the macOS Keychain
  (service `pofu-openai-api`) or in `POFU_OPENAI_API_KEY` in the founder's
  local shell only. Never write it to a file, a log, a commit, or a
  message. `run` prints a cost estimate; run with `--yes` only after the
  founder has agreed to that amount.
- **Never automate chatgpt.com in a browser.** If neither path works,
  stop and report.
- Work in **a separate clone** for art (for example
  `~/projects/pofu-art`), not in the folder the local Claude session
  uses (`/Users/edk/projects/pofu`).

## Current status (2026-11-01)

**Production art has not started.** Both batches are
`status: blocked` in their manifests, on (1) the founder's account
decision and (2) his 7-day gate dogfood. `run` refuses to generate for a
blocked batch; `plan`, `prompt` and `run --dry-run` work. Wait until the
lead merges a PR that sets a batch to `status: open`.

When a batch opens, do the [first-run checklist](docs/design/art-pipeline.md#first-run-checklist)
once, with the founder.

## Decisions you must respect

From the founder (2026-11-01) and the lead:

- **Style target:** the founder's island take 1 (the softer, less
  contrasty one, `design/art/tests/2026-11-01/world__island-main-s_take1.png`)
  and R1 (`design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`).
  Props are pulled toward R1, never the other way. Art test 01's images
  are references only, never masters.
- **Art direction:** [art-direction study](docs/design/art-direction-study.md).
  Matte, chunky, high-key props; one light from the upper left; the
  island's low camera (about 20°, ground ellipses 0.3 tall : wide); no
  grain, no outlines; the `soft-lock` style lock; Pofu is never locked.
- **Proportion B:** a balanced diorama, Pofu about 20 % of the screen
  width, the world about 70 % of the height.
- **Glass++ (ADR-0018):** native iOS glass plus illustrated UI art.
  No painted glass, ever: glass is native, painted art sits under or
  inside it. System actions (close, settings, share, back) stay SF
  Symbols; only domain concepts get painted icons. The seed jar and the
  calm lantern are indicators, never controls; the lantern is two layers
  (off, on) so code drives the glow. The map shows a 30 pt vector Pofu
  pin (code, not art). The camera is continuous; the cloud pass happens
  only when a new island arrives (code).
- **Batches:** `batch-01-slice` (game design §15 D1–D8, then çay ocağı
  L3–L5 and garden L2) first; `batch-02-ui` (12 UI images) after batch
  01's island and çay ocağı L1 are approved.

## The workflow, step by step

All commands from the repository root, with the venv:
`.venv/bin/python -I tools/imagegen/run.py <command> --manifest tools/imagegen/manifest/<batch>.yaml`.

1. `git pull` on `main`, then `git switch -c art/<batch>` (or continue
   the open branch for the next round).
2. `plan`: lists jobs and which are ready (parents approved, references
   present). Only ready jobs are generated.
3. `run --dry-run`, then `run` (Codex) or `run --backend openai-api`
   (prints the estimate; `--yes` after the founder agrees). The pipeline
   paces itself (one image at a time, 90 s apart, at most 3 takes per job
   and 12 images per run). Do not change those limits.
4. `post`: style lock and QA for every take; writes the contact sheet
   (`build/review/<batch>.png`), a small copy
   (`design/art/review/<batch>-contact.jpg`) and the review file
   (`design/art/review/<batch>.yaml`).
5. Show the founder the contact sheet (open the PNG). Ask in Turkish
   which take he wants for each job, or none. Write `pick: <n>` (or
   `none`) and his reason in `note`. Never pick for him. Never approve a
   take that failed QA unless he insists; then write why.
6. `promote`: copies picks to `design/art/{stations,masters,ui}/…` with
   provenance. `plan` then shows what the next round can generate.
7. Commit the review file, the small contact sheet and the new master
   folders (nothing from `design/art/inbox/` or `build/`). Push
   `art/<batch>` and open a PR into `main` titled
   `design(art): <batch> round <n>` with: what was generated (counts,
   time), the contact sheet, the picks, QA warnings accepted and why, and
   anything that surprised you. Then stop and wait for the lead.

File names are made by the pipeline: raw takes are
`<kind>__<name>--t<n>.png`; do not rename them. Kinds: `char`, `station`,
`world`, `prop`, `plate`, `sheet`, `icon`, `ui`, `widget`, `appicon`.

## Stop conditions (stop, report, do not retry)

- The batch is `blocked`, or `account.owner` / `account.kind` is empty.
- Any usage-limit, rate-limit, quota, sign-in or key message.
- Codex answers without an image, or refuses.
- A generation times out.
- Two takes in a row of one job fail QA on the same check: the prompt
  needs fixing; tell the lead in the PR, do not "roll again".
- The key guard fires, or the API estimate is above what the founder
  agreed.
- Anything needs `sudo`, a system install, or a change outside
  `tools/imagegen/`, `design/art/` and the PR: ask the founder first.

## Changing things

- Do not edit prompt blocks, manifests, `style_lock.json` or QA
  thresholds on your own. Propose the change in the PR description; the
  lead makes it.
- One exception: if the first-run checklist shows that Codex stores
  images somewhere else or names its events differently, adjust only the
  clearly marked adapter block in `tools/imagegen/backends.py`, run the
  tests (`.venv/bin/python -I -m pytest tools/imagegen/tests`), and
  explain it in the PR.
