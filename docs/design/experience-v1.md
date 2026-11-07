# Experience v1: navigation, light, menus, frame rate, visitors, fullness

_Status: accepted; built in part (2026-11-05). Owner: the lead. Inputs: the founder's night
list and slice test (founder input, 2026-11-05), the Apple Design Awards
study (`docs/research/apple-design-awards.md`), ADR-0015, ADR-0017, ADR-0018,
`home-layout.md`, `../archive/ui-system-v2.md` §2–3, `../archive/design-language.md` §8 and §11,
`light-standard.md`. Numbers are starting values; they live in `LookTuning`
or config, never as code literals._

His notes are views, not orders. Where the real fix lies elsewhere, this
table says so:

| He saw | The real cause in the code | Fix |
|---|---|---|
| Side items bob like a floating menu | Jar, lantern and pots are drawn in screen space in their own 15 Hz `TimelineView` (`WorldHome.objects`), placed from Pofu's projected feet, while the world moves at 60 Hz: they lag up to 66 ms, then catch up | Put them **in the world** (§1.4) |
| Navigation is broken | Two controls for one camera: the top `FramingPicker` dial and the bottom map button; the dial vanishes at Home | One place control plus gestures (§1.2) |
| Night character light feels disconnected | `WorldLight.characterGrade` lifts every character equally, wherever they stand; only two emitters exist, so the ground around a lit character stays dark | A light field that lights the ground and the characters together (§2) |
| Menus stutter | The world's full-screen grade and depth-of-field passes keep running under a sheet whose glass samples them every frame | Freeze and flatten the world under a sheet; keep the glass (§3.1) |
| The phone heats up | A flat 60 Hz whenever anything moves; the depth pass runs during fast camera moves | A frame-rate policy by state (§4) |

---

## 1. Navigation and camera: one camera, one control

### 1.1 The model

One camera, one continuous zoom (the existing `CameraRail`), no screen
switches. The stops: **Close** (z 2: Home with Pofu, the keeper's corner on
other islands), **Island** (z 1, panned tip to tip), **Archipelago** (z 0,
the sea, shared by every island's rail). Between islands the camera always
zooms out, travels, zooms in, so the player always knows where they are.
The rail gains an island: `CameraPlace = (island: IslandID, z: Double)`.

### 1.2 What the player does

Gestures mean the same in every framing:

1. **Pinch** scrubs the zoom and lands on the nearest stop with the existing
   spring, with the "land" haptic (§3.3).
2. **One-thumb zoom:** double tap, hold, then drag down to zoom in or up to
   zoom out, as in Apple Maps. Everything works one-handed.
3. **Double tap** steps in toward the point (exists).
4. **One-finger drag** pans and brushes the world (§1.3).
5. **Tap** acts on the thing under the finger (§1.3). A tap on empty ground
   does nothing. Today such a tap at Home flies to Island, which surprises
   the player, so it goes. At Archipelago a tap on an island flies there.

**The one control** replaces both the dial and the map button. It is a 52 pt
glass circle, **bottom trailing, at the same spot in every framing** (thumb
zone, muscle memory), and its glyph always shows where a tap goes next:

| Framing | Glyph | Tap | Long press |
|---|---|---|---|
| Close (Home) | island outline | out to Island | native `Menu`: Pofu, each arrived island, Archipelago |
| Island | archipelago (dots on waves) | out to Archipelago | same menu |
| Archipelago | Pofu's face (vector) | fly home to Pofu | same menu |

The glyph morphs (0.25 s) as a pinch crosses halfway, so it previews the
landing. The menu scales to fifty islands: story order, grouped by
constellation past eight. VoiceOver reads "Uzaklaş" or "Eve dön", with the
menu as custom actions, and `accessibilityZoomAction` stays. The top band
holds only the gear, and only at Home. Island and Archipelago show the
island's name tag (`IslandNameChip`). The play door lives in the world (the
garden), so the gamecontroller button goes.

**Flight** (an Archipelago tap, a menu pick, a story arrival) has three
parts. It rises to z 0.15 (35 % of the time), travels over the sea with the
clouds in parallax (30 %), and descends to the target's Island stop (35 %).
It lasts `0.9 + 0.25·log2(1 + d/1000)` s, capped at 1.6 s. The target's
plates start decoding at the tap (`byPreparingForDisplay()`), and the flight
holds at its apex only if they are not ready yet, for at most 300 ms. Reduce
Motion uses the existing crossfade.

**Focus follows the camera.** The founder found the focus "heavy" and
"static". While the camera moves (finger down, pinch, momentum, flight),
depth of field is **off** and its depth-map pass is skipped. The world is
crisp in motion, and the costliest pass is gone exactly when the frame rate
is highest. On settle, a 0.35 s **rack focus** pulls to the target: the
ground at screen centre at Island, the character at Close, or the focused
object. That pull is the beat, instead of a blur that just sits there. The
Archipelago has no depth of field, only haze by distance.

**Many islands.** Only islands in the viewport plus a screen's margin are in
the render tree; far islands are one 512 px sprite each; full plates stay
loaded for two islands at most (current and target). Past twelve islands, a
pinch below z 0 shows constellations as labelled clusters.

### 1.3 Touching the world: taps and brushing

**Taps.** One resolver replaces the per-object `.onTapGesture` overlays
(`IslandScene.hitArea`). A single `SpatialTapGesture` calls
`WorldHitTest.resolve(screenPoint)`, which projects every `HitTarget {id,
worldBox, depth, kind}`, **inflates each to at least 44 × 44 pt on screen**
and returns the frontmost hit (on a tie, the nearest centre). It is pure and
unit-tested, and the scene ends up with fewer views. Accessibility keeps one
invisible element per target. Every tap answers within one frame: a squish
(`PofuMotion.squish`), the "tap" haptic and the object's sound. Then focus
and the sheet follow, as today.

**Brushing.** At Island and Close (z ≥ 0.8), a dragging finger also touches
the island while it pans. `TouchField` unprojects the finger's path into the
world, and every prop within 24 units gets an impulse: sunflowers bend and
spring back, tufts ruffle, butterflies scatter, a frog hops, the chime
rings. These reactions are passive, so they never fight the pan, and taps
stay the only verbs. The island becomes a toy under the thumb (Alba,
Townscaper). `TouchField` keeps at most 16 impulses `{prop, t0, amplitude,
direction}`. Each prop flagged `touchable` in `IslandLayout` reads
`sway(prop, at:)` as a rotation about its base. Frames run only while an
impulse lives (at most 1.2 s).

### 1.4 The fixed home objects

The jar (the seed bag), the calm lantern and the skip pots move **into the
world canvas** at fixed world points (`HomeSlots`). The points are converted
from today's `HomeObjectsLayout` offsets at `IslandFraming.homeScale`, so
Home looks the same. The objects share the island's transform, so they never
lag or bob, and the resolver makes them tappable in every framing. The jar's
count tag becomes a screen overlay in `ScreenOverlays`, shown at z > 1.6.
The separate 15 Hz `TimelineView` is deleted.

### 1.5 Budget and acceptance

**Budget.** Direct manipulation and flights run at 120 Hz with no depth
pass. The settle runs at 60 Hz for the 0.35 s rack focus, then drops to 0.
The hit test is pure CPU over at most 40 targets.

**Acceptance.** CI screenshots: Home, Island and Archipelago each show
exactly one place control at the same rect and no dial; at z 1.9 the jar,
lantern and pots sit on their projected world anchors (±1 pt). Unit tests:
`WorldHitTest` (frontmost wins, 44 pt inflation, the Archipelago),
`TouchField` (decays by 1.2 s), flight duration (grows with distance,
capped). On device: no lag between the jar and the island while pinching,
brushing feels alive, and the world is sharp in motion with focus pulling
after.

---

## 2. Light: real sources that light the ground and the characters

### 2.1 What the player sees

At dusk the lights come on in the cascade of `home-layout.md` §6: from the
garden to the lighthouse in about 6 s, once per evening on screen, each with
a soft "tink". At night every source throws **a warm pool on the ground**
and lights **whoever stands in it**. Mochi, by her door, is warm on the
door's side, and her feet stand in the window's spill. **Pofu's key light at
night is his calm lantern**: the calmer the day, the brighter it burns and
the warmer his face. The game's state shows in the picture, with no UI. A
character between sources keeps a thin cool moon rim and stays readable,
never a silhouette. By day the sun works as now (key, rim, sun on the
stations), and the pools are off.

### 2.2 The model (cheap by construction)

`LightField` (new, pure, in `PofuWorld/Look`) holds the **sources**: every
open emitter of `home-layout.md` §6, the calm lantern, the guest room (H4)
on visit nights, and the moon. A source is `{kind, point, height, colour,
reach, pool shape (round | window spill | pond ellipse), strength(light)}`.
Strength comes from the colour script's `practicals` for each cell, and the
calm lantern's strength follows `calm` (1…2 → 0.4…1.0). The light builds up
in four layers, back to front:

1. **Ambient grade** (exists): the night cell's world grade. At night the
   characters' separate warm lift (`characterGrade`) shrinks to the world
   grade plus a small readability lift (exposure +0.08, tunable), so the
   pop now comes from real light, not a filter.
2. **Baked light pools:** one low-resolution light map (512 × 256 over the
   canvas) holding every source's pool. It is painted from the Codex pool
   sprites and composited with `plusLighter` over the graded world. It
   re-bakes only when the lit set or a strength bucket (1/16) changes, which
   happens a few times an evening. Each frame draws one quad with the camera
   transform, however many sources there are.
3. **Character key:** `LightField.sample(feet)` returns the dominant
   source's colour, direction and strength, plus the ambient.
   `HD2DLayer.drawRims` already masks a gradient by the sprite's alpha. It
   gains a broad **key** from the source's side, a **bounce** (the pool's
   colour on the sprite's lower third), and a **contact shadow** (an
   ellipse cast away from the source). The ground and the character now
   agree.
4. **Glow sprites:** an additive painted halo on each source
   (`drawEmitters`), plus the fireflies.

Flicker (lantern strength × 0.94…1.0) runs only in the Ambient state (§4).
The settled frame is steady, so the cache holds. The normal-map relight
stays off.

**Colour script tie.** The sources' colours and the per-cell gains
(`poolGain`, `ambientFloor`, `moonRim`) go into the cells of
`colour-script.json` beside `practicals`, and are generated into
`ColourScript+Generated.swift`. The light standard holds: sprites are painted
under the day cell with no baked cast shadow, and code casts the light and
the shadows.

### 2.3 Budget, art, acceptance

**Budget.** The bake costs about 1–2 ms of CPU, a few times an evening, off
the frame. Each frame costs one quad plus two masked fills per visible
character (at most 8), inside the existing HD2D `Canvas`, with **no new
full-screen pass**. Target: HD2D at or under 1.5 ms of GPU at 120 Hz. In Low
Power Mode or at thermal state `.serious`, the pools stay, and flicker,
fireflies and light shafts drop.

**Codex art:** the `glow-*` jobs (§7), painterly additive sprites on pure
black, plus a lit edit of the calm lantern. Painted lit overlays on stations
(batch 07) stay only where a shape changes.

**Acceptance.** CI shots (night, Home and Island): warm pools under the
lantern and the door window; Pofu's face at least 12 % brighter on the
lantern side; a resident far from every light still above the readability
floor; a partial cascade at dusk, t = 3 s. Unit tests: `sample` picks the
nearest strong source, the lantern brightens monotonically with calm, and
the bake key changes only with a source or a bucket. On device: the light
comes from somewhere, and in Rehearsal Mochi warms as she walks into her
window's pool.

---

## 3. Menus, shield, loading: glass and paper, calm and fast

### 3.1 When glass is cheap

Glass plus paint is our signature (ui-system-v2 §2). Glass costs only when
what it samples changes every frame. So:

1. **Freeze, then flatten.** When a sheet or a cover is requested, the world
   freezes on that frame (`isCovered`, #183). Its subtree flattens into one
   offscreen texture (`.drawingGroup()` while covered), so the grade and
   depth passes run once and the glass samples a still image. On close the
   world resumes from that same frame.
2. **Glass at partial detents, paper at large.** At the medium detent the
   frozen island glows through the glass. At the large detent nothing shows
   behind the sheet, so the sheet is opaque paper (`paint-paper` nine-slice,
   #183).
3. **Content is never glass.** Cards are paper; the primary action is
   `.glassProminent`; nothing animates behind glass during a transition.
   Reduce Transparency switches everything to paper (exists).

### 3.2 Sheet anatomy (the station sheet is the template)

Five slots, top to bottom: (1) the grabber; (2) a **painted header plate**
(112 pt): the station's vignette on paper, the name in SF Pro Rounded
title2 bold, and drawn level pips; (3) **the one thing**: the rate now and
at the next level, as live numbers with monospaced digits; (4) **one
primary action** pinned at the bottom ("Kur · 12", `.glassProminent`,
violet), with any secondary action as a text button; (5) one flavour line
in Pofu's voice. At most three blocks sit above the fold at the medium
detent. The Today,
decor, island and Plus sheets use the same slots.

**Motion:** the system spring. The world beneath dims by 12 % and
desaturates by 10 % through one grade parameter over 0.25 s, with no blur
pass.

**Type:** SF Pro Rounded for everything people read. Baloo 2 only for four
display moments: the reward line, a level-up, an arrival title, and the
loading line.

### 3.3 Haptics and sound palette (`PofuHaptics`)

| Name | When | Feedback | Sound |
|---|---|---|---|
| `tap` | any world object or control | `.selection` | the object's own |
| `land` | the camera lands on a stop; a flight arrives | `.impact(.soft, 0.4)` | soft air |
| `edge` | rubber band at the end of a pan | `.impact(.rigid, 0.3)`, once | none |
| `nudge` | the check-in appears (Hop!) | `.impact(.light, 0.6)` | two notes |
| `resist` | the resist payoff | custom: two rising soft transients, 0.12 s apart | resist chime |
| `seed` | seed count-up | `.selection` ticks (at most 6 per second), then `.impact(.soft)` | ticks |
| `growth` | a build's level-up | custom: three rising transients plus a soft tail | build sting |
| `pouch` | cheeks full | custom "pouch pop" (exists) | pop |
| `warning` | not enough seeds | `.warning`, never `.error` | none |
| `quiet` | passive updates, bedtime | **nothing** | nothing |

Haptics confirm; they never decorate and never loop. Core Haptics plays only
the custom patterns. This table replaces the map in design-language §11.

### 3.4 The shield and the reward

Apple renders the shield; we control the colour, the icon and the copy.

**Look.** A solid background in four palettes (dawn, day, dusk, night) taken
from the colour script's sky, the lesson of Tide Guide. There is **no
`backgroundBlurStyle`**: a blur would show the feed the user reached for,
which is the temptation itself. The icon is Pofu at his door (180 px), with
a mood per state; his cheeks are never puffed and he never looks guilty.

**Copy rules** (for `pofu-voice.md` §4.7): a title of at most 28 characters
from `ShieldCopy`; an optional subtitle that counts **resists only** ("Bugün
2 kez vazgeçtin."), never opens; no exclamation chains, urgency, shame or
numbers about failure; the tone ladder runs friendly, playful, jealous-play
(at most 3 a day), kind, and bedtime is always soft; the buttons are "Boş
ver" (primary) and "Açmam lazım".

**The "I resisted" moment.** "Boş ver" closes the app to the Home Screen.
**No notification follows**: we never pull someone into an app at the
moment they resisted. The next time they see Pofu, a **fixed 1.0 s payoff**
plays, the same length every time (amended by [ui-v3 §3b](ui-v3.md): on Home
the payoff is now the door stamp, new seals pressed onto the earth beside the
round door (and staying as the day's tally), 2 s, once per open, skippable by any tap; Hop! keeps the
1.0 s payoff below): the day's skip pot blooms, one seed arcs
into the jar, the `resist` haptic and the chime play, and a line in Baloo
appears in the bubble ("Vazgeçtin. Bir tohum."). Several resists play as one
1.0 s cascade, with the pots blooming left to right. Hop! plays the same
payoff. A Live Activity is a P2.

### 3.5 An honest loading screen

1. The launch screen becomes a painted dawn sky
   (`UILaunchScreen.UIImageName = launch-sky`).
2. If the world is ready within 150 ms of the first frame (the state is
   decoded and the home plates are prepared off the main thread), the sky
   crossfades to the world in 0.2 s.
3. Otherwise a **cloud curtain** (three painted layers drifting at 30 Hz)
   stays only while loading actually runs, then parts in 0.6 s into the
   establishing shot.
4. **There is no minimum duration and no fake progress.** After 2 s, one
   honest line in Baloo appears: "Pofu uyanıyor…".
5. A `firstWorldFrame` signpost measures it. Target: a cold launch under
   600 ms on iPhone 17.

### 3.6 Art and acceptance

**Art:** `launch-sky`, `cloud-curtain-1..3`, `shield-pofu-door`,
`reward-seed-burst`, and `sheet-header-*` gaps after #183's 23 masters.
**Acceptance.** CI (`MenuScreenshotTests`): the station sheet shows glass
over the frozen world at medium and paper at large; Today in light, dark and
AX3; the shield replica in four palettes, every title 28 characters or
fewer; the launch sky. Unit tests: the subtitle never contains opens, and
the payoff lasts 1.0 s for one resist and for five. On device: five
open/close cycles at night with no hitch longer than one frame
(Instruments, Animation Hitches).

---

## 4. Frame rate and battery

### 4.1 Policy by state (`FramePolicy`, pure and tested)

| State | When | Rate | What runs |
|---|---|---|---|
| **Direct** | finger down, pinch, momentum, flight, brush impulses | 120 Hz (`CAFrameRateRange(80, 120, 120)`) | camera, grade, HD2D; **no depth pass** |
| **Moment** | build, collect, reward payoff, rack focus | 60 Hz | everything |
| **Ambient** | the visit window (`LookTuning.visitSeconds`, about 8 s) after an arrival or a touch | 30 Hz | sway, particles, flicker, sky drift |
| **Settled** | otherwise | 0 (paused, frame cached) | nothing |
| **Covered** | a sheet or cover is up | 0, world flattened | the sheet only |
| **Minigame** | a garden round | 60 Hz (`SKView.preferredFramesPerSecond`); 120 for drags later | the round; the world is unloaded |
| **Background** | the scene is not active | 0 | nothing |

The world's `TimelineView(.animation(minimumInterval:paused:))` reads its
interval and pause from the policy. `CADisableMinimumFrameDurationOnPhone`
stays on (`Config/Info.plist`), so 120 Hz happens only where the policy asks
for it. Ambient time is quantised to 1/30 s.

**Low Power Mode:** Direct at 60 Hz, Ambient skipped (straight to
Settled), no depth of field, no particles. **Thermal state**
(`ProcessInfo.thermalState`): `.fair` caps Direct at 60 Hz; `.serious` also
drops Moment to 30 Hz and turns off Ambient, depth of field and shafts;
`.critical` caps everything at 30 Hz and shows the settled world. The
policy steps back up only after 30 s at a lower state, so it never
oscillates. For the beta, `directRate` (tunable) is 60 Hz; it moves to
120 Hz after measurement.

### 4.2 Measurement

**Scripted beats** (Rehearsal motion beats): a 10 s pan, a pinch from Home to
Archipelago and back, five sheet open/close cycles, 60 s settled, 60 s of
night Ambient, and one garden round. **Instruments:** Animation Hitches (a
hitch ratio under 5 ms/s while panning), Metal System Trace (GPU time per
pass), the SwiftUI instrument (`SceneFrame`'s body cost) and Power Profiler
(on-device recording, drain per state). **MetricKit:** a subscriber writes
`MXCPUMetric`, `MXGPUMetric`, `MXDisplayMetric`, `MXAppLaunchMetric`,
`MXAppExitMetric` and `MXSignpostMetric` (`flight`, `sheet`, `visit`,
`firstWorldFrame`) to a dev-only log. **Targets on iPhone 17:** 0 frames
over 10 s when settled; a 10-minute mixed session stays `.nominal`; Direct
takes at most 4 ms of GPU per frame; drain per 10 minutes is baselined once
and must not regress.

**Acceptance.** Unit tests (`FramePolicyTests`): every combination of state,
Low Power and thermal state matches the tables, and the hysteresis holds.
CI: driving the scene from Direct to Settled pauses the timeline (the
`needsFrames` seam). On device: the phone stays cool for 10 minutes, and the
frame meter reads 120 while dragging, 30 in Ambient and 0 when settled.

---

## 5. Visitors: someone comes every day

### 5.1 The design

His idea is right. "Today X came, so Y" is the small daily surprise that
makes a 60-second visit worth it (Animal Crossing's campsite, Cats & Soup's
guests). The weekday table (`home-layout.md` §5) becomes a **weighting**:
each resident is likelier on their own day, so the week keeps its rhythm,
but any healed island's resident may come on any day.

**One visitor a day.** The visitor is drawn when the day starts and stays
unseen until the player opens Pofu. They **stay until the first visit after
their day ends**, so nothing is missed and nothing expires (ADR-0017). Every
visit has **one reason**:

| Reason | On the island | Effect (small, one day) |
|---|---|---|
| Gift | a wrapped parcel; a tap opens it | a decor piece or a seed handful (ADR-0015: seeds never buy screen time) |
| Help | something of theirs needs a tap (kite in a tree, stuck cart) | a thank-you line, +1 heart |
| Festival | their island's day: a prop and an accent on the guest stall | +50 % at their favourite station (exists) |
| News | a rumour or a letter (Emanet) | a story line, maybe a map hint |
| Stay-over | they sleep in the guest room (H4) | H4's window lit at night: a new light source (§2) |
| Just sitting | they sit with Pofu: a two-line micro-scene | warmth only |

**Invitations: his idea, evaluated, yes, with one rule.** Once two or more
islands are healed, about one day in seven is a **quiet day**. Pofu hands
over a letter ("Yarın kimi çağıralım?"), and the player taps a resident they
have met. That resident comes tomorrow as **Invited**: a bigger scene plus
the favourite-station bonus. This gives agency and a gentle reason to
return, without a streak. **The rule:** an invitation never expires and
never costs anything.

Before any island is healed, Gezgin's postcard drifts in on a dandelion
seed. That keeps the early days alive and teaches the slot. The lines come
from the `pofu-story` skill (barks per reason). The arrival is the visit's
existing `news` beat, before Collect.

### 5.2 Data model hooks (PofuCore, pure)

`Game/VisitorSchedule.swift` has `visit(for day: LocalDay, state:, seed:) ->
DailyVisit?`: deterministic from the save's seed and the day, weighted by
weekday and hearts, and never the same reason twice in a row for one
resident. `Game/VisitorLedger.swift` holds `DailyVisit {day, resident,
reason, slot, gift?, state: arriving | present | greeted | departed}`,
`invitation: Invitation?`, `hearts: [ResidentID: Int]` (hearts count visits,
never streaks) and the history. `GameState.visitors` is new, and
`WorldClock.advance` rolls the visit at the day boundary. The new
`GameEvent` kinds are `greetedVisitor`, `openedGift`, `helped` and
`invited(ResidentID)`. The world reads only `WorldSnapshot.visitor:
VisitorSnapshot?`. The gift and the festival bonus go into `economy.md` in
the same change as `PofuCore`.

### 5.3 On the island

| Slot | World point | When |
|---|---|---|
| V1 front-lip guest spot | (−95, 36) | before the harbor (IL < 3), between D4 and D3 |
| G1 guest stall | (398, −6) | IL ≥ 3 (exists) |
| V2 favourite-station guest slot | beside the worker | Festival, Invited |
| H4 guest room | (−15, 98) | stay-over nights |

Once the harbor exists, Gezgin lands the visitor at the pier. Before that,
the visitor drifts down to V1 under a dandelion seed. In both cases the
camera pans to the slot first (home-layout rule 5). PR D's test checks V1
against the plate and the footprints.

**Budget:** as a resident; the arrival runs in Moment for at most 2 s.
**Acceptance.** Unit tests: the schedule is deterministic, the weekday
weighting holds over 10,000 days, no reason repeats back to back,
invitations persist, and quiet days stay at or under one in seven. CI: a
visitor at V1, and H4 lit at night. On device: three days in a row feel
different.

---

## 6. Fullness: cute at every build stage

The rules:

1. **No bare lawn.** Over the lawn polygon, a 40 × 40-unit grid: at every
   island level (IL1–IL10), every cell holds something drawn (a station, a
   resident, decor, dressing or a critter's rest spot). `IslandFullnessTests`
   checks this from the layout data alone.
2. **Dressing fills the future.** Each unopened slot carries hand-placed
   dressing from a per-level table (wildflowers, tufts, pebbles, a watering
   can, crates). These are authored tables, not procedural scatter, per the
   founder's craft rule. The dressing leaves in the reveal's puff, and the
   next slot's faint sketch stays.
3. **Life in every frame.** Critters sit at rest spots that read in a still
   frame: a butterfly on a sunflower, a snail on the lip, a bird on the
   tallest roof, the frogs from IL4. They move only in Ambient or when
   brushed.
4. **Thirds.** At Home and at Island, each third of the lawn has a focal
   object and a warm accent.
5. **Night.** Every level shows at least two light sources at Home. At IL1
   those are the door window and the calm lantern.
6. **Idle variety.** No two residents share an idle pose; they wander P1
   only in Ambient.

**Implementation:** `Layout/IslandDressing.swift` (piece, point, level range,
touchable) and `Layout/Critters.swift` are pure data, and the test runs on
Linux. Dressing joins the station pass; the critters (at most 6) join the
characters' pass. The settled cost is 0.

**Acceptance:** `IslandFullnessTests` passes for IL1–IL10. CI shots of IL1,
IL3, IL6 and IL10 at Home and Island, by day and by night. IL1 on its own
looks cute, not empty.

---

## 7. Implementation plan

**Ground rules.** First, merge #183 (painted menus, `isCovered`) on green
CI; the four PRs branch after it, and each owns its own files. Only PR C
edits `Localizable.xcstrings`: A, B and D use
`String(localized:defaultValue:)`, list their Turkish in the PR body, and C
adds those strings last. At most three agents run at once: A, B and C start
on Sonnet 5.5, and D starts when the first one lands. Merge order: #183,
then B (it defines `FramePolicy`), C, A, D, and wave 2. A's last commit
wires in the policy and C's one-line freeze in `IslandScene.swift`. Each PR
runs its targeted tests locally, then CI once, with at most two red rounds.

Paths are under `Packages/PofuKit/Sources/PofuWorld/` unless they say
otherwise.

| PR | Scope | Owns |
|---|---|---|
| **A** `feat/world-navigation` | §1: camera, place control, touch, fixed objects | `Scene/IslandScene.swift`, `Scene/IslandSceneModel.swift`, `Scene/WorldStrings.swift`, new `Scene/PlaceControl.swift`, `Scene/WorldHitTest.swift`, `Scene/TouchField.swift`; `Camera/*`; `Layout/IslandFraming.swift`, `Layout/IslandLayout.swift`, new `Layout/HomeSlots.swift`; `Home/WorldHome.swift`, `Home/HomeObjects.swift`; `App/Home/HomeView.swift`; tests `{WorldHitTest,TouchField,CameraFlight,HomeSlots}Tests`, `WorldScreenshotTests` |
| **B** `feat/light-and-power` | §2, §4: light field, frame policy | `Look/WorldLight.swift`, `Look/WorldEmitter.swift`, `Look/ColourScript*.swift`, `Look/RelightMath.swift`, `Look/GraphicsSpike.swift`, new `Look/LightField.swift`; `Scene/WorldLookLayers.swift`, `Scene/GraphicsSpikeLayers.swift`, `Scene/DepthImage.swift`, `Scene/LivingSky.swift`, `Scene/FarSky.swift`, `Scene/FrameMeter.swift`, new `Scene/FramePolicy.swift` (with a `WorldPower` observable); `design/art/colour-script.json`; glow assets; `App/PofuApp.swift` (MetricKit), new `App/Support/PowerTelemetry.swift`; the garden's `SKView` host; tests `{LightField,FramePolicy}Tests`, `LookScreenshotTests` |
| **C** `feat/menus-shield-launch` | §3, on top of #183 | `Scene/StationSheet.swift` (deletes `FramingPicker`); `PofuDesignSystem/*` (new `PofuHaptics.swift`, `PofuSheet.swift`); `Home/HomeObjectViews.swift` (the payoff); `App/RootView.swift`, new `App/Launch/LaunchCurtain.swift`, `App/Hop/*`, `App/Support/SheetChrome.swift`, `App/Settings/*`; `Extensions/Shared/ShieldStyle.swift`, `Extensions/ShieldConfiguration/*`, `Extensions/ShieldAction/*`; `Config/Info.plist`; both string catalogs; `pofu-voice.md` §4.7, `design-language.md` §11; tests `MenuScreenshotTests`, `RehearsalScreenshotTests`, `HapticsTests` |
| **D** `feat/visitors-and-fullness-data` | §5 and §6's data; pure, tests run on Linux | `PofuCore/Game/VisitorSchedule.swift`, `PofuCore/Game/VisitorLedger.swift`, `PofuCore/Game/GameState.swift` (with `WorldSnapshot`), `PofuCore/Game/GameEvent.swift`, `PofuCore/Game/WorldClock.swift`; `Layout/IslandDressing.swift`, `Layout/Critters.swift`, `Layout/VisitorSlots.swift`; `economy.md`, `home-layout.md` §5; tests `VisitorScheduleTests`, `IslandFullnessTests` |

The lantern emitter in B sits at `IslandLayout.pofu` plus the offset of
`HomeSlots.lantern`, and A's `HomeSlotsTests` checks that the two match.
**Wave 2**, after A, draws the visitors, the dressing and the critters in the
world canvas. It is built (`feat/visitors-and-life`) with code-drawn stand-ins
that swap to the Codex sprites by name (`WorldArt.sprite(name)` is tried
first): the dressing families draw as `dressing-meadow`, `dressing-garden`
and `dressing-harbor`, the critters as `critter-butterfly`, `critter-snail`,
`critter-bird`, `critter-ladybug` (the frog keeps `critter-frog`), the visit
as `visitor-dandelion`, `gift-parcel` and `guest-letter`.

- **Arrival.** The first time the scene sees an ungreeted visitor it holds a
  Moment of at most 2 s: the camera pans to the slot (0.4 s lead), then the
  visitor drifts down under a dandelion seed (V1) or steps in from the pier
  (G1, V2, H4). Reduce Motion and a still frame skip it.
- **Taps.** One resolver, four parts: the visitor greets (`greetedVisitor`),
  the parcel opens (`openedGift`), the help target helps (`helped`), the quiet
  day's letter opens a sheet that lists the met residents and sends
  `invited(ResidentID)`. A stay-over night lights H4's window
  (`HD2DLayer`'s `guestNight`); the visitor sleeps.
- **Life.** Dressing draws in the station pass and leaves in a 0.6 s puff
  when its slot opens; critters draw in the characters' pass and move only in
  Ambient (`CritterMotion`), otherwise they are exactly at rest, so a settled
  frame costs nothing. A brush sways touchable dressing and critters.
- **Layout.** The workshop moved to x 6 and the windmill to x −90 so the
  workshop's lit doorway clears Pofu's head at Home at night.

**Codex manifest:** `tools/imagegen/manifest/batch-35-experience.yaml`.
Sprites carry `light: {cell: day, layer: subject}`; glows are `ui` (additive,
on black); the launch plates use `cell: dawn`.

| Job id | Brief |
|---|---|
| `glow-warm-halo` | Soft round lantern halo, painterly grain, on pure black |
| `glow-window-spill` | Warm trapezoid of window light falling on grass, broken edge, on black |
| `glow-ground-pool` | Elliptical warm pool on a lawn seen at 17°, on black |
| `glow-pond-shimmer` | Cool teal shimmer ellipse for the pond at night, on black |
| `calm-lantern-lit` | Edit of the calm lantern: flame and glass lit, nothing else changes |
| `firefly` | Four-frame firefly, warm core |
| `launch-sky` | Full-bleed dawn sky plate (1290 × 2796), soft clouds, calm bands |
| `cloud-curtain-1` | Front cloud bank for the loading curtain, transparent |
| `cloud-curtain-2` | Middle cloud layer, transparent |
| `cloud-curtain-3` | Back cloud wisps, transparent |
| `shield-pofu-door` | Pofu at his round door, three moods (calm, proud, sleepy), 180 px, cheeks never puffed |
| `reward-seed-burst` | Six-frame sunflower-seed sparkle for the resist payoff |
| `dressing-meadow` | Twelve pieces: grass tufts, wildflower clumps, pebbles, a mushroom ring |
| `dressing-garden` | Ten pieces: watering can, seed sack, twine, small crates, trowel |
| `dressing-harbor` | Ten pieces: rope coil, buoy, crate, folded net, oar |
| `critter-butterfly` | Four-frame butterfly and a rest pose |
| `critter-snail` | Snail at rest and a two-frame crawl |
| `critter-bird` | Small bird perched (two poses) and a two-frame flap |
| `critter-ladybug` | Ladybug on a leaf and a two-frame walk |
| `visitor-dandelion` | A big dandelion seed a small visitor drifts down under |
| `gift-parcel` | Wrapped parcel with twine, closed and open |
| `guest-letter` | Pofu's invitation letter, folded and open, no text in the art |

**Pilot first:** `glow-ground-pool`, `glow-window-spill`, `dressing-meadow`
and `launch-sky`. The rest follow once the founder has seen the pilot in a
night screenshot.
