# UI v3: every surface world-class

_Status: proposal (2026-11-06). Owner: the lead. Founder input
(2026-11-06): "every UI, menu, pop-up screen, every component of the app
must look, feel and be used wonderfully"; the "Boş ver" shield and the
break screen must be stunning. Inputs: every shot on
`screenshots/main`, `screenshots/feat-gate-painted-scene` and
`screenshots/feat-life-pass` (2026-11-06), the batch-11, 13, 27, 46, 48
and 58 takes, [ui-system-v2](ui-system-v2.md),
[the audit](ui-audit-2026-11-06.md), [gate v2](../product/ux/gate-v2.md)
§1, §5, §6, [design language](design-language.md), and the code in
`PofuDesignSystem`, `App/Hop` and `Extensions/`._

**The verdict in one paragraph.** Pofu has two products on one phone. The
world (the island, the garden game, the gate postcards, the celebration
card) already looks like a game people would pay for. Everything that
frames it (sheets, Today, Settings, the resident card, the chrome over
Home, the breath room) looks like a well-behaved iOS template with a beige
tint. The fix is not more decoration: it is **one material family**
(paper, linen, honey-stained wood, clay; all already painted by Codex in
batch-27 and batch-11/13), **one verb colour** (honey plaques, never
system violet), **one display voice** (Baloo 2 for every title Pofu says)
and **motion and touch on every press**. ADR-0018's "no painted button
frames, bars or sheets" clause is what holds this back; v3 needs a new ADR
(ADR-0020, below) that keeps native *behaviour* everywhere and lets
Pofu-owned surfaces be painted.

## 1. The bar: ten principles

| # | Principle | Good (ours) | Bad (ours) |
|---|---|---|---|
| 1 | **Every surface is an object in the world**, not a system panel: it has a material, an edge, a weight and a light source that matches the scene | `look-celebration-card`: a stitched paper tag hanging under the island, ribbon pin, live text | `17-sheet-station-medium-glass`: grey glass over a night island, nothing in it belongs to Pofu |
| 2 | **One warm material family**: paper (cards, sheets), linen (info), honey wood (actions), clay (round buttons), felt (chips), wax and ink (marks). No grey, no system blue/violet, no charcoal | `24-garden-set-end-light`: paper card, clay tiles, wood tray, all one family | `01-home-visit-dark`: charcoal glass chrome on a sunny daytime island |
| 3 | **One verb colour**: the action is honey with cocoa ink, everywhere (gate, shield, sheets, game) | `20-gate-0700` and the current shield: honey "Vazgeç" / "Boş ver" | `04-station-build-light` "İnşa et" and `23-garden-round-end` "Sonraki tur": violet, a different app |
| 4 | **Type with character**: Baloo 2 for what Pofu or the world says (titles, rewards, names), SF Rounded for everything read in passing; never system Medium for a headline | `20-gate-*` "Hop!" in a warm bold display | `15-menu-today-light` "Pofu / Her atlayış…" in system weights, `21-launch-curtain` "Pofu uyanıyor…" in plain bold |
| 5 | **Show, then say**: a painted thing first, a number second, a sentence last | `24-garden-set-end` five sunflower seals with +3 … +4 | `15-menu-today` "Henüz açma isteği yok." as the entire day |
| 6 | **Motion that breathes**: every surface enters with a spring from where it came from (sheets rise from the station, cards swing on their string, bubbles grow from the mouth) and settles with one overshoot | `12-collect-flight`: seeds arc from Pofu | `05-build-pop`: the build happens behind a sheet that collapses into a spinner |
| 7 | **Touch that feels**: press = the object sinks 2 pt and darkens 6 %, release = a spring, the haptic names the outcome (selection, success, soft) | `PofuPlaqueButtonStyle` squish (gate) | ghost-violet disabled buttons that do nothing and say nothing (`06-build-after`) |
| 8 | **Never a dead state**: disabled is bare wood with a reason on it, empty is a painted vignette with one action, loading is Pofu doing something | `look-celebration-card` (even a small event has a body) | `18-sheet-station-large-paper`: 70 % empty paper, a greyed button, "İnşa etmek yakında açılıyor." |
| 9 | **Night is a light, not a theme**: world screens follow the scene's light (lamplit paper at night), never the system's dark mode; menus use paper-night, not #15111C | `visitor-h4-night`: lamplit, warm | `15-menu-today-dark`, `16-menu-settings-dark`: generic charcoal |
| 10 | **Nothing generic, nothing twice**: one Pofu per screen, one bubble style, one close button, one verb per act ("Boş ver" everywhere) | `20-gate-0700`: one Pofu, one title, one choice | `20-gate-1200` and `-2230`: a painted hamster behind the live Pofu (two Pofus); gate says "Vazgeç", shield says "Boş ver" |

## 2. Screen by screen

Grades: A ships at Apple Design Award level, B good but generic in
places, C template-feeling, D broken or embarrassing. "Art" names the
batch in §6.

| Screen (file) | Grade | What is wrong (one line) | Redesign | Art |
|---|---|---|---|---|
| Shield, 4 hours (`19-shield-*`, life-pass) | C | The 60 pt icon is a wide Pofu-plus-door composite that reads as two blobs; the subtitle repeats the title and leaks "Huzur ×1,4" | §3: round door medallion icon by mood, copy rewrite, honey stays | 48 t1 medallions (exist) |
| Breath room (`BreathRoom.swift`, no shot exists) | D | Flat lavender, an `accentTint` circle, stock buttons; no scene, no haptic during the breath, no sound | §4: the painted halo isle, drawn ring, breathing Pofu, Core Haptics swell, sound | 61 |
| Station sheet, medium (`17-…-glass`, `integration-reaction-happy-workshop`) | D | Content clipped mid-card ("Seviye 1 / 5" cut), muddy glass, ghost button, left-aligned flavour line under a centred one | Paper at every detent; a fixed five-slot layout that never clips; the level shown as five painted pots | 59 |
| Today (`15-menu-today-*`) | D | A beige page with a purple teacup glyph and two cards; the day has no picture | A day-card: the hour's painted island strip on top, today's resists as wax seals in a row, the cheek count as a jar, one Pofu line in Baloo 2 | 59, 60, 62 |
| Home chrome (`01/02/09/13-home-*`, `10-home-ax3`, `01-home-visit-dark`) | C | White system bubble, violet "Topla" pill overlapping the pots, glance pill, glass gear; dark mode turns it charcoal at noon; at AX3 the bubble buries Pofu | Paper bubble with a cut tail and speaker tab; "Topla" a honey plaque under the jar (not over pots); the glance a paper strip; chrome follows world light; AX sizes move the bubble above the island top | 59 |
| Gate landing (`20-gate-*`) | B | Postcards 1200 and 2230 paint a second hamster where Pofu stands; "Vazgeç" not "Boş ver"; the pause plaque reads as a disabled grey bar; flat drawn plaques | Move to the batch-58 round door (layered); "Boş ver"; the pause is a honey fill that breathes, labelled "Bir nefes, sonra açılır"; painted plaques on the rope | 58, 59 |
| Build flow (`04`, `05`, `06-build-*`) | C | The build — the game's best moment — happens behind a sheet that shrinks to "İnşa ediliyor…" with a spinner | Sheet drops away on "İnşa et"; camera eases to the stake; dust puff, plank pop, the station rises; level-up card swings in (`look-celebration-card` pattern) | 60 |
| After build (`06-build-after`) | C | Ghost-violet "20 çekirdek daha" button: disabled and unreadable | Bare-wood plaque, cocoa text "20 çekirdek daha" with a seed icon and a tiny jar meter; tap explains, never dead | 59 |
| Large station sheet (`18-…-large-paper`) | C | 70 % empty paper | Large detent shows the station's painted ladder (levels 1–5 as small plates), the resident, the next yield | 59 |
| Resident card (`08-resident-card`) | C | A system popover with an SF smiley and a grey capsule | A paper tag on a string from the resident, sticker reaction face, honey "Tezgâha git" plaque | 59 (sticker 42 exists) |
| Map (`07-map-light`) | C | White pills, a generic violet paw pin, empty sky | Paper name flags on stakes; a drawn Pofu pin (ADR-0018 §4); faint dotted flight path; unexplored islands as painted silhouettes | 59 |
| Settings (`16-menu-settings-*`) | C | A stock grouped list on beige; eight identical toggles; violet links | Keep the native list (behaviour), add a painted header (Pofu at a desk), paper-night canvas, flat-duo row icons, moss-tinted toggles, app rows with real app icons | 46, 62 |
| Speech bubbles, story (`koke-beat-3`, `koke-rumour-harbor`) | B | White rounded rect, speaker name in grey caption | Paper bubble, speaker's name on a small coloured ribbon tab (resident colour), Baloo 2 for the line's first word only when it is a name | 59 |
| Island name tag (`03-island-light`) | B | White capsule "Ayçiçeği" | Paper tag on string (batch-11 `ui-tag-paper`), swings with camera | 11 (exists) |
| Place control (bottom-right disc) | B | White disc with an SF-ish glyph; three looks across shots | Clay disc (`ui-face-disc`) with the batch-46 duo icon; one disc, glyph morphs home ↔ map | 46, 11 |
| Launch (`20-launch-sky`, `21-launch-curtain`) | B | Lovely sky, then "Pofu uyanıyor…" in plain bold | Baloo 2 line under a sleepy Pofu peeking through the curtain; one yawn | 62 |
| Celebration card (`look-celebration-card`) | A− | The bar; ribbon pin slightly small | Keep; it is the template for every reward card | — |
| Level-up glow (`levelup-*`) | B | Glow only, no word | Glow, then the celebration card | — |
| Garden HUD and rounds (`20`–`26-garden-*`) | A− | Violet clay buttons in an otherwise wooden game | Honey clay buttons; nothing else | — |
| Garden "+0" (`27-garden-handoff`) | C | Celebrates "+0 yanaklarına" | No reward line at 0: "Bahçe dinlendi." with a sleeping sunflower | — |
| Prova panel, Tuning Lab | n/a | Dev tools, accepted | — | — |

**Top 10 by impact** (how often seen × how visible × founder ask):
1 shield, 2 breath room, 3 station sheet, 4 Today, 5 Home chrome (incl.
dark and AX3), 6 gate landing, 7 build flow, 8 resident card, 9 map,
10 Settings. (A contact sheet of these ten went to the lead with the
PR; it is not committed.)

## 3. The shield ("Boş ver"), honestly

**What Apple allows** (gate v2 §1.1–1.2; nothing here goes beyond it):
one opaque background colour (any `UIColor`, dynamic), one icon image
drawn by the system at about 60 pt, title and subtitle as text plus colour
(no font, no size, no layout), a primary button (label colour, fill
colour), a secondary button (label colour), and from iOS 26.4 up to three
submenu strings under the secondary plus the system's Cancel. No images
beyond the icon, no gradient, no animation, no layout. It is rebuilt only
when shown or deferred. **It will never be stunning in the way the gate
is.** It can be the most *crafted* shield on the App Store.

**The best possible within it:**

- **Colour by hour and mood.** Keep the current warm set in
  `Extensions/Shared/ShieldStyle.swift` (dawn peach #FBE4D8, day cream
  #FFF1DE, golden #FFE0C0, night ink #1E1A3C, breath lavender). Add one
  rule: unwell days use the day colour at 8 % lower chroma, never grey.
  The background must be the gate postcard's dominant sky colour for that
  hour, so the tap from shield to gate feels like a door opening onto the
  same sky (sample it from `gate-door-scene` once batch-58 lands).
- **The icon.** Replace the wide composite with the **round door
  medallions** (`x-shield-icons` t1: curious, proud, jealous, breathe,
  excited, sleeping). A circle reads at 60 pt; a wide image is scaled to
  fit and loses Pofu. Production: 180 × 180 px, a 6 px warm rim, Pofu's
  face at ≥ 55 % of the diameter, transparent corners, one per mood, a
  night set with lamplight. Contrast check against every background.
- **Copy craft** (`PofuCore/ScreenTime/ShieldCopy.swift`). Title = Pofu,
  ≤ 26 chars; subtitle line 1 adds something the title did not (never the
  same words: "Güne akışla mı başlıyoruz? / Güne akışla başlamayalım" is
  an echo); line 2 the tally in words. **Drop "Huzur ×1,4" from the
  shield**: a multiplier is jargon at the moment of reaching. Example
  morning: "Günaydın. Önce ben." / "Çay demleniyor, akış bekleyebilir.\n
  Bugün 2 kez boş verdin." Jealous: "Yine mi Instagram?" / "Bu saat 3.
  kez. Onda ne var bende yok?".
- **Buttons.** Primary honey #F6C453 with cocoa #4A3326 (day), amber
  #E9A93B with deep ink (night): the same plaque colour as the gate and
  every in-app action. Secondary label umber by day, amber-300 by night,
  never violet. One verb: "Boş ver" on the shield, in Hop!, in the
  breath room and in the notification.
- **The 26.4 submenu.** "Açmam lazım" opens: 1 "3 dakika bakacağım", 2
  "Pofu'yla aç" (gate v2 §5.4). Strings only; no icons, no colour. Never
  three items: two plus Cancel reads calmer.

**Where the wow moves instead:**

- **(a) The in-app landing (Hop!).** The round door (batch-58, layered):
  sky by hour (code), the earth bank, the warm burrow, live Pofu holding
  the door, the door leaf swinging open on arrival (0.6 s, spring), three
  painted plaques on a rope as the choices ("Boş ver" big; "3 dakika",
  "15 dakika" small). Pofu's line in a paper bubble. The plaque you press
  dips on its rope (2 pt, rope sways), `.success` on "Boş ver" and the
  door closes softly behind Pofu. This is the screen to make famous.
- **(b) The payoff moment** (`App/Hop/ResistPayoffStore.swift`,
  `PofuDesignSystem/PofuResistPayoff.swift`). "Boş ver" on the shield
  leaves no trace; the next time Pofu is on screen the 1 s payoff plays
  (pots bloom, a seed arcs to the jar, chime, line). Keep the 1 s rule
  for one or two resists. **Add a "door stamp"** for the first open of a
  day with ≥ 3 unseen resists: Pofu pops out of the home island's round
  door holding a paper day-card, one wax seal stamps per resist (0.18 s
  each, cap 5, then "+n"), the card folds into the jar; 2.4 s, tap to
  skip, Reduce Motion = the card appears stamped. (Amends experience v1
  §3.4: the lead decides.)
- **(c) The notification** (`Extensions/Shared/GateNotificationContent.swift`).
  Allowed: a local notification can carry an image attachment
  (`UNNotificationAttachment`), shown as a thumbnail in the banner and
  large when expanded; a Notification Content Extension can draw a custom
  view, including animation, **only in the expanded (long-press) view**,
  not in the banner. Do: attach the mood medallion (same art as the shield
  icon), and build a content extension that shows the round door with
  Pofu waving for the long-press case. Do not: communication-notification
  avatars (they need a messaging intent; not our category, review risk).
- **(d) Live Activity and widgets.** Live Activity: SwiftUI on the Lock
  Screen and Dynamic Island, bundled art, `Text(timerInterval:)` and
  system transitions only; no free animation, payload ≤ 4 KB. Do: a paper
  strip with the medallion, the app name, a honey timer bar, "Şimdi bitir"
  (gate v2 §7.1). Widgets: static timelines, App Intent buttons; a small
  "today's pots" widget (painted pots by count, the day's line) and a
  Lock Screen circular "Pofu's mood" glyph. Neither can host the gate.

## 4. The break screen (the breathing room)

Today `BreathRoom.swift` is a lavender page with a tinted circle. The
redesign makes it the calmest twenty seconds in the app, built on the
batch-48 `x-gate-breath` direction (Pofu, eyes closed, on a small mossy
isle inside a glowing halo, over sunset clouds). **Layers, back to front:**
sky gradient by hour (code; the breath palette tints it toward lavender
at 30 %), far cloud band, the halo glow (painted soft light), the **breath
ring** (drawn: a 3 pt honey-to-cream angular stroke that *fills
clockwise* over the in-breath and *unwinds* over the out-breath; no
numbers), the isle plate, live Pofu (eyes closed; chest and cheeks swell
4 % on the in-breath, settle on the out; ears tilt back 3°), near cloud
band and drifting petals (fireflies at night). On the in-breath the whole
isle rises 6 pt and the clouds part slightly; on the out-breath they
settle. Title in Baloo 2 in the sky band ("Bugünkü saatimizi
doldurduk."), the line under the isle ("Nefes al…" / "…ve ver."), honey
plaques at the bottom ("Pofu'yla nefes al", then "İyiyim, boş ver"),
"Şimdi değil" as a quiet text button at every moment. **Haptics** (this
amends gate v2 §6.5's "none during"): a Core Haptics continuous event
whose intensity swells 0.12 → 0.40 (sharpness 0.10) over the in-breath and
falls back over the out-breath, a soft transient at the turn, `.success`
(light) at "Çok güzel"; a Settings toggle "Nefeste titreşim" defaults on.
**Sound** (`PofuSound`, ambient session, respects the silent switch): a
soft air pad that opens with the inhale and closes with the exhale, one
wooden chime at the end. **Done:** Pofu opens his eyes, one small hop,
three petals fall. Reduce Motion: the ring still fills, nothing moves,
the glow fades in and out. Night: the isle is lamplit, ink sky.

**Art list (batch-61 `breath-room`, kind `ui`/`world`, 1024 × 1536 shared
canvas, layers register):** `breath-isle` (transparent, mossy isle, no
Pofu), `breath-isle-night` (lamp, fireflies), `breath-halo` (soft glow
sprite, transparent), `breath-clouds-far`, `breath-clouds-near`
(transparent bands, day and night), `breath-petals` (6 sprites),
`pofu-breath-in`, `pofu-breath-out` (edits of the R1 eyes-closed pose:
puffed and soft), `pofu-breath-done` (eyes open, content).

## 5. The component kit v3

Behaviour stays native (every control is a SwiftUI `Button`, `Toggle`,
`TextField` with system hit testing, focus, VoiceOver, Dynamic Type);
material is painted; numbers and words are always live text. All pieces
below are blank (no letters), 3× density, and ship a night variant.

| Component | Material | States (rest · pressed · disabled · focused) | Motion and haptic | Codex paints |
|---|---|---|---|---|
| **Plaque** (primary action) | Honey-stained wood, soft carved bevel, cocoa ink | rest; pressed sinks 2 pt, −6 % brightness, shadow tightens; disabled = bare unstained wood, label 60 % + a reason line, never transparent; focused = 2 pt cocoa ring + warm glow | squish 0.97 spring; `.selection` on release, `.success` for a resist or build | `ui-plaque-honey`, `-pressed`, `ui-plaque-bare` (3-slice, 1536 × 384, caps 192 px) |
| **Quiet plaque** (secondary) | Cream linen on wood | as above in cream | same, `.selection` | `ui-plaque-cream`, `-pressed` |
| **Rope plaque** (gate, rewards) | Plaque hung on rope | press dips 2 pt, rope sways | spring 0.5 s | `gate-door-plaques` (batch-58) |
| **Text button** | Cocoa text, hand-drawn underline swash on press | rest, pressed (swash draws), disabled 50 % | `.selection` | `ui-swash` (1 stroke, 3 widths) |
| **Round icon button** (close, gear, place control) | Clay disc with a duo icon | pressed sinks, disabled matte | squish; `.selection` | `ui-face-disc` v2 day, night (batch-11 exists for day) |
| **Sheet** | Paper (day) / lamplit paper (night) at **every** detent; deckle top edge; ribbon grip replaces the grey grabber visually (system grabber kept for VoiceOver) | n/a | rises from the tapped object's position, 0.42 s spring | `ui-sheet-paper-v3`, `-night` (9-slice 1024², insets 96), `ui-sheet-deckle` (tileable 1536 × 128), `ui-ribbon-grip` |
| **Card** | Stitched paper (reward, info), linen (stat), wood (game) | static; tappable cards press like plaques | swing in on a string (rewards), fade-rise (info) | `ui-card-stitched`, `ui-card-linen` (9-slice), `ui-pin-ribbon` |
| **Speech bubble** | Paper with a cut tail and soft cocoa edge; speaker tab ribbon in the resident's colour | grows from the mouth, 0.25 s | none | `ui-bubble-paper` (9-slice), `ui-bubble-tail` (3 angles), `ui-tab-ribbon` (5 tints) |
| **Chip / tag** | Paper tag on string (world), felt chip (filters, reasons, app chip) | selected = stitched border + darker felt | tag swings with camera; `.selection` | `ui-tag-paper` night, `ui-chip-felt` (3-slice), `-selected` |
| **Toast** | Paper strip with stitched edge, −1° rotation | slides from top 0.3 s, holds 2.5 s, slides back | `.success` only for wins | `ui-toast-strip` (3-slice) |
| **Place control** | One clay disc with the batch-46 duo glyph | the glyph morphs home ↔ island ↔ map | matched-geometry morph 0.35 s; "land" haptic | batch-46 duo set, extended to 18 glyphs |
| **Progress** | Carved wood groove, honey fill (drawn), pips as tiny pots or seeds | fill animates with spring; full = one glint | `.success` at full | `ui-groove-wood` (3-slice), `ui-pip-pot` (empty, bud, bloom) |
| **Toggle** | Native `Toggle`, tint moss #7FA36B (day) / amber (night) | system | system | — (native by design) |
| **Text field** | Native field on a paper inset (drawn inner shadow) | focused = honey underline | system | — |
| **Empty state** | One painted vignette + a Baloo 2 line + one plaque | n/a | vignette fades up 0.4 s | batch-62: `empty-today`, `empty-map`, `empty-friends`, `empty-letters`, `permission-key` |
| **Loading** | Pofu doing something (yawn, rolling a seed), never a spinner | n/a | loop ≤ 1.2 s | `loading-seed-roll` (6 frames), `pofu-yawn` |
| **Marks** | Wax seals (resisted, gift, day done), ink stamps (day mood by hour) | stamped = 0.18 s press with a puff | soft impact per stamp | batch-60: `seal-resist`, `seal-gift`, `seal-day`, `stamp-dawn/day/golden/night` |

## 6. Waves

**Before wave 1:** ADR-0020 "Painted surfaces, native behaviour"
(supersedes ADR-0018's "no painted button frames, bars or sheets" for
Pofu-owned surfaces; keeps native behaviour, live text, Reduce
Transparency, and system surfaces Apple owns). The lead writes it; one
page.

**Codex batches (in order):**

| Batch | Contents | Blocks |
|---|---|---|
| 59 `ui-kit-v3` | plaques (honey, cream, bare, pressed), sheet paper v3 day/night + deckle + ribbon grip, cards (stitched, linen), bubble + tails + tab ribbons, felt chips, toast strip, wood groove, pot pips, clay disc night, swash | waves 1–3 |
| 46 (finish) | pick the duo direction; extend to 18 glyphs (home, island, map, today, settings, close, back, plus, info, shield, letter, gift, bell, clock, friend, sound, haptic, lock) | wave 3 |
| 61 `breath-room` | §4 list | wave 1 |
| 48 → shield icons | produce the six medallions at 180 px + night set from `x-shield-icons` t1 | wave 1 |
| 58 (running) | round door layers | wave 2 |
| 60 `seals-and-stamps` | wax seals, ink stamps, build dust and plank pop sprites | wave 2 |
| 62 `empty-and-waiting` | empty-state vignettes, loading loops, launch yawn, Settings header | wave 3 |
| 50 (fix) | repaint gate postcards 1200 and 2230 without the hamster, or retire them for batch-58 | wave 2 |

**Wave 1: the kit and the two showpieces** (three Sonnet PRs, disjoint):

- **1A `feat/ui-kit-v3`**: `PofuDesignSystem/PofuPlaque.swift` (painted
  faces, all states), new `PofuPaper.swift` (sheet and card surfaces),
  `PofuSheet.swift` (paper at every detent), `PofuComponents.swift`
  (bubble, chips, toast, progress), `PofuTokens.swift`, `PofuColor.swift`
  (one verb colour, retire violet as an action fill), `Resources/`. Test:
  a component sheet screenshot, every state, day and night, AX3.
- **1B `feat/breath-room-v3`**: `App/Hop/BreathRoom.swift`, new
  `App/Hop/BreathScene.swift`, new `App/Hop/BreathHaptics.swift`,
  `PofuSound` breath cue. Uses the existing `PofuPlaqueButtonStyle` API.
- **1C `feat/shield-v3`**: `Extensions/Shared/ShieldStyle.swift`,
  `Extensions/ShieldConfiguration/*`, `PofuCore/ScreenTime/ShieldCopy.swift`
  and its tests, `App/Rehearsal/ShieldReplicaView.swift`, the medallion
  assets, `Extensions/Shared/GateNotificationContent.swift` (attachment).

Merge order 1A, 1C, 1B (1B rebases on 1A's painted plaques).

**Wave 2: menus and moments**:

- **2A `feat/today-settings-v3`**: `App/Home/HomeView.swift` (`TodaySheet`,
  `TodayCard` moved to a new `App/Home/TodaySheet.swift`),
  `App/Settings/SettingsView.swift`.
- **2B `feat/station-build-v3`**: `PofuWorld/Scene/StationSheet.swift`,
  `BuildEffects.swift`, `CelebrationCard.swift` (the build moment out of
  the sheet; no clipping at any detent or AX size).
- **2C `feat/gate-door-v3`**: `App/Hop/HopView.swift`, `GateScene.swift`,
  `HopOutcomes.swift`, `HopRungs.swift`, `ResistPayoffStore.swift`,
  `PofuDesignSystem/PofuResistPayoff.swift` (the door stamp).

Merge order 2B, 2A, 2C.

**Wave 3: the world chrome and the rest**:

- **3A `feat/home-chrome-v3`**: `PofuDesignSystem/PofuSkinViews.swift`
  (crafted skin by default, follows world light, not system appearance),
  `PofuWorld/Scene/PlaceControl.swift`, `PofuWorld/Home/HomeObjectViews.swift`.
- **3B `feat/world-cards-v3`**: resident card and map flags
  (`PofuWorld/Scene/ResidentLife.swift`, `LifeViews.swift`,
  `WorldStrings.swift`, `IslandScene.swift` overlays), story bubbles
  (`PofuWorld/Koke/KokeScene.swift`).
- **3C `feat/edges-v3`**: `App/Launch/LaunchCurtain.swift`,
  `App/Onboarding/OnboardingView.swift`, `App/Earn/EarnSheet.swift`,
  `App/Home/PassesSheet.swift`, empty states, the Live Activity and the
  "today's pots" widget (new widget extension; needs the membership
  build).

Merge order 3A, 3B, 3C. Each PR attaches a before/after screenshot sheet;
the lead reviews every sheet before merging.

## 7. Self-critique

- Painting every surface risks a "skeuomorphic beige soup". Guard: one
  material per role, generous empty space, and live crisp text; if a
  screen has more than three materials it is wrong.
- Paper at the medium detent gives up the glass "see the world" effect;
  `17-…-glass` shows that glass over a pastel night island fails anyway.
  If the founder misses it, keep glass only for the round chrome.
- The breath haptic contradicts gate v2 §6.5; it is opt-out and the
  founder feels it on his iPhone before it ships.
- No shots exist for the breath room, Hop! rungs, onboarding, Earn and
  Passes: the screenshot harness must add them in wave 1, or this table
  is half blind.
- The shield copy rewrite changes tested strings in `ShieldCopyTests`;
  the length limits stay.
