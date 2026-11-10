# AGENTS.md: Brief for OpenAI Codex (and any other coding agent)

Codex reads this file at the start of every session, as Claude Code reads
[`CLAUDE.md`](CLAUDE.md). It agrees with `CLAUDE.md` and
[`CONTRIBUTING.md`](CONTRIBUTING.md); if they ever disagree, `CLAUDE.md`
wins and you say so in your PR.

## Who and what

- **Product:** Pofu, an iOS app with an illustrated fluffy hamster
  companion (repository `ErenDenizK/pofu`). **Founder:** Eren Deniz
  Kuyucaklıoğlu (`ErenDenizK`); he speaks Turkish and can veto any art.
  **Lead:** a cloud Claude session writes manifests and prompts, reviews
  and merges PRs.
- **Your job (Codex in the cloud):** run the image pipeline in
  [`tools/imagegen/`](tools/imagegen/README.md): generate takes, post-process
  and QA them, let QA auto-pick, promote the picks, open a PR. You do not
  change app code, Swift, ADRs, `CLAUDE.md`, prompt blocks, manifests,
  `style_lock.json` or QA thresholds (propose changes in the PR; the lead
  makes them). Two exceptions: the `-v2` manifest copies of the standing
  rule, and the marked adapter block in `tools/imagegen/backends.py` if
  Codex stores images or names events differently (run
  `.venv/bin/python -I -m pytest tools/imagegen/tests`, explain in the PR).

## Non-negotiables

- **Language:** everything in the repository is in English; talk to the
  founder in **Turkish**.
- **Commit identity**, set at the start of every session:

  ```sh
  git config user.name "Eren Deniz Kuyucaklıoğlu"
  git config user.email "109629701+ErenDenizK@users.noreply.github.com"
  ```

  No `Co-Authored-By` trailer for Codex. End every commit message with
  exactly `Generated-With: OpenAI Codex`.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/),
  imperative, one logical change per commit, for example
  `design(art): add batch-01 round 1 masters (island, Mochi)`.
- **Branches and PRs:** `art/<batch>/<track>` (or `art/<batch>`), one PR per
  batch into `main`. **Never push to `main`. Never merge**; the lead merges.
- **Secrets:** never commit or print an API key, anything from `~/.codex`,
  `.env` files or tokens.

## The account rule (read twice)

Founder's decision (2026-11-02): art is generated on his uncle's ChatGPT
plan with permission, and provenance says so truthfully. Before launch, a
written assignment or masters regenerated on his own plan.

- Every master names its generating account exactly as `account.owner` in
  `tools/imagegen/config.yaml` says. If `account.owner` or `account.kind`
  is empty, or you are unsure the signed-in account is the right one,
  **stop and ask the founder** (in Turkish).
- **Codex path (`chatgpt-plan`):** "Sign in with ChatGPT". **Never set
  `OPENAI_API_KEY`** (it switches to API billing; the pipeline refuses).
- **API path (`api`):** the key lives only in the macOS Keychain (service
  `pofu-openai-api`) or `POFU_OPENAI_API_KEY` in the founder's shell; never
  in a file, log, commit or message. `run` prints a cost estimate; `--yes`
  only after the founder agrees to that amount.
- **Never automate chatgpt.com in a browser.** If neither path works, stop
  and report.

## The queue: the line never ends

The work comes from one ordered queue,
[`docs/design/art-production-plan.md`](docs/design/art-production-plan.md#the-queue).
Its table, not this file, says what is `READY`. Fetch `origin/main` and
re-read it at the start of every task and before every batch. Work in this
order, forever (founder, 2026-11-05: "it must never stop"):

1. The `READY` rows of the queue, in order.
2. Then the [production backlog](docs/design/art-production-plan.md#the-production-backlog)
   rows whose manifest is on `main`, in order: real ids, promoted on pass.
3. Then the [`BACKLOG`](docs/design/art-production-plan.md#the-backlog)
   rows, in order: explorations (`x-` ids), never promoted.
4. When the backlog is exhausted, start again from its first row with
   **fresh variations**: copy the manifest to `batch-NN-<name>-v2.yaml`
   (then `-v3`, ...; new `batch:` name, same header rules, new exploration
   ids) and give each job a new angle (pose, camera, time of day, season,
   palette, composition). Never run the same prompt twice. This is the one
   manifest edit you may make, only for `x-` explorations, committed in that
   batch's PR.

New `READY` rows always go first. There is no "queue empty" state. When you
open a batch's PR, start the next batch on a new branch at once; never wait
for a review or merge. Never start a `BLOCKED` batch (`status: blocked`).

- **Pilot gate (production only):** a production batch may have a pilot
  manifest (`batch-NN-<name>-pilot`, 2 to 5 jobs), run exactly as written.
  Jobs gated behind it are skipped and the line goes on. A failed pilot
  skips only its dependents (`edit_of`, `approved:`, as `plan` shows), the
  whole batch only if the header names it the style anchor of every job.
- **Explorations** (`EXPLORATION` in the queue and manifest header):
  generate, ingest, post, auto-pick, **never `promote`**. Commit only the
  takes, contact sheet and `review.yaml` under `design/art/takes/<batch>/<id>/`.
- **Salvage first:** a job whose `notes` say SALVAGE FIRST ingests the named
  takes already on `main` (`run.py ingest --source salvage-<batch> <files>`)
  and generates only if none passes.
- **Factory continuity (founder, 2026-11-10):** keep authorized work moving
  autonomously with parallel agents where jobs are independent. Recover missing
  originals from authentic retained takes before regenerating. A retained q90
  review take may serve as a concept master when the founder authorizes recovery;
  record its exact path, hash and encoding, and explicitly distinguish it from
  the unavailable original PNG. Never invent original-source provenance. If no
  usable copy exists, regenerate and submit the replacement for its own review.
  A recoverable source, processing or upload issue must not stop independent
  work. Preserve generated originals promptly; retry uploads within the existing
  limits and retain local work if publication is temporarily unavailable.
- **`promote --force`** is allowed only when a queue row or the manifest
  header's lead rule names the job (and the failing checks); cite that row
  or rule in the review note. Otherwise a failed take is never promoted.

## Running a batch

The founder starts a task with: "AGENTS.md parallel auto mode, `<batch>`,
track `<name>`". The manifest is `tools/imagegen/manifest/<batch>.yaml`; its
header names the tracks. A track runs one object's whole chain (each level
an edit of the approved previous one, so levels stay sequential); "track
`all`" runs every track in one task on `art/<batch>/all` with one PR
(preferred). Parallelise tracks inside the task if you can (sub-agents or
concurrent generations; say which in the PR), otherwise run them in header
order. PR title: `art(batch-NN): <track>`. Every command runs from the repo
root as `python3 -I tools/imagegen/run.py <command> --manifest <manifest>`.

1. `pip install -r tools/imagegen/requirements.txt`. If that fails, stop and
   ask the founder to add it to the Codex environment's setup script.
2. **Dependencies:** get approved parent masters from `main`, or from the
   other track's branch (`git fetch origin art/<batch>/<track>`, then
   `git checkout origin/art/<batch>/<track> -- design/art/<master folder>`,
   the whole folder). Jobs marked `external:` are never generated; fetch
   them the same way. A master stored only as `<name>.webp` is decoded
   first: `python3 -I -c "from PIL import Image; Image.open('<dir>/<name>.webp').save('<dir>/<name>.png')"`.
3. `plan` shows which jobs are ready. Print a job's prompt and attachments
   with `prompt --job <id>` and generate **2 takes** with your built-in image
   tool, attaching the listed references. No image tool: stop and say so.
   Pacing: at most 2 takes per job and 40 images per run; independent jobs
   may generate concurrently. A refusal skips that job (never retried or
   rephrased).
4. `ingest --job <id> --source codex-cloud <files>`, then `post --only <id>`.
5. **Auto-pick:** the take that passes QA with the lowest style-lock load;
   between equals, the higher `harmony` score (match to the approved island,
   or to Pofu for characters; below 70 warns). If none passes, one more
   round of takes; if that fails too, skip the job (Stop conditions). Read
   the job's `notes` for review checks or skip cases. Run
   `promote --only <id>` and write "auto-picked by QA; founder review
   pending" in the provenance note.
6. **Commit only this job's files**, each under 600 KB: the folder `promote`
   wrote (with `raw.webp`), the takes as WebP q90 plus `contact.jpg` and
   `review.yaml` in `design/art/takes/<batch>/<id>/`, the harmony file and
   the content node (below). Never edit the shared
   `design/art/review/<batch>.yaml`; the lead merges the fragments. Push
   after **every** promoted job (dependent tracks start early), run the
   upload check, open the PR after the first push. After the last job, say
   so in the PR and go straight on to the next batch.

File names come from the pipeline (`<kind>__<name>--t<n>.png`); never rename
them. The founder vetoes in Turkish ("tea-stall-1: take 2", or "redo"); the
lead or a new task applies it.

## Uploads: every file under 600 KB

The connector a Codex cloud task pushes through **cuts files at 768 KB,
silently** (batch 01 arrived as broken stubs). So:

- **Every uploaded file is under 600 KB** (614,400 bytes).
- **Takes are lossy WebP q90:**
  `python3 -I -c "from PIL import Image; Image.open('<take>.png').save('<take>.webp', 'WEBP', quality=90, method=6)"`.
- **The raw is never dropped:** `promote` keeps the unlocked take as
  `raw.webp` (lossless if under 600 KB, else lossy q95, q92 or q90). Always
  commit it; the style lock can be redone only from it
  (`tools/imagegen/relock.py`).
- **The master stays lossless:** upload `<name>.png` if under 600 KB, else a
  lossless WebP twin `<name>.webp` instead
  (`Image.open(p).save(q, 'WEBP', lossless=True, method=6)`); the lead
  restores the PNG on merge.
- **Check every push:**

  ```sh
  git fetch origin art/<batch>/<track>
  python3 -I tools/imagegen/check_upload.py --branch art/<batch>/<track> \
      design/art/takes/<batch>/<id> design/art/<stations|masters>/<name>
  ```

  It fails a file of 600 KB or more, one that differs from your copy or
  does not decode, and a master folder without `raw.webp`. Fix and re-push
  before the next job.

## Harmony and content: per master, in the same PR

CI runs `python3 -I tools/assets/harmony.py check`; a new master without its
harmony entry fails CI. For every promoted master:

1. `python3 -I tools/assets/harmony.py measure`, then commit only your
   masters' `design/art/harmony/assets/<id>.json`. If other assets' files
   changed, a shared input moved: do not commit them, tell the lead.
2. `python3 -I tools/content/sync_assets.py` writes or updates the
   `content/assets/asset-<job id>.yaml` node
   ([`content/README.md`](content/README.md)). If the station, character
   or theme that uses the image does not link it yet, add
   `uses_asset: [asset-<job id>]` there. A rejected take you keep stays as
   a node with `status: cut` and why; never delete a node.
3. `harmony.py check` and `python3 -I tools/content/validate.py` pass
   before you push.

## Art decisions you must respect

- **Style target:** the founder's island take 1
  (`design/art/tests/2026-11-01/world__island-main-s_take1.png`) and R1
  (`design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`). Props
  are pulled toward R1. Art test 01 images are references, never masters.
- **Look:** [art-direction study](docs/design/art-direction-study.md):
  matte, chunky, high-key props; one light from the upper left; the low
  island camera (about 20°, ground ellipses 0.3 tall : wide); no grain, no
  outlines; for sprites, the `lock-light` style lock (the app grades
  saturation and contrast at runtime); **Pofu is never locked**. Plates are
  painted at final colour and size (ADR-0023, docs/design/visual-system.md):
  use `plate-style-rich-v1` (`plate-style-v1` only for calmer states), never filter a plate.
- **Light standard:** every new job declares `light: {cell, layer}`; paint
  sprites under the day cell with no cast shadow, never lift the subject's
  blacks, use `style-anchor-v2`
  ([light standard](docs/design/light-standard.md)). Edits that repaint
  declare `acceptance: {edit_mode: recolor | region}`; colours outside the
  kind's palettes add `palettes: [...]` (`tools/imagegen/README.md`).
- **Glass++ (ADR-0018):** glass is native, never painted; painted art sits
  under or inside it. System actions stay SF Symbols; only domain concepts
  get painted icons. The seed jar and calm lantern are indicators (the
  lantern is two layers, off and on). The map pin and the cloud pass are
  code. `batch-02-ui` stays blocked until the friends beta.

## Stop conditions

**A failed job never stops the line.** A job that fails (the same QA check
twice, a timeout, an answer without an image, a manual check) gets one retry
round. If that fails too, record it as `skipped` with the reason in its
`review.yaml` and content node (`status: cut`), skip only its true dependents
(`edit_of`, `approved:`), say so in the PR, and go on with the next job and
batch. There is no consecutive-failure stop. Never loop; never waive a check
to force a pass (only the `promote --force` rule above). Finished picks are
always published.

**Global stop** (stop, report, do not retry) only for:

- Free disk below 1 GB: stop immediately and tell the founder.

- The batch is `blocked`, or `account.owner` / `account.kind` is empty.
- Any account, sign-in, key, quota, usage-limit or rate-limit message.
- Three refusals or image-less answers in a row (one is a skip, not a stop).
- Upload or identity corruption: a pushed file still fails `check_upload.py`
  after one re-push, or the commit identity is wrong.
- The key guard fires, or the API estimate exceeds what the founder agreed.
- Anything needs `sudo`, a system install, or a change outside
  `tools/imagegen/`, `design/art/`, `content/` and the PR: ask the founder.
