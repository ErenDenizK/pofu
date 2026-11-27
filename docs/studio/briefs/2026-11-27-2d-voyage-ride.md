# Brief: PR 2d, the voyage ride (2026-11-27)

Role: `.claude/agents/builder.md`. Main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main) section 6 row **2d**
is your spec (branch `feat/voyage-ride`): the characters hop aboard,
she flies with the camera on her, she moors; 3 to 5 s; Reduce Motion
cross-fades. ADR-0028 is merged. 2b (#529, `PofuWorld/Gezgin/`) and 2c
(#538, `PofuWorld/Voyage/`; `voyageSail` calls the old `fly(to:)` today)
are merged: build on both.

Also carry these leftovers, each fixed or named in the hand-back:
- 2b: the `path-gezgin-wake` frame shows her asleep (the test sets
  `wokeAt` on `world.clock` but the frame clock is real time); her cloud
  shadow reads faint at mid-crossing; no mooring rope; her chime is a
  stand-in (leave the sound as is, it is a sound-desk ask).
- 2c: the row's islands float above the cloud sea with no bed; the
  neighbours are thin (10-17 % of an island); the row is not graded by
  the hour (Köke and the tower stay day at night); she is not drawn in
  the row (draw her moored at the current island at row scale, from
  batch 172's map-scale form, if it reads at 1:1; else name why).
- 2c: `MapSlots.swift`, its tier frames and the Map reveals are still in
  code because `KokeLayout`, `CaglayanLayout`, `HomePlate.mapStop`,
  `PaintedSky` and `CompositionRules` read them: remove them if the ride
  frees them; otherwise list what still holds them.

Acceptance: motion beats `voyage-0.0..4.0`, `CameraFlightTests`, the
2b/2c frames regenerated; 1:1 crops in the hand-back. Pofu never stands
behind anything taller than himself; she is never shown from behind.
Label `screens`; frames only via `tools/review/fetch_frames.sh`;
`changes/feat-voyage-ride.md`. Other builder: 1c pond (#528:
`plate-home.json` `stations`, `tools/plate/station_looks.py`, plate
tests): do not touch those. One full worktree; disk floor 5 GB. Swift
tests via `tools/swift/test-linux.sh` only. At most 3 pushes after the
PR opens. Hand back once CI and frames are in: PR link, CI, sheet + 1:1
crops (paths), each leftover's state. At most 15 lines.
