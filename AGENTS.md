# AGENTS.md: Brief for OpenAI Codex (and any other coding agent)

This file is read by OpenAI Codex at the start of every session in this
repository, the way Claude Code reads [`CLAUDE.md`](CLAUDE.md). It is
consistent with `CLAUDE.md` and [`CONTRIBUTING.md`](CONTRIBUTING.md); if
they ever disagree, `CLAUDE.md` wins and you say so in your PR.

## Who and what

- **Product:** Pofu, an iOS app with an illustrated fluffy hamster
  companion (repository `ErenDenizK/pofu`). **Founder:** Eren Deniz
  Kuyucaklıoğlu (`ErenDenizK`); he approves art and speaks Turkish.
  **Lead:** a Claude session in the cloud writes manifests and prompts,
  reviews and merges PRs.
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

## Current status (2026-11-02): the production queue

**Batches 01, 03 and 04 are merged.** The work now comes from one ordered
queue: [`docs/design/art-production-plan.md`](docs/design/art-production-plan.md).
The founder wants the line never to idle and art picked automatically by
QA; he reviews afterwards and can veto any pick. Batch 02 stays
`status: blocked` until the friends beta.

**The standing rule:** when you open a batch's PR, immediately start the
next `READY` batch in the queue, in order, on a new branch. Never wait for
a review or a merge. Never start a `BLOCKED` batch (`status: blocked` in
its manifest). When a batch is finished (its PR is open), continue to the
next `READY` batch automatically, again and again, until none is left; do
not stop to ask. If no row is `READY`, say so in your last PR and stop.

**Pilots first:** every new batch has a small pilot manifest
(`batch-NN-<name>-pilot`, 2 to 5 jobs) that the lead reviews before the
rest of the batch (`batch-NN-<name>`) opens. Run pilots exactly as
written: they test the method before it scales.

**Explorations** (`EXPLORATION` in the queue and in the manifest header):
generate, ingest, post and auto-pick as usual, but **never run
`promote`**. Commit the takes (WebP q90), the contact sheet and
`review.yaml` under `design/art/takes/<batch>/<id>/`, and nothing else.

**Salvage before you generate:** a job whose `notes` say SALVAGE FIRST
ingests the named takes already on `main`
(`run.py ingest --source salvage-<batch> <files>`), posts and picks them;
it generates only if none passes.

**Tracks:** a task runs one object's whole chain (each level an edit of
the previous, auto-picked); every job makes **2 takes** (a third is
usually a weaker copy of the second). Each manifest's header names its
tracks. "Track `all`" runs every track of the batch in one task, on
`art/<batch>/all`, with one PR (preferred by the founder).

- **Parallelise inside the task if you can** (sub-agents or concurrent
  generations), and say in the PR which mechanism you used. Otherwise run
  the tracks in the header's order.
- **Either way,** a chain's levels stay sequential: each level is an edit of
  the approved previous level.

The founder starts a task with: "AGENTS.md parallel auto mode,
`<batch>`, track `<name>`" (for example "AGENTS.md parallel auto mode,
batch-03-home-island, track pond"). Branch: `art/<batch>/<track>`. PR
title: `art(batch-NN): <track>`. Within the task, run steps 2 to 6 for each
job of the track in order. The manifest is
`tools/imagegen/manifest/<batch>.yaml`. The order of batches is the
[queue](docs/design/art-production-plan.md#the-queue).

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
   load (the post report lists both); between takes that are otherwise
   equal, prefer the higher **harmony** score (the QA line `harmony`:
   how closely the take matches the approved island, or Pofu for
   characters, measured by `tools/assets/harmony.py`; below 70 it warns).
   If no take passes, generate at most
   one more round of the job's variants. If that also fails, skip the job and its
   dependents and go on (see Stop conditions); do not loop. Set that take as the pick for this job
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

The founder vetoes in Turkish ("tea-stall-1: take 2", or "redo"). The lead or
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
- **The raw is never dropped.** `promote` keeps the unlocked take as
  `raw.webp` in the master folder: lossless WebP when that is under
  600 KB, otherwise lossy WebP q95 (q92 or q90 only if q95 does not fit).
  Always commit it. The style lock is a choice that can be redone only
  from the raw (`tools/imagegen/relock.py`); a master folder without a
  raw fails `check_upload.py`.
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
  does not decode, and a master folder (one with a `meta.json`) that keeps
  no `raw.webp`. Fix and re-push before you start the next job. (Batch
  01 masters already on `main` decode and may stay as they are.)

## Harmony manifest: commit your master's own file

CI runs `python3 -I tools/assets/harmony.py check`, and a new master needs
its harmony entry, so an art PR without it fails CI (batches 05 to 07 did).
The manifest is one small file per asset, `design/art/harmony/assets/<id>.json`,
so parallel art PRs never touch the same file. The push checklist for every
promoted master:

1. `python3 -I tools/assets/harmony.py measure`
2. Commit only the new or changed `design/art/harmony/assets/<id>.json` of
   your masters in the same PR as the master (and its `raw.webp`, content
   node and provenance). If other assets' files changed too, a shared input
   moved (config, reference); do not commit those, tell the lead.
3. `python3 -I tools/assets/harmony.py check` must pass before you push.

## Next batches: the queue

The ordered list of batches, their state (`READY`, `BLOCKED`, `NEXT PR`)
and why each exists is in
[`docs/design/art-production-plan.md`](docs/design/art-production-plan.md#the-queue).
The lead keeps it current; read it at the start of every task. Right now
these batches are `READY` and may run at once (the table has the order):

```text
AGENTS.md parallel auto mode, batch-05-fixes, track all
AGENTS.md parallel auto mode, batch-06-pofu-rig, track all
AGENTS.md parallel auto mode, batch-07-light, track all
AGENTS.md parallel auto mode, batch-11-ui-pilot, track all
AGENTS.md parallel auto mode, batch-08-decor-pilot, track all
AGENTS.md parallel auto mode, batch-09-explore-pilot, track all
AGENTS.md parallel auto mode, batch-10-island-concepts-pilot, track all
AGENTS.md parallel auto mode, batch-12-minigame-art, track all
AGENTS.md parallel auto mode, batch-13-ui-rest, track all
AGENTS.md parallel auto mode, batch-14-harbor, track all
AGENTS.md parallel auto mode, batch-15-explore, track all
AGENTS.md parallel auto mode, retry-2026-11-03, track all
```

Batches 09, 10 and 15 are EXPLORATION: never run `promote` on them. Batches
12 to 15 carry their pilot as their first jobs. A failed pilot skips only the
jobs that depend on it (`edit_of`, `approved:`), exactly as `plan` shows;
never skip a whole batch for a pilot, unless the batch's header names that
pilot as the style anchor every other job attaches. The 32 jobs skipped in
batches 11 to 14 are rerun as `retry-2026-11-03`.
Edits that repaint the object declare it (`acceptance: {edit_mode: recolor |
region}`), and a brief that names colors outside the kind's palettes adds
`palettes: [...]` (`tools/imagegen/README.md`).

- **batch-05-fixes-pilot:** `bagel-cart-2` and `workshop-2` are SALVAGED from
  batch 03's takes on `main` (their `notes` list the files). Batch 03's
  failures there were a pipeline bug (edits were moved twice), now fixed.
- **batch-06-pofu-rig-pilot:** edits of R1, which lives at
  `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png` (the
  manifest's `pofu` job names it with `master:`). Pofu is never locked.
- **batch-07-light-pilot:** lit edits of `tea-stall-1` and `tea-stall-5` that change
  only the burner. Do not add glow; the app does.

Masters on `main` stored only as `<name>.webp` (for example `mochi-v2`,
`island-main-l-v2`, `workshop-1`) are decoded to `<name>.png` first, as in
step 2.

## Content graph: one asset node per promoted master

Content planning lives in `content/` ([`content/README.md`](content/README.md)). For **each master you
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
  grain, no outlines; the `lock-light` style lock (since 2026-11-02: saturation
  and contrast are graded at runtime by the app, so the files stay near
  neutral; `soft-lock` remains for comparison); Pofu is never locked.
- **Light standard (new manifests):** every job declares `light: {cell, layer}`; paint sprites under the day cell with no cast shadow, never lift the blacks of the subject plane, and use `style-anchor-v2`; see [light standard](docs/design/light-standard.md).
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
- **UI batch:** `batch-02-ui` (12 UI images) stays blocked until the
  friends beta. The UI direction is a hybrid of native Liquid Glass and
  custom painted elements, specified separately; UI boards stay
  explorations.

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

## Stop conditions

**A failed job does not stop the line** (lead, 2026-11-02: one failed decor
bench froze 14 finished rig picks and every later batch). Two levels:

**Skip and continue.** A job that fails (QA failure on the same check twice,
a timeout, a Codex answer without an image, a manual check such as the decor
guide fit) gets its one allowed retry round (a fresh pair of takes). If that
also fails, record the job as `skipped` with its reason in its `review.yaml`
and its content node (`status: cut`, never delete), skip every job that depends
on it (`edit_of`, `approved:`), say so in the PR, and **go on with the next
job and the next batch**. Only true dependents are skipped; unrelated jobs and batches go on, however many jobs have failed in a row (there is no consecutive-failure stop). Never loop, never waive a check to force a pass.
Finished picks are always published; a skipped job never holds them back.

**Global stop** (stop, report, do not retry) only for:

- The batch is `blocked`, or `account.owner` / `account.kind` is empty.
- Any account, sign-in, key, quota, usage-limit or rate-limit message.
- Codex refuses, or answers without an image three times in a row.
- Identity or upload corruption (a pushed file fails `check_upload.py`
  after one re-push, or the commit identity is wrong).
- The key guard fires, or the API estimate is above what the founder agreed.
- Anything needs `sudo`, a system install, or a change outside
  `tools/imagegen/`, `design/art/` and the PR: ask the founder first.

**Before every batch:** run `git fetch origin main` and re-read
[the queue](docs/design/art-production-plan.md#the-queue); new `READY` rows
may have appeared. **When the queue is empty,** re-check it every 20 minutes
for 2 hours before ending the session.

## Changing things

- Do not edit prompt blocks, manifests, `style_lock.json` or QA
  thresholds on your own. Propose the change in the PR description; the
  lead makes it.
- One exception: if the first-run checklist shows that Codex stores
  images somewhere else or names its events differently, adjust only the
  clearly marked adapter block in `tools/imagegen/backends.py`, run the
  tests (`.venv/bin/python -I -m pytest tools/imagegen/tests`), and
  explain it in the PR.
