2026-11-26: no music in the app yet. The plan below starts tonight.

# Music desk: plan

Rows are in [the music system](../../design/music-system-v1.md),
section 8.

## Now

| Row | What | State |
|---|---|---|
| MU1 `feat/music-score` | The ABC parser, the band, the renderer, the lint; three candidate Home day tunes as 40 s auditions with their piano rolls | can start; Python lane |
| Gate 1 | He listens to the two proof loops that exist and says whether the instruments' sound pleases him | sent with the morning cards |

## Next

| Row | What | Waits for |
|---|---|---|
| Gate 2 | He chooses the Home day tune from A, B, C | MU1 |
| MU2 `feat/music-director` | The director and the player in `PofuSound`; "Ada müziği" in Settings | MU1; the Swift lane (after step 2 of the route) |
| MU3 `feat/music-room` | "Müzik odası" in Rehearsal mode | MU2 |

## Later

MU4 Home whole (night, four season leads, stingers, the New Year tune
`#newyear`); MU5 the voyage; MU6 and on, one island each with step 5.

## Asks

| From | What |
|---|---|
| Story | Correct the six islands' moods in the bible (system, section 5) against Book One before an island's tune is written |
| World | `MusicDirector` needs the island's season and stage in the snapshot (the calendar's C1) |

## Decided

- 2026-11-26: a score in the repository, one synthesized band, cells
  played by a director (ADR-0029).
- 2026-11-26: tunes with pauses, not loops; on by default and quiet;
  silent on the gate and at night (system, D2, D7, D8).
- 2026-11-26: one key for the whole game, a mode per island (D4).
