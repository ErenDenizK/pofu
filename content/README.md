# content/: planned and shipped content nodes

Every piece of planned or shipped content lives here as one YAML file per
node: islands, stations (with their five levels), characters and Pofu's
emotions, systems, storyboard moments, themes and seasons, ideas, and every
image asset (each generated master and each manifest job not yet
generated). The Atlas board that once rendered it is retired (2026-11-02); the nodes
stay as the art pipeline's asset records (`sync_assets.py`, `validate.py`).

**The rule: every new decision, idea, or generated asset gets a node.** If
it is not in `content/`, it is not on the board, and the board is where
planning happens. Documents still hold the reasoning; a node links to them
through `sources`.

## Layout

| Folder | `type` | Id prefix | Notes |
|---|---|---|---|
| `islands/` | `island` | `island-` | `residents`, `stages`, `unlock.day`, `theme_en`, `ritual_en` |
| `stations/` | `station` | `station-` | `levels` (exactly 5: titles, cost, rate, `asset`), `resident`, `unlock.day` |
| `characters/` | `character` | `char-` | `kind: resident` or `kind: emotion` (`variant_of: char-pofu`) |
| `systems/` | `system` | `sys-` | `group`, `board: {col, row}` (position in the systems map) |
| `moments/` | `moment` | `moment-` | `act` (storyboard row) and `sequence` (left to right) |
| `themes/` | `theme` | `theme-` | `kind`: season, event, plus, grade, world |
| `ideas/` | `idea` | `idea-` | the Ideas board lanes are `horizon`; `kind`: feature, milestone, question, route… |
| `assets/` | `asset` | `asset-` | `art.jobs` (`<batch>:<job id>`) and/or `art.images` |

`schema.json` is the JSON Schema for every node. Common fields:

```yaml
id: station-cay                 # = file name, unique, lowercase, hyphens
type: station
title_tr: Çay ocağı             # shown on the board
title_en: Tea stall
status: in-app                  # idea | planned | in-production | in-app | cut
horizon: now                    # now | next | later | maybe
summary: >-
  One paragraph, in English.
notes:                          # facts, numbers, decisions, risks; one line each
- Level costs 1→5: 40 · 88 · 194 · 426 · 937.
links:                          # typed edges, outgoing only (inverses are computed)
  part_of: [island-aycicegi]
  related: [char-mochi]
art:
  images: [design/art/stations/cay-1/cay-1.png]   # or {path, branch} while on an art branch
  jobs: [batch-01-slice:cay-1]
sources:
- doc: docs/product/game-design.md
  anchor: '#idle-production-and-stations'        # a real GitHub heading anchor
```

Edge types: `unlocks`, `requires`, `part_of`, `variant_of`, `uses_asset`,
`inspired_by`, `feeds`, `drains`, `leads_to`, `supersedes`, `related`. The
systems map draws `feeds`, `drains`, `leads_to` and `requires` between
systems. An asset counts as **used** when something links to it with
`uses_asset` or `inspired_by` (or a station level names it, or another asset
is an edit of it); a generated asset nobody uses gets the red "kullanılmıyor"
flag.

Nodes no document defines yet carry `source: lead-brainstorm` (or
`founder`, `codex`) and, for brainstorms, `horizon: maybe` until the founder
picks them up.

## Who updates what

- **The lead (cloud Claude):** every decision, doc change, idea and cut
  becomes a node edit in the same PR as the doc. Status and horizon move as
  work moves (a merged feature goes to `in-app`; a postponed one changes
  `horizon`). New manifest jobs get asset nodes (`sync_assets.py`).
- **Codex (art):** for each promoted master, add or update the asset node:
  run `python3 -I tools/content/sync_assets.py` after `run.py promote`; it
  writes stub nodes for new jobs and adds the promoted image to `art.images`.
  Then link it where it is used (`uses_asset` from the station, character or
  theme) if that link is not there yet. See `AGENTS.md`.
- **Future agents:** same rule. Never delete a node to hide a mistake; set
  `status: cut` and say why in `notes`, so no generation and no idea is lost.

## Commands

```sh
python3 -I tools/content/validate.py        # ids, links, art paths, jobs, anchors (CI runs it)
python3 -I tools/content/sync_assets.py     # asset nodes in step with manifests and promoted art
```

`pip install -r tools/content/requirements.txt` installs PyYAML, jsonschema,
Pillow and pytest.

