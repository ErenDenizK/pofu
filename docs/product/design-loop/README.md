# The design loop

_Status: process, 2026-11-03. How Pofu's islands, clusters and big story
get better on a fixed rhythm instead of by accident. First run:
[loop 1](loop-1.md). Data: [`content/islands/profiles.yaml`](../../../content/islands/profiles.yaml);
checks: [`tools/content/island_metrics.py`](../../../tools/content/island_metrics.py)._

The founder's rule behind it: nothing is accepted as it is; think again
and again per island (design, features, story), and every island must
serve the whole story. His notes are guidance, weighed against the
system's rules, never pasted in as rules; the loop owns every detail at
the bar of the world's best world builders.

## 1. Cadence

- **One loop per round of founder feedback**, at most one a week while
  islands are in design; a loop is never started without new input
  (founder scores, a concept round's takes, playtest data or a new
  constraint).
- **Three passes inside a loop** (section 4), metrics re-run after each.
- A loop ends with **one PR** (docs, profiles, tool changes), merged on
  green CI, and **one concept round spec** for Codex.

## 2. Roles

| Who | Model / person | Does | Never |
|---|---|---|---|
| **Creative director** | One **Opus** agent per loop | Reads the inputs, runs the three zooms, decides, writes `loop-N.md`, edits the profiles, writes the concept round | Writes final dialogue lines; regenerates art |
| **Metrics and upkeep** | **Sonnet** | Runs `island_metrics.py`, extends the tool and its tests when a new rule is agreed, keeps content nodes, manifests and links in sync, rebases and merges on green | Changes a design decision to make a check pass |
| **Concept rounds** | **Codex** (AGENTS.md) | Paints the round from the YAML spec as an exploration batch (never promoted), pilot first | Promotes; paints text or UI |
| **Dialogue** | **The founder and friends** | Write every line from the beat IDs, intents and subtext notes | — |
| **Review** | **The lead, then the founder** | The lead reviews contact sheets and sends only the chosen takes; the founder **scores every island 1–10 with one line why** | — |
| **Lookups** | **Haiku** | Finds a fact in the repo or a source | Judges |

## 3. Inputs and outputs per step

| Step | Input | Output | Owner |
|---|---|---|---|
| 0. Ingest | Founder scores and notes, concept takes, playtest data, founder-input log | `founder_scores` appended per island in `profiles.yaml` (history kept, newest last), a founder-input entry | Sonnet |
| 1. Zoom 1: data | `profiles.yaml`, last loop's violations | Edited profiles; a metrics run with its violations listed in the loop doc | Opus |
| 2. Zoom 2: story | Lore bible, story delivery, the spine | The spine, the reveal ladder, the duo's beats (IDs, intents, subtext) | Opus |
| 3. Zoom 3: islands | Each island and cluster, Revontuli formula, tiers | Per island: the unforgettable thing, what it changes in the story, its gift to home, its satellite; cluster deltas | Opus |
| 4. Re-run | Edited profiles | `no violations`, or each remaining one argued in the doc | Sonnet |
| 5. Concept round | The riskiest new ideas | A fenced YAML spec (≤ 12 images, pilot of 2–4) in `loop-N.md` | Opus → Codex |
| 6. Review | Takes | The founder's scores (step 0 of the next loop) | Lead, founder |

**How founder scores steer the design** (implemented in the tool):

- Each island carries `design_loop` (the loop that last redesigned it)
  and `founder_scores: [{loop, date, score, note}]`. A score judges the
  design of its own loop or later; older scores stay as history.
- A big or parallel island scored **below its tier's floor** (premium 7,
  god-tier 9) is a violation: the next loop redesigns it or moves it to a
  lower tier. Until then its **runway is capped** (a weak island holds the
  player less long, so the next arrival comes sooner).
- A low score is analysed against the highest one (loop 1 did this for
  Revontuli's 10 and Gezgin's 7: the seven-part formula in loop-1 §3.0),
  and the finding becomes upgrades for every island, not only the low one.

## 4. The three zooms (each pass)

1. **Data:** six axes per island (palette, material, sky, landform,
   texture, culture), cluster palette deltas from home, beats (the fresh
   thing on each day), tiers. Fix violations **by design**, never by
   renaming a value.
2. **Story:** the spine behind the simple game, the reveal ladder (each
   early island looks small and turns out big later), the duo's arc, the
   tone rules. Beats and intents only.
3. **Islands and clusters:** a merciless re-think of each island in turn,
   the weakest-scored first, each serving the whole story.

Loop 1 ran four passes because two founder notes arrived mid-loop; two to
three is the norm.

## 5. Stopping criteria

A loop stops when **all** hold:

- `python3 -I tools/content/island_metrics.py` prints `no violations`;
- every big and parallel island has an unforgettable thing, a rung in the
  spine (or a stated reason it has none), a gift to home and, for bigs,
  a satellite;
- every island in the next concept round shows at least five of the
  seven Revontuli-formula points (loop-1 §3.0);
- the creative director's self-critique names no blocking problem;
- the token budget is not exceeded.

A loop also stops, with a report instead of a PR, when the same
violation survives two passes: that is a design question for the
founder, asked with options and a recommendation.

## 6. Token budget

- **Opus pass: ≤ 250k tokens** per loop (reading included). Reading is
  the largest cost: the creative director reads the previous `loop-N.md`,
  `profiles.yaml` and the founder-input entries since the last loop, and
  only the sections of older docs a decision touches.
- **Sonnet upkeep: ≤ 100k** (metrics, tests, nodes, merge).
- **Concept round:** ≤ 12 images, pilot first (the pilot rule).
- Over budget: stop, write what is decided, list what is not.

## 7. Files

| File | What |
|---|---|
| `docs/product/design-loop/loop-N.md` | One per loop: the log of passes, decisions, the concept round YAML, self-critique, questions |
| `content/islands/profiles.yaml` | The data every loop edits (not a content node; `validate.py` skips it) |
| `tools/content/island_metrics.py` | The checks; tests in `tools/content/tests/test_island_metrics.py` |
| `content/islands/island-*.yaml` | One content node per island, new ones included |
