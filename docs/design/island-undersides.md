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

**Reconciled 2026-11-06 with the canonical
[Book One story map](../product/story-map/book-one.md):** the journey's
keepsakes live on **Nazlı's back** ("Sırtında biriken") and each main
island leaves its **EVE HEDİYE** at home (the map). The roots are
secondary: they grow with the island level only (§3), and the story
islands' own undersides (§5) stay as plate art. The keepsake list that was
§4 is replaced by the map's lists.

## 1. Why the underside

In the game camera the island's earth body and the air below it fill about
a third of the screen at home, and nothing there ever changes: every level,
gift and season grows on the lawn. The lawn is crowded (home layout §1.3,
"the back is hidden, the gaps are gold"); the underside is empty, always
visible, and lit badly at night (founder, 2026-11-06). It is the cheapest
place left to make every level a visible change, and it has a story waiting
in it.

## 2. The idea: the roots grow

Home layout already gives the **earth face** (y 45-150) to the residents'
round doors. Below it, the body tapers into dangling roots and open air.
That lower zone becomes **the roots** (Kökler):

- **The journey is remembered elsewhere.** The story map puts each main
  island's keepsake on Nazlı's back and its lasting gift at home (§4), so
  the roots carry no journey map.
- **The roots grow with the island level.** A few island levels add a
  small, living change below, so a level-up is seen from two sides.
- **It is calm, not a second base.** No slots to manage, no menus; pieces
  appear on their own on a level, and a tap only plays a small
  reaction (a bell rings, a jar glows, water splashes).

Lore fit: Pofu's den is behind the round door in the earth (deep lore M2,
the wheel behind the round door). The roots are under his home and grow
as the home grows; the journey's gifts are given, not trophies, and live
where the map puts them (§4).

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

## 4. Where the journey's keepsakes live (the story map)

The roots hold no island keepsakes. The map gives each main island two
lasting marks:

| Island | On Nazlı's back ("Sırtında biriken") | At home (EVE HEDİYE) |
|---|---|---|
| Çağlayan | "havuz ve şelale" | "Evdeki havuzun çeşmesi akar (Salı: Damla gelir)." |
| Revontuli | "aurora kavanozu" | "Köprüde bir fener daha (Cuma: Tuli gelir)." |
| Emanet | "teal tahta" | "Çarşamba kapıda bir paket; atölyeye cilalı buluntular." |
| Mehtap | "ay taşı" | "Tepe'de teleskop (Pazar: Nane gelir)." |
| finale | "Ayçiçeği toprağından genç bir ayçiçeği"; "Ihlamur'un feneri, yanık" | the trail in home's night sky |

Fillers leave no keepsake (the map: no counter, a joke or a feeling). Arı
is a home upgrade (the hive), not a keepsake. Read left to right, Nazlı's
back is the order of the journey; "Bağ büyüdükçe büyür, harcamayla değil."

## 5. Story islands: undersides only where they carry the wound

Not every island needs one. An underside earns its place when the wound or
the cure is told better from below.

| Island | Underside? | What it carries |
|---|---|---|
| Koke (filler) | no | Koke is the island; its belly is the earth, and the story is on top |
| **Çağlayan** | **yes** | Stage 0: dry stone lips under the plate where water once fell, a dry stain on the body. Each stage, one stream finds the edge. Stage 4: the falls pour off the island's underside into the cloud sea, the real signature, seen as a long fall below the plate |
| **Emanet** | **yes** | The fog pools under the island like a cloud skirt and lost things dangle in nets from the roots; the cure gathers them up, and the skirt thins to a soft mist |
| Çanlar (filler) | small | the mute bells' ropes hang down tangled through the body, untangled per stage |
| **Revontuli** | **yes** | The dark island: unlit lantern chains hang below. Healed: icicles become crystal lanterns that carry the aurora's colour under the island |
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
  underside at IL1, IL6 and IL10; Çağlayan's underside
  at stages 0 and 4. Then production sprites per piece, painted against the
  plate's earth body like the stations.
- **Night:** the underside is where the derived normals fail most; the
  light-direction pilot (`batch-47`) solves the plate's real normals, so
  the roots' lantern and amber stones light the body as a volume.
- **Order:** after Koke is finished and alongside Çağlayan (its plate
  underside is the first real use).

## 7. Decided

1. **Tapping a keepsake replays a memory** (founder, 2026-11-06: yes): a
   one-line memory of that island in a resident's voice, once a day per
   piece. Re-pointed 2026-11-06 to the story map: the keepsakes are the
   pieces on **Nazlı's back**, so her back becomes the place players
   revisit. Lines are written with the `pofu-story` skill when each island
   ships.
