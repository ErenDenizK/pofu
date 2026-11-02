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

_Founder's decision (2026-11-02): art is generated on his uncle's ChatGPT plan with permission, and provenance says so truthfully. Before launch: a written assignment or shipped masters regenerated on his own plan (roadmap Phase 6)._

Every master must name its generating account truthfully: use exactly
what `account.owner` in `tools/imagegen/config.yaml` says.

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

**Batches 01, 03 and 04 are open** ([Next batches](#next-batches-2026-11-02-finish-01-then-03-and-04)). The founder wants art to flow fast and
automatically: many Codex cloud tasks in parallel, **one object per task**,
with the take picked automatically by QA. The founder reviews afterwards
and can veto any pick. Batch 02 stays `status: blocked` until the friends
beta.

**Tracks: one object per task, on its own branch.** A task runs one
object's whole chain from start to end (each level an edit of the
previous, auto-picked), so there are three short starts instead of six
waves. Every job
makes **2 takes** (a third is usually a weaker copy of the second).

Batch 01's tracks (batches 03 and 04 are under
[Next batches](#next-batches-2026-11-02-finish-01-then-03-and-04)):

| Track | Jobs, in order | Starts |
|---|---|---|
| `island` | `island-main-s` → `island-main-l` → `terrace` | now |
| `mochi` | `mochi` | now |
| `cay` | `cay-1` → `cay-2` → `cay-3` → `cay-4` → `cay-5` | when the `island` task has pushed `island-main-s` (its style reference) |
| `garden` | `garden-1` → `garden-2` | when the `cay` task has pushed `cay-1` |
| `simit` | `simit-1` | when the `cay` task has pushed `cay-1` |

**Or one task for everything (preferred by the founder):** "AGENTS.md
parallel auto mode, batch-01-slice, track `all`" runs every track in a
single task, on branch `art/batch-01-slice/all`, with one PR.

- **Parallelise inside the task if you can.** If your environment lets you
  spawn sub-agents or run several image generations concurrently, run
  independent work at the same time: `island`, `mochi` and, once
  `island-main-s` exists, `cay`; then `garden` and `simit` once `cay-1`
  exists. Say in the PR which mechanism you used.
- **If you cannot,** run the tracks one after another in the table's
  order.
- **Either way,** a chain's levels stay sequential: each level is an edit of
  the approved previous level. Wall time is at least the longest chain,
  the five `cay` levels.

The founder starts a task with: "AGENTS.md parallel auto mode,
`<batch>`, track `<name>`" (for example "AGENTS.md parallel auto mode,
batch-03-home-island, track pond"). Branch: `art/<batch>/<track>`. PR
title: `art(batch-NN): <track>`. Within the task, run steps 2 to 6 for each
job of the track in order. The manifest is
`tools/imagegen/manifest/<batch>.yaml`. Open batches and their tracks are in
[Next batches](#next-batches-2026-11-02-finish-01-then-03-and-04).

1. Install the tools: `pip install -r tools/imagegen/requirements.txt`. If
   that fails, stop and ask the founder to add it to the Codex
   environment's setup script (setup runs with internet access).
2. If the job depends on others, get their approved masters from `main`,
   or, if they are not merged yet, from the other track's branch:
   `git fetch origin art/<batch>/<track>` and
   `git checkout origin/art/<batch>/<track> -- design/art/<master folder>`
   (the whole folder: later edits read its `meta.json`). Jobs marked
   `external: batch-01-slice` in a manifest are batch 01's masters: `plan`
   shows them as "external"; never generate them, fetch them the same way
   from `main` or `art/batch-01-slice/all`. If a master folder holds
   `<name>.webp` but no `<name>.png` (see [Uploads](#uploads-every-file-under-600-kb)),
   decode it:
   `python3 -I -c "from PIL import Image; Image.open('<dir>/<name>.webp').save('<dir>/<name>.png')"`.
   Do not wait for the lead to merge. Track tasks push after **each**
   promoted job, not only at the end, so dependent tasks can start early.
3. Print the exact prompt and attachments with
   `python3 -I tools/imagegen/run.py prompt --manifest <manifest> --job <id>`,
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
   "auto-picked by QA; founder review pending". Read the job's `notes` in
   the manifest: some name a review check or a case where you must stop.
6. **Commit only this job's files**, so parallel tasks never conflict, and
   every file under 600 KB ([Uploads](#uploads-every-file-under-600-kb)):
   - the master or station folder that `promote` wrote;
   - every take as **lossy WebP, quality 90**, in `design/art/takes/<batch>/<id>/`;
   - the job's contact sheet as `design/art/takes/<batch>/<id>/contact.jpg`;
   - the job's QA summary as `.../<id>/review.yaml`.

   Do **not** edit the shared `design/art/review/<batch>.yaml`; the lead
   merges the fragments. Push branch `art/<batch>/<track>` after every
   promoted job, run the upload check, and after the first push open the
   PR. After the last job, say so in the PR and stop.

The founder vetoes in Turkish ("cay-1: take 2", or "redo"). The lead or
a new task applies the veto.

On the Mac, the `codex` backend (`run.py run --backend codex`) does steps
3 and 4 by itself.

## Uploads: every file under 600 KB

The GitHub connector a Codex cloud task pushes through **cuts every file
off at 768 KB, silently**. Batch 01's takes and `raw.png` files on
`art/batch-01-slice/all` arrived as 786,443-byte stubs that do not open.
So, for every task and every push:

- **Every uploaded file is under 600 KB** (614,400 bytes).
- **Takes are lossy WebP at quality 90:**
  `python3 -I -c "from PIL import Image; Image.open('<take>.png').save('<take>.webp', 'WEBP', quality=90, method=6)"`.
  A 1536 × 1024 take is about 70 to 90 KB.
- **`raw.png` is uploaded only if it is under 600 KB.** Otherwise leave it
  out of the commit and write "raw.png not uploaded (over 600 KB); the q90
  takes are the record" in the job's `review.yaml`.
- **The master stays lossless.** If `<name>.png` is under 600 KB, upload
  it. If not, upload a lossless WebP twin `<name>.webp` in the same folder
  instead of the PNG
  (`Image.open(p).save(q, 'WEBP', lossless=True, method=6)`; masters land
  at 430 to 500 KB). It decodes back to identical pixels; dependent tasks
  decode it (step 2) and the lead restores the PNG on merge.
- **Check every upload:** after each push, re-download every file you
  pushed and decode it:

  ```sh
  git fetch origin art/<batch>/<track>
  python3 -I tools/imagegen/check_upload.py --branch art/<batch>/<track> \
      design/art/takes/<batch>/<id> design/art/<stations|masters>/<name>
  ```

  It fails a file that is 600 KB or more, differs from your local copy, or
  does not decode. Fix and re-push before you start the next job. (Batch
  01 masters already on `main` decode and may stay as they are.)

## Next batches (2026-11-02): finish 01, then 03 and 04

Three open manifests, so Codex never sits idle. Every job makes 2 takes
and is auto-picked by QA (steps above); the founder reviews afterwards.

### Batch 01: finish it (`art/batch-01-slice/all`)

- Remaining jobs: `cay-2` → `cay-5`, `garden-1` → `garden-2`, `simit-1`.
  Batch 03's `garden` and `simit` tracks wait for `garden-2` and
  `simit-1`, so push them as soon as they are promoted.
- **Do not promote `terrace`.** It was drawn against the old large island;
  batch 03's `terrace-v2` replaces it. `island-main-l` and `mochi-base`
  stay where they are; batch 03's `island-main-l-v2` and `mochi-v2`
  replace them in the app (founder: the large island must be clearly
  larger; Mochi has no curl on her head, it is Pofu's alone).
- **Repair the truncated uploads** on that branch: every `*.webp` take and
  every `raw.png` there is cut off. Re-upload the takes as lossy WebP q90
  from the original files, re-upload a `raw.png` only if it is under
  600 KB and delete the others, then run `check_upload.py` on each job's
  folders. If the originals are gone (a new container), delete the broken
  files and say so in the PR.

### Batch 03: Ayçiçeği, stages 1–5 (`batch-03-home-island`)

One object per track. "Needs" is what must be on `main` or a pushed
branch first.

| Track | Jobs, in order | Needs | Starts |
|---|---|---|---|
| `mochi` | `mochi-v2` → `mochi-work` | `mochi-base` (main) | **now** |
| `plates` | `island-main-l-v2` → `terrace-v2` → `islet-east` → `bridge-east` | `island-main-s` (main) | **now** |
| `pond` | `pond-1` → `pond-2` → `pond-3` → `pond-4` → `pond-5` | `cay-1`, `island-main-s` (main) | **now** |
| `workshop` | `workshop-1` → … → `workshop-5` | `cay-1`, `island-main-s` (main) | **now** |
| `windmill` | `windmill-1` → … → `windmill-5` | `cay-1`, `island-main-s` (main) | **now** |
| `findik` | `findik` → `findik-work` | `mochi-v2` (scale and finish) | when `mochi` has pushed `mochi-v2` |
| `garden` | `garden-3` → `garden-4` → `garden-5` | batch 01's `garden-2` | when batch 01 has pushed `garden-2` |
| `simit` | `simit-2` → `simit-3` → `simit-4` → `simit-5` | batch 01's `simit-1` | when batch 01 has pushed `simit-1` |

30 jobs, 60 takes. The longest chains are the five-level stations.

### Batch 04: the living sky (`batch-04-sky`)

| Track | Jobs, in order | Needs | Starts |
|---|---|---|---|
| `clouds` | `cloud-1` → (`cloud-2`, `cloud-3`, `cloud-4`, `cloud-5`) → `cloud-sea` | `island-main-s` (main) | **now** |
| `isles` | `far-isle-1` → (`far-isle-2`, `far-isle-3`) | `island-main-s` (main) | **now** |
| `sun` | `sun-glow` | `island-main-s` (main) | **now** |

10 jobs, 20 takes. Jobs in parentheses need only the first job of their
track and may run at the same time; `cloud-sea` also needs `cloud-4`. If
`sun-glow` comes back opaque, do not key it: stop that job and say so
(its `notes`).

**Can start immediately:** batch 03's `mochi`, `plates`, `pond`,
`workshop` and `windmill`, and all of batch 04 (`clouds`, `isles`, `sun`),
alongside batch 01's remaining jobs.

### Task lines (paste one per Codex task)

```text
AGENTS.md parallel auto mode, batch-01-slice, track all
AGENTS.md parallel auto mode, batch-03-home-island, track all
AGENTS.md parallel auto mode, batch-04-sky, track all
```

`track all` runs every track of the batch in one task, on
`art/<batch>/all`, with one PR, in parallel inside the task where it can
(as for batch 01) and otherwise in the table's order. To split a batch
across tasks instead, one line per track:

```text
AGENTS.md parallel auto mode, batch-03-home-island, track mochi
AGENTS.md parallel auto mode, batch-03-home-island, track plates
AGENTS.md parallel auto mode, batch-03-home-island, track pond
AGENTS.md parallel auto mode, batch-03-home-island, track workshop
AGENTS.md parallel auto mode, batch-03-home-island, track windmill
AGENTS.md parallel auto mode, batch-03-home-island, track findik
AGENTS.md parallel auto mode, batch-03-home-island, track garden
AGENTS.md parallel auto mode, batch-03-home-island, track simit
AGENTS.md parallel auto mode, batch-04-sky, track clouds
AGENTS.md parallel auto mode, batch-04-sky, track isles
AGENTS.md parallel auto mode, batch-04-sky, track sun
```

A track whose "Needs" is not pushed yet waits: fetch again every few
minutes, and if it has not appeared after 30 minutes, stop and say so in
the PR.

## Pofu Atlas: one asset node per promoted master

Content planning lives in `content/` and renders into Pofu Atlas
([`content/README.md`](content/README.md)). For **each master you
promote**, add an `asset` node or update its `art:`:

1. After `run.py promote`, run `python3 -I tools/content/sync_assets.py`.
   It writes a stub `content/assets/asset-<job id>.yaml` for a new job and
   adds the promoted image to `art.images` of an existing node.
2. If the station, character or theme that uses the image does not link to
   it yet, add `uses_asset: [asset-<job id>]` there (station levels already
   name their asset).
3. A take you reject but keep stays as a node with `status: cut` and a note
   saying why; never delete a node.
4. Run `python3 -I tools/content/validate.py` and commit the content change
   in the same PR as the art.

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
  L3–L5 and garden L2) first; then `batch-03-home-island` (the rest of
  the home island, stages 1–5) and `batch-04-sky` (the living sky) in
  parallel; `batch-02-ui` (12 UI images) stays blocked until the friends
  beta.

## The workflow, step by step

All commands from the repository root, with the venv:
`.venv/bin/python -I tools/imagegen/run.py <command> --manifest tools/imagegen/manifest/<batch>.yaml`.

1. `git pull` on `main`, then `git switch -c art/<batch>` (or continue
   the open branch for the next round).
2. `plan`: lists jobs and which are ready (parents approved, references
   present). Only ready jobs are generated.
3. `run --dry-run`, then `run` (Codex) or `run --backend openai-api`
   (prints the estimate; `--yes` after the founder agrees). Pacing (founder,
   2026-11-02): no pause, at most 2 takes per job and 40 images per run,
   and **concurrent generation is allowed**: independent jobs may run at the
   same time in separate agents or sub-agents. Stop on the first usage,
   rate-limit, sign-in or refusal message; never retry in a loop.
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
