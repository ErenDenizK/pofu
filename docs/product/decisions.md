# Decisions register

**What this is:** the one place that says what is decided in Pofu, who
decided it, and what is still open. Built on 2026-11-07 from an audit of
every thread: the founder's 60 messages from 2026-11-03 to 2026-11-07
(verbatim, from the session transcripts), his Pofu Hub answers, notes and
scores, [the founder log](founder-input.md), the
[Book One story map](story-map/book-one.md) (both pages), every design and
product doc, the code on `main` and the art takes.

**How to read a row:**
- **F** means the founder said or chose it. His words are quoted.
- **L** means it is a lead decision. It is in force but reversible, and he
  has not confirmed it. Big L items are put to him.
- **Q-n** means it is open, and the number is the question on the
  2026-11-07 sheet (§10).
- **FIX** means a doc or the code says something that is not true. The
  right version is given.

**Rule:** when a doc disagrees with this register, this register wins
until the doc is fixed. A founder answer moves a row from L or Q to F the
same day.

**On the story map's status:** the map is the lead's proposal ("ÖNERİ …
kurucu onayına"). The founder called it "elimdeki en iyi dokümantasyon"
but added "birebir uymak zorunda değiliz" (2026-11-07). So it is the base
we follow and depart from on purpose, row by row. It is not law.

## 1. Lasting product rules

| # | Rule | Status | Source |
|---|---|---|---|
| R1 | Seeds never buy screen time; Pofu never dies | F, ADR-0015/0017; the map: "Tohum ekran süresi satın almaz. Pofu asla ölmez." | **FIX:** the built gate still lets seeds buy minutes on a third reach (`FrictionLadder` pay rung, `EconomyConfiguration.swift:155`, `HopView.swift:245`). Removing it is the top app item (§9) |
| R2 | Targets: Instagram, YouTube, TikTok | F (log 2026-11-02) | — |
| R3 | No new features for the free `Pofu` build or the Shortcuts path | F (log 2026-11-02) | — |
| R4 | Never ask a visual question without images; no PDFs for now | F: "Bir daha görselsiz sorma" (Hub, 11-03); "şu anlık bir PDF ihtiyacı yok" (11-06) | — |
| R5 | Anything shown to the founder is committed the same day | L (after the forgotten map, 11-06) | CLAUDE.md |
| R6 | A doomscroller must see the effect, in the game and the app | F: "çok doomscrollayan kişi de etkisini görmeli. Hem oyun hem uygulama tarafı." (11-06) | — |

## 2. Book One: the journey

| # | Decision | Status | Source and notes |
|---|---|---|---|
| S1 | Order: Ayçiçeği → Gezgin (early) → Koke → Çağlayan → Çanlar, Martı Kayası → Revontuli → Olta → Fanus, Pervane → Emanet → Çömlek, Arı (home) → Mehtap finale → Yakamoz, Yosun's letter | L (the map) | He endorsed the map as a whole, not each node |
| S2 | Four main islands (Çağlayan, Revontuli, Emanet, Mehtap) | F: "ana ada 4-5 tane gelebilir" (11-05) | — |
| S3 | Main islands and fillers are separate; Çanlar is a filler on a random day | F (11-05 06:14) | — |
| S4 | Yıldız, Kaplıca and Kitap are dropped | F: "Ha, kalkıyor bunlar, pardon." (11-05) | **FIX:** `content/` still lists `island-kaplica`, `char-pamuk`, `char-bulut` as planned, and game plan §6 names Kitap |
| S5 | Fillers: six (Koke, Çanlar, Martı Kayası, Fanus, Pervane, Çömlek) plus one seasonal (Leylek) | L | **FIX:** the map says "+7 filler, 1 mevsimlik", and story map §9.3 made Leylek "the seventh filler". Leylek is the seasonal card, and no seventh filler is defined. We do not invent one to hit a number |
| S6 | An act must really end (teasing is fine, no half story) | F (11-05 12:35) | — |
| S7 | Each new island is a little better than the last; the curve rises | F: "her yeni gelen öncekinden biraz daha iyi olacak" (11-03) | — |
| S8 | Islands start a little worse and end much better and livelier, at both ends; not a full ruin, not "a few lights came on" | F (11-05 22:22, 11-07) | Amplitude: **Q-3** |
| S9 | Different moods per island (scary fog, a scary sound, a ruin): a view, not an order | F (11-05 22:27) | — |
| S10 | The finale waits for the real full moon; Mehtap's door is timed so stage 3 lands a few days before it; fallback only past 7 days | L (story map §9.2) | Kept: it is the map's own tag |
| S11 | Two islands may run at once: the next island's rumour shows at the current main island's stage 3; at most one main island plus one filler is unhealed at a time | L | Answers his "birkaç tanesi aynı anda gidebilsin… abartmadan" (Hub, 11-02) |
| S12 | Koke's secret (the hill breathes, Book Two) stays hidden; at the finale "Uzakta Koke bir kez nefes alır" | F (Q-5 B, 11-07) | Built Koke stands up and "snores" at stage 4, so it gives the secret away |
| S13 | Ihlamur's lantern is fished up at Olta and rides to the finale | L (the map) | **FIX:** deep lore line 217 says it comes from Emanet |
| S14 | Söz 1 is read on the mill stone through spilled tea | L (the map) | **FIX:** code `caglayan.line.3` says "Duvarda yazıyor" (the wall) |
| S15 | Nazlı: two forms; form 1 faces the camera (her face turned to the pier hid it) | F (11-05 06:14, 20:09) | — |
| S16 | Keepsakes live on Nazlı's back; each main island leaves an EVE HEDİYE at home | L (the map) | His "Evet diyelim" (11-06 08:18) answered a different question: replaying a memory by tapping a keepsake. Moving the keepsakes from the roots to Nazlı's back was not shown to him. Low risk: it is the map's own picture |

### 2.1 Characters (names and species as the map draws them)

L, the map: Pofu (hamster), Mochi (lop bunny), Fındık (hedgehog), Simit
(ginger kitten), Nazlı (cloud whale), Yosun (tortoise), Damla (river
otter; player text "su samuru", since "samur" alone is a sable), Tuli
(white arctic fox), Boncuk (magpie), Nane (owl), Sumi (dormouse, Koke), Zil
(bell-ringer mouse), Zümrüt (glass frog), Kil (potter mole), Lale (old
stork), Ihlamur (the old keeper, never seen in Book One).
**FIX:** the code's Saturday "bee keeper" visitor goes (Arı's honey arrives
as an object). `char-nane`, `char-lale` and `char-kil` follow the map. Sumi
is missing from the Koke scene.

## 3. Islands: look and stages

| # | Island | Decision | Status |
|---|---|---|---|
| I1 | Çağlayan look (F, Q-1 A, 11-07: back to the map's plate; the stage concepts are picked on the Q-16 board) | The founder loved the batch-34 Çağlayan (the map's plate): "yeni Çağlayan çok güzel" (11-05 20:09). The game ships a different island from batch-43 (a stepped grey cliff, one pool), which he never saw beside it | **Q-1** (recommended: back to the map's plate) |
| I2 | Çağlayan water source (F, Q-2: spout for stages 0-3, Damla with a full glass on top at stage 4) | The map shows a plain stone spout in a cream boulder. **No otter statue appears on the map or in any take.** The otter-with-water picture is Damla's card (she pours her glass into the falls). The log recorded his memory as fact | **Q-2** (recommended: the spout for stages 0-3; at stage 4 Damla sits on top with a full glass) |
| I3 | Çağlayan stage 0 | The map's line: "havada donup kalmış bir şelale". The built stage 0 has a full, still pool instead | L: follow the map (frozen curtain, dry side pools, leaf boats aground) |
| I4 | Revontuli wound | The map has an ice island (cabin, lamp post, ice hole). batch-45 tried ruined towers on an earth plate | F (Q-4 C, 11-07): ice island + three toppled lantern posts, one rises per stage |
| I5 | Emanet, Mehtap | Follow the map plates, pushed at both ends (Q-3) | L |
| I6 | Water effects | Feasible in our stack (SwiftUI Canvas plus Metal `layerEffect`). The falls off the underside and the home fountain are already code. A one-day spike (`docs/research/water-2d.md`) comes before new water art. The water-source choice is taste, not tech risk | L |
| I7 | Undersides | Not every island needs one ("her adanın ihtiyacı yok zaten", 11-06). Çağlayan, Emanet and Revontuli get one | F (principle) + L (which) |

## 4. Island gameplay systems

| # | Decision | Status |
|---|---|---|
| G1 | Not every island needs a game: story, mini-game or upgrade, as long as each is fun; about three mini-games are enough | F: "3 tane falan mini oyunumuz olsa yeter" (11-03) |
| G2 | Three engines: place (garden), connect (flow), recall (listen and repeat) | L (follows G1) |
| G3 | Earned rounds: earned by resisting, between "earned" and "unlimited"; an island's game can loop endlessly | F: Hub q-earned-play A + "evet ve sınırsız arasında bir yerdeyim" |
| G4 | **Heal → live → upgrade** per main island. Heal: stage rounds, one stage a day on a resisted day. Live: after stage 4 the island keeps its game; earned rounds pay its material; free play beyond that pays nothing. Upgrade: three small, visible island upgrades bought with its material | **Q-6** (his "kazanmak durmasın" and "bu upgrade'lar") |
| G5 | Per island (proposal under G4). Çağlayan: leaf-boat flow boards; upgrades lily pads and frogs, a second wheel and a mill lantern, Damla's slide. Revontuli: flow plus light, a sauna-sit toy; upgrades a lantern path, a sauna bench, an ice slide. Emanet: "Kimin bu?", one parcel a day returned from three clues; upgrades a shelf bay, a bell and a queue, a parcel slide. Mehtap: moon-thread flow and star-joining; upgrades telescope views, a hammock, the moon pool reflecting home. Olta: fishing stays, one earned cast a day. Fillers get one act or toy each and no upgrades | Q-6 |
| G6 | Çömlek's merge game waits for an update after Book One (Book One keeps three engines) | L |
| G7 | Islands never pay seeds; each has its own material | F: Hub q-island-materials A |
| G8 | No game rounds at night | F: Hub q-night-rounds A, with the note "İsteyene 1 sakin tur için alternatifleri değerlendir" (still to answer: one calm bedtime round is a candidate) |
| G9 | **FIX:** `flow-game.md` §3 ("no replay") and `home-progression.md` §7 (rounds keep paying) contradict each other; G4 replaces both | — |

## 5. Home island

| # | Decision | Status | Source and notes |
|---|---|---|---|
| H1 | Home is the centre | F: "Asıl merkez ana ada zaten." (11-03) | — |
| H2 | Many things grow together, gently capped, with big payoffs and Cats & Soup level-ups; growth is visible step by step: shop, house, character, light, decor | F (11-05, asked five times) | **FIX:** on screen IL1-5 and IL8-10 look almost the same. All 16 growth pieces are code stand-ins (batch-65 merged manifests only). The tracker's "art for most steps" is wrong |
| H3 | The IL1-10 table, caps, eight stations, 1,950 seeds to Tam Çiçek | L (`home-progression.md`) | Built in `Archipelago.swift`. "10 levels" was his example ("10 tane yok, salladım sayıyı") |
| H4 | Home framing: the whole island on open, one tap to come close to Pofu | F (Q-7 C, 11-07) | Which home concept is the target: **Q-16** |
| H5 | The plate keeps its shape and is repainted at 5-6 levels, plus pieces, plus İskele on the right over a bridge | F (Q-8 C, 11-07); concept pick **Q-16** | **FIX:** the tracker calls the batch-57 strip "the target for every level", but it reshapes the plate, which `home-layout.md` §1.1 forbids, and its IL10 take was rejected |
| H6 | Home starts a little worse too (dusty wheel, pale grass, dim light), opening over IL1-3 | F (Q-9 B, 11-07) | He gave the rule for islands only |
| H7 | İskele joins the home frame on the right, over a bridge | L (the map's "Evin varacağı hal", home-layout §2) | **FIX:** the code still places the harbour as a separate isle (`IslandLayout.swift:160`) |
| H8 | Residents of healed islands stay home and **visit** (git-gel); they do not move in | F in spirit: "belki arasında git gel yapabilir" (11-05 16:24) | **FIX:** `home-progression.md` §2/§6 still has them moving in |
| H9 | Visitors: a daily draw, with the resident's own day likelier; quiet days are invitation days | F: "karakterler haftalık değil… günlük" (11-05) + L (weighting) | The map says "kendi gününde", so the built mix serves both. Thursday becomes a letter day, not Yosun |
| H10 | Seasons: real calendar for looks, plus a weekly small theme | **L, not F.** He said "bilmiyorum… değerlendirelim" (11-05 15:16) | **FIX:** `home-progression.md` "Founder decisions" misquotes him, and his "taşınma" meant a story character moving home, not station reassignment |
| H11 | Roots: the home underside grows a little every few levels (sprout, ladder, fireflies, lantern, vines, nest) | L | **FIX:** tracker §6.3 still says the roots keep keepsakes |
| H12 | Level-up must be flashy and lit, but later | F: "bunları sona bırakıyorum" (11-05) | The light ceremony is built (#240) |
| H13 | Decor on sockets only | L (ADR-0019) | The log has him wanting free decor spots (11-02, paraphrase). Revisit when decor is built |
| H14 | Map clue "ayçiçeği geceleri sise döner" | L: built as a night-only turn of the sunflowers toward the fog bank (code only) | — |

## 6. Look, light and night

| # | Decision | Status | Source and notes |
|---|---|---|---|
| V1 | The grade follows the time of day | F: Hub q-look A ("görsel iyileştirme ve daha fazla assetle çok daha iyi olur") | — |
| V2 | Less paleness: haze grows toward the background and falls toward the centre; objects keep their own colour | F (11-03, 11-05 twice) | L: clear midday contrast is every hour's base, and weather sits lightly on top. The light standard is enforced on production art (haze > 0.20 fails) |
| V3 | Fog may be real fog; even the bad state must be impressive | F (11-06 05:52) | — |
| V4 | Night needs its own art direction: light comes from real sources onto characters and ground (GI logic); the current system is not enough | F (11-05, 11-06) | **FIX:** the tracker says "built". In code the per-pixel relight is a spike that is off by default, and Pofu is still self-lit at night. Brightness: **Q-10**. A night ADR follows the answer |
| V5 | No hard-edged light | F (critique 11-06: "çapraz çizgi gibi kesiliyor") + L (rule) | **FIX:** the screen-haze shaft (`WeatherLayer.swift`, `ShaftShape`) is still a hard diagonal |
| V6 | "Pofu'nun vektör map'i köşeli": what he meant | F (Q-11 A, 11-07): the normal map | Rebake softer before relight goes default |
| V7 | Plate base: v2 with more thickness | F: Hub q-plate C | Island bases should be parts Codex fits, not patches (11-06) |
| V8 | Concept art is a target, not the game; harmony is tested with near-game concepts as background, decor and character | F (11-03, 11-06) | — |

## 7. The Door, the shield and the app

| # | Decision | Status | Source and notes |
|---|---|---|---|
| D1 | The wall must be a wow masterpiece, not a flat wall with plain text; every UI, menu and pop-up world-class | F (11-06) | — |
| D2 | Two places: Apple's shield (a fixed template: colour, ~60 pt icon, two labels, two buttons) and our in-app Door scene with the states Arrive, Breath, Choose, Boş ver, A minute, Hand-off. The wow goes into the Door | **Q-12** | He asked "Sonuç olarak bizim ekranımız değil mi?" and never answered the trade |
| D3 | The Door's look: **all three scenes (round door, halo isle, pier and sky) rotate** | F (11-07: "3 kapı da gözükebilir hani dönüşümlü olarak"; against the lead's A) | **FIX:** no doc says the Door is blocked on art. The batch-58 door came back at half resolution with its layers skipped, and `DoorScene` does not exist in code |
| D4 | Breath only past the daily threshold; one word "Boş ver" everywhere | L (ADR-0015, the Door) | **FIX:** the built gate breathes 5 s on every first open and says "Vazgeç". The shield subtitle says "vazgeçtin" |
| D5 | "Pofu'yla bir dakika": three times a day, 60 s | F: Hub q-minute A | — |
| D6 | Pofu's personality: sweet and lightly jealous; never shame, at most one tease a day, never at night | F: Hub q-personality B | L: humour comes from the situation; memes only if the founder or friends write them (he later called the meme lines "AI slop", per the log) |
| D7 | Sound: Pofu's tiny sounds on, ambience optional; procedural chord music welcome | F: Hub q-sound B | **FIX:** the tracker says "the world is silent", but a world sound pass is on main |
| D8 | Menus: glass and custom together | F: "camı da tamamen kaldırmayalım. Cam ve hani custom'ı birleştirmek… unique" (11-05) | F (Q-14 C, 11-07): round buttons and the top strip glass, panels paper. ADR-0020 and UI v3 turned every menu to paper, against his words |
| D9 | The bottom-right icon is very bad; flat menu icons are fine | F (11-06) | F (Q-15 A, 11-07): two-tone flat icons on a painted clay disc |
| D10 | One honey verb colour; violet retired | L (UI v3) | **FIX:** violet is still in the Topla pill, the map pin, the resident card, Today and the Settings night rows |
| D11 | UI direction: the Living Diorama (the UI is the game), and "find the middle way" | F: Hub q-ui-direction B + "doğru orta yolu bulalım" | — |
| D12 | 60 fps for beta; 120 Hz while touching, 30-60 ambient, 0 settled | F (60 fps) + L (the rest, not "agreed") | Measure on device first |
| D13 | Navigation: a map button plus a three-way dial is broken UI | F as a view (11-05) | The single camera with the place control is built |
| D14 | No naming step in onboarding | L | — |

## 8. Money (pricing details come from the founder)

| # | Item | Status |
|---|---|---|
| M1 | Hybrid: yearly + lifetime (+ DLC rather than tips) | F: Hub q-monetization D; "bahşiş değil dlc satabiliriz" |
| M2 | Plus sells beauty, never function; the gate is always free | L (Hub recommendation) |
| M3 | Prices: his working numbers are ~349,99 TL/year and ~999,99 TL lifetime | F as "gibi" and "hemen hemen okay". **FIX:** the log and tracker say "approved". Monthly 129,99 TL and all US prices are the lead's alone. "fiyat noktasında detayı sonra vermek istiyorum" (11-07) |
| M4 | Where the free part ends | Open: "şimdilik açıkta bırakabiliriz" (Hub). **FIX:** the story map's §9 and monetization v2 fixed it at Act I (Olta). It is a default to test, not a decision |
| M5 | Questions for when he gives prices: monthly or not; one membership or acts (his 350/450 TL idea); where the free part ends; whether users know the cut; what stays at lapse; is the Door always free; prices abroad and trials; Family Sharing | Open, his |
| M6 | Friends: "selamla" and friend approval for an emergency, after launch; island visits later | F: Hub q-friends B |
| M7 | Economy scale: small and meaningful (~10-40 seeds a day, prices 5-200) | F: Hub q-economy-scale A |

## 9. Built status (2026-11-07, `main`)

**Built:**
- The home island IL1-10 logic, and the station masters L1-5.
- The level-up light ceremony.
- Sky, fog and weather (SW-1 to SW-3), sun and cloud shadows.
- Additive night light pools.
- Residents' 8 s life loop, walk frames for Mochi and the goat.
- The visitor schedule, and Damla with the home fountain.
- Koke, five stages.
- Çağlayan: five plates, Damla, code falls, and the flow game with eight boards.
- The garden game.
- The shield: hour palettes, mood medallions, copy.
- The Hop! landing: painted postcards, plaques, the skipped state, "a minute".
- The breath room (v3 layout, ring, haptics), and the payoff seals.
- The code-drawn UI kit v3, and the duo icons.
- World sound.
- Screen Time through `PofuLive` and its three extensions.

**On paper only:**
- `DoorScene`; the care rung (E9).
- Painted growth pieces.
- The home roots; materials, the hive, pairs, decor, seasons.
- The Nazlı rig in the app.
- Revontuli, Emanet, Mehtap and the fillers in code.
- The recall engine.
- The night relight as the default; a night ADR.
- Painted night UI.
- Widgets and the Live Activity.
- StoreKit.

**Wrong in code against a rule (fix first):**
- Seeds buy minutes (R1).
- The breath on every open, and "Vazgeç" (D4).
- The hard diagonal shaft (V5).
- Violet (D10).
- The Saturday bee keeper, and Söz 1 "on the wall" (S14).

## 10. The 2026-11-07 question sheet

Sent to the founder as images, in Turkish (`decisions-2026-11-07/sheet-p1.jpg`
to `sheet-p6.jpg`; page 1 lists the possibly-wrong facts). He answers like
"1A 2C …". The three audits behind this register, with every quote and
evidence path, are archived in `docs/archive/audit-2026-11-07/`.

| Q | Topic | Recommendation |
|---|---|---|
| 1 | Çağlayan: the map's plate vs the built cliff vs a mix | A, the map |
| 2 | Çağlayan's source: stone spout vs otter statue vs Damla's glass | spout + Damla's glass at stage 4 |
| 3 | Worse at the start, livelier at the end: how far | B, clear but still magical |
| 4 | Revontuli: ice island vs ruined towers vs ice + three toppled lantern posts | C |
| 5 | Koke at stage 4: stands up vs sleeps, blooms and breathes once at the finale | B, sleeps |
| 6 | After an island heals: it ends vs earned rounds keep paying + free play + three upgrades | earned + free play |
| 7 | Home framing: whole island vs close vs whole on open, tap to come close | C |
| 8 | Home growth: plate repainted every level vs fixed + pieces vs fixed shape repainted at 5-6 levels | C |
| 9 | Home starts a little worse too? | B, lightly |
| 10 | Night: dark and real vs fairy-tale bright vs between | C |
| 11 | "Pofu'nun vektör map'i köşeli": the normal map, the outline, or other | (only he knows) |
| 12 | The wall: the shield stays simple and the wow goes into our Door vs the Door on every reach vs Shortcuts | A |
| 13 | The Door's look: round door vs halo isle vs pier | A, with the halo as its Breath state |
| 14 | Menus: all paper vs glass panels + paper contents vs round buttons and top strip glass, panels paper | C |
| 15 | The bottom-right icon: two-tone flat on a painted clay disc vs one-colour flat vs as now | A |

Lead calls that do not need his answer, told to him on the sheet:
- Visitors stay daily, with the resident's own day likelier (H9).
- Çömlek's game comes after Book One (G6).
- Paleness gets fixed (V2).
- The roots grow lightly (H11).
- Humour comes from the situation (D6).
- Seasons follow the calendar (H10).

### 10.1 Answers (2026-11-07, late morning)

The founder accepted every recommendation on the sheet ("önerdiğin her
şeyi şey yapıyorum"), with these exceptions and additions, all **F**:

1. **Concept picks are his.** "arada çok farklı yönlerde birkaç konsept
   tasarım oldu. İlk seviyeden son seviyeye. Dolayısıyla aradan seçip yorum
   yapsam daha iyi olur." He picks which concept becomes the accepted target
   for each subject, from a board of the different directions (**Q-16**).
2. **Concept fidelity.** "oyunlaştırırken konseptten uzaklaşmak
   istemiyorum… direkt konsepte göre oyunu yap… konsepti taklit etmeye
   çalışırsak çok iyi olur." The game imitates the picked concept; when a
   game screen and its concept disagree, the concept wins and the gap is a
   bug.
3. **Concept match for light and colour.** Concepts look clean, game
   screens look muddy and inconsistent. Take the single-image Codex concepts
   (day, night, weather), copy them one to one, compare side by side, find
   why they differ, and match them; the same when building an island.
4. **Island and its assets painted together.** The new doors in the earth
   face look patched because they were added later. Treat the island as one
   whole; if needed, have Codex paint the island and the island with its
   assets in one image so the parts match.
5. **The Door: all three scenes rotate** (D3).
6. **No drawn swipe hint** on the shield replica: the system's home
   indicator is enough (done in code).
7. He fixed some visuals earlier, thought they were fixed, then could not
   judge them later. Every visual change is judged against its concept,
   side by side, before it reaches him.

### 10.2 Q-16: the concept board (sent 2026-11-07)

`decisions-2026-11-07/board-p1.jpg` to `board-p4.jpg`. The founder picks one
direction per subject: home (E1-E7), the light and weather target set
(I1-I5), Çağlayan stages (Ç1-Ç4), and Revontuli, Emanet, Mehtap (R, EM,
M). The lead recommends E1 with E3's distant islands, I1 (I4 for mist, the
Tam Çiçek night for night), Ç1, R1 with the three toppled lantern posts,
EM1 and M1. Only stage 0 and stage 4 exist for the map's islands; stages
1-3 are painted from the same plate after his pick.

### 10.3 Q-16 answered (2026-11-07, midday): one flow per subject

All **F**; details and the stage-by-stage flows in
[concept flows](../design/concept-flows.md).
- **Home: E1**, plus E2's IL7 charm; E6 retired (bad base, poor fog); the
  roots are redesigned later. **Anchors:** things keep their places from
  level to level; only a big change may move something, a stall may move,
  a tower never.
- **Background never empty:** fixed distant islands and Gezgin behind
  home; every island but home is fixed in the sky.
- **Light: I1** (the seasonal island's seven lights) is the target set; the
  postcards help. Night is **not** I4/I5's Tam Çiçek (too contrasty, too
  bright); Gezgin's and Revontuli's nights are good references; no
  one-to-one copy.
- **Çağlayan: C1**, nothing moves between stages, with C2's greens and
  flowers.
- **Revontuli:** one flow: R2's ruined towers (stuck) → R1's ice island →
  the ice lake → the aurora tail.
- **Emanet: EM1's** flow with EM2's stilted bureau or suitcase pile and
  EM2's misty stuck state.
- **Mehtap: M1**, the flashiest island of the game (the last); a much
  bigger gap between stuck and healed.

