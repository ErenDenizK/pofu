# Now

The one status page kept by hand, and the handoff: if this page is true,
the lead's session can be compacted, reset or replaced at any moment. At
most 60 lines. How the studio runs: [studio.md](studio.md). Threads and
history: [tracker.md](tracker.md). What changed for the player:
`python3 -I tools/studio/pulse.py`.

**Goal:** a solid, playable game on the founder's own iPhone for the demo
(about 2026-11-24): Rehearsal mode, days 1 to 21, played hands-on, sometimes
shown to friends ([spec](design/game-solid-v1.md)); no TestFlight before it.

**Updated:** 2026-11-12 (late night, session 2), `main` at `1364ac01` (#402).
**Founder last played on his phone:** 2026-11-05 (told late on 11-12 to try `main`).
**Founder log read up to:** 2026-11-12 (late night).
**Route:** none yet.

## Decided this session

- The demo is ONE painted world on days 1 to 21 (a critic ranked the
  sprite/plate switch the path's most visible defect).
- Rain streaks are drawn in code, never baked in a master (ADR-0025).

## In flight ([spec](design/demo-one-world-v1.md) #404; players reach IL7)

1. #408 painted sky at Koke and the harbor: a fix builder grades Koke at
   night (it was noon-lit) and saves the sky frames as PNG; one push left.
2. Night character tone (Sonnet): one tone IL2 to IL10; harmony_check
   nights use `--reference l10-night`.
Merged: #405 feedback, #407 hours/weather, #406 Home nights, #409
Çağlayan nights s0/s1; pofu-art #18, #23 to #27 (founder approved).

## Next steps, in order

1. Spec PR 6 (IL1 night; pick: batch-80 t2, warmer than IL2, cool it in
   the fit) after the night-tone PR merges (both edit objects.json).
2. Codex (starts with "çalış"): 0-h9 batch-82 Koke stages 0 and 2 redo
   (+ stage 1 t1), 0-h10 batch-83 Sumi and Damla edits. Next art rows:
   Koke stage 4's baked pale halo (bad alpha); Koke night fringe if art.
   Then spec PR 7 (Koke at final colour) once batch-82 is picked.
3. Ingest into the app: batch-78 parcel, moss, fountain t1, Gezgin; the
   batch-79 dribbles and night UI. Tile junctions parked (failed twice).
4. Port pofu-art's QA and run.py fixes into pofu's tools/imagegen before
   any full `sync_to_art.py`.
5. Follow-ups: wheel sunflower gone IL3-6; IL5 night warm pool; Çağlayan
   nights' empty top and flat band; #405's met goal, caption, badge.
6. Record the Rehearsal path once one world lands (CI `beats` label).

## Desks

| Desk | Where it stands | Waits on |
|---|---|---|
| Game | game-solid and feedback (#405) merged | follow-ups |
| Look | Home and Çağlayan painted at every hour (IL1 night: PR 6) | #408 |
| Art factory | batches 76 to 81 merged; 0-h9, 0-h10 READY | "çalış" |
| App | paused until after the demo | the demo |
| Story | lines ship with game PRs; studio in use since 11-12 | |

## Open with the founder (no question pending)

- Device testing; studio.md at 405 lines over its own 330 cap.
- Known stale: roadmap.md (11-07), tracker.md thread statuses.
