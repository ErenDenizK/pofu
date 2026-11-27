# 0028. The far view is a voyage row, and the Gezgin stays moored while you choose

- **Status:** Accepted
- **Date:** 2026-11-27
- **Supersedes:** [0027](0027-one-camera-free-near.md)'s Map stop (the tier frame of
  `world-map.json` and `MapSlots`). 0027's rail, mid and near stand.

## Context

The Map shows every island in one still frame. On a 402 x 874 pt screen it leaves most of the
cloud sea empty, draws the destinations small and high, shrinks Home when a second island
appears, and was laid out for six places where Book One has eleven. The founder, after the
far-camera pilot: the main island is too high, about 60% of the screen is cloud, the islands are
far from the thumb, "we have not produced a solution". A tall screen cannot give one still frame
both depth and large targets.

An earlier draft of this record (#503) answered with a voyage in which the Gezgin, the whale who
carries the player, flew with the camera on her while the world slid under her. The founder's
answers (founder-input 40, 43 and 44) refine it: she is **moored at the island and stays still
while the player chooses**; she moves only when the player says go. Pofu never stands behind
anything taller than himself, and she is never shown from behind.

## Options considered

1. **Keep the Map and add her to it.** The Map's far-away problems stay, and every new island
   needs a new balance of the frame.
2. **#503 as drafted:** she carries the camera and the world slides under her while the player
   chooses. Rejected by the founder: she should not move during the choice.
3. **No far view, a bar of islands only.** Fast, but the world between islands and the Gezgin
   have no place. Kept as the shortcut on the place control.
4. **A voyage row, she moored** (chosen).

## Decision

- **The far stop is a row.** The camera pulls back from mid to a row of islands along the route:
  one island large (about 0.7 of the width), its neighbours cut by the screen edges, the cloud
  sea under them. The Gezgin is moored at the island in view, at her pier, and does not move
  while the player chooses.
- **The hand.** A horizontal swipe changes the island in view and snaps to one; a tap on a
  neighbour glides there. One glass bar (native, never painted) at the bottom shows the
  island's name, one line of state and the verb "Yola çık" ("Set sail").
- **The verb starts the ride.** The characters hop onto her back, and she flies with the camera
  on her to the next island's mooring, where she lands. Every travel between islands is this
  ride, from mid to mid. Reduce Motion cross-fades.
- **Where she lives.** From the day she arrives she is moored at Home's pier (her level shown
  as a cut-out, asleep at night); a tap wakes her with a line and a cue. Before she arrives,
  her shadow crosses the cloud.
- **Her look is data and code.** One cut-out per level and state, moved by code (bob, a squash
  on landing, eyes by swapping the asleep and awake cut-outs, a tail piece that sways). Her
  level is data in `world-map.json`: 1 on arrival, 2 when the first island is healed, 3 when
  the first main island is healed.
- **The route is data.** An island keeps its slot; a new island needs a slot and nothing else.
- **The row exists from the day she arrives.** Before that there is no far view and no control
  for one.

## Consequences

- `MapSlots`, its tier frames, slot towers and the Map reveals are removed once the row ships.
- The Map's composition rules are replaced by the row's data and tests.
- Home's sky set loses its baked whale (she is a character now).
- The world is no longer seen whole in one picture. Home's sky, which shows the player's own
  islands, carries that.
- Undoing this means restoring the Map stop and its tier maths: days, hence this record.
