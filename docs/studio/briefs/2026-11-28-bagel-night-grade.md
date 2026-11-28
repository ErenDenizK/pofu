# Brief: bagel cart painted night, the grade fix (2026-11-28)

Role: `.claude/agents/builder.md`. Branch `art/bagel-night-grade`. Desk: `[world]`.

## Where it stands

#563 (merged, 3294260d) ships painted nights for the workshop and the
lighthouse. The bagel cart was pulled back to the derived (N1) night look
at every level (`DERIVED_NIGHT` in `tools/plate/station_looks.py`)
because its painted nights read lime or olive at 1:1. The lead's
measurement on #563's push-3 frames was the median hue of the warm pixels
(CIELAB, C* over 12, hue 30-150, L* over 55):

- the whole bagel cart: about 75 degrees painted against about 57 derived;
- the level 1 awning: about 90 degrees painted.

The raw take (batch 190, `x-plot-bagel-cart-1-night`, pick t1) shows a
warm orange-cream awning to the eye, so the lead's reading is that our
grade, not the art, moved the hue. That reading is a lead to check, not a
fact.

The pipeline: `station_night_looks` takes `fit_grade` to
`PLATE_NIGHT_TARGET["bagelCart"]` (L* 58.1, C* 18.3), then `station_grade`
(light, the toe, chroma), then `build_looks`, then `restore_awning`, with
`awning_measure` as the gate (hue within 5 degrees, stripes at 0.70 of the
day look's or better).

## Facts to check first (a false premise is a result)

- The warm-pixel hue of the raw take, the take after `station_grade`,
  after `build_looks`, after `restore_awning`, and of the derived look,
  per level. Find the step that moves it. If the raw takes are already
  at about 75 degrees, the art is at fault: stop and report, do not grade
  around it.
- What C* the night plate's own cart has, and whether 18.3 is too low for
  a warm, painted cart to keep its colour.

## Change and targets

- The bagel cart's painted nights, levels 1 to 5, back on (out of
  `DERIVED_NIGHT`), graded so that they keep the take's own warmth: no
  blanket chroma cut that leaves a yellow at low chroma reading khaki; a
  plain colour fit to the plate is fine.
- The warm-pixel median hue within 5 degrees of the derived look's, at
  every level. The awning reads warm cream and orange, never olive, at 1:1.
- Mean L* within 3 of the derived look's.
- A level that cannot meet the targets stays derived. Say which and why.

Stay out of the tea stall (its redo is pofu-art D73), the workshop and
lighthouse nights (byte-identical to main), `plate-home.json`'s
`near` and `seasons` keys, and the near ground code.

## Acceptance

- `path-bagel-cart-night-l1..5`: 1:1 crops of the cart, before (main)
  and after, plus the derived look beside them, with the measured hue, L*
  and C* per level.
- Every other frame unchanged against `screenshots/main` apart from known
  capture noise (UI bands). Say which frames differ.
- `plate_gate home` green; report the worst state against 12,000,000 px.
- `station_looks` pytest green.
- A `changes/art-bagel-night-grade.md` line starting `[world]`.

## Process

- Your own worktree at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Fetch frames only with `tools/review/fetch_frames.sh`, never into the
  shared `.git`. Disk is about 8 GB; delete frames as you go.
- No local `.build`. Do not merge.

Hand back: the PR number, head SHA and CI result; the crops' paths; the
per-step hue table; the frame-diff list; the budget; what you can still
see.
