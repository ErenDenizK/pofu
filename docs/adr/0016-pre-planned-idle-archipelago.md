# 0016. Pre-planned idle archipelago

- **Status:** Accepted
- **Date:** 2026-11-01
- **Amends:** [0012](0012-ux-v1-decisions.md) (decision 1, Home; decision 5, when neighbors arrive)

## Context

The game layer must reward time away from the phone, end every visit
finished, and stay beautiful when the art comes from GPT Image under the
art bible (ADR-0010). The founder's direction of 2026-11-01: pre-planned
growth, idle stations that work while you are away, a calm multiplier,
and **an archipelago rather than one island**: new islands unlock over
time (and arrive with app updates and seasons), each with its own small
concept so a new island feels like a fresh delight, not "+1 bonus".

Forces:

- **Free building** (an isometric grid, placement, decoration) invites
  dwelling, needs SpriteKit-scale rendering, and asks AI art to stay
  consistent across arbitrary combinations.
- **One island** is a two-month game (the v1 simulation finished it on
  day 45–60), then retention depends on seasons alone.
- **Idle games** are the one genre whose core verb is not playing, and
  also the genre most tuned for compulsive checking.

## Options considered

1. **Free-building island.** Expressive; high art risk, dwell-inducing,
   heavy tech.
2. **One pre-planned island,** extended with seasons. Simple; a short
   horizon and every new thing is "+1 level".
3. **A pre-planned idle archipelago.** A home island with staged slots,
   then more islands arriving on designed rules, each with three
   stations, one resident and one small ritual.

## Decision

Option 3, as specified in [game-design.md](../product/game-design.md):

- **Home is Pofu up close on his island** (Home direction B), replacing
  ADR-0012's "Pofu's room". One continuous world with three camera
  framings: Home, the island in view, and the archipelago map. No free
  camera, no panning, no placement.
- **Stations** sit on fixed slots with five designed levels each; every
  level is an edit of the previous image. The player chooses the order
  (and a style at some levels), never the placement.
- **Idle production:** stations make seeds while no guarded app is open,
  times calm (ADR-0015). No storage cap, no timers, no collection
  deadline, no game notifications.
- **Islands** v1: Ayçiçeği (home), İskele (tea-and-simit harbor, the
  morning ferry and postcards), Yıldız (night observatory, stargazing),
  Kaplıca (hot-spring hamam, the warm spring), Kitap (library, Bulut's
  story; arrives with a season update). Arrival rules use cumulative
  tended days, calm nights and levels, never streaks. Seasonal islands
  arrive for everyone and stay.
- **Neighbors arrive with stages and islands** (Mochi at home stage 2,
  Simit with İskele), replacing ADR-0012's first neighbor at 100 skips.
- **Pacing targets** (checked by `tools/sim/island_economy.py`): everyone
  builds on day 1; nobody finishes the home island before about day 40;
  heavy scrollers still progress every week; the archipelago is a
  season-long horizon.
- **Plus sells variety, never progress:** style variants, extra residents
  that produce nothing, seasonal skins, island themes. Never seeds, calm,
  speed, or islands.
- **Rendering:** pure SwiftUI (layered images, `TimelineView`, `Canvas`
  particles) in a `PofuWorld` module; the model in `PofuCore`.

## Consequences

- Art stays consistent because every frame is designed and every level is
  an edit; the asset list is long but mostly edits (about 80 images for
  the home island, about 27 per further island).
- New content has a template (theme, three stations, one ritual, one
  resident, an arrival rule), so seasons can ship islands without new
  systems.
- Each island ritual must stay finite (at most once a day) and earned by
  calm; any ritual that rewards opening Pofu or the gate is rejected.
- `PofuCore` gains `StationLedger`, `IslandCatalog` and `Archipelago`;
  Home's information architecture and user flows are updated when this is
  implemented.
- Risk: idle structure plus arrival beats could create a checking habit.
  Mitigations are the anti-addiction rules A1–A14 in game-design.md; the
  metric to watch is Pofu opens per day against impulses resisted.
