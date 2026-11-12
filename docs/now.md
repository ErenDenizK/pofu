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

- The demo is ONE painted world on days 1 to 21 (a critic ranked the
  sprite/plate switch the path's most visible defect).
- Rain streaks are drawn in code, never baked in a master (ADR-0025).

## In flight (agents of this session)

[Spec](design/demo-one-world-v1.md) #404, D1-D11 accepted; players reach IL7.
1. PR 3 `feat/painted-sky-everywhere` (Sonnet high; the lead's look). PR 1 merged (#407).
2. PR 2 `feat/home-nights` (Sonnet high; the lead merges after its look).
3. PR 4 `feat/caglayan-nights` (Sonnet; the lead's look). Feedback #405
   merged (heart on greeting, gift tags, board solve caption).

## Next steps, in order

1. Next free builder slot: spec PR 4 (Çağlayan's early nights). Then
   PR 6 and PR 7 once art A1 and A2 are picked.
2. Every eye PR: a critic on 1:1 crops first, then the lead's one sheet.
3. Codex queue on pofu-art main (#13, #14 and #22 merged with the
   founder's approval): 0-h5 batch-78, 0-h7 batch-80 IL1 night, 0-h8
   batch-81 Koke, 0-h6 batch-79 flow redo. Review each within a day.
4. Port pofu-art's QA `edit_structure` night fix and the run.py fix into
   pofu's tools/imagegen before any full `sync_to_art.py` (it would
   overwrite them); sync `flow-tile-split-guide.webp` back to pofu.
5. Ingest the batch-77 flow pieces (bend: narrow east mouth; frame:
   9-slice caps of 240 at 1024).
6. Small feedback follow-ups (critic on #405): a met goal shows nothing
   (say "Ada 3 hazır"), the solve caption sits far from the board, the
   blue check badge breaks the hand-drawn counter.
7. Record the Rehearsal path once one world lands (CI `beats` label).
Swift on Linux: /opt/swift, from download.swift.org (Docker Hub gives 429).
## Desks

| Desk | Where it stands | Waits on |
|---|---|---|
| Game | game-solid and feedback (#405) merged | follow-ups |
| Look | painted Home by day IL2 to IL10, IL10 golden and night; all else sprite | PR 1, 2 |
| Art factory | four Demand rows READY; batches 76 and 77 merged | Codex start |
| App | paused until after the demo | the demo |
| Story | lines ship with game PRs; studio in use since 11-12 | |

## Open with the founder (no question pending)

- Device testing; keeping the lead lean; restarting Codex by hand.
- Known stale: roadmap.md (11-07), tracker.md thread statuses.
