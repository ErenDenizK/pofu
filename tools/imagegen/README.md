# Image pipeline (`tools/imagegen`)

Manifest-driven, operator-agnostic generation of Pofu's art: compose the
prompt from shared blocks, generate a few takes on the founder's own
OpenAI account, style-lock and QA every take, review on a contact sheet,
promote the approved take with full provenance.

- Workflow, roles, account rule, first-run checklist:
  [`docs/design/art-pipeline.md`](../../docs/design/art-pipeline.md)
- Why the look and the thresholds:
  [`docs/design/art-direction-study.md`](../../docs/design/art-direction-study.md)
- Brief for the operator (OpenAI Codex): [`AGENTS.md`](../../AGENTS.md)

## Files

| File | What |
|---|---|
| `run.py` | The CLI: `plan`, `prompt`, `run`, `ingest`, `post`, `promote`, `palette-card` |
| `pipeline.py` | Manifest model and validation, prompt composition, paths, fingerprints |
| `backends.py` | `codex` (with the one marked adapter block), `openai-api` (key guard, cost estimate), `manual` |
| `qa.py` | Normalization (keying, canvas fit, station registration, edit alignment) and every QA check |
| `style_lock.py`, `style_lock.json` | The style lock and its presets (`lock-light` is the default; `soft-lock` was until 2026-11-02) |
| `light.py` | The light standard: LIGHT prompt block, subject-region measurements, cell x layer grading (`design/art/light-standard.json`; [rules](../../docs/design/light-standard.md)) |
| `relock.py` | Re-locks an approved master from its kept raw with another preset (no regeneration) |
| `review.py` | Contact sheets, the review file, provenance |
| `palettes.json` | The `world-props` palette (extends `design/tokens/pofu-tokens.json` for drift checks) |
| `config.yaml` | Account, paths, rate limits, backends, reference aliases, palettes per kind |
| `blocks/*.txt` | Prompt blocks pasted verbatim (anchors copied from the art bible; a test keeps them identical) |
| `manifest/*.yaml` | One file per batch |
| `tests/` | Unit and end-to-end tests (a stub Codex stands in for the real one) |

## Guide fit

The image model draws objects too large for their guide, so size is enforced in
post-processing, not only in the prompt (prompts may still state it).
`qa.fit_to_guide` shrinks a root station or ground decor piece uniformly about
its ground anchor to the footprint width and height bar (never up, never below
x0.6: that is a real art failure and QA fails it). It runs before registration
and the lock in `run.py post`, is skipped for edits (they inherit the parent's
frame), is recorded as `meta.json` `fit`, and `relock.py` replays it (no `fit`
= no scaling). A job can set `fit: {max_width: px, top: y}` or `fit: false`.

## Setup and tests

```sh
python3 -m venv .venv
.venv/bin/pip install -r tools/imagegen/requirements.txt
.venv/bin/python -I -m pytest tools/imagegen/tests        # or: -m unittest discover -s tools/imagegen/tests
```

About a minute; no network.

## Manifest format

```yaml
batch: batch-01-slice           # kebab-case; names the inbox, review file and branch art/<batch>
title: ...
status: blocked                 # open | blocked; run refuses to generate unless open
blocked_on: ["..."]             # required when blocked
refs: {alias: path}             # extra reference aliases (config.yaml has the shared ones)
defaults: {variants: 2}
jobs:
  - id: tea-stall-2                   # kebab-case, unique
    kind: station               # char | station | world | prop | plate | sheet | icon | ui | widget | appicon
    name: tea-stall-2                 # output stem: station__tea-stall-2--t<n>.png (default: id)
    size: 1024x1024             # requested size (default per kind)
    canvas: 1024x1024           # normalized canvas (default per kind; widget 1536x720)
    transparent: true           # default: false for plate, widget, appicon
    key: green                  # chroma-key fallback color: green, or blue for green assets
    variants: 2                 # takes to keep per round, 1-4 (config caps at 3 per run)
    edit_of: tea-stall-1              # an edit of that job's approved master (attached first; needs the edit-keep-v1 block)
    chat: "Pofu · Çay ocağı"    # ChatGPT chat name for the manual backend
    attach:                     # alias, repo path, palette:<name>, or approved:<job-id>; role is required
      - {ref: station-guide, role: "The composition guide ..."}
    prompt:                     # text parts and verbatim blocks, in order; the output line is added
      - text: Add two thin wooden poles ...
      - block: edit-keep-v1
    acceptance:                 # optional threshold overrides, e.g. depth_ratio: {warn: 0.3, fail: 0.4};
                                # edit_mode: recolor (whole-object glaze change: shape, light structure and
                                # lightness are checked instead of colors) | region (a large part is repainted:
                                # edit_kept 0.50/0.30 plus a shape check) | keep (default)
    palettes: [world-night]     # optional extra drift palettes for colors the brief names (tokens artPalettes or palettes.json)
```

A job runs only when every job it depends on (`edit_of`,
`approved:<id>` attachments) is approved and every other reference
exists.

To continue a chain another batch started, declare that batch's master
as an **external** job (same `kind` and `name`, no prompt, no `attach`):

```yaml
  - {id: garden-2, kind: station, name: garden-2, external: batch-01-slice}
  - {id: garden-3, kind: station, edit_of: garden-2, prompt: [...]}
```

An external job is never generated, ingested or promoted here; it counts
as approved once its master is on disk (fetched from `main` or the other
batch's branch), and `plan` shows where it comes from. A master outside
the pipeline's folders (R1, the approved Pofu) is named by path:

```yaml
  - {id: pofu, kind: char, name: pofu-r1, external: r1,
     master: design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png}
```

Edits are never moved by the chain root's anchor registration: they are
drawn on the registered master already (batch 03's simit and workshop
chains failed `edit_stability` because they were moved twice). Every edit
also gets `edit_chroma`: its median chroma over the parent's, which
catches the per-level fading that batch 03's chains accumulated.

`check_upload.py` re-downloads pushed art from the remote branch and
decodes it; uploads must stay under 600 KB (AGENTS.md, "Uploads").
