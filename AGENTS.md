# AGENTS.md: Brief for OpenAI Codex (and any other coding agent)

This file is read by OpenAI Codex at the start of every session in this
repository, the way Claude Code reads [`CLAUDE.md`](CLAUDE.md). It is
consistent with `CLAUDE.md` and [`CONTRIBUTING.md`](CONTRIBUTING.md); if
they ever disagree, `CLAUDE.md` wins and you say so in your PR.

## Who and what

- **Product:** Pofu, an iOS app with an illustrated fluffy hamster
  companion that helps people resist reflexive opens of Instagram,
  YouTube and TikTok. The repository is `ErenDenizK/pofu` (renamed from
  `rot`; the old URLs redirect).
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
  `main`. Never merge.** The lead (the cloud Claude session, authorized
  in `CLAUDE.md`) reviews and merges; that is not a conflict with this
  rule.
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

## Current status (2026-11-02): parallel auto mode

**Batch 01 is fully open.** The founder wants art to flow fast and
automatically: many Codex cloud tasks in parallel, **one object per task**,
with the take picked automatically by QA. The founder reviews afterwards
and can veto any pick. Batch 02 stays `status: blocked` until the friends
beta.

**Tracks: one object per task, on its own branch.** A task runs one
object's whole chain from start to end (each level an edit of the
previous, auto-picked), so there are three short starts instead of six
waves. Every job
makes **2 takes** (a third is usually a weaker copy of the second).

| Track | Jobs, in order | Starts |
|---|---|---|
| `island` | `island-main-s` → `island-main-l` → `terrace` | now |
| `mochi` | `mochi` | now |
| `cay` | `cay-1` → `cay-2` → `cay-3` → `cay-4` → `cay-5` | after the `island` track is merged (`island-main-s` is its style reference) |
| `garden` | `garden-1` → `garden-2` | after `cay-1` is merged |
| `simit` | `simit-1` | after `cay-1` is merged |

**Or one task for everything:** "AGENTS.md parallel auto mode,
batch-01-slice, track `all`" runs the tracks one after another in the
order of the table (island, mochi, cay, garden, simit) in a single task,
on branch `art/batch-01-slice/all`, with one PR at the end. It is slower
than parallel tasks but needs no merges in between, because every
reference is already on its own branch.

The founder starts a task with: "AGENTS.md parallel auto mode,
batch-01-slice, track `<name>`". Branch: `art/batch-01-slice/<track>`. PR
title: `art(batch-01): <track>`. Within the task, run steps 2 to 6 for each
job of the track in order.

1. Install the tools: `pip install -r tools/imagegen/requirements.txt`. If
   that fails, stop and ask the founder to add it to the Codex
   environment's setup script (setup runs with internet access).
2. If the job depends on others, restore their approved masters from
   `main`. They are already in the repo; do nothing if they are present.
3. Print the exact prompt and attachments with
   `python3 -I tools/imagegen/run.py prompt --manifest tools/imagegen/manifest/batch-01-slice.yaml --job <id>`,
   and generate the job's 2 takes with **your built-in image generation
   tool**, attaching the listed references. If you have no image tool here,
   stop and say so.
4. Ingest the takes with
   `run.py ingest --manifest <manifest> --job <id> --source codex-cloud <files>`,
   then run `run.py post --manifest <manifest> --only <id>`.
5. **Auto-pick:** choose the take that passes QA with the lowest style-lock
   load (the post report lists both). If no take passes, generate at most
   one more round of the job's variants. If that also fails, stop and report
   the failing checks; do not loop. Set that take as the pick for this job
   only, and run `promote --only <id>`. In the provenance note, write
   "auto-picked by QA; founder review pending".
6. **Commit only this job's files**, so parallel tasks never conflict:
   - the master or station output that `promote` wrote;
   - every take as lossless WebP in `design/art/takes/batch-01-slice/<id>/`;
   - the job's contact sheet as `design/art/takes/batch-01-slice/<id>/contact.jpg`;
   - the job's QA summary as `.../<id>/review.yaml`.

   Do **not** edit the shared `design/art/review/batch-01-slice.yaml`; the
   lead merges the fragments. After the last job of the track, push branch
   `art/batch-01-slice/<track>`, open the PR, and stop.

The founder vetoes in Turkish ("cay-1: take 2", or "redo"). The lead or
a new task applies the veto.

On the Mac, the `codex` backend (`run.py run --backend codex`) does steps
3 and 4 by itself.

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
