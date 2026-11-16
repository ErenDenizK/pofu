# 0028. The far view is a voyage, not a map

- **Status:** Proposed (the founder decides; see
  `docs/design/island-progression-v1.md` section 10)
- **Date:** 2026-11-16
- **Supersedes, if accepted:** [0027](0027-one-camera-free-near.md)'s Map stop (the tier frame
  of `world-map.json`); 0027's rail, mid and near stand

## Context

The Map shows every island in one still frame. On a 402 x 874 pt screen that frame leaves 63%
of its cloud sea empty on day 13, draws the destinations 131 to 145 pt wide in the upper third,
shrinks Home by 20% when a second island appears, and was laid out for six places where Book
One has eleven (`docs/research/island-progression-2026-11-16/art/frames.md`). The founder, after
the far-camera interface pilot: the main island is too high, about 60% of the screen is cloud,
the islands are far from the thumb, "we have not produced a solution; maybe an entirely
different way is needed".

A tall screen cannot give one still frame both depth and large targets: depth makes far things
small. And the story's road between islands, the whale Nazlı (ADR-0019, the story map), has no
part in travel: a flight is a camera move.

## Decision

- **The stop at z 0 is Sefer, the voyage.** Islands stand on a route of slots 235 pt apart: Home
  at slot 0, the main road to the right in story order, fillers to the left in the order they
  arrive. An island keeps its slot for good.
- **One composition at every stage of the game:** the island ahead 300 pt wide with its foot on
  row 528, one neighbour each side cut by the screen edge, a far lane of what else is known in
  haze above the horizon (row 271), Nazlı 330 pt wide in the foreground with Pofu and Mochi on
  her back, and one glass bar at the bottom with the island's name, one line of state and the
  only honey verb ("İn").
- **The hand:** a sideways drag slides the world under her and snaps to an island; a tap on a
  neighbour glides there; a tap on the island ahead or the verb lands at that island's mid stop.
  When Sefer opens she already faces the island where something waits.
- **Flights become rides:** every travel between islands leaves mid, slides along the route and
  arrives at mid.
- **Sefer exists from the day Nazlı arrives.** Before it there is no far view and no control
  for one.
- Reduce Motion cross-fades between slots; VoiceOver reads the route as one adjustable element.

## Consequences

- `MapSlots`' tiers, the tier frames, slot towers and the WP12 reveals are not built further;
  the cloud kit and floor become Sefer's sea.
- The Map's composition rules (C1 to C6) are replaced by the band table of
  `island-progression-v1.md` section 2.1, as data and tests.
- Home's sky set loses its baked whale and generic isles (same document, section 3).
- A new island needs a slot and nothing else; no frame is ever recomposed.
- The world is no longer seen whole in one picture. Home's sky, which shows the player's own
  islands, and the far lane carry that.

## Alternatives

- **Keep the Map and enlarge it** (denser tiers, a vertical pan): the islands stay under 60% of
  the width and every new island needs a new balance; this is the path of the last three weeks.
- **No far view, a glass bar of islands only:** fast, but the world between islands disappears
  and Nazlı has no place. Kept as the shortcut on the place control.
- **Over her shoulder, flying into the picture:** the strongest image, but destinations ahead
  are small again and the view needs a whole new painting of her from behind.
