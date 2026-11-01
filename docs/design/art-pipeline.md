# Art Pipeline: From Manifest to Master

_Status: v1, 2026-11-01. Tool: [`tools/imagegen/`](../../tools/imagegen/README.md).
Look and thresholds: [art-direction study](art-direction-study.md).
Rules for images: [art bible](art-bible.md)._

Pofu's art is generated in small, reviewed batches from manifests. Every
image is a job with a fixed prompt composed from shared blocks, fixed
references, and acceptance checks. A person approves every master on a
contact sheet; the repository records who generated it, with what, and
what was done to it afterwards.

## Batch status

| Batch | Manifest | Contents | Status |
|---|---|---|---|
| `batch-01-slice` | [`batch-01-slice.yaml`](../../tools/imagegen/manifest/batch-01-slice.yaml) | Game design §15 D1–D8 (island small and large, terrace, çay ocağı L1–L2, sunflower garden L1, simit cart L1, Mochi) plus çay ocağı L3–L5 and garden L2 | **Not started.** Blocked on the account decision and the founder's 7-day gate dogfood |
| `batch-02-ui` | [`batch-02-ui.yaml`](../../tools/imagegen/manifest/batch-02-ui.yaml) | Glass++ (ADR-0018): 6 domain icons, seed jar ×2 states, calm lantern off/on, a medium widget, an app icon draft (12 jobs) | **Not started.** Same blockers; runs after batch 01's island and çay ocağı L1 are approved |

A blocked manifest cannot generate: `run` refuses until the lead flips
`status: blocked` to `open` in a reviewed PR. `plan`, `prompt` and
`run --dry-run` always work.

## Whose account

**Production art is generated only on the founder's own OpenAI
account.** OpenAI's terms forbid sharing an account or making it
available to anyone else, and a shipped master must name a real,
consenting owner in its provenance. Two candidates, the founder's choice:

| | Founder's ChatGPT plan, through Codex | Founder's API key, through the Images API |
|---|---|---|
| Backend | `codex` | `openai-api` |
| `account.kind` in `config.yaml` | `chatgpt-plan` | `api` |
| Cost | Inside the plan's Codex allowance (image generations use it faster than text) | Pay per image; `run` prints an estimate and needs `--yes` |
| Transparency | Unverified for the Codex image tool; the pipeline can fall back to a chroma key | Supported by `gpt-image-1` (`background: transparent`); verify for newer models |
| Reproducibility | No seed, no model pin | Model pinned in config |
| Key handling | **`OPENAI_API_KEY` must not be set**: the codex backend refuses to run if it is, so a plan run never silently bills an API account | Key from the macOS Keychain (service `pofu-openai-api`) or `POFU_OPENAI_API_KEY` in the founder's local shell; never written, logged or committed; `run` scans the repo and output folders and refuses if the key appears anywhere |

`run` refuses to generate until `account.owner` and `account.kind` are
filled in and match the backend. Every take's sidecar and every master's
`meta.json` and `provenance.md` record the owner and kind.

The images in `design/art/tests/2026-11-01/` are an exploration made
before this rule; they are references, never masters.

## Roles

| Who | Does | Where |
|---|---|---|
| **Lead** (Claude, cloud) | Writes and corrects manifests and prompt blocks, tunes thresholds, reviews art PRs, merges | `tools/imagegen/`, docs |
| **Local operator** (OpenAI Codex CLI on the founder's Mac, in its own clone; or the local Claude session) | Runs `plan`, `run`, `post`, shows the contact sheet to the founder, records his picks, runs `promote`, opens the `art/<batch>` PR | The Mac, with the founder's account |
| **Founder** | Chooses the account, signs in, picks one take per job (or none) in Turkish, approves the PR | Contact sheet, PR |

Codex reads [`AGENTS.md`](../../AGENTS.md) at the repository root: it has
the full brief, the conventions and the stop conditions.

## The loop (one round)

```text
plan ──> run ──> post ──> founder picks ──> promote ──> PR art/<batch> ──> lead review, merge
  ^                                                                               │
  └──────────── the next round: jobs whose parents are now approved ──────────────┘
```

1. `python3 -I tools/imagegen/run.py plan --manifest <m>`: which jobs are
   ready (every parent approved, every reference present).
2. `run --manifest <m> --dry-run`, then `run --manifest <m>` (codex) or
   `run --manifest <m> --backend openai-api` (prints the cost estimate;
   add `--yes`). One generation at a time, 90 s apart, at most 3 takes per
   job and 12 images per run. Stops on the first limit, sign-in, refusal
   or timeout message. Resumable: existing takes with the same prompt and
   references are kept; changed inputs make old takes stale.
3. `post --manifest <m>`: for every take, keying if opaque, canvas fit,
   station registration (chain roots), alignment to the parent (edits),
   the style lock, and QA. Writes `build/review/<batch>.png`, a small copy
   `design/art/review/<batch>-contact.jpg`, and the review file
   `design/art/review/<batch>.yaml`.
4. The founder looks at the contact sheet and says which take he wants
   per job. The operator writes `pick: <n>` (or `none`) and his words in
   `note`.
5. `promote --manifest <m>`: copies the raw take and the locked master to
   `design/art/stations/<name>/`, `design/art/masters/<name>/` or
   `design/art/ui/<kind>-<name>/`, with `meta.json` and `provenance.md`.
   Refuses a take that failed QA (unless `--force` with a note), a take
   with no account owner, and replacing an existing master (later levels
   depend on it) without `--force`.
6. Commit the review file, the small contact sheet and the new masters on
   branch `art/<batch>`; open a PR into `main`.

The `manual` backend writes a copy-paste pack for ChatGPT on the
founder's own plan; `ingest` brings the downloads back in as takes.

## Files and names

| What | Where | In git |
|---|---|---|
| Manifests, blocks, presets, palettes, config | `tools/imagegen/` | yes |
| Raw takes `<kind>__<name>--t<n>.png` and their `.json` sidecars | `design/art/inbox/<batch>/` | no |
| Locked takes, QA reports, run log, manual pack | `build/imagegen/<batch>/` | no |
| Full contact sheet | `build/review/<batch>.png` | no |
| Review file and small contact sheet | `design/art/review/<batch>.yaml`, `<batch>-contact.jpg` | yes |
| Approved stations | `design/art/stations/<name>/{<name>.png, raw.png, meta.json, provenance.md}` | yes |
| Approved world, characters, props | `design/art/masters/<name>/…` | yes |
| Approved UI art (icons, jar, lantern, widgets, app icon) | `design/art/ui/<kind>-<name>/…` | yes |

Kinds: `char`, `station`, `world`, `prop`, `plate`, `sheet`, and for
Glass++ `icon` (domain icons; 1024 transparent, read at 24 and 30 pt),
`ui` (seed jar fill states as edits; the lantern off and on as separate
layers so code drives the glow), `widget` (opaque crops or edits of world
plates; medium is 1536 × 720), `appicon` (1024, opaque, no text). System
actions stay SF Symbols; no image ever paints glass.

Note: `tools/assets/process_assets.py` has its own `icon` kind meaning
the app icon. The two tools do not share inboxes, but rename that kind to
`appicon` before feeding UI art through it.

## QA checks

| Check | Kinds | Fails when |
|---|---|---|
| transparency | sprites | opaque and not keyable, or keying leaked into the object; opaque kinds fail when they have holes |
| canvas | all | warns on aspect mismatch or upscaling |
| chroma ceiling, value floor, detail budget | all | outside the R1-derived envelope ([study §8](art-direction-study.md#8-qa-thresholds-derived-from-r1)) |
| lock load | all but characters | the lock had to move colors by mean ΔE > 18 (warn > 10) |
| palette drift | all | process_assets' nearest-mix ΔE against the kind's palettes |
| guide magenta | station, prop, world | the guide's magenta survived |
| station anchor | station | footprint off the cross, ground line off the ellipse's front half, taller than the bar |
| edit alignment and stability | edits | the edit rescaled more than 25 %, or less than 55 % of the parent survived after alignment |
| depth ratio, lawn chroma | world | earth deeper than 42 % of the width; lawn too saturated |
| icon fill, thin parts, small detail, light and dark glass | icon | the icon would not read at 24 pt on glass |
| app icon opacity, calm corners | appicon | transparency; busy corners |

## First-run checklist

Do this once, with the founder, before the first real batch. Each step
is a few minutes; stop and report at the first surprise.

1. **Account.** The founder decides: his ChatGPT plan (Codex) or his API
   key. Fill in `account.owner` and `account.kind` in
   `tools/imagegen/config.yaml` (commit it).
2. **Folder.** A separate clone for art work, for example
   `~/projects/pofu-art`, so the art operator never touches the local
   Claude session's working tree. `git config user.name/user.email` as
   in AGENTS.md.
3. **Python.** `python3 -m venv .venv && .venv/bin/pip install -r tools/imagegen/requirements.txt`,
   then `.venv/bin/python -I -m pytest tools/imagegen/tests` (all green).
4. **Codex path only:**
   - `codex --version` and `codex login status`: signed in **with
     ChatGPT**, as the founder.
   - `env | grep OPENAI_API_KEY` prints nothing (and nothing in
     `~/.zshrc` sets it).
   - `codex features list | grep image_generation` shows it enabled (if your
     version has no `features` subcommand, the test below is the check).
   - One test generation **outside the repository**:
     `cd /tmp && codex exec --skip-git-repo-check --ephemeral --json -s read-only "Use your built-in image generation tool exactly once to make a small cream circle on a transparent background. Reply with only the saved file path."`
     Confirm: (a) an image appears under `~/.codex/generated_images/<thread id>/`;
     (b) the `thread.started` event carries that id; (c) whether the PNG
     has real transparency (`python3 -c "from PIL import Image; im=Image.open('<path>'); print(im.mode, im.getextrema())"`).
     If there is no transparency, set `backends.codex.background: chroma`.
     If the folder or event differs, adjust only the marked adapter block
     in `tools/imagegen/backends.py` and say so in the PR.
5. **API path only:**
   - Store the key: `security add-generic-password -a "$USER" -s pofu-openai-api -w`
     (it prompts; nothing lands in shell history), or export
     `POFU_OPENAI_API_KEY` in the current shell only.
   - `pip install openai` in the venv.
   - Check `backends.openai-api.model` and `prices_usd` against OpenAI's
     current pricing page; set `prices_checked`.
6. **Dry run.** `run --manifest tools/imagegen/manifest/batch-01-slice.yaml --dry-run`
   (works while blocked): the plan, the exact Codex command, the
   estimate.
7. **Unblock.** Only when the lead has merged a PR that sets the batch to
   `status: open`. Then round 1: `island-main-s` and `mochi`.

## Etiquette and stop conditions

- Small batches: one round at a time, at most 12 images per run, 90 s
  between generations. Never loop `run` in a script.
- Stop and report (do not retry) on: any usage, rate-limit or quota
  message; a sign-in or key problem; a refusal or "no image" answer; a
  timeout; two consecutive takes of one job that fail QA on the same
  check (fix the prompt, not the dice); the key guard; an estimate above
  what the founder agreed.
- Never automate chatgpt.com in a browser. Never set `OPENAI_API_KEY`
  for the Codex path. Never commit a key, a token, `~/.codex/auth.json`
  or anything from `~/.codex`.

## Changing the pipeline

- Prompt wording lives only in `blocks/` and manifests; bump a block's
  version (`prop-style-v3.txt`) rather than editing a block that
  approved masters were made with.
- Style-lock and QA thresholds change only with a before/after contact
  sheet in the PR.
- The Codex command line and image location live only in the marked
  adapter block of `backends.py`.
