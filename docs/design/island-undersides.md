# The roots: island undersides as growth and memory

**Status:** proposal by the lead, 2026-11-06. The founder (2026-11-06):
think through how the island grows step by step and the other islands;
evaluate a design and story pass for the islands' undersides ("not every
island needs it").

Builds on [home progression](../product/home-progression.md) §3 (island
level 1-10), [home layout](../product/home-layout.md) §1 (rules of the
ground; the earth face holds the residents' round doors), the
[healing arc](island-healing-arc.md) and
[sky and weather v1](sky-and-weather-v1.md).

## 1. Why the underside

In the game camera the island's earth body and the air below it fill about
a third of the screen at home, and nothing there ever changes: every level,
gift and season grows on the lawn. The lawn is crowded (home layout §1.3,
"the back is hidden, the gaps are gold"); the underside is empty, always
visible, and lit badly at night (founder, 2026-11-06). It is the cheapest
place left to make every level a visible change, and it has a story waiting
in it.

## 2. The idea: the roots remember

Home layout already gives the **earth face** (y 45-150) to the residents'
round doors. Below it, the body tapers into dangling roots and open air.
That lower zone becomes **the roots** (Kökler):

- **The island remembers where it has been.** Every healed wonder island
  leaves a keepsake that hangs from, grows into or pours out of home's
  roots. Over Book One the underside becomes a quiet map of the journey,
  readable at a glance, and nobody says so in words.
- **The roots grow with the island level.** A few island levels add a
  small, living change below, so a level-up is seen from two sides.
- **It is calm, not a second base.** No slots to manage, no menus; pieces
  appear on their own on a level or a gift, and a tap only plays a small
  reaction (a bell rings, a jar glows, water splashes).

Lore fit: Pofu's den is behind the round door in the earth (deep lore M2,
the wheel behind the round door). The roots are under his home, so the
keepsakes are his, kept close: the thesis that nothing needed him to be
fixed stays intact, because the keepsakes are gifts given, not trophies.

## 3. Home: the roots by island level

Only levels that need another visible change get one (the lawn already
changes at every level, home progression §3).

| IL | Below the island | Moves |
|---|---|---|
| 1 | Bare roots, the round door's earth; a single tiny root sprout with one leaf | the sprout sways |
| 3 | A rope ladder from the earth face down to the harbor bridge's foot (the harbor arrives) | the ladder sways in wind |
| 5 | A hollow between two roots where fireflies sleep by day and glow at night | fireflies drift out at dusk |
| 6 | A small lantern hung on the thickest root (lights at dusk, a real source for the night relight) | flame flicker at the 30 Hz tier |
| 7 | Flowering vines trailing over the rim and down the body (the flower borders above, overflowing) | petals drop rarely |
| 9 | Warm amber stones in the earth that glow faintly at night (the hill gate's glow, from below) | a slow pulse |
| 10 | Tam Çiçek: roots in bloom, a small bird nest with two birds | birds come and go |

## 4. Home: keepsakes from the wonder islands

| Island | Keepsake under home | Signature motion |
|---|---|---|
| Koke | a soft moss beard on the roots, with one sprout like Koke's crown | sways; tiny spores drift up on calm mornings |
| Çağlayan | a thin stream that pours off home's edge into the cloud sea (the game plan's "a waterfall pours off home's edge", day 14) | falls, with a mist puff where it meets the clouds |
| Emanet | a small net of lost-and-found things hanging from a root, each labelled | swings when Pofu passes |
| Çanlar | one small bell on a root that rings the four notes when tapped | rings |
| Revontuli | a cluster of ice crystals that holds a faint aurora at night | colours shift slowly |
| Arı | a small wild comb tucked between roots, bees in and out by day | bees |
| Mehtap | a tiny moon lamp, the last light to come on at night | glows |
| Gezgin | the hook where Nazlı's lantern hangs when she docks | the lantern sways |

By the end of Book One the roots hold seven or eight keepsakes. Read top to
bottom, they are the order of the journey.

## 5. Story islands: undersides only where they carry the wound

Not every island needs one. An underside earns its place when the wound or
the cure is told better from below.

| Island | Underside? | What it carries |
|---|---|---|
| Koke | no | Koke is the island; its belly is the earth, and the story is on top |
| **Çağlayan** | **yes** | Stage 0: dry stone lips under the plate where water once fell, a dry stain on the body. Each stage, one stream finds the edge. Stage 4: the falls pour off the island's underside into the cloud sea, the real signature, seen as a long fall below the plate |
| **Emanet** | **yes** | The fog pools under the island like a cloud skirt and lost things dangle in nets from the roots; the cure gathers them up, and the skirt thins to a soft mist |
| Çanlar | small | the mute bells' ropes hang down tangled through the body, untangled per stage |
| **Revontuli** | **yes** | The ruin: broken lantern chains hang below. Healed: icicles become crystal lanterns that carry the aurora's colour under the island |
| Arı | no | the story is the flowers and the swarm above |
| Mehtap | small | a dark underside that fills with tiny stars as constellations join |
| Gezgin | no | a whale, no underside |

## 6. How it is built

- **Code (PofuWorld):** an `UndersideLayout` of anchors in the body's lower
  zone (below y 150, in world units, the same convention as
  `IslandLayout`), pieces chosen by island level and by healed islands from
  `PofuCore` state; motion only at the 30 Hz ambient tier, settled frames
  0 Hz; each lit piece registers as a `LightSource` (the night relight's
  sources). Test: the lower zone never covers a resident door or the
  harbor bridge.
- **Art (Codex):** concepts first (`batch-49-roots`, exploration): home's
  underside at IL1, IL6 and IL10 with two keepsakes; Çağlayan's underside
  at stages 0 and 4. Then production sprites per piece, painted against the
  plate's earth body like the stations.
- **Night:** the underside is where the derived normals fail most; the
  light-direction pilot (`batch-47`) solves the plate's real normals, so
  the roots' lantern and amber stones light the body as a volume.
- **Order:** after Koke is finished and alongside Çağlayan (its waterfall
  keepsake and its underside are the first real use).

## 7. Open question (recommendation first)

1. **Tapping a keepsake replays a memory** (a one-line memory of that
   island, in the residents' voice)? Recommend yes, once a day per piece, so
   the roots become a place players revisit. Alternative: motion only.
