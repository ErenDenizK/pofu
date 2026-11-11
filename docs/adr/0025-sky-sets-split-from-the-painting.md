# 0025. Sky sets are split from the painting

- **Status:** Accepted (amends 0022 and 0023)
- **Date:** 2026-11-11

## Context

A baked sky cannot move. Landscape island plates also leave about 40% of a
portrait screen empty (`docs/product/decisions-2026-11-11/result-caglayan-landscape-plates.jpg`).
Between home stages the cloud sea differs by delta C* 1.3-1.9 and the sky by
3-10, yet both are repainted for every stage.

## Decision

Each world screen is an **island plate** (per stage and time, painted, matted
to alpha; the cloud bank at the island's base stays in it) over a **sky set**
(per island and light: gradient sky, far and mid cloud layers, distant isle and
whale sprites, a hole-filled cloud sea). A sky set is **split from one painted
portrait master** per island and light, never generated separately. At rest the
composite equals the painting. Motion is code only (drift, parallax, a breathing
cloud sea, bobbing isles, star twinkle), off under Reduce Motion; the island
never moves. Sky masters may carry about +10% C* p90; island bands do not change.

Rain and golden for the remaining cells: a **pilot** of an offline colour
transfer fitted from each island's own painted pair, baked into files (no
runtime grade), shipped only if the founder approves the pilot screenshot.
Night and day cells stay painted.

## Why this is not the old collage

The collage failed on objects sharing contact shadows and bounce light on the
island surface. A sky set shares only atmosphere and comes from the same painting.

## Screen checks

`tools/plate/screen_check.py` (being built): frame-zero identity (mean delta E
< 1.5, p99 < 6), seam under motion, colour drift, dead composition at most 18% of
the height, life, resolution at least 0.9 px per px.

## Consequences

- Batch-75 shrinks from 54 jobs to 16 (4 pilots, 8 light edits, 4 rain skies).
- The rain and golden bake is a pilot needing founder approval.
- Sky layers ship as HEIC (ADR-0024); `docs/state/plates.yaml` gains `sky_sets:`.
- ADR-0022 and 0023 stay as history; where they bake the sky in, this ADR wins.
