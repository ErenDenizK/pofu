# Home progression: Ayçiçeği from day one to the long tail

**Status:** accepted; built in part (progression designer, 2026-11-05). Extends
[game plan v1](game-plan.md) section 2 (the home cluster); where this file
and older docs disagree about home levels, this file wins. Numbers are
scale A ([economy](economy.md#economy-scale-a-small-numbers)); the day
columns come from a simple model of the published 60-day income curve
(below), and `GameScenarioTests` becomes the authority once the code
follows. Order and gates are fixed; days are what the typical user sees,
never a schedule (founder, 2026-11-05: no fixed durations).

Why it exists: the founder (2026-11-05) asked for several things on the
home island that grow slowly together, gently capped, with big payoffs
for maxing one thing and for maxing everything, Cats & Soup style
level-ups, and a plan for the island's whole development: seasons,
add-ons, levels, objects, characters, lights and effects. Paper first,
then concept art, then code.

Hard rules that bind every row: seeds never buy screen time (ADR-0015,
[care over currency](../adr/0015-care-over-currency.md)); Pofu never dies
and nothing built is taken away ([ADR-0017](../adr/0017-pofu-never-dies.md));
the anti-addiction rules A1 to A14 in
[game design §4](game-design.md#4-anti-addiction-rules-acceptance-criteria):
no timers, no storage cap, no notifications, no streaks, no FOMO, no paid
acceleration, visits of one to two minutes.

## Founder words and open decisions (2026-11-05)

What he said on 2026-11-05: "Start everything that is certain: upgrades,
different shops, residents, decorations, a cozy island" (the list of what
to begin). On seasons and moving he did **not** decide: "mevsimler takvime
bağlı olabilir haftalık da olabilir bilmiyorum taşınma olayından tam emin
değilim değerlendirelim" (15:16). A little later he said what "taşınma"
meant: a story character moving home, and the island they left must not
feel empty: "belki arasında git gel yapabilir" (16:24).

- **Seasons:** a lead decision, not his (register H10). The real calendar
  for the island's look plus a weekly small theme on top (a visitor, a
  market stall, kites, a lantern night, a fishing day, rain boots, a
  picnic, a stargazing night); a theme is a small prop or overlay, nothing
  expires or is bought, and it returns in later years.
- **Residents of healed islands visit, they do not move in** (register
  H8). They come home and go back (*git-gel*), so their own island never
  feels empty. The home residents of Book One (Mochi, Simit, the goat, the
  frogs, Fındık and Pofu) do live on the home island.
- **Stations:** each home resident first works their fixed favourite
  station (section 6; no assign sheet at first). Moving a resident to
  another station is optional and opens at island level 4. This is the
  lead's design for station work; it is not what "taşınma" meant.
- The concept art for all of this is queued as backlog rows B-A to B-F in
  the [art plan](../design/art-production-plan.md#the-backlog).

## 1. What we take, what we refuse

Research, short (community guides and press for Cats & Soup; Animal
Crossing and Hay Day from design knowledge).

| Game | We take | We refuse |
|---|---|---|
| Cats & Soup | Facilities that visibly change as they level; small numbers on every card; residents (cats) assigned to a station, animating there and boosting it; a reason to move a resident once a station is done; decor that dresses the world; area expansions as the big moments; themed seasonal decor | Limited-time events and tokens that expire; gems and the star reroll (gacha); ads for boosts; a 24,000-level ladder of invisible increments; login rewards, daily missions, feeding chores |
| Animal Crossing | The home that grows in readable steps (tent, house, rooms); an island rating that quietly opens the next thing; seasonal looks that return every year; residents who come to live (ours from other islands only visit) | Real-time pressure (turnips, a two-week window for an item); a debt framing |
| Hay Day | The farm level that opens new buildings, so the next slot is always in view | Timers, storage caps, speed-ups for currency, orders that expire |

**Our line:** every level is a picture you notice, every cap is visible
and lifts by itself, nothing expires, nothing asks you to come back at a
time, and there is no currency besides seeds and a handful of island
materials that cannot be bought.

## 2. The systems at a glance

| System | Count | Grows with | Gives |
|---|---|---|---|
| **Island level** (*Ada seviyesi*) | 1 to 10 | tended days (a floor) + built levels | opens station slots, raises the station cap, adds island-wide light and life |
| **Stations** | 8 in Book One (5 home, 3 harbor), +1 gift station (the hive) | seeds, and at a few levels one island material | idle seeds; a visible change every level; a payoff at L5 |
| **Pairs** (*ikililer*) | 4 | both stations of a pair at L5 | a shared scene that only exists when both are done |
| **Residents** (*sakinler*) | 6 at home in Book One; one visitor per healed island | the six live at home; island residents visit; work a station you choose | +25 % at their station (+50 % at their favourite), hearts that unlock looks and lines |
| **Decor sets** (*takımlar*) | 4 in Book One, 1 per season after | seeds, island gifts, resident hearts | a piece per spot; a full set adds one light or sound effect |
| **Materials** (*malzemeler*) | 6 in Book One | finishing wonder islands; later, their rounds | needed for a few late station levels and the hive |
| **Mastery levels** L6 to L10 | 8 stations × 5 | seeds + a material; the cap rises one level per season | a small touch per level, a golden master at L10 |
| **Seasons** | 4 a year, real calendar | the date | the island's look, a visitor, a season set, +1 mastery cap |

Growth (*büyüme*) is what the island level counts: **built station
levels**, nothing else, so the threshold is easy to read ("Ada 6 için: 2
seviye daha") and decor stays optional. It only goes up.

## 3. Island level: the soft cap

The island level is the one number that keeps everything growing
together. It rises when **both** a tended-day floor and a growth threshold
are met; it can never fall. Each level raises the **station cap** (the
highest level any station may reach) and opens slots. It replaces the
five home stages (`homeStageTendedDays`), which only counted days.

| IL | Tended day ≥ | Growth ≥ | Opens | Station cap | What changes on the island (art · light · sound) |
|---|---|---|---|---|---|
| 1 | 1 | 0 | garden (built L1), Pofu's nest | 2 | a small round island, one sunflower bed; wind and bees |
| 2 | 2 | 2 | tea stall slot | 2 | a stone path to the tea corner; the kettle's whistle in the morning |
| 3 | 3 | 3 | **the harbor** (fog lifts), bagel cart | 3 | the rope bridge to İskele; gulls; the harbor bell once |
| 4 | 4 | 6 | pond slot (the island widens) | 3 | the lawn widens to the right; frogs at dusk |
| 5 | 6 | 10 | pier slot | 4 | stepping stones; fireflies on calm nights (code) |
| 6 | 10 | 15 | workshop and lighthouse slots (the back terrace) | 4 | the back terrace rises; path lamps light at dusk (warm pools, code) |
| 7 | 14 | 20 | the four decor spots, set 1 | 5 | flower borders along every path; the island's own short melody on arrival |
| 8 | 24 | 28 | windmill slot (left terrace) | 5 | birds circle the windmill; evening lanterns along the terraces |
| 9 | 36 | 34 | the hill path to a closed gate; the hive slot (with Arı) | 5 | a gate on the hill with a sunflower carved in it, a soft glow behind |
| 10 | — | 40 levels: all eight stations at L5 | **Tam Çiçek** (full bloom), section 5 | 5, then +1 a season | the hilltop terrace opens |

**The rules that keep it gentle (tested):**

1. **No dead end.** At every island level, the next threshold can be met
   without materials not yet available: the open stations times the cap,
   minus material-gated levels, is at least the next threshold
   (IL5 needs 10, max at cap 3 is 12; IL6 needs 15, max 19; IL7 needs 20,
   max 26; IL8 needs 28, max 33; IL9 needs 34, max 37).
2. **The next goal is always visible and near.** The cheapest open thing
   (a level under the cap or a decor piece) costs at most **two days** of
   the typical user's current income, and three days at the very most;
   the next island level is shown as a short line ("Ada 6 için: 2 seviye
   daha"), never a timer.
3. **Something new every day or two.** Across days 1 to 60 no window of
   three tended days passes without a level, an island level, a resident
   heart, a decor piece or an island stage (section 6 shows it).
4. **The cap is a picture, not a lock icon.** A capped station shows its
   next level as a faint pencil sketch beside it, with "Ada 7'de" on the
   sign. No red, no padlock.
5. **A skipped day only pauses.** Floors count tended days, never in a row
   (A4).

Why both a floor and growth: the floor keeps the "morning change" (one
visible change a morning, game plan day 2) and stops an early spender from
rushing the island in a week; growth makes the island level something you
did, not something that happened to you.

## 4. Stations

### 4.1 Ladders (re-budgeted)

The home ladder is unchanged (1,403 seeds, 25 approved masters). The
harbor ladder drops from 1,385 to 777 seeds, because the harbor now opens
on day 3 instead of day 8 and Book One's other sinks (decor, the hive)
need room. The windmill and workshop come down a little so the full bloom
lands near day 60. Total for the eight stations at L5: **1,950** (was
2,788). Materials (section 7) gate seven levels.

| Station | Opens | L1 | L2 | L3 | L4 | L5 | Sum | Material |
|---|---|---|---|---|---|---|---|---|
| garden | IL1 (built) | 0 | 5 | 9 | 15 | 25 | 54 | none |
| tea stall | IL2 | 8 | 14 | 24 | 38 | 60 | 144 | L5: water |
| pond | IL4 | 15 | 25 | 40 | 60 | 85 | 225 | L4: moss; L5: light |
| workshop | IL6 | 30 | 45 | 65 | 90 | 120 | 350 | L4: keepsake |
| windmill | IL8 | 40 | 55 | 75 | 100 | 130 | 400 | L5: wax |
| bagel cart | IL3 | 12 | 20 | 32 | 48 | 70 | 182 | none |
| pier | IL5 | 20 | 32 | 48 | 70 | 100 | 270 | L5: keepsake |
| lighthouse | IL6 | 25 | 40 | 60 | 85 | 115 | 325 | L5: light |

Rate: unchanged, 0.02 of a seed an hour per built level, plus an **L5
completion bonus** of two extra levels of rate (so an L5 station runs as
seven levels). That is about +1 seed a day per finished station: small on
purpose; the payoff is what you see.

### 4.2 What every level looks like

Levels 1 to 5 are the painted masters (game design §5; home masters all
approved, harbor in batch 21). Levels 6 to 10 are mastery (section 9):
mostly code (light, particles, sound) plus one small painted overlay,
and a golden master at L10. Every level-up plays the **level-up card**
(section 4.4).

| Station | L1 | L2 | L3 (style choice) | L4 | L5 (complete) |
|---|---|---|---|---|---|
| garden | three sunflowers in a bed | picket fence, two more | watering can, seedlings | sunflower arch with bunting | one giant sunflower that follows the sun |
| tea stall | counter, kettle, two tulip glasses | striped awning | two stools and a table; rose stripes or İznik blue | string lights | tiled roof, geranium, a flag |
| pond | small pond, pebbles | lily pads | reeds and a blossom | wooden dock, moss on the stones | floating lanterns |
| workshop | shed and bench | wall of tools | wind vane; red or green shutters | chimney, an old restored clock (the keepsake) | big gear sign |
| windmill | stone mill, bare sails | cream sail cloths | sacks of seeds; plain or painted sails | lanterns along the cap | flag and window boxes with wax-sealed jars |
| bagel cart | cart with a pile of simit | sun umbrella | simit pole; red or blue umbrella | a bench for regulars | a little kiosk with a flag |
| pier | planks and posts | lantern post | the little ferry moors | bench and two tea glasses | bunting, a found ship's bell |
| lighthouse | striped tower | lit lamp room | balcony all around; red or blue stripes | slow warm beam at night | flag and a garden at its foot |

What each level adds besides the picture:

| Level | Light | Motion | Sound |
|---|---|---|---|
| L1 | none | idle (steam, a turning wheel) | one soft loop when on screen |
| L2 | none | the resident appears if assigned | |
| L3 | | style choice (free, changeable any time) | a second layer in the loop |
| L4 | **night light**: the station's lit overlay or code glow | a second idle motion | |
| L5 | warm rim light at dusk | **signature animation** (sunflower turns, ferry docks, beam sweeps) | the station's four-note motif, once per visit |

### 4.3 The L5 payoff (maxing one thing)

Finishing a station is the Cats & Soup "facility evolves" moment, made
bigger because there are only eight of them:

1. A five-second ceremony (skippable): the station glows, its resident
   comes out and does their thing, the motif plays, a stamp lands in the
   Seyir defteri ("Çay ocağı tamam").
2. The signature animation stays on for good.
3. The station's resident gets a heart (section 6) and a line from the
   duo.
4. +2 levels of rate (above).
5. It counts toward a pair (4.5) and toward the full bloom.

### 4.4 The level-up card

Tap a station: a native sheet shows the next level as a painted
before/after (current master, next master as a sketch until bought), the
price in seeds (and a material icon if any), what it adds in one line
("Gece ışık yanar"), and a single Build button. On build: dust puff,
cross-fade to the new master, the resident reacts, a short sting (under
two seconds). No confirmation step, no multi-buy.

### 4.5 Pairs: maxing two things together

| Pair | Stations at L5 | The shared scene (stays for good) |
|---|---|---|
| Çay ve simit | tea stall + bagel cart | mornings: Simit carries a tray of simit across the bridge and Mochi pours two glasses; a "Çay-simit" stamp |
| Su | garden + pond | a little stream runs from the pond to the giant sunflower; dragonflies |
| Değirmen | workshop + windmill | the windmill drives the gear sign by a belt; seeds trickle visibly into Pofu's jar on collect |
| Liman | pier + lighthouse | at night the ferry runs a slow loop under the beam; friends' boats dock lit |

Each pair also brings a short duo exchange.

## 5. The full bloom: maxing everything

When all eight stations reach L5 (and IL9 is reached), the island reaches
**IL10, Tam Çiçek**. Typical user: about day 59 with rounds, day 67
without (band to test: 55 to 70).

- **The ceremony (one evening, about 20 seconds, once):** at dusk every
  lantern on both islands lights in order from the garden to the
  lighthouse; all residents gather on the lawn; the giant sunflower opens
  a second, golden head; Gezgin circles the island once; the hill gate
  opens.
- **A new area, the hilltop (*Tepe*):** a terrace above the windmill
  reached by the hill path, with Pofu's lookout (a bench and a telescope
  where night content lives later), and the season stage (where each
  season's set and visitor appear). Book Two add-ons are built here.
- **The island hums:** stations produce +25 % for good (about +5 seeds a
  day), which pays for mastery levels.
- **Mastery opens:** station cap 6 (section 9).
- **Keepsakes of the moment:** a golden jar skin and a "Tam Çiçek"
  stamp; the app icon may switch to the bloom variant (setting, off by
  default).

Smaller full-set moments on the way: **Ayçiçeği complete** (the five home
stations at L5: the island's flower border blooms gold, the bees arrive if
the hive is not there yet), **İskele complete** (the three harbor
stations: the harbor bell rings at noon and a flag line crosses the
bridge).

## 6. Residents (Cats & Soup assignment, without the gacha)

The home residents arrive through story, never by purchase or chance,
and stay forever. Residents of healed islands **visit and go back**; they
do not move in (register H8). Each station has one work slot (two at L5).
A resident can work any station and can be moved at any time for free; at their favourite
station they give +50 % to that station's output, elsewhere +25 %. A
working resident animates at the station; an idle one wanders the lawn.

| Resident | Arrives | Favourite | Hearts unlock |
|---|---|---|---|
| Pofu | day 1 | garden (cannot be moved away from the island; can work any station) | his outfits by season |
| Mochi (bunny) | IL2 | tea stall | a scarf, then the İznik apron; lines about how you take your tea |
| Simit (kitten) and the goat | IL3 | bagel cart (Simit), pier (goat) | Simit's bell, the goat's hat |
| the frogs | IL4 | pond | a frog choir at dusk |
| Fındık (hedgehog) | IL6 | workshop | goggles; makes the style variants |
| a small resident from each main island (a visitor, not a lodger) | when that island is done | from the story plan (Koke's sprout: pond or garden) | their island's small decor piece |

**Hearts** (1 to 5) grow with days worked (cumulative, any station): at
3, 7, 14, 28 and 50 days; at their favourite station each day counts
double. Heart 3 unlocks an outfit, heart 5 a decor piece and a short
scene. Hearts never fall, there is no feeding, and an unassigned resident
loses nothing.

Why +25 %: at scale A a station level makes about half a seed a day; a
resident on a five-level station adds about 0.6 to 1.2 seeds a day. The
reason to place them is to see them work and to grow hearts, not the
number.

## 7. Materials from the wonder islands

Each main wonder island leaves one material when it is finished. After
stage 4 the island **keeps its game** (register G4, open question Q-6):
earned rounds (won by resisting) pay that island's material now and then
(one per three rounds, never more than one a day), and free play beyond
that pays nothing. `flow-game.md` §3 follows the same rule. Fillers leave
decor, never a material, so a random filler can never gate home. The one
exception is **Koke**, the
first filler and the arc's tutorial ([story map](story-map/book-one.md)
§9), which always comes on the first journey, so its moss can never gate
home by chance. Order and roles follow the
[Book One story map](story-map/book-one.md); there are no fixed days
("Kapı, gün değil"), so the days below are typical only.

| Material (TR) | From (story map order) | Typical first day | Used for |
|---|---|---|---|
| moss (*yosun*) | Koke (first filler, tutorial) | ~8 | pond L4; mastery L6 |
| water (*berrak su*) | Çağlayan (main 1) | ~14 | tea stall L5; the Su pair's stream; mastery L7 |
| light (*ışık*) | Revontuli (main 2) | ~20 | pond L5, lighthouse L5; mastery L9 |
| keepsake (*emanet*): the polished finds | Emanet (main 3; "atölyeye cilalı buluntular") | ~33 | workshop L4, pier L5; mastery L8 |
| wax and honey (*bal mumu*) | Arı, the home hive upgrade (after Emanet; not an island) | ~40 | windmill L5; the hive |
| moonstone (*ay taşı*, the map's Mehtap object) | the finale (Mehtap's full-moon night) | ~45 | mastery L10 (the golden level) |

Separate from these home materials, each main island also leaves one
piece on Nazlı's back and one lasting gift at home (the map's EVE HEDİYE;
[the roots](../design/island-undersides.md) §4).

Rules: materials are counted in single digits, shown as small painted
objects (world objects, ADR-0018), never bought, never expire, have no
cap, and are debited only by a build. If the story order changes, each
material moves with its island.

**The hive (gift station from Arı).** Arı is the map's home upgrade
("Kovan eve gelir"), arriving after Emanet; the hive opens at IL9 once it
has come (Saturday: honey).
Costs 1 wax plus 20 · 30 · 45 · 60 · 80 seeds (235). Levels: a straw
skep; two skeps and lavender; a painted hive box; a bee path over the
garden (code); a honey stand by the tea stall. L5 payoff: bees visit every
flowering station and the garden's flowers change colour with the
season. Not required for the full bloom.

## 8. Decor sets

The four decor spots (lawn, awning, pond edge, door; art plan "Decor
spots") open at IL7. A set is one piece for each spot. Pieces sit on
sockets, never free placement; any owned piece can go on any spot of its
family, swapped at no cost.

| Set | Arrives | Pieces from | Set effect (stays) |
|---|---|---|---|
| 1 Bahçe (bench, paper lanterns, toy sailboat, mailbox) | IL7 | seeds, 10 · 15 · 20 · 25 | the paper lanterns sway and glow at dusk |
| 2 Ada hediyeleri | as main islands finish | one gift per main island, as the story map's EVE HEDİYE (Çağlayan: the pond fountain flows; Revontuli: one more lantern on the bridge; Emanet: the Wednesday parcel and polished finds; Mehtap: the telescope on the Tepe), plus Koke's moss stool | a soft wind chime when a gift is tapped |
| 3 Sakinler | resident heart 5 | one piece per resident | residents visit each other's stations on calm evenings |
| 4 Liman | İskele complete | seeds, 20 · 25 · 30 · 35 | a fishing line and a lantern on the water at night |
| one per season (section 10) | with that season, first year | seeds, 20 to 40 each | the season's own light effect, all year |

Spending on decor is optional
and never needed for the full bloom, so a player who ignores decor loses
nothing but a lantern.

## 9. Mastery levels L6 to L10 (the long tail)

After the full bloom the station cap rises by **one level a season**
(cap 6 at the bloom, 7 at the next season change, up to 10), for
everyone, and it stays. So the tail is gentle: there is always one more
level per station to look forward to, and there is never a reason to
play more than a visit a day.

| Level | Cost per station | Material | What it adds (mostly code) |
|---|---|---|---|
| L6 | 120 to 160 | moss | a living detail (a cat on the roof, a second kettle, a heron) |
| L7 | 140 to 180 | water | a weather reaction (rain drips, steam, a rainbow in the spray) |
| L8 | 160 to 200 | keepsake | a story object from the old Bekçi set into the station |
| L9 | 180 to 220 | light | a new night light pattern |
| L10 | 200 to 250 | moonstone | **golden master** (one painted edit per station), a title, a heart for the resident |

Prices stay inside scale A's legible range (no number above 250). One
mastery level for all eight stations costs about 1,100 to 1,700 seeds, a
season's quiet income after the bloom (about 40 to 50 a day). **All eight
at L10 ("Altın Ada")** is the year's second transformation: the island
edge turns to gold at dusk and the hilltop telescope finds the last dark
star, timed to meet Mehtap's telescope (Book One's finale gift, story map), if the
player is there; it arrives on its own whenever they get there.

## 10. Seasons and add-ons (no FOMO)

Seasons follow the real calendar (hemisphere from the device region).

| Season | Look (code first, free, every year) | Visitor | Season set (first year, then always on sale) |
|---|---|---|---|
| Spring (Mar to May) | blossoms on the arch, storks over the harbor, Hıdırellez wish-ribbon tree 5 to 6 May | a stork pair on the windmill | Bahar: ribbon tree, tulip pots, kite, nest |
| Summer (Jun to Aug) | long golden evenings, fireflies on calm nights | a sea turtle at the pier | Yaz: hammock, ice-cream cart, beach umbrella, paper boat |
| Autumn (Sep to Nov) | leaves drift, lanterns on calm evenings | a migrating crane | Güz: pumpkin lanterns, chestnut stove, scarf on the sunflower, leaf pile |
| Winter (Dec to Feb) | snow on roofs and paths, the pond freezes (frogs skate) | a snow owl in the lighthouse | Kış: sled, snowman Pofu, salep pot, star string |

**The no-FOMO rules:** a season's look returns every year and needs
nothing; its set can be bought in any later month once released (it is
just shown first in its season); the visitor returns every year and its
gift (a decor piece) is given on the first visit of that season, whenever
that is; nothing has a countdown; a player who joins in year three gets
every set ever released.

**Edition content (Book Two and later)** plugs in through three sockets
only, so it never resets anything:

1. a **wonder island** (new story), which brings one material, one
   resident and one gift to home;
2. a **hilltop add-on**, a small station of three levels built on the
   Tepe (Fanus: a glass greenhouse; Çömlek: a kiln by the workshop),
   built with seeds; Fanus and Çömlek are Book One fillers (story map),
   so these add-ons are their later-book growth, not their arrival.
   Mehtap's telescope on the Tepe is Book One's finale gift, not an
   add-on;
3. a **decor set**.

## 11. The timeline

### 11.1 Days 1 to 60 (the typical user, with rounds)

Model: the published daily income (week 1 about 19 with rounds, day 60
about 46), three visits a day, the cheapest open level bought first,
island floors and material days as above. Without rounds everything after
week 2 is two to eight days later (full bloom day 67).

| Day | Seeds/day | Built (levels) | Island level | Also new that day or the day before |
|---|---|---|---|---|
| 1 | 15 | garden 2 (2) | 1 | Pofu wakes; two garden rounds |
| 2 | 19 | tea stall 1, 2 (4) | **2** | Mochi moves in; the morning change starts |
| 3 | 19 | garden 3, bagel cart 1 (6) | **3** | fog lifts: İskele, Simit and the goat |
| 4 | 19 | pond 1 (7) | **4** | the island widens; the frogs |
| 5 | 19 | bagel cart 2 (8) | 4 | Koke rumour |
| 6 | 19 | tea stall 3: style choice (9) | 4 | Koke arrives |
| 7 | 19 | (saving) | 4 | week page; Mochi heart 2 |
| 8 | 27 | pond 2, garden 4 (11) | **5** | Koke wakes: moss, Koke's sprout starts to visit; fireflies |
| 9 | 27 | pier 1 (12) | 5 | |
| 10 | 27 | bagel cart 3 (13) | 5 | Çağlayan arrives |
| 11 | 27 | pier 2 (14) | 5 | Çağlayan stage 2 |
| 12 | 27 | (saving) | 5 | Çağlayan stage 3 |
| 13 | 27 | tea stall 4: string lights (15) | **6** | back terrace; Fındık moves in; path lamps |
| 14 | 27 | lighthouse 1 (16) | 6 | waterfall restored: water |
| 15 | 30 | workshop 1 (17) | 6 | |
| 16 | 30 | lighthouse 2 (18) | 6 | Revontuli arrives |
| 17 | 30 | pond 3 (19) | 6 | |
| 19 | 30 | workshop 2 (20) | **7** | decor spots, set 1; the island melody |
| 20 | 30 | **garden 5** (21) | 7 | first L5 ceremony; Revontuli done: light (Olta follows) |
| 21 | 30 | bagel cart 4 (22) | 7 | a decor piece (bench) |
| 23 | 34 | pier 3: the ferry (23) | 7 | Çanlar (filler) may drift in |
| 25 | 34 | lighthouse 3 (24) | 7 | |
| 26 | 34 | pond 4 (25) | 7 | Mochi heart 4 |
| 28 | 34 | **tea stall 5** (26) | 7 | second L5 |
| 30 | 34 | workshop 3 (27) | 7 | Emanet arrives |
| 32 | 34 | **bagel cart 5** (28) | **8** | **pair Çay ve simit**; windmill slot; birds |
| 33 | 34 | windmill 1 (29) | 8 | Emanet done: keepsake |
| 35 | 34 | windmill 2 (30) | 8 | decor set 1 complete (lanterns) |
| 37 | 34 | pier 4 (31) | 8 | Arı: the hive comes home |
| 39 | 34 | windmill 3 (32) | 8 | |
| 42 | 34 | lighthouse 4: the beam (33) | 8 | Arı's first honey: wax |
| 44 | 39 | **pond 5** (34) | **9** | **pair Su**; the hill gate; the hive slot |
| 45 | 39 | hive 1 | 9 | the finale (Mehtap, full moon): moonstone |
| 46 | 39 | workshop 4 (35) | 9 | |
| 49 | 39 | **pier 5** (36) | 9 | |
| 51 | 44 | windmill 4 (37) | 9 | |
| 54 | 44 | **lighthouse 5** (38) | 9 | **pair Liman**; İskele complete |
| 57 | 46 | **workshop 5** (39) | 9 | |
| 59 | 46 | **windmill 5** (40) | **10** | **pair Değirmen**; Ayçiçeği complete; **Tam Çiçek** |
| 60 | 46 | | 10 | the hilltop; mastery cap 6 |

Gaps: before day 40 no more than two days pass without a build; after
it, levels take two to three days and the gaps are filled by island
stages, hearts, decor pieces and the hive (shown in the last column).
Decor and hive spending, not in the model, move the bloom by a few days
(band 55 to 70).

### 11.2 After day 60 (the long tail)

| When (typical) | What lands |
|---|---|
| days 60 to 70 | the hilltop; hive L2 to L5 (the bees); decor sets 3 and 4; residents' heart 5 scenes |
| next season change | mastery cap 7; the season set and visitor; Book Two's first island (Fanus) with its hilltop add-on |
| each six weeks | one wonder island, one hilltop add-on, one mastery level for every station, one season set |
| about 9 months | all stations at L10, **Altın Ada** (Book One's finale, Mehtap, came near day 45) |
| year two | Kitap opens (game plan §6); seasons return with new sets; nothing old is reset |

Nothing in the tail is a daily obligation; a missed month costs nothing
but time.

## 12. Implementation plan

### 12.1 PofuCore (data model and tests)

1. `IslandLevelRule` (`tendedDayFloor`, `growth`, `opens: [StationID]`,
   `stationCap`) and `ArchipelagoCatalog.islandLevels`, replacing
   `homeStageTendedDays`; `StationLedger.islandLevel` derived from growth,
   monotonic; `BuildError.capped(level:)` beside `notOpen`.
2. Station ladders re-budgeted (4.1); `StationSpec.levelMaterials:
   [MaterialID?]`; `levelCosts` extended to 10 for mastery;
   `seasonCap` raises the cap after the bloom.
3. Retire the Yıldız, Kaplıca and Kitap station islands (game plan §10);
   the harbor opens with IL3 (tended day 3).
4. `MaterialID` and a material balance on the ledger (credit by island
   completion and capped round drops; debit only by `build`).
5. `ResidentID`, `ResidentRoster` (moved in, assignment, days worked,
   hearts); output multiplier per station.
6. `DecorSet`, `DecorPiece`, owned and placed pieces, set completion.
7. `Milestone` events derived from state (station complete, pair, island
   complete, full bloom, mastery, Altın Ada) for the UI and story beats.
8. Tests: island level and every count monotonic (A4); no dead end at
   any island level (rule 1, for every reachable state); the cheapest
   open thing at most two days of typical income through day 60; full
   bloom in 55 to 70 for `typical`; a build or milestone in every three
   tended days through day 60; materials and residents never touch the
   gate (A13, extend `SeedsNeverBuyTimeTests`); scale A bands re-banded.
9. Regenerate `content/stations/*.yaml` from code; update
   [economy](economy.md) to the new ladders.

### 12.2 Art (Codex queue, concept first)

Ordered; each a pilot of one or two before the rest.

1. **Concept:** one wide sheet, the island at IL1, IL4, IL6, IL8 and IL10
   (same camera), so the founder sees the whole growth at once.
2. **Concept:** the full bloom keyframe and the hilltop terrace.
3. Harbor ladders (batch 21, already queued: pier and lighthouse L1 to
   L5).
4. Island level edits of the base plate (the terraces, the hill path,
   the gate, the hilltop), one edit per IL that changes the land.
5. Residents at work: one pose per resident per favourite station
   (Mochi, Simit, the goat, Fındık, the frogs), then their heart 3
   outfits.
6. Materials: six small painted objects.
7. Pair scenes: the four overlays (tray, stream, belt, ferry).
8. Decor sets 1 (the pilot four) and 4; set 2 comes with each island's
   batch.
9. The hive L1 to L5.
10. L3 style variants for the five stations without one.
11. Season sets (one per season, before its first season).
12. Golden L10 edits (eight), last.

Light, particles, glow, beams, snow and leaves are code first (art plan
"Day and night: code first").

### 12.3 Build order

| Phase | Ships | Needs |
|---|---|---|
| A | island level, caps, re-budget, materials and residents in the model, tests | code only (now) |
| B | the level-up card, the capped sketch, IL banner, L5 ceremony | home view; existing masters |
| C | residents: assign sheet, working poses, hearts | art 5 |
| D | materials with the wonder-island model and Koke | game plan §10 step 3; art 6 |
| E | decor spots and sets, pairs | art 7, 8 |
| F | full bloom, the hilltop, the hive | art 2, 4, 9 |
| G | seasons, mastery, edition sockets | art 11, 12 |

A and B go into the playable build v1 (the founder asked for levels he
can upgrade); C onwards follow the dogfood.

## 13. Open questions (recommendation first)

1. **Full bloom around day 60** (after the book's finale near day 45).
   Alternative: the bloom at the book's end (cheaper harbor, about day
   45). Recommend day 60: the story finale and the home finale should not
   compete, and day 60 answers "what comes after day 50".
2. **Mastery cap rises one level a season.** Alternative: no cap after
   the bloom. Recommend the season cap: it keeps every station growing
   together and gives each season a home reason.
3. **Home residents move freely between stations, no stars.** Alternative: fixed stations.
   Recommend free moves: it is the Cats & Soup joy without its gacha.
4. **The harbor re-budget (1,385 to 777).** Recommend yes; it opens on
   day 3 now.
5. **Real-calendar seasons.** Alternative: seasons counted from the
   player's start. Recommend the real calendar: Hıdırellez, snow at
   New Year and friends seeing the same season.
