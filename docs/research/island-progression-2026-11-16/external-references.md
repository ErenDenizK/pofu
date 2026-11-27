# External references: floating-island map, flying companion, upgrade feel

Gathered 2026-11-16 by web search plus page fetches. These are references, not recommendations; the team copies none of them.

Confidence tags:
- **[read]** I fetched the page and the facts below come from its text.
- **[snippet]** Only a search-result summary was seen. Treat it as a lead and open the page before relying on it.
- **[secondary]** Fan wiki, guide or press recap, not the developer.

Gaps up front:
- No source gave concrete numbers for how large or how far apart destinations sit on a phone screen. Only the generic minimum tap sizes (principles 1 and 2) are firm.
- No developer talk was found on how a ridden or companion flyer grows or levels. The growth and ride references are indirect.
- The GDC Vault talks I found (Monument Valley art, Sky) are behind a paywall, so they are listed only as leads.

---

## A. World map, journey and overworld screens

**A1. Mobile game map formats (Candy Crush, Cookie Jam, Bubble Witch Saga 2)** [read]
- Author and date: Junxue Li, Game Developer, 2014-11-19.
- What it does: compares four map formats.
  - "Small Island": separate islands, each a landmark with a path around it.
  - "Big Island": each island floats in air or sea and holds 10 to 20 small levels. A new island is added to add levels.
  - "Vertical Scroll": regions stacked vertically, left-right locked, no zoom, about one screen per region. Seams between regions are blended with gradients or mists.
  - "Traditional": a natural world map that "could easily reach 3x3 full screen size" and needs zoom.
- Source: https://www.gamedeveloper.com/production/mobile-game-maps-which-format-is-right-for-you
- Why it matters: it is the one game-specific source on floating islands as map units and on the trade-off between fitting one phone screen and zooming.

**A2. The Legend of Zelda: Skyward Sword, Skyloft as a hub and the sky as a course-select screen** (Nintendo EPD, Wii, 2011) [read]
- Source: Iwata Asks, Vol. 5 "The Dense Sky and Town", https://www.nintendo.com/en-gb/Iwata-Asks/Iwata-Asks-The-Legend-of-Zelda-Skyward-Sword/Vol-5-The-Dense-Sky-and-Town/3-A-Town-Designed-to-Function/3-A-Town-Designed-to-Function-204444.html. The page is undated; the interview series ran around 2011.
- What it does:
  - Iwata says the "sky functioned like a course selection screen, and later it became a town called Skyloft".
  - The hub is "a kind of home base that you always come back to after having accomplished something" (Iwamoto).
  - The bazaar sits in the centre of town because walking everywhere "would take time and be a hassle".
  - There are multiple entrances, and shops sit near each other (Hisada).
- Why it matters: it states the home-base-plus-sky-travel structure in the designers' own words.

**A3. Sky: Children of the Light, touch controls and flight over clouds** (thatgamecompany, iOS first, 2019 to 2020) [read]
- Source: Apple Developer, "Behind the Design: Sky: Children of the Light", 2020-07-17, https://developer.apple.com/news/?id=zm47it7t
- What it does:
  - Players fly through cloudy, dreamlike realms.
  - The team tried several approaches, including a full flight simulator, before settling on "a simple set of familiar controls".
  - Controls are subtle rings in the screen corners that expand and contract to show range and speed.
  - A two-hand mode was added after launch.
  - Goal: controls "better than a real controller" that do not block the art.
- Why it matters: a painted cloud-sky game that cut its touch controls down to a minimum so the picture stays visible.

**A4. Pile Up!, building upward above the clouds** (Karaköz, Pile Up!, 2024) [read]
- Source: Joel Couture, Game Developer, 2024-03-21, https://www.gamedeveloper.com/design/the-complexities-and-delights-of-building-up-into-the-sky-in-pile-up-
- What it does:
  - Cities grow upward, not outward.
  - Each island has its own colour scheme and atmosphere.
  - The third island is "literally above the clouds".
  - Houses keep basic shapes "to keep the cities look unified".
  - Placement uses OutCubic easing and squash-and-stretch.
- Why it matters: separate islands that each look different but share one shape language, in a sky setting.

**A5. Spiritfarer, home base plus islands, with a cut flying-boat upgrade** (Thunder Lotus, PC and console, 2020) [read for the flying boat; the rest is secondary]
- Source: Screenhype interview with Thunder Lotus, 2021-10-07, https://www.screenhype.co.uk/spiritfarer-interview-thunder-lotus-games/
- What it does:
  - The ship is both home and transport, and the layout is reshaped over the game.
  - There are "plenty of different islands" with different design styles.
  - A flying boat was planned as the final upgrade, opening flying islands and mountain tops. It was cut because the game was "waaaaay too long already".
- Why it matters: a home that is also the vehicle, and a developer's own note that a final "now you can fly" upgrade was wanted.

**A6. Pokémon Sleep, an island chain opened one at a time** (Select Button / The Pokémon Company, iOS and Android, 2023) [secondary]
- Source: Bulbapedia (Greengrass Isle, https://bulbapedia.bulbagarden.net/wiki/Greengrass_Isle) and Serebii (https://www.serebii.net/pokemonsleep/locations/greengrassisle.shtml). Not a developer source, and I saw no screen layout.
- What it does: the player starts on one island with its own Snorlax. Further islands unlock later. An "Expert" version of an island unlocks after reaching a rank on it. Each island has a short blurb on the select screen.
- Why it matters: a live phone game with few islands, each unlocked in turn, and a harder return version of the first one. Open the app itself to judge the layout.

**A7. Animal Crossing: New Horizons, travel to other islands by seaplane** (Nintendo, Switch, 2020) [secondary]
- Source: Nookipedia, https://nookipedia.com/wiki/DAL. No developer interview was found.
- What it does: the airport is a fixed building on the player's coast and is the gateway to visiting other islands and to inviting others.
- Why it matters: a fixed departure point on the home island, as in the travel-station idea.

**A8. Cozy Grove, an island that fills with colour** (Spry Fox, iOS, Android and PC, 2021) [read]
- Source: Game Developer Q&A with David Edery, 2021-03-29, https://www.gamedeveloper.com/design/q-a-designing-for-empathy-in-wholesome-life-sim-i-cozy-grove-i-
- What it does:
  - The world starts mostly uncoloured.
  - Helping the ghosts restores colour, makes trees fruit and flowers bloom, and the harvest feeds crafting.
  - Story is released "in small pieces over several months", like following a web-comic.
- Why it matters: a before/after on the whole island (grey to colour), with progress paced over months.

**A9. Alto's Odyssey, a painted, minimal world** (Snowman, iOS, 2018) [read]
- Source: Joel Couture, Game Developer, 2019-01-28, https://www.gamedeveloper.com/business/road-to-the-igf-team-alto-s-i-alto-s-odyssey-i-
- What it does: lead artist Harry Nesbitt asks "how far can you simplify a form until you're left only with its essence". Slowly shifting lunar cycles hint at a larger world. The environments are "the main character".
- Why it matters: the closest tonal reference for a calm, painted mobile world. It gives no camera or touch numbers.

**A10. Dorfromantik, asset readability from a fixed viewpoint** (Toukana Interactive, 2021 to 2022) [read]
- Source: 80.lv interview by David Jagneaux, 2026-05-25, https://80.lv/articles/how-dorfromantik-expands-its-cozy-world-through-minimalist-design
- What it does:
  - Every asset is designed for the one fixed, slightly top-down viewpoint.
  - "The silhouette needs to be clear and the asset has to read well from the in-game perspective."
  - Palettes are checked in grayscale for value contrast before hue and saturation are added for mood.
- Why it matters: a stated test (silhouette plus grayscale) for reading small painted objects at a fixed distance.

---

## B. Ridden and companion flying creatures

**B1. Zelda: Skyward Sword, the Loftwing** (Nintendo EPD, Wii, 2011) [read]
- Source: same Iwata Asks page as A2.
- What it does: Hisada says they "prepared jump-off spots here and there around Skyloft". Link "jumps down from there, whistles, and his Loftwing swoops in, and he can go all sorts of places". Summaries add that the team worked hard to make the bird a comfortable ride (not in the text I fetched).
- Why it matters: shows how a creature picks you up and carries you, from fixed calling spots to a short, repeatable ride.

**B2. Whale in the High (WITH)** (Gravity, mobile idle game, announced 2022) [read]
- Source: Indie Games Plus, Jupiter Hadley, 2022-11-17, https://indiegamesplus.com/whale-in-the-high-preview/
- What it does: you watch a small town on a flying whale's back, built near the blowhole. Upgrading areas around the map is "a primary way of playing", and upgrades change the world and add features. The article says nothing about camera or how the whale travels.
- Why it matters: the closest match to a cloud whale carrying a settlement. It was pre-release when written, so check whether it shipped.

**B3. Neva, a companion that grows through four seasons** (Nomada Studio, 2024) [read]
- Source: MobileSyrup interview with technical director Adrian Cuevas, 2024-12-20, https://mobilesyrup.com/2024/12/20/neva-nomada-studio-adrian-cuevas-interview/
- What it does:
  - The wolf grows over four seasons, and players "see how the growth of Neva transmits this change in the relationship".
  - Animation is traditional (hand-drawn), so "it's really hard to interpolate movements".
  - The team had to "do the NavMesh [AI] and try to make it feel alive". One person worked on the wolf's AI from day one.
  - They considered a bird because it was easier to move, but a wolf connected better.
- Why it matters: companion growth shown as relationship change, and the cost of making a hand-animated creature move in a game.

**B4. The Last Guardian, Trico** (Sony JP Studio / genDESIGN, PS4, 2016) [read, partial]
- Source: genDESIGN, Projection Trico staff interview (undated; exhibition 2018), https://www.gendesign.co.jp/qa_01/interview01en.html
- What it does: Ueda says the team had "a pretty good AI for Trico's behavior". The creature reacts to objects, sounds and onlookers in real time.
- A separate search summary quotes lead animator Tanaka on procedural animation and keyframe-only work (no mocap). I did not confirm that on the page [snippet]: https://gendesign.co.jp/qa_01/interview04en.html or the sibling pages.
- Why it matters: a companion that feels alive through behaviour, not only animation.

**B5. Sky: Children of the Light, flight tied to light** (thatgamecompany, 2019) [snippet / secondary]
- Source: GameSpot review, https://www.gamespot.com/reviews/sky-children-of-the-light-review-flying-free/1900-6417262/. The summary says flying draws light from your cape and limits aerial freedom.
- Why it matters: flight is rationed by a resource, not free. Check the review text.

**B6. Flower (thatgamecompany, 2009)** [snippet]
- Source: Game Developer, "GDC Europe: Thatgamecompany's Santiago On Flower's Emotional Search", https://www.gamedeveloper.com/game-platforms/gdc-europe-thatgamecompany-s-santiago-on-i-flower-i-s-emotional-search
- What it does (per summary): the player steers petals on the wind with simple controls and no losing conditions. It was framed as a "feel-good game".
- Why it matters: calm, no-fail motion as the whole game feel. Unverified; open the page before use.

**B7. World of Warcraft: Dragonflight, dragonriding** (Blizzard, 2022) [secondary]
- Source: Wowpedia, https://wowpedia.fandom.com/wiki/Dragonriding (a wiki, not a Blizzard post).
- What it does (per the wiki): the Dragon Isles were redesigned with more height and cloud layers to suit riding, and flight is momentum-based with upgradable skills.
- Why it matters: a world shaped to suit a mount. Treat as a lead.

**B8. Mika and the Witch's Mountain, delivery by flying broom** (Chibig, 2024) [read, thin]
- Source: Chibig blog, 2024-11-21, https://chibig.com/ghibli-kikis-delivery-service-mika-witchs-mountain/
- What it says: delivery by flying broom is the core mechanic, and flying is described as a design challenge needing "a fun and satisfying experience". It gives no flight, camera or upgrade detail.
- Why it matters: the nearest cozy Ghibli-style flier, but the page offers no mechanics.

---

## C. Making each upgrade feel big

**C1. Isometric city-builder art guide: silhouette progression** (Sunstrike Studios, article updated 2026-05-18) [read]
- Source: https://sunstrikestudios.com/en/blog/isometric-city-builder-art/
- What it says: treat upgrades as art content, and a level-1 house and a level-5 mansion should belong to one visual family. "Use silhouette progression as the primary visual signal." Tiers share a palette, roof material and window style, with ornament added. A wider zoom range calls for simpler silhouettes at all levels. It gives no tier count or measurable criteria.
- Why it matters: a plain statement of "silhouette first, detail second" for upgrade ladders. It is a studio blog, not a postmortem.

**C2. Clash of Clans, Builder Base 2.0** (Supercell, mobile, 2023) [read]
- Source: Supercell blog, 2023-04-04, https://www.supercell.com/en/games/clashofclans/blog/news/builder-base-2-0-staying-small-going-deeper-2
- What it says: players find later Builder Halls less fun. "Unfortunately as bases get bigger and bigger this feeling is lost". From Builder Hall 6 a second buildable area is added, with its own key building, within one connected base.
- Why it matters: a developer naming the late-ladder problem and answering it with a new area, not more of the same.

**C3. Animal Crossing: New Horizons, Resident Services tent to building** (Nintendo, 2020) [secondary]
- Source: iMore guide, https://www.imore.com/animal-crossing-new-horizons-how-upgrade-resident-services-tent-building, and Nookipedia, https://nookipedia.com/wiki/Resident_Services. The guides disagree on the resident count (3 or 5) and are not from Nintendo.
- What it does: after enough residents move in, the tent closes for a day and the building opens the next. Isabelle joins Nook and the building adds functions such as moving your home.
- Why it matters: an overnight before/after with a new function, a classic staged reveal. Check the in-game sequence.

**C4. Spiritfarer, a named ladder of ship sizes** (Thunder Lotus, 2020) [secondary]
- Source: Albert's Shipyard guide, https://guidestrats.com/spiritfarer-alberts-shipyard/ and the ship upgrades guide https://indiegameculture.com/guides/spiritfarer-ship-upgrades-guide
- What it does (per guides): size upgrades are named, from "The Exploring Krill" (16x15) up to "The Fearless Whale" (66x67). Whether the look changes is not stated.
- Why it matters: a ladder with names that grow from small to large, ending in a whale. A guide, not the developer.

**C5. Pile Up!, placement as the reward** (Karaköz, 2024) [read]
- Source: same as A4.
- What it says: the team wanted "every placement feel satisfying and exact", using OutCubic easing, VFX that stress "a perfect placement", and squash-and-stretch.
- Why it matters: the moment of placing or upgrading is built from ease curve, squash and VFX, not a larger asset.

**C6. Dorfromantik, small feedback on the most frequent action** (Toukana Interactive, 2021) [read]
- Source: Game Developer interview with Timo Falcke, 2021-07-19, https://www.gamedeveloper.com/disciplines/sparking-joy-through-tile-placement-in-idyllic-village-builder-i-dorfromantik-i-
- What it says: "the interaction the player does the most has to feel as satisfying as possible." Small animations and sounds add weight, but "no sound or animation would disrupt the calming atmosphere".
- Why it matters: a stated limit on feedback intensity in a calm game.
- Also, from the 80.lv piece (A10): a ruin tile was turned into "a large castle in its prime", a before/after of a place at its best.

**C7. EXOR Studios, per-level building models** (Last Train Home / base-builder, dev blog) [snippet]
- Source: https://www.exorstudios.com/blog/building-level-models-refresh. Summary says buildings placed in large numbers (energy storage, walls) got a model per level, and the rest got a numbered plate, which they called a middle ground that "could be done better".
- Why it matters: a developer admitting the number plate is a weak substitute for a look change. Open the page to confirm which game and the wording.

**C8. Player feedback on upgrades with no visible change** [snippet]
- Smoldering City thread asking for a visible change after each upgrade track, two or three times per track: https://feedback.eremitegames.com/b/suggestions-feature-requests/visual-upgrades-in-smoldering-city/
- A State of Decay 3 thread notes an outpost looks the same at level 2: https://redlib.belloworld.it/r/StateofDecay3/comments/1fxuxg3/when_upgrading_an_outpost_its_appearance_should/lqsr293/?context=3
- Why it matters: player forums, not developers. They show what "no visible change" looks like to the people it happens to.

**C9. Clash of Clans, Town Hall level looks** [secondary, low confidence]
- Source: 1337wiki, https://clash-of-clans.1337wiki.com/?p=67 (fan wiki, no date). It says the Town Hall shows substantial visual changes at each stage. I found no Supercell statement on this.
- Why it matters: only as a lead for a screenshot ladder.

---

## Design principles that sources state explicitly

1. **Tap target size, Apple.** "Create controls that measure at least 44 points x 44 points so they can be accurately tapped with a finger." Apple Developer, "UI Design Dos and Don'ts", https://developer.apple.com/design/tips/ [read]. The same page says text should be at least 11 points.
2. **Tap target size, Google.** Material Design 3 treats 48x48dp as the minimum target even when the visible icon is smaller, with about 8dp between neighbouring targets. This is a paraphrase from a search summary of m3.material.io (grids and spacing, chips pages), not a verified quote [snippet]. Android's help page says the same: https://support.google.com/accessibility/android/answer/7101858
3. **Silhouette first.** "Use silhouette progression as the primary visual signal." Sunstrike Studios, 2026 [read]. And: "The silhouette needs to be clear and the asset has to read well from the in-game perspective." 80.lv on Dorfromantik, 2026 [read].
4. **One family across the ladder.** Tiers keep "same palette, same roof material logic, same window grammar", with ornament added as they rise (Sunstrike, 2026, [read]). Pile Up! likewise kept houses to basic shapes "to keep the cities look unified" (Game Developer, 2024, [read]).
5. **Feedback on the most frequent action, kept calm.** "the interaction the player does the most has to feel as satisfying as possible", while "no sound or animation would disrupt the calming atmosphere". Toukana, Game Developer, 2021 [read].
6. **Late ladders lose their feel.** "Unfortunately as bases get bigger and bigger this feeling is lost." Supercell on Builder Base, 2023 [read].
7. **Phone touch should stay out of the picture.** Sky's team wanted controls "better than a real controller" that do not block the graphics (Apple Developer, 2020, [read]).
8. **Phone map format.** Per Li (2014, [read]): vertical-scroll maps lock left-right, allow no zoom, and fit narrow phones. Big-Island maps hold 10 to 20 levels per floating island. This is the article's description, not a quoted rule.

## Strongest leads, not verified

- GDC Vault, "The Art of Monument Valley" (ustwo, GDC 2018): https://gdcvault.com/play/1025003/The-Art-of-Monument-Valley, paywalled.
- Jenova Chen, GDC 2022 recap, PocketGamer.biz, 2022-03-24: https://www.pocketgamer.biz/news/78479/gdc-jenova-chen-hard-lessons-pivoting-pcconsole-mobile/. It covers Sky's pivot to mobile and "social theme park" framing, not touch or flight.
- The Last Guardian procedural animation talk (genDESIGN slides), referenced in search results but not confirmed.
