# Now

The one status page kept by hand, and the handoff: if this page is true,
the lead's session can be compacted, reset or replaced at any moment. At
most 60 lines. How the studio runs: [studio.md](studio.md). Threads and
history: [tracker.md](tracker.md). What changed for the player:
`python3 -I tools/studio/pulse.py`.

**Goal:** a solid, playable game on the founder's own iPhone for the demo
(about 2026-11-24): Rehearsal mode, days 1 to 21, played hands-on and
sometimes shown to friends ([spec](design/game-solid-v1.md)). No
TestFlight before the membership. The app side follows the demo.

**Updated:** 2026-11-12 (late night, session 2), `main` at `1364ac01` (#402).
**Founder last played on his phone:** 2026-11-05 (told late on 11-12 to try `main`).
**Founder log read up to:** 2026-11-12 (late night).

## Decided this session

- The demo is ONE painted world on days 1 to 21. A critic ranked the
  sprite/plate switch the path's most visible defect: IL1, the harbor,
  Koke, rain, mist, overcast, dawn, dusk and night below IL10 are sprite
  (`HomePlate.swift:92-132`).
- Rain streaks are drawn in code, never baked into a master (ADR-0025).

## In flight (agents of this session)

1. Spec `docs/design/demo-one-world-v1.md` (branch spec/demo-one-world):
   smallest set of code overlays, wiring and art jobs for one painted
   world by about 11-22. Over 20 art jobs is a premise gate (Fable).
2. Builder, game desk: visible feedback (visitor greeting, wonder gifts,
   a solved board), board counters and gutter, two copy bugs.
3. Builder, `pofu-art`: fix and merge #13 (batch-76) and #14 (batch-77,
   picks 84507a1: tile-gate t1, no tile-split), fix QA `edit_structure`
   for night recolours, add Demand row 0-h6 `batch-79-flow-redo`.

## Next steps, in order

1. Read the spec; gate it; brief its PRs (at most three builders).
2. Look at the feedback PR's frames (critic first), merge.
3. Ingest batch-77 picks into the app (flow board pieces); Codex: 0-h5
   (batch-78) then 0-h6. The founder starts Codex by hand.
4. Record the Rehearsal path (spec §8) once one world lands; CI records
   with the `beats` label, but no test drives the path yet.

## Desks

| Desk | Where it stands | Waits on |
|---|---|---|
| Game | game-solid merged (#394 to #400); feedback gaps found by a critic | in flight 2 |
| Look | painted Home by day IL2 to IL10, IL10 golden and night; all else sprite | in flight 1 |
| Art factory | batch-78 READY (0-h5); #13, #14 reviewed, closing | in flight 3 |
| App | paused until after the demo | the demo |
| Story | lines ship with game PRs; studio in use since 11-12 | |

## Open with the founder (no question pending)

- How device testing is run; which means keep the lead's context lean;
  restarting the art line (he runs Codex by hand).
- Known stale: roadmap.md (11-07), tracker.md thread statuses.
