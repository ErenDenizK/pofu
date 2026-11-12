# Demo one world: follow-ups found in review

Defects the critics found on 2026-11-12 that did not block a merge. Each
names its frame on a `screenshots/*` branch. Pick them up after the
spec's PRs ([demo-one-world-v1](demo-one-world-v1.md)) land.

| Where | Defect | Kind |
|---|---|---|
| Home nights (#406) | The wheel's sunflower is at IL2 and IL7+, gone at IL3 to IL6 | art |
| Home nights (#406) | IL5 night has a warm light pool left of Mochi before the lamps open at IL6; IL5 night is lighter and greener than its neighbours | art |
| Home nights (#406) | No whale at IL2 night | art |
| Çağlayan nights (#409) | Every stage: the top 40% of the frame is empty and the cloud sea below turns into a flat lavender band at about y 1790 | framing |
| Çağlayan (#409) | Greenery does not grow monotonically from stage 0 to 3 (s1 is greenest); s0's pool is full though the island is "dry" | art |
| Koke (#408) | Stage 4 plate has a baked, blocky pale halo (bad alpha) left of and above Koke | art |
| Koke (#408) | Possible pale fringe round the plate at night | art or code |
| Harbor (#408) | The harbor isle is still the sprite (spec D9); a sliver of an island is cut at the left edge | look |
| Home (#405) | A met goal shows no line; it should say the level is ready | game |
| Flow board (#405) | The solve caption sits far below the board; the system check badge clashes with the drawn counter | UI |
| Flow tiles (pofu-art #25) | Generated tile junctions (split, wheel, bend) failed twice with seams; compose them from the straight's own pixels instead | method |
| Screenshots | Most world frames are 460 x 1000 JPEGs, too small for 1:1 checks | tooling |
