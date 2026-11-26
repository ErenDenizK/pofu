# The island calendar v1: seasons and special days

**Status:** spec by Fable for founder-input 47 (item 1), 2026-11-26.
Amends the main-flow plan's step 6, decision D8 and question Q1
([mainflow-plan-2026-11-26.md](mainflow-plan-2026-11-26.md)). The
founder's page is
[themes-music-studio-2026-11-26-tr.md](themes-music-studio-2026-11-26-tr.md).

**Basis:** pofu `origin/main` a816a65e (#520), pofu-art `origin/main`
bbc91ec. Marks: **[seen]** I opened the file or the picture in this
session; **[scout]** from `docs/research/studio-2026-11-26/raw-themes-motion.md`
on the lead branch, not re-opened. Paths are under
`Packages/PofuKit/Sources/` unless they start with `App/`, `Tests/`,
`tools/` or `docs/`.

**Who applies what:** **[now]** the lead applies without waiting;
**[his]** waits for the founder, with the picture named in section 8.

## 0. The goal, restated

He asked for two things together: special days tied to the calendar
(New Year, Halloween, the bayrams, festivals), and seasons that are
*not* the real world's but "an in-game season system planned before".

**The premise is false and the wish is right.** No document plans an
in-game season. Every season text says the real calendar
(`docs/product/decisions.md` H10, a lead decision made on his "bilmiyorum,
değerlendirelim"; `docs/product/home-progression.md:367`) [scout]. The
nearest things to what he remembers are his own line "seasons change in
the game" (`docs/product/founder-input.md:577`) [seen] and one rejected
alternative, "seasons counted from the player's start"
(`docs/product/home-progression.md:550-553`) [seen]. So there is nothing
to resume; there is something to design, and his version is the better
one for this game:

- A real season lasts three months. A player who arrives in December
  sees one look until March, and he, testing in Rehearsal mode, would
  never see a second one.
- The real calendar needs the hemisphere. The code has only the north
  (`PofuWorld/Sky/Weather.swift:38-62`) [seen].
- Two clocks never fight if each owns a different thing. **The island
  keeps its own year; the real calendar keeps the days people share.**

## 1. What "done" means

1. He taps "next day" seven times in Rehearsal mode and the island has
   turned a season: the air (leaves, petals, snow), the sky's tint, the
   weather's odds, the ambience and, once music exists, the tune.
2. On 31 December 2026 a player opens the app and finds a small lit
   pine by the tea stall, a snowman by the pond, snow in the air and,
   at night, fireworks; Pofu says one line. On 2 January it is gone.
   Nothing was sold and nothing was missed: it returns next year.
3. Autumn and winter at Home look *painted*, not filtered, if and only
   if the pilot of section 5 (PR C4) earns it.

## 2. Where it stands

| Thing | Today | Evidence |
|---|---|---|
| A season in code | `enum Season`, month to season, northern, read by tests only | `PofuWorld/Sky/Weather.swift:38-62` [seen]; `git grep "Season\b"` outside tests and that file: no hit [seen] |
| The player's first day | Stored: `GameState.firstDay`, set once | `PofuCore/Game/GameState.swift:97`, `PofuCore/Game/WorldClock.swift:403-404` [seen] |
| Moving time on his phone | Rehearsal mode's clock is the system clock plus a stored offset; "next day" jumps it | `App/Rehearsal/RehearsalMode.swift:52-72`, `App/Rehearsal/RehearsalPanel.swift:109` [seen] |
| Weather | Five kinds, a seeded bag per half day; no snow | `PofuWorld/Sky/Weather.swift:10-15` [seen]; `docs/design/sky-and-weather-v1.md:60` [scout] |
| Small painted things set on the island | Exists: `PlateProp` (the seed jar, the pots) with named states and one slot per island stage | `PofuWorld/Plate/PlateIsland.swift:377-387`; `plate-home.json` `props` [seen] |
| Particles | Fireflies at night (18, four frames); build dust | `PofuWorld/Look/WorldLight.swift:48-49,327-332` [scout] |
| Season art | Seven concept frames of *another* island layout (batch 25); four edits of the shipped plate by day and four by night are written and were blocked (batches 177, 178) | batch 25 autumn, snow, spring [seen]; `tools/imagegen/manifest/batch-177-themes-seasons.yaml` in pofu-art [seen] |
| A special day | A voice line for New Year and a pending one for the bayrams; nothing drawn; Halloween nowhere | `docs/brand/pofu-voice.md:522,533,594` [scout] |

**A test I ran, because D8 rested on it.** The main-flow plan's D8 said
a theme is "a grade, a sky set, particles and one small painted dressing
set" and never a repaint. I graded the shipped level-10 day plate in
code towards autumn (greens turned to gold) and towards winter (greens
paled and lifted) and looked at both beside the original
(`world-home-plate-day-0`) [seen]. Autumn reads as a dry lawn: the
flowers, the tree's blossom and the sunflower still say spring. Winter
reads as a washed-out photograph: nothing says snow. Batch 25's frames
[seen] show where a season lives in this art: the tree's crown, snow
caps on roofs and bushes, a frozen pond. **A grade alone does not make a
season on this plate.** D8 is replaced by C3 below.

## 3. Gaps, ranked by what the player feels

| # | Gap | Closed by |
|---|---|---|
| G1 | The island is the same every day of the year | C1, C2 |
| G2 | New Year passes and the island does not notice | C3 |
| G3 | Where a season does show, it must not look like a filter | C4 |
| G4 | Nobody can see a season on a phone without waiting months | C1 (seven days), C2 (a Rehearsal readout) |

## 4. Decisions

| # | Decision | Not taken, and why | Who |
|---|---|---|---|
| C1 | **The island year.** Four seasons of `seasonDays` (7) each, counted from `GameState.firstDay`: days 1 to 7 spring, then summer, autumn, winter, and round again. A pure function in `PofuCore`; the length and the order are in `tuning.json`. A season with no look yet is left out of the cycle by a list in the same file | *The real calendar* (H10): three months a look, needs the hemisphere, and he said no. *A global island year* (the same season for every player): nothing in the game is shared between players, and counting from the first day makes every player's first week the approved spring island. *The moon as the island's clock* (a season per lunar quarter): pretty beside Mehtap's full-moon night, but it makes week one's look a matter of luck | [now]; the reading itself is [his], with a default (Q-A) |
| C2 | **Special days follow the real calendar,** from a table in the bundle (`special-days.json`): New Year (31 December, 1 January), Hıdırellez (5 and 6 May), the two bayrams (dates listed per year: they move), Halloween (31 October), and the island's own festival night (the last evening of each island season, the only "day" on the island clock). A day's kit shows from 18:00 the evening before to the end of its last day | *Compute the bayrams:* the lunar calendar is announced, not computed; a table to 2030 is a few lines, and a test fails when it has under a year left | [now] |
| C3 | **A special day is a kit, never a repaint:** two to four painted props on the island's own slots (the `PlateProp` mechanism that already draws the jar), with a lit state at night; one sky event drawn by code (fireworks, falling snow, rising lanterns); one line from Pofu; and, when music exists, one tune. Nothing is sold, nothing counts down, everything returns next year (A7, no FOMO, `docs/product/game-design.md:127`) | *A themed island* (pumpkins on every roof): 20 plates and 80 station looks a day | [now] |
| C4 | **A season is three layers, bought in this order.** (a) *The air*, all code: particles (petals, fireflies, leaves, snow), the sky's tint, the weather's odds (snow joins the bag in winter), the ambience mix. Works on every island stage on the day it merges. (b) *Dressing*: two or three props per season on the same slots as C3. (c) *The painted island*: autumn and winter as edits of the shipped plates (10 stages, day and night; golden is the day edit under the golden grade, as station looks already are), station looks graded by a look fitted to the plate pair (`tools/looklab/bake_luts.py`). **(c) is a pilot first** (PR C4): the level-10 plate in autumn and winter, in the app, on his phone. Spring is the island as it ships; summer is spring plus the air | *Grade only* (D8): the test in section 2. *Paint everything, looks included:* 80 looks a season before one season has been seen in the app | (a), (b) [now]; scaling (c) past the pilot is [his], on his phone |
| C5 | **Weekly themes are dropped.** The island now turns every seven days by itself, and a special day covers "something small is different today" | *Keep H10's weekly props:* two systems for one feeling | [now] |
| C6 | **Other islands keep their own climate** (ADR-0022: Revontuli is polar night). In v1 the island year changes Home; elsewhere only the air | *Every island in four seasons:* multiplies C4 (c) by five | [now] |
| C7 | **A special day wins over a season where they meet,** and never changes the ground: on New Year's night it snows even in the island's summer. A sky island may | *Skip a kit that does not suit the season:* then the calendar would lie | [now] |

No ADR: every choice above is data or a pure function, and reversing C1
is a number and a rule in one file. H10 in `docs/product/decisions.md`
is replaced by C1, C2 and C5; the lead edits that row.

## 5. Pull requests

The Swift lane holds one build at a time; C1 is small and goes first.
"test" is accepted by named tests, "eye" by a named frame against a
named reference.

| PR | Branch | Kind | Files (owned) | Change | Acceptance | Fallback |
|---|---|---|---|---|---|---|
| C1 | `feat/island-year` | test | new `PofuCore/Game/IslandYear.swift`, new `PofuCore/Game/SpecialDays.swift`, new `PofuCore/Resources/special-days.json`, `PofuTuning/Resources/tuning.json` (a `calendar` block), `PofuWorld/Sky/Weather.swift` (the old `Season.of(month:)` goes; `Season` moves to `PofuCore`), `Tests/PofuCoreTests/IslandYearTests.swift`, `SpecialDaysTests.swift`, `App/Rehearsal/RehearsalPanel.swift` (one readout line: season, day of season, today's special day) | `IslandYear.season(on:firstDay:rules:)` and `SpecialDays.active(on:at:)`, pure. Snapshot carries both | Day 1 is spring, day 8 summer, day 29 spring; a disabled season is skipped; 31 Dec 2026 18:00 and 1 Jan 2027 return `newYear`; the table test fails when the last bayram listed is under 365 days away; `WeatherTests` updated | If `Season` cannot move modules without a cycle, it stays in `PofuWorld` and `IslandYear` returns an `Int` index |
| C2 | `feat/season-air` | eye | new `PofuWorld/Scene/SeasonAir.swift`, `PofuWorld/Scene/WeatherLayer.swift` (snow as a sixth weather, drawn like rain's streak tile with slow flakes), `PofuWorld/Sky/Weather.swift` (odds per season), `PofuWorld/Look/WorldLight.swift` (fireflies in summer only), `PofuSound/Ambience.swift` (mix per season), `Tests/WorldScreenshots/PlayerPathScreenshotTests.swift` | Particles and tint per season under `FramePolicy`'s ambient tier; off under Reduce Motion and Low Power, as rain is | Frames `path-season-<s>-i3` and `-i10` by day and `-night`; 1:1 crops: flakes and leaves are soft, never streaks or dots in a grid. Existing `path-*` frames pin spring and stay byte for byte. Reference: the falling leaves and snow of batch 25's `x-season-autumn` and `x-season-snow` t2 for size and density only | If particles cost frames on the render server, halve the count before touching anything else |
| C3 | `feat/special-day-kit` | eye | `PofuWorld/Plate/PlateIsland.swift` (`PlateProp` gains `when`), `PlateHomeViews.swift`, new `PofuWorld/Scene/SkyEvents.swift` (fireworks), `plate-home.json` `props` (the New Year kit and its slots for all ten stages), the kit's imagesets, `WorldStrings.swift` (Pofu's line, T-01 of `docs/brand/pofu-voice.md`), the screenshot tests | The kit draws when `SpecialDays.active` names it; the lit state at night; fireworks from 22:00 to 01:00 on the night itself | `path-newyear-i3`, `-i10`, `-night`, `-fireworks-0.0..2.0`. Reference: batch 183's two previews (`x10-ny-preview-day`, `-night`) for where the props stand and how calm the island stays. On `main` by 20 December | A prop whose cut fails review is left out of the data; a stage with no good slot for a prop draws the kit without it |
| C4 | `art/season-plates-pilot` | eye | `plate-home.json` (`seasonPlates`), two imagesets by day and two by night, `PofuWorld/Plate/HomePlate.swift`, the screenshot tests | The level-10 plate in autumn and winter, from the picked takes of batches 177 and 178, drawn when the island year says so; a stage without a season plate draws the shipped plate with the air | `path-season-autumn-i10`, `-winter-i10`, by day and night, beside `path-d21-0900`: the island did not move (difference outside the edited regions under the compositor's seam limit), the season reads at Map size. Reference: the picked takes themselves | A take that moved the island is not ingested; that season stays air and dressing |
| C5 | `art/season-dressing` | eye | `plate-home.json` `props`, imagesets from batch 186 | Two or three props per season on the kit's slots | `path-season-<s>-dressing-i3`, `-i10` | As C3 |

C1 starts now and has no art in it. C2 follows it. C3 needs C1 and
batch 183. C4 needs C1 and batches 177 and 178. After C4 he plays, and
the next rows (nine more stages by two seasons by two lights: 36 edit
jobs, about 16 MB of plates at the shipped 0.44 MB each [seen: 20 Home
plates are 8.8 MB]) are written only if he keeps the painted season.

## 6. Codex

In pofu-art PR #179: batch 183 (the New Year kit, 8 jobs), 186 (season
dressing, 8), 187 (later special-day kits, 10, stock), and batches 177
and 178 (8 jobs) moved back to READY as C4's pilot. Batch 179 (weekly
themes) is dropped by C5.

## 7. The days (C2's table, to be checked before it ships)

| Day | Dates | Kit | Sky event |
|---|---|---|---|
| New Year | 31 Dec, 1 Jan | pine, parcels, snowman, star lantern | snow in the air; fireworks at night |
| Hıdırellez | 5, 6 May | a rose bush tied with ribbons | petals |
| Ramazan Bayramı | 2027: 9 to 11 March | a table of sweets, bunting | none |
| Kurban Bayramı | 2027: 16 to 19 May | the same kit | none |
| Halloween | 31 Oct | a smiling pumpkin lantern, a paper ghost lantern, sweets | none; lanterns lit at night |
| Festival night | the last evening of each island season | paper lanterns | lanterns rising |

The 2027 bayram dates are from my memory and **not verified**; the
builder of C1 takes them from Diyanet's published calendar and lists
the years to 2030. The bayram kit follows the voice rule already set
for words (`docs/brand/pofu-voice.md:594`): nothing religious, no
symbol, no writing.

## 8. What is the founder's

| # | Question | My pick, applied meanwhile | Picture |
|---|---|---|---|
| Q-A | "Oyun içi mevsim" dediğin şey bu mu: adanın kendi yılı, 7 günde bir mevsim, Pofu'nun geldiği gün başlıyor? | Yes; C1 is built so. A different answer changes two numbers | pofu-art `design/art/takes/batch-25-seasons/x-season-autumn/plate__x-season-autumn--t2.webp` beside `.../x-season-snow/plate__x-season-snow--t2.webp` (what a season looks like; not the shipped island) |

Nothing else here is a question. He sees C2 to C4 on his phone and
vetoes there.

## 9. Out of scope

National days (23 Nisan, 29 Ekim) until he names them; a hemisphere
setting; seasons on other islands' plates; season skins and sold season
sets (`docs/product/game-design.md:397`); seasonal visitors (a stork,
a snow owl); hats or costumes on characters; a countdown to any day;
weekly themes; station looks painted per season; a season's music
(the music system's own spec carries it).

## 10. Corrections

- `docs/product/decisions.md` H10 and `:231`: replaced by C1, C2, C5.
- `docs/product/home-progression.md:37-41,80,367-380`: real-calendar
  seasons and weekly themes; superseded. `:367` also says "hemisphere
  from the device region", which no code does.
- `docs/product/game-plan.md:137` and `docs/adr/0016`: "season" there
  means a release cycle of new islands. Call that a *chapter* or a
  *wave* from now on, so the word has one meaning.
- `docs/adr/0022-plate-first-islands.md:86` says the home's seasons stay
  on the sprite path; Home is plate-first now.
- `mainflow-plan-2026-11-26.md` D8, step 6, row 6a and Q1: replaced by
  this page (amended there in the same PR).
- `content/themes/theme-*.yaml` (all `status: planned`): the four season
  files and `theme-hidirellez.yaml` now point at nothing built; the lead
  updates or retires them with C1.
