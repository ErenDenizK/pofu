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

**Updated:** 2026-11-12 (evening), `main` at `3d053570` (#400) plus the
studio PR that adds this page.
**Founder last played on his phone:** 2026-11-05.
**Founder log read up to:** 2026-11-12 (evening), the studio design approved.
**Lead session cost:** 2026-11-03 to 11-12: 1,999 turns, median context
317k, about $223 of $749. Aim: an average under 150k.

## Next steps, in order

1. Merge the studio PR here and the queue PR in `pofu-art`. On the next
   real brief, try one scout and one builder from `.claude/agents/`, and
   note here whether the session loads agent types from that folder.
2. Game: send the founder the Rehearsal path (spec §8) as a recording or
   frames, and say what on `main` is worth trying on his phone. The
   screenshots of #399 (`koke-stage-4`, `caglayan-beat-3`) were not
   produced in CI and nobody has seen them.
3. Art: run an art-reviewer on `pofu-art` #13 (batch-76) and #14
   (batch-77), both delivered on 2026-11-12. Then give Demand new rows.
   A draft manifest for the painted visitor, parcel, moss and fountain
   (batch-78) exists only in the lead's scratchpad
   (`batch-78-draft.yaml`): commit it or it is lost with the container.
4. Look: a scout lists which states of days 1 to 21 still draw the sprite
   island and renders one sheet of them; then decide whether the demo
   gets painted night at IL2 to IL9 (painted and picked, not in the app).

## Desks

| Desk | Where it stands, checked at the commit above | Waits on |
|---|---|---|
| Game | The six game-solid PRs and one polish PR are merged (#394 to #400); the demo-run test plays days 1 to 21 | step 2 |
| Look | Home is painted by day at IL2 to IL10 and at IL10 golden and night; every other home state draws the sprite island. The plate's visitor, moss and fountain are code-drawn stand-ins | steps 3 and 4 |
| Art factory | `pofu-art`: #13 and #14 delivered and open; seven Stock PRs open (#6 to #12); no untaken READY row | step 3 |
| App | Paused by the founder until after the demo. Then: the Door and onboarding spec, a premise for Fable | the demo |
| Story | Lines ship with game PRs | |
| Studio | Applied on 2026-11-12 by Fable 5.2; why: [the design](research/studio-design-2026-11-12.md) | step 1 |

## Open with the founder (to design together, no question pending)

- How device testing is run. He installs through a separate cloud session.
- Which means keep the lead's context lean: compaction, a reset, a new session.
- Restarting the art line once the studio is in place; he runs Codex by
  hand.

## Known stale

- [roadmap.md](roadmap.md): its status block is dated 2026-11-07.
- [tracker.md](tracker.md): a thread's status may be older than the code.
