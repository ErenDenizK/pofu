# The motion vocabulary: what the app can move, and Çağlayan

**Status:** by Fable for founder-input 47 (item 2), 2026-11-26. A
standing reference for every brief that asks for a place, a prop or a
character, and the decision on Çağlayan. Amends the main-flow plan's
D10, D11, step 5 and Q2.

**Basis:** pofu `origin/main` a816a65e. **[seen]** opened in this
session; **[scout]** from `docs/research/studio-2026-11-26/raw-themes-motion.md`
on the lead branch. Paths are under `Packages/PofuKit/Sources/` unless
they start with `App/`, `tools/` or `docs/`.

## 0. His question, and the answer

> "Sabit görsellerle çalışıyoruz. Akan dere, hareket eden bulut, uzuvlar
> gibi şeyleri az buçuk kurtarabiliyoruz. Ama su çeviren koca bir çarkı
> nasıl anime ederiz? Yapamayacağımız işin altına girmemeliyiz."

He is right, and the wheel is real: the shipped Çağlayan plate at its
last stage shows a wooden water wheel at an angle, with its rim's depth
in view and sheets of water pouring over it, beside a broad fall with
foam, spray and a rainbow, and a rippled winding stream
(`world-caglayan-plate-day-4`) [seen]. None of it moves
(`plate-caglayan.json` has no `water` key and its objects are all still)
[seen]. The picture's subject is three motions, painted frozen.

The mistake was not a missing technique. It was the order: the picture
was painted first and the question "how does this move" was asked
after. **From now on the question is asked before the paint,** against
the list below. A thing a viewer expects to move is either on the list
or designed out of the picture.

## 1. The verbs

Everything that moves in the app today is one of nine verbs. Each is a
pure function of time over still art, so it holds its shape for ever.

| # | Verb | What it does | Art it needs | Where it runs | State |
|---|---|---|---|---|---|
| 1 | **drift** | A layer slides, wraps, bobs | A cut-out or a tile | clouds, far isles, the Gezgin: `PofuWorld/Sky/SkySetView.swift`, `Sky/CloudFloor.swift` | shipped |
| 2 | **ripple** | A shader moves a calm water surface inside a polygon: drift along a flow line, ripple, glint; floating things stay still | The plate itself and a hand-measured polygon; the water painted flat and calm | Home's pond: `PofuWorld/Plate/PlateRegionEffects.swift:1-30`; at most 5 % of the island's pixels (`:116`) [seen] | shipped at Home |
| 3 | **stream** | Streaks scroll down inside a mask; a mist breathes at the foot | A mask and a streak tile, cut from the painting | the falls of the far isles: `PofuWorld/Sky/SkySetView.swift:168-193` [seen] | shipped in sky sets; **not on a plate** |
| 4 | **sway** | A crop shears from its foot | A crop and a mask | a canopy, a blossom: `SkySet.Detail` (`PofuWorld/Sky/SkySet.swift:57-64`) [seen] | shipped in sky sets |
| 5 | **glow** | A lit layer brightens and dims | A lit crop | lanterns, windows: the same `Detail` | shipped |
| 6 | **fall** | Small things are born, fall and fade: rain, splashes, fireflies, dust | A streak tile or a few frames, or none | `PofuWorld/Scene/WeatherLayer.swift`, `Look/WorldLight.swift` [scout] | shipped |
| 7 | **hop** | A whole cut-out lifts, arcs and lands with a squash | The character's one cut-out | `PofuWorld/Scene/PlateHops.swift`, `PlateMoves.swift` [seen: header] | shipped |
| 8 | **flip** | Two to four painted frames swap | A short strip | critters: `PofuWorld/Layout/Critters.swift:24-34` [seen] | shipped off the plate |
| 9 | **breathe** | A rigged still deforms: breath, blink, squash | A base, face variants, lid masks | Pofu: `PofuCompanion/CompanionView.swift:172` [seen] | shipped for Pofu |
| 10 | **spin** | A rigid flat part turns about its centre and is pressed into its tilt; a still shade is drawn over it | The part alone, flat from the front, evenly lit, hub at the canvas centre; the picture without the part | only the stream board's wheel tile, seen from above: `PofuGames/Flow/Scene/FlowScene.swift:323` [seen] | **unproven in the world**; pilot in section 3 |

What is **not** on the list, and is therefore designed out:

- anything that turns and shows its depth while it turns (a wheel, a
  sail or a gear painted at an angle);
- water painted onto another moving thing;
- limbs: walking, arms working, a tail curling (decided, main-flow D9:
  poses, not walk cycles);
- cloth and hair in wind;
- frames painted one after another by the art line: they do not hold a
  shape from one to the next (main-flow D6).

Nothing here needs Lottie, Rive, video or a skeletal rig; none is in the
project [scout] and none is proposed.

## 2. The rule: a motion sheet before paint

Every manifest or brief for a place, a prop or a character carries a
short list, and a reviewer checks the take against it:

```text
Moves: <thing> = <verb>; <thing> = <verb>
Still: <thing a viewer might expect to move, and why it is at rest>
```

A thing that would need an eleventh verb is redrawn until it does not:
the wheel faces the viewer, the stream is a calm channel, the flag hangs.
Water is always painted calm, flat and dry of foam, because the app adds
the motion and painted motion on top of real motion reads as a fault.
This is one line in `AGENTS.md` of pofu-art and one in the art-reviewer's
role file; both are proposals in
[../studio/desks-2026-11-26.md](../studio/desks-2026-11-26.md).

## 3. Proving `spin` and `stream` on a plate

| PR | Branch | Kind | Files (owned) | Change | Acceptance | Fallback |
|---|---|---|---|---|---|---|
| V1 | `feat/plate-rotor` | eye | new `PofuWorld/Plate/PlateRotor.swift`, `PlateIsland.swift` (a `rotors` key: art, centre, tilt as an affine, period, shade art), `plate-home.json`, the windmill imagesets, `Tests/WorldScreenshots/PlayerPathScreenshotTests.swift` | The Home windmill's sails turn: batch 184's sails drawn over the plate without sails, one turn in about 9 s, at the ambient rate; still under Reduce Motion and Low Power | Motion beats `path-mill-spin-0.0..2.0` at 1:1: the hub does not wobble, no edge of the old sails shows, the sails' tilt matches `path-d21-0900`. Reference: `path-d21-0900` for the still, batch 184's `x11-mill-sails` pick for the part | If no take of the sails is flat and even enough to turn, the windmill stays still and `spin` is struck from the list: the answer to his question is then "no wheels", and section 4 uses its wheel-less picks |
| V2 | `feat/plate-falls` | eye | `PofuWorld/Plate/PlateRegionEffects.swift`, `PlateIsland.swift` (a `falls` key: mask polygon, direction, speed), `PlateHomeViews.swift` | Verb 3 on a plate: the sky set's `drawFall` reads a plate polygon | Built with Çağlayan's new plate (section 4), not before; `path-caglayan2-fall-0.0..2.0` | If the scrolled streaks show a seam at 1:1, the fall keeps only its breathing mist |

V1 is small, needs only batch 184 and answers his question on his own
phone with a thing he already knows. It runs in the Swift lane after
`feat/island-year`.

## 4. Çağlayan

What he said: the island's design may change from scratch; the stream
game does not change, is frozen, and is returned to at another time.

| # | Decision | Not taken, and why | Who |
|---|---|---|---|
| M1 | **The stream game is frozen as it is:** eight boards on Çağlayan, bug fixes only. No board, tile or kit work for any island, and the four delivered island kits are not ingested, until he thaws it. This answers the main-flow plan's Q2 and widens its D11 | *Ingest the kits with their islands* (main-flow 5b): that is board work | [now] |
| M2 | **Islands arrive without a game.** Step 5 (Revontuli, Emanet, Mehtap) brings each island's plate, light, resident, mooring and healing arc; healing does not depend on a board (`PofuCore/Game/WonderIslands.swift` names no board or round) [seen: `git grep`]. Row 5b loses its kit ingest and its "4 boards solvable" | *Hold the islands until the game thaws:* three approved islands would wait on a frozen thing | [now] |
| M3 | **Çağlayan is painted again, to the list above.** Its water becomes calm surfaces (verb 2), one ribbon fall (verb 3) and, if V1 proves it, one wheel flat to the viewer (verb 10). The three stone basins stay as the game's door | *Animate the shipped plate:* the wheel at an angle cannot turn, and the foam and spray are painted in. *Leave it as it is:* it is the one island whose subject is motion, and it is the stillest | the direction [now]; the picture [his] (Q-B) |
| M4 | **Six frames first, then one choice** (pofu-art batch 185): two edits of the shipped plate (calmed; wheel removed, or hung flat on the mill's front) and four new layouts (one tall fall; the fall leaving over the island's rim; terraces of pools; a spring and a tarn). The cheapest that he likes wins: an edit keeps five stages of layout data; a new layout repaints five stages in four lights | *One design, chosen by me:* the look of an island is his | [his] |
| M5 | **The rebuild waits for step 2** (the voyage) and is the first job of step 5, before Revontuli: the template the other islands copy should be the one made to the vocabulary. Until then the shipped Çağlayan stays in the app untouched | *Now:* it would take the Swift lane from the steps he is waiting to play | [now] |

The rebuild's PRs are written when he has chosen (one eye PR for the
plate set and its polygons, V2 for the fall, one for the sky set). Their
reference will be the picked take of batch 185.

### What is the founder's

| # | Question | My pick | Picture |
|---|---|---|---|
| Q-B | Çağlayan için altı resimden hangisi? | None before the frames exist: the cheapest one he likes wins (an edit before a new layout) | The six takes under pofu-art `design/art/takes/batch-185-caglayan-again/` once delivered, beside the shipped plate: [assets/motion/caglayan-day-4-plate.jpg](assets/motion/caglayan-day-4-plate.jpg) |

Until he chooses, nothing of M3 is built; M1, M2 and V1 do not wait.

## 5. Out of scope

Any change to the stream game, its boards, tiles or kits; other islands'
games; a skeletal rig; frame animation by the art line; water on the
shipped Çağlayan plate; turning the lighthouse lamp, the cart wheel or
the workshop's gear (after V1, as rows of their own).

## 6. Corrections

- `docs/design/world-presentation-build-spec.md:140` (G8, "water is
  still"): untrue for Home since the pond shader (#3c9fae5a), true for
  Çağlayan.
- `docs/design/mainflow-plan-2026-11-26.md` D10 says he asked that
  Çağlayan's water not be finished; the scout found no such words in the
  founder log. His words are now founder-input 47, and they are wider.
- The scout's raw file gives the board wheel's spin as "4 s
  (`FlowScene.swift:48`)"; the action is at `:323`, one turn in 2.4 s
  (6 s under Reduce Motion).
- `PofuWorld/Sky/SkySet.swift` header says the sky set draws at 15 Hz
  and `docs/research/feel-motion-facts-2026-11-14.md:13` says 30 Hz; I
  did not resolve it.
