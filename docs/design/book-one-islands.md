# Book One island sheets

**Status:** design sheets under the canonical
[Book One story map](../product/story-map/book-one.md) (lead, 2026-11-05;
reconciled 2026-11-06). The map decides islands, order, residents, themes,
Söz lines, gifts and Nazlı's growth; this file only adds what the map does
not draw: plate layouts, stages, games, art lists and risks. Where the two
disagree, the map wins and this file is fixed. Çağlayan's detail lives in
`batch-43` and the [flow game](flow-game.md); Koke's in the
[Koke prototype](koke-prototype.md).

Sources: the story map, [game plan](../product/game-plan.md) §3-§5,
[healing arc](island-healing-arc.md), [sky and weather v1](sky-and-weather-v1.md)
§2.4, [lore bible](../product/lore-bible.md) §4,
[deep lore](../product/deep-lore.md) §3.2, §4, §5, §6,
[home layout](../product/home-layout.md) §1, §3, §5,
[home progression](../product/home-progression.md) §7-§8.

**Book One at a glance (from the map):** 0 Ayçiçeği (home) · G Gezgin
arrives (the vehicle, from the first days) · Koke (first filler, first
visitor) · 1 Çağlayan · Çanlar, Martı Kayası (fillers, random) · 2
Revontuli · ½ Olta (the midpoint, at Revontuli's ice hole) · Fanus, Pervane
(fillers) · 3 Emanet · Çömlek (filler), Arı (home upgrade) · 4 Mehtap and
the finale · Yakamoz, Yosun's letter (after). No fixed days: "Kapı, gün
değil" (the next main island comes after the previous bloom plus a few
quiet days; tests set the durations).

## 0. Shared conventions

**The wonder plate frame** (home layout §1, scaled to a plate about the size of `island-main-s`, framed by the camera like home):

| Zone | World box (wu, origin = lawn centre, +y toward the viewer) | Use |
|---|---|---|
| Lawn | ellipse ±150 × ±30 | everything that stands |
| Back band | y −30…−12 | only the landmark (tall, ≥ 110 wu) and props taller than whatever stands in front; at ~17° the rest is hidden |
| Mid band | y −12…10 | the props the stages change |
| Front lip | y 10…30 | the duo (Pofu, Mochi), the resident, every tap target that matters (≥ 44 pt) |
| Earth face | x −130…130, y 32…90 | the plate's body; the resident's door if they live in the earth |
| Underside | below y 90 | only where §5 of [the roots](island-undersides.md) says yes |

**Stage rules for every sheet** (healing arc, sky and weather §2.4, Koke prototype §1): a main island ends in 4-6 short visits (the map); a visit advances one stage, at most one a day, only on a day with a resisted reach; nothing expires; islands never pay seeds. Light per stage: chroma 0.5 · 0.65 · 0.8 · 0.95 · 1.0, the depth fog's extra 0.55 · 0.4 · 0.28 · 0.15 · 0.08, one hue family unlocked per stage; stage 0 has a full value range and **one warm focal light** that the camera finds first and that grows. First warm practical at stage 2. The signature only at stage 4. A stage change is a 3-6 s eased reveal. Stage 3 is the turn beat (the map's DÖNÜM, where Mochi reads the Söz line); stage 4 is the map's ÇÖZÜLME, wordless.

**Every main island delivers the map's five parts:** a theme of silence (TEMA), a resident bigger than they first look, an object of the old keeper (ESKİ BEKÇİ), one Söz line (DÖNÜM), and a lasting change at home plus one piece on Nazlı's back (EVE HEDİYE).

**Columns of the stage tables:** *Mended* = the one named element; *Plate* = what the edit of `-island-0` changes; *Light*; *Motion · sound*; *Beat* = what the resident or the duo does (lines are written later with `pofu-story`, from the map's İKİLİ); *Game* = what is played that day.

**Art ids** follow batch-39/43: `<island>-island-0` is the root plate (1536 × 1024, the home camera), `-1`…`-4` are edits of `-0` only; characters are a root plus rig edits on the same canvas and ground line. Batch numbers from 51 are proposals.

## 1. Çağlayan (main 1), noon, flow

Map: *"Öğle güneşinde, havada donup kalmış bir şelale."* Resident Damla
(otter, empty cup → full cup at the top of the falls); Söz 1 on the mill
stone; gift: home's pond fountain flows (Tuesday: Damla visits) and a small
pool on Nazlı's back. Plates and boards: `batch-43`, [flow game](flow-game.md)
(built, #297). Its underside (the falls pouring off the plate) is in
[the roots](island-undersides.md) §5.

## 2. Revontuli (main 2), night, flow + light

| | |
|---|---|
| Map | *"Kutup ışığının hiç doğmadığı bir buz adası; ama sauna hâlâ sıcak."* TEMA: "Alınan sessizlik: söndürülen ışık kaybolmaz, gök onu saklar." |
| Wound | **unlit**: the aurora never rose; the lantern towers stand dark and snow-bent (the variety table's ruin, kept as the dressing) |
| Register | wind through dark towers; the sauna the one warm thing |
| Experiment | the island **keeps its own polar night** at any clock hour (a cosmetic dome of night, not the real night; rounds still follow the no-rounds-at-night rule by the real clock); and **the sound heals by subtraction**: the wind loses one whistle per tower lit |
| Signature (ÇÖZÜLME) | "Yeşil-mor perdeler, fener altın; Tuli'nin kuyruğu havaya bir fırça darbesi çizer." The fishing hole mirrors it |
| Place | after Çağlayan and its fillers; no filler between Revontuli and Olta |
| Engine | **flow + light** (the flow engine with a light skin): rotate ice-prism and chain pieces to carry the sauna's warm light to a tower's lantern |
| BASAMAK | "Aurora, oyuncunun sakin gecelerinden sonra daha parlak. Sessiz bir 'bu ben miyim?'" The aurora's brightness (on the island and in the jar on Nazlı's back) follows the player's recent calm nights, never a number |

### 2.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| Aurora post | back centre | (0, −24), ~140 tall | the aurora's lantern on a tall post; dark until stage 4 |
| Sauna on stilts | back left | (−75, −20) | warm window from day one; the old keeper's small glove on the hanger by the door (ESKİ BEKÇİ); Söz 4 under the bench, in the bucket |
| Tower A | front right | (115, 12) | dark, snow-capped; lit at 1 |
| Tower B | mid right | (70, −14) | leaning on the spruce; righted and lit at 2 |
| Tower C | mid left | (−110, −6) | toppled in the snow; raised at 3 |
| Snowy spruce | back right | (118, −22) | |
| Fishing hole, stool | front left | (−55, 20) | the mirror of the signature; **Olta happens here** (§3) |
| Tuli | at the hole | (−30, 18) | back to the camera at 0 |
| Duo | front centre | Pofu (20, 24), Mochi (42, 26) | |
| Underside | **yes** | below y 90 | dark lantern chains hang below; healed: the icicles become crystal lanterns holding the aurora's colour |

### 2.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | three dark towers, dark lantern post, snow drifts; deep indigo sky (zenith L* ≥ 12, never black), stars | ice body glows faint cold; **one warm light: the sauna window** | three whistles in the wind; gentle snow | Tuli sits at the hole with her back to everyone, tail plain white | none |
| 1 | tower A | A's lantern lit | 0.65; a warm amber pool on the snow at A | snow slides off; whistle 3 stops | Tuli's ear turns | flow + light: sauna → A (short board) |
| 2 | tower B | B upright and lit | 0.8; first warm practicals on the path; **a faint low aurora ribbon**, still, at the horizon | whistle 2 stops | in the sauna talking is forbidden: Pofu cannot bear it, Mochi smiles (İKİLİ) | sauna → B |
| 3 | tower C | C raised and lit; three lanterns in a ring | 0.95 | one whistle left, softer | **Mochi reads Söz 4** in the bucket under the sauna bench | sauna → C |
| 4 | (signature) | the post's lantern gold; curtains of aurora | full | the last whistle becomes a soft chord; curtains move slowly; Tuli's tail colours | wordless: Tuli paints a stroke into the air; the hole mirrors it; the duo sit side by side, silent at last | the long board: A, B, C → the post |

### 2.3 Resident and gifts

| | |
|---|---|
| Resident | **Tuli**, round white arctic fox; "düz beyaz kuyruklu tilki → kuyruğu fırça, göğü boyar"; wants someone to sit the whole sauna without talking |
| Visit | Friday ("Cuma: Tuli gelir"); works the lighthouse S9 |
| EVE HEDİYE | **one more lantern on the bridge** at home; **a painted aurora jar on Nazlı's back** |
| Material | light (*ışık*), home progression §7 |
| Week page | stamp: a green-violet brush stroke; the page marks each calm night with a tiny ribbon |

### 2.4 Art (`batch-53-revontuli`)

- `revontuli-island-0` … `-4`: plate chain (towers dark at 0; edits light them) — **concept first**: stage 0 and 4 at the same camera, rooted in `x-revontuli-stage0-night`
- `revontuli-aurora-1`, `-2`: light-on-black curtain cards, two layers
- `tuli`, `tuli-back`, `tuli-paint`: character rig (tail plain and coloured)
- `revontuli-glove`: the old keeper's glove on the sauna hanger
- `flow-prism`, `flow-chain`: flow pieces in light skin
- `revontuli-underside-icicles` (dark and lit): plate underside
- `home-bridge-lantern-2`, `nazli-back-aurora-jar`, `stamp-revontuli`: home, Nazlı and UI

### 2.5 Risks

1. **Day at home, night on the island**: a pan across the clock can jar. Test: a crossfade through the cloud sea in the Koke build with a night grade.
2. **The dark island depresses rather than enchants.** Test: batch-45's take on the lookdev sheet; the sauna window must be the first thing seen.
3. **Flow with a new skin feels like a repeat.** Test: the prism piece (light splits to two outputs) on Çağlayan's engine; keep it only if a tester notices the difference.

## 3. Olta (the midpoint), at Revontuli's ice hole

| | |
|---|---|
| Map | `KİTABIN ORTASI` `REVONTULİ'NİN BUZ DELİĞİ`. "Olta buz deliğinden eski Bekçi'nin fenerini çıkarır. Mochi uzun uzun bakar: 'Onu tanırdım.'" |
| What it is | **not a new island**: a story stop on Revontuli's healed plate, at the fishing hole, a few quiet days after Revontuli blooms |
| The turn | "Soru döner: 'Bekçi kim?' → 'Pofu da onun gibi gidecek mi?'" From here on the clues stay in the background; Mochi's fear is in front. Feeling: "şefkat, biraz endişe" |
| The lantern | the old keeper's (Ihlamur's) lantern, unlit; it travels with the duo on Nazlı's back until it hangs on her hook, lit, at the finale |
| Game | none |
| Beat | Pofu fishes (one tap and hold, cannot fail); the line comes up with the lantern; Mochi looks a long time and says the line; nothing else is explained |
| Art | `olta-lantern-ihlamur` (wet, unlit); `revontuli-island-4` with the duo at the hole; the lantern sits on Nazlı's back patch until the finale |

## 4. Emanet (main 3), afternoon, story island

| | |
|---|---|
| Map | *"Bir kayıp eşya bürosu; ama burada hiçbir şey kayıp değil, emanet."* TEMA: "Devretmek: yorulunca bırakmak da bir bekçilik." Tags `İKİNDİ` `HİKÂYE ADASI` |
| Wound | **unclaimed** (things piled in fog, unlabelled) |
| Register | a soft fog (the variety table's fog island): muffled sound, a shape that moves in the fog, solved as a joke |
| Experiment | **the fog parts where you touch**: a press-and-hold thins it in a ~60 wu radius for 4 s and shows what is under it (only things, never a face) |
| Signature (ÇÖZÜLME) | "Her şey rafta, krem etiketli; pencere sıcak, el arabası paket dolu." |
| Place | after Olta and the fillers Fanus and Pervane |
| Engine | none (story island). The day's act is **one return**: drag one found thing from the heap to its shelf or tag (5 s, cannot fail; a wrong shelf just slides it to the right one) |
| BASAMAK | "Yeni bir Bekçi var, ve çok yakın. Oyuncu Pofu'dan bir adım önde." |

### 4.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| The office | back centre | (0, −22), ~120 tall | crooked house on short stilts built of found things: an upturned umbrella roof, a teacup water tank, a top-hat chimney, a spoon ladder; the counter window faces the camera |
| Hook post | back right | (100, −18), ~75 tall | **eight hooks, the eighth empty** (ESKİ BEKÇİ); seven hold small covered things |
| Shelves | mid right | (70, 0), 3 bays | empty at 0, one bay per stage 1-3; the lowest shelf holds Pofu's night-light (below) |
| Hand-cart | mid left | (−85, −4) | carries the fog shape at stage 0; full of parcels at 4 |
| The Big Heap | front centre | (5, 18) | the drag source; shrinks per stage; Boncuk sits on top at 0 |
| Counter and scale | front right | (110, 16) | a little outdoor counter with a brass scale; **Söz 7 is under the scale** |
| Small heap | front left | (−115, 20) | gone at stage 2 |
| Duo | front lip | Pofu (−45, 24), Mochi (−22, 26) | |
| Underside | **yes** | below y 90 | the fog pools under the plate as a cloud skirt; nets of found things dangle from the plate's roots; the cure gathers them and the skirt thins to mist |

Taps: the heap (drag), the shelf bays (targets), Boncuk, the fog (hold), the hook post, the lowest shelf (stage 4: Pofu's night-light).

### 4.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | knee-deep lilac fog over the lawn; heaps everywhere; blank tags; window dark; shelves bare; **the fog shape**: a tall hat on an open umbrella, standing on the hand-cart, drifting across the back | afternoon drained to amber-grey; shade violet; **one warm light: an oil lantern on the counter window sill** | fog drifts 1 pt/s; the shape crosses every ~40 s; every sound low-passed, one far creak | Boncuk asleep on the heap, a duster in her claws; she wakes, startled, and polishes the duo's feet | none; first tap on the heap surfaces one object |
| 1 | the heaps become shelves | first shelf bay full; the big heap a third smaller | chroma 0.65; the lantern's pool reaches the shelf | things hop onto the shelf one by one; **the first unmuffled sound**: a clean wooden knock | Boncuk polishes the first thing, shelves it, checks it twice | one return |
| 2 | labels return | second bay; cream tags with handwriting on everything shelved; small heap gone | chroma 0.8; **first warm practical**: the office window lights | the fog shape stops: it is an umbrella in a hat on a cart; Pofu pops it open and laughs | Boncuk ties tags; Pofu wears the hat | one return |
| 3 | the office opens | third bay; door open; the back room glows; fog only under the plate | chroma 0.95; warm interior spill | the scale lifts; tea ripples | **DÖNÜM, Söz 7:** Mochi reads the line under the scale and sees she has read her upside-down glass as "wait for me" for years; she gives Boncuk her never-opened ıhlamur tin, on purpose. Pofu, for the first time, asks nothing | one return |
| 4 | (signature) | every thing on a shelf with a cream tag, warm window, the cart full of parcels | full; warm practicals; afternoon gold | parcels stacked; the fog skirt below thins to mist | wordless: Boncuk polishes a cup at the counter | none |

**The quiet secret (ESKİ BEKÇİ, unsaid):** on the lowest shelf, Pofu's own night-light, tagged with the player's real first day in a new hand. Found only by tapping that shelf. Nobody comments.

### 4.3 Resident and gifts

| | |
|---|---|
| Resident | **Boncuk**, magpie, soft teal sheen; "yığının tepesinde toz bezli saksağan → tezgâhta fincan parlatan büro sahibi" |
| Visit | Wednesday ("Çarşamba kapıda bir paket") |
| EVE HEDİYE | **a parcel at the door every Wednesday; polished finds for the workshop**; **a teal plank on Nazlı's back** |
| Material | keepsake (*emanet*): the polished finds (home progression §7) |
| Week page | stamp: a cream luggage tag on a teal string; the page draws the five things returned that week, in a row |

### 4.4 Art (`batch-51-emanet`)

- `emanet-island-0` … `-4`: plate chain — **concept first**: one layout concept, stage 0 and 4 side by side, rooted in `x-emanet-stage0-fog`
- `boncuk`, `boncuk-duster`, `boncuk-polish`: character rig
- `emanet-found-1` … `-8`: drag sprites (cup, glove, key, kite, spoon, sock, compass, bell)
- `emanet-fog-shape`: sprite (hat on umbrella on cart)
- `emanet-underside-nets`: plate underside
- `home-wednesday-parcel`, `nazli-back-teal-plank`, `stamp-emanet`, `nightlight-tagged`: home, Nazlı and UI

### 4.5 Risks

1. **The fog shape reads as a stranger** (a hat and a tall figure). Test: a contact sheet at 28 pt to five people; if anyone says "a man", widen the umbrella.
2. **The return act blurs "story, not game".** Test: the act on Koke's placeholder plate; it must take under 6 s with no instruction.
3. **Press-to-part fog nobody discovers.** Test: does anyone touch the fog in the Koke pilot unprompted? If not, Pofu parts it once on arrival.

## 5. Mehtap (main 4) and the finale, blue hour, real full moon

| | |
|---|---|
| Map | *"Hilal biçiminde bir ay taşı beşiği: kubbe kapalı, harita boş, baykuş uykuda."* TEMA: "Eve dönüş: izi takip eden, izin evde bittiğini görür." Tags `MAVİ SAAT` `GERÇEK DOLUNAY` |
| Wound | **dark** (dark stars; the chart blank) |
| Register | quiet dread: the darkest moment of the book, right before the release |
| Experiment | **a star dims while you watch** on arrival (a 6 s fade to a faint ember, never to black, with a cold glassy tone; lead 2026-11-06). The cure: they are dark stars, remembered lights, and they join into trails |
| Signature (ÇÖZÜLME) | "Kubbe açılır; yedi soluk iz ve yeni, parlak bir iz; havuz gümüşe döner, Nane uyanır." The new trail ends at Ayçiçeği; its stars are **the player's real calm nights of Book One**, one star each |
| Place | after Emanet, Çömlek and Arı; no filler before the finale, visitors only at home |
| Engine | **flow (moon line)**: the board is the sky above the island (the camera tilts up); connect stars by rotating thread segments |
| The moon | the finale night is under the **real full moon** (map). Open decision (story map §8.2): time Mehtap's door so stage 3 lands a few days before a full moon; the 2026-11-06 "blessing, not a gate" fallback only if tests show a long wait |

### 5.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| Crescent horns | back left and right | (−135, −10), (135, −10), ~70 tall | the plate's two ends rise like a cradle |
| Observatory dome | back centre | (0, −22), ~110 tall | closed at 0; a pale-gold keyhole |
| Moon pool | front left | (−55, 18) | dull pewter at 0, silver at 4; **Söz 10 on its rim** |
| Nane's perch and lantern | mid right | (95, −6), ~90 tall | |
| Bench and chart board | front right | (60, 20) | the chart blank at 0; **seven faint trails** drawn on it at 3 (ESKİ BEKÇİ) |
| Duo | front centre | Pofu (−5, 26), Mochi (18, 27) | |
| Nane | at the perch's foot | (88, 10) | asleep in a ball beside her lantern at 0 |
| Underside | **small** | below y 90 | a dark underside that fills with tiny stars as constellations join |

### 5.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | dome shut, pool dull, chart blank, a thin sky | blue hour gone cold, silver drained; **one warm light: the dome's pale-gold keyhole** | on arrival one star dims to an ember; a cold descending tone; then nothing moves | Nane asleep; Mochi holds Pofu's paw (the only time) | none |
| 1 | the first faint trail | one old trail joined | 0.65 | the cold tone warms half a step | Nane stirs at dusk | flow: one trail |
| 2 | the dome opens | the telescope out; a second trail | 0.8; first warm practical: Nane's lantern lit | the dome's slow turn | Nane shows Pofu the telescope; he looks the wrong way | flow: second trail |
| 3 | the chart drawn | seven faint trails on the chart and in the sky | 0.95 | the pool stills | **DÖNÜM, Söz 10:** Mochi reads the line at the pool's rim; the newest trail ends at Ayçiçeği, tonight | flow: the last faint trails at once; the newest stops short of home |
| 4 | (finale, the full-moon night) | the dome open, seven faint trails and the bright new one; the pool silver; Nane awake, wings open, the star chart in hand | full; moonlight | the four beats (§5.3) | wordless except Nane's "Günaydın." | none |

### 5.3 The finale: four beats (the map)

1. **Nazlı büyür:** "Aynı balina, ikinci form: ilk kez şarkı söyler, dört nota. Uzakta Koke bir kez nefes alır." (§6)
2. **İz eve iner:** "Kara yıldızlar birleşir; Ayçiçeği seyirciye döner. Nane oyuncuya: 'Günaydın.'" The camera follows the new trail home.
3. **Mochi oturur:** "Eski bardağı düz çevirir, doldurur, ekranın kenarına koyar. Ve oturur."
4. **Pofu bakar:** "Bir kez kameraya. Teşekkür eder, övmez. Kimse açıklamaz."

Then "İyi geceler." The book ends: no cliffhanger, no open question.
İKİLİ: Pofu finds you at the end of the trail, not the keeper; Mochi lets
her fear go ("giden gitmez, dinlenir"). BASAMAK: "Bekçi sensin. Bir kez:
bir bakış, bir bardak, bir cümle."

### 5.4 Resident and gifts

| | |
|---|---|
| Resident | **Nane**, tiny round grey-and-cream owl; said "günaydın" to the old keeper every evening and he answered (ESKİ BEKÇİ); at the finale she says it to the player |
| Visit | Sunday ("Pazar: Nane gelir"); works the windmill S5 at dusk |
| EVE HEDİYE | **the telescope on the Tepe** at home; **a moon stone on Nazlı's back**; **Ihlamur's lantern on her hook, lit** |
| Home change | from then on, the player's trail is in home's night sky every clear night; it ends over the sunflower |
| Week page | the finale page: the chart with the player's trail, each star dated |

### 5.5 Art (`batch-55-mehtap`)

- `mehtap-island-0` … `-4`: plate chain — **concept first**: stage 0 and 4, rooted in batch-17's crescent (`x2-mehtap-a`)
- `mehtap-trail`, `mehtap-star` (lit and dark): light-on-black sprites; code draws the trail from data
- `nane`, `nane-asleep`, `nane-wings-chart`, `nane-lantern`: character rig
- `flow-thread`: flow piece in the moon skin
- `home-tepe-telescope`, `nazli-back-moon-stone`, `stamp-mehtap`: home, Nazlı and UI

### 5.6 Risks

1. **The dimming star frightens.** Test: five people, the 6 s fade at 28 pt; if anyone says "sad" not "eerie", fade it less.
2. **The full moon waits too long.** Test: a `PofuCore` scenario over a year of start dates with the door timed to the moon: median and worst wait for the finale after stage 3.
3. **The trail from real nights is thin for a player with few calm nights.** Test: the record of the light user; floor of seven stars, the rest filled from resisted days.

## 6. Gezgin: Nazlı, the vehicle (form 1 to form 2)

| | |
|---|---|
| Map | `ARAÇ · ANA YOLUN KENDİSİ` `FORM 1`. *"Limanda yorgun, nazlı bir bulut-balina; sırtında bir avuç ada. Artık adalara gidilebilir."* |
| Arrival | "Erken: ilk günlerde iskeleye yanaşır. Arkadaş limanları (online) onunla hikâyenin içinde gelir." Every main island is reached on her back |
| ESKİ BEKÇİ | "Sırtında boş bir fener kancası ve sönmüş küçük bir kâğıt fener biçiminde bir iz." |
| İKİLİ | "Pofu dümen ister; Nazlı sessiz olan yere gider. Mochi çantayı çoktan hazırlamış." |
| BASAMAK | "Bir Bekçi var ve yer değiştiriyor. Kitabın sorusu açılır." |
| BÜYÜME | "Her ana adadan sırtına bir malzeme; ödeme değil, bağ büyütür." Never bought (deep lore §8.1 rule 7) |
| Finale | form 2 on Mehtap's full-moon night: "ilk kez şarkı söyler, dört nota. Uzakta Koke bir kez nefes alır." "Eski formuna sessiz bir veda." |

### 6.1 Layout (at the harbor)

| Piece | World (wu) | Notes |
|---|---|---|
| Nazlı | sky east, (520, −40), about three islet widths | moored beside the pier S8 |
| Back patch | her back, ±90 wu around (520, −70) | bench, mooring post, grass tuft, the empty lantern hook, the paper-lantern-shaped mark |
| Back sockets N1-N6 | along the back patch, left to right | one per piece of the map's "Sırtında biriken" list (below); none needs a menu |
| Yosun | on the bench | the tortoise postman, a satchel |

### 6.2 What gathers on her back ("Sırtında biriken")

| Socket | After | Piece (map) | Light | Beat |
|---|---|---|---|---|
| — | start | form 1: grey-blue, cream belly, head low, heavy-lidded eye; empty hook; the faint paper-lantern mark | cool, drained | Pofu wants the helm; she goes where it is quiet; Mochi's bag is already packed |
| N1 | Çağlayan | "havuz ve şelale": a palm-sized pool with a tiny fall | 0.65 | her breath slows near a slow breather |
| N2 | Revontuli | "aurora kavanozu": a painted aurora jar, brighter after the player's calm nights | 0.8 | |
| (rides) | Olta | Ihlamur's lantern, unlit, rides on the bench (not yet on the hook) | | Mochi keeps a paw on it |
| N3 | Emanet | "teal tahta": a teal plank | 0.95 | |
| N4 | Mehtap | "ay taşı": a moon stone | full | |
| N5 | finale | "Ayçiçeği toprağından genç bir ayçiçeği" | full | |
| N6 | finale | "Ihlamur'un feneri, yanık": the lantern on the hook, lit; the paper-lantern mark glows | full | form 2: she sings the four notes; far off Koke breathes once |

### 6.3 Resident, art

| | |
|---|---|
| Resident | **Yosun**, tortoise postman: every letter is addressed "Bekçi'ye" and the address keeps moving; "postacı; bir gün ona da bir mektup gelecek" (his letter waits, after the finale: "Yosun'un mektubu", opens in Book Two) |
| Home change | from the finale Nazlı moors lit at the pier every night |
| Memory | tapping a piece on her back replays a one-line memory of that island ([the roots](island-undersides.md) §7, re-pointed) |
| Art (`batch-56-nazli-forms`) | masters exist (`nazli-body`, `-fins`, `-tail`, `-eyes-closed`, `-island-patch`; batch-22 forms). New: `nazli-eyes-open`, `nazli-back-pool`, `-aurora-jar`, `-teal-plank`, `-moon-stone`, `-young-sunflower` (each ships with its island), `nazli-form-2-patch` (**concept first**), `lantern-ihlamur` (unlit, lit), `nazli-mark-glow` |

### 6.4 Risks

1. **"The grown form chosen once"** (story rule 4). Lead decision 2026-11-06: one tap between three back gardens, default after 10 s; every variant carries the map's six pieces.
2. **The finale needs every main island**; a player who stalls never sees it. Test: scenario tests for the light user; ≤ day 70.
3. **Song without audio.** The tone sketch first (as Çanlar).

## 7. Fillers

The map's rule: "rastgele sakin bir günde süzülür, 1–2 ziyarette biter; bir
şaka ya da bir his. Ana hikâyeyi taşımaz, sayaç yok, süresi dolmaz, bir
hikâye anından hemen önce gelmez. İkili atışır." Each keeps one secret for
a later book, never said in Book One.

| Filler | Window (map) | Resident | The joke or feeling (map) | Secret |
|---|---|---|---|---|
| Koke | first journey; first visitor (Monday) | Sumi, dormouse (*yediuyur*) | "Uyuyan bir yosun tepesi; uyuduğu için özür dileyen Sumi teşekkür mektuplarını tırmıklar." | "tepe nefes alıyor gibi... (Kitap 2)" |
| Çanlar | after Çağlayan, random | Zil, bell-ringer mouse | "Kulağı ağır, gururlu yaşlı zilci; 'dinle ve tekrarla' oyununun ilk adası. İkili kimin daha iyi dinlediğine atışır." | "en eski ezgi... (Kitap 2)" |
| Martı Kayası | after Çağlayan, random | the gulls | "Martılar ıvır zıvır takas eder; biri bir leylek tüyü uzatır. Mochi'nin çayı kıpırdar." | "Fener Kayası'nın yolu (Kitap 2)" |
| Fanus | after Olta, before Emanet | Zümrüt, glass frog | "Ilık yağmur kavanozunda utangaç, saydam bir kurbağa; kavanozdaki ayçiçeklerinin üstünde tarihler yazılı." | "kavanoz okunabilir (Kitap 2)" |
| Pervane | after Olta, before Emanet | the moths, a lamp | "Güveler bir lambanın etrafında döner. Mochi Pofu'ya bir fener yakar; Pofu ilk kez tek başına kısa bir tur atar." | "yanık kalmasına izin verilen tek ışık (Kitap 3)" |
| Çömlek | after Emanet | Kil, potter mole | "Fırını soğuk bir çömlekçi; dokunduğu her şeyde başparmak izi. İkili ilk çanağı kimin yapacağına atışır." | "Halka Taşı'nı pişiren el (son kitap)" |

Seasonal: **Leylek** (Lale), "Gerçek baharda gelen yaşlı leylek; gülmek yerine gagasını takırdatır. Kitabın her yerinde olabilir." (sır Kitap 2'de).
After the finale: **Yakamoz**, Book Two's door, arrives days later as an object.

**Koke** is built as a five-stage island ([Koke prototype](koke-prototype.md)). Open decision (story map §8.1): keep it as the first filler's longer visit, a gentle tutorial of the arc (recommended), or trim to two visits.

Only Çanlar has a full sheet (below), because it debuts the recall engine; the others get one page from the template (§7.2) when they are scheduled.

### 7.1 Çanlar, the bells

| | |
|---|---|
| Wound | **mute** (bells tangled and silent) |
| Register | odd, funny; **a wrong note**: at night one "bell" rings off-key by itself |
| Experiment | a playful creep solved with a joke: the fourth bell is missing and Zil hung his **copper kettle** in its place; at night his brazier warms it and it sings off-key. The real fourth bell is his bed, upside down, with a quilt in it |
| Healed signature | **sound first, shown too**: the screen holds still for one beat, then the four-note chord rings and the bells swing in a wave around the frame |
| Window | after Çağlayan, on a random quiet day, never the day before a main beat |
| Engine | **recall debut** ("dinle ve tekrarla"). Filler pacing: stages 1-3 advance one per recall round, so one visit can reach stage 3; stage 4 needs a second visit on a later day, at dusk or after |

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| The spire | back centre | (0, −22), ~160 tall | terracotta roof, verdigris trim; ropes run down from it |
| Bell frame | mid, across | x −75…75, y 2 | bells at x −60, −20, 20, 60, graded big to small; the four tap targets |
| The kettle | in slot 4 | (60, 2) | until stage 3 |
| The rope knot | mid centre | (0, −8) | one rope freed per stage |
| Zil's door | spire base, left | (−40, −12) | a bell-shaped door, a candle in its window |
| Brazier and bed | front right | (95, 18) | the upturned fourth bell with a quilt |
| Duo | front left | Pofu (−70, 24), Mochi (−48, 26) | |
| Zil | on the frame, barefoot | (0, 6) | he rings by the buzz in his feet |
| Underside | **small** | below y 90 | the ropes hang down through the body, tangled; untangled per stage |

| Stage | Mended | Plate | Motion · sound | Beat | Game |
|---|---|---|---|---|---|
| 0 | (the wound) | ropes knotted; three bells mute and askew; the kettle in slot 4; one warm light: the candle in Zil's window | at dusk the kettle goes "dooonk", off-key | Zil stamps on the frame to feel a ring that is not there | none |
| 1 | rope 1 | bell 1 straight | bell 1 rings | the duo bicker over who listened better (İKİLİ); the phrase replays, no fail | recall, 3 notes |
| 2 | rope 2 | bell 2 straight; the brazier glows | two true notes | the bickering goes on, quieter | recall, 3 notes |
| 3 | rope 3 and the real bell | bell 3 straight; the bed is a bell: the duo rehang it; Zil moves into the kettle | three notes and a squeak | the joke lands: Zil sleeps in the kettle, lid as a hat | recall, 4 notes |
| 4 | (second visit, dusk or later) | all four bells hung | the chord, then the wave | wordless; Zil, too loud, pleased | recall, the four-note call |

Resident Zil: proud, hard of hearing; never the joke (the kettle is). Risks: **audio has not landed** (four tones in an AVAudioEngine sketch on the founder's phone before any art); **a random filler carries the recall debut** (`GameScenarioTests` with light and heavy users: Çanlar must fall between Çağlayan and Revontuli for all of them); **hard-of-hearing as comedy** (the `pofu-story` editorial pass). Art (`batch-52-canlar`): `x-canlar-concept-a/b/c` (concept first), `canlar-island-0` … `-4`, `canlar-bell-1` … `-4`, `canlar-kettle`, `zil`, `zil-ringing`, `zil-kettle-bed`, `recall-glint`, `stamp-canlar`.

### 7.2 Filler template (one page per filler)

| Field | Rule |
|---|---|
| Joke or feeling | the map's card line; no lore the main story needs (the card's secret stays unsaid) |
| Arrival | drifts in on a random quiet day inside the map's window, never the day before a story beat; never expires |
| Pacing | complete in one or two visits; stages may advance per round; no counter, no material |
| Layout | the shared plate frame; one landmark back centre; one prop the joke lives in; the duo front; underside only if the joke is below |
| Stages | 0 the oddity with one warm light; 1-3 the oddity undone; 4 the payoff, wordless |
| Engine | reuse an engine with its Book One skin; never debut one (Çanlar is the single exception) |
| Duo | they bicker (the map: "İkili atışır") |
| Resident | one, no weekday (Koke's Sumi is the exception: Monday) |
| Art | `<filler>-island-0` … `-4`, one character root and one edit, a stamp; a concept only if no silhouette exists |
| Risk check | does it duplicate a neighbour's register, colour or hour? |

## 8. Arı: the home upgrade (not an island)

Map (ev dalı, after Emanet): "Kovan eve gelir: arılar Ayçiçeği'nin üstünde
dans eder, çiçekler renk değiştirir; Cumartesi bal." Secret: "dans hep aynı
yöne döner..." (it points somewhere; never said in Book One).

| | |
|---|---|
| What arrives | the hive at home (station S6, home progression §7, "the hive (gift station from Arı)"); no plate, no resident island, no stages |
| Signature | the swarm dances over the sunflower; the flower borders change colour |
| Visit | Saturday: honey ("Cumartesi bal") |
| Material | wax and honey (*bal mumu*), home progression §7 |
| Art | the home hive (`hive-1` … `-3` merged; `hive-4`, `-5` blocked on the lead's review); a bee sprite sheet (4 frames) for the dance; no island batch |

## 9. The Book One arc

**Fear and strength** (0 = none, 5 = the most Book One allows):

| Order | Node | Type | Hour (map) | Register | Fear | Colours (dominant, then accent) |
|---|---|---|---|---|---|---|
| 0 | Ayçiçeği | home | follows the clock | home | 0 | sunflower gold, cream |
| G | Gezgin | vehicle | moves | humble | 0 | grey-blue, cream |
| f | Koke | filler | morning | sleepy | 0 | moss grey to green; flower pink |
| 1 | Çağlayan | main | noon (öğle) | dry | 1 | cream stone; teal water, rainbow |
| f | Çanlar, Martı Kayası | fillers | dusk; day | odd, funny | 1 | terracotta, verdigris bronze |
| 2 | Revontuli | main | night (gece) | dark, unlit | 3 | indigo, ice white; aurora green-violet |
| ½ | Olta | midpoint | Revontuli's night | tender, a little worried | 2 | as Revontuli, one unlit lantern |
| f | Fanus, Pervane | fillers | rain; lamp night | shy; brave | 1 | glass green; moth cream |
| 3 | Emanet | main | afternoon (ikindi) | soft fog | 2 | honey amber, lilac fog; teal as accent only |
| f, ev | Çömlek, Arı | filler, home | day | warm | 0 | clay; gold and ochre at home |
| 4 | Mehtap | main, finale | blue hour (mavi saat), full moon | quiet dread, then release | 4 → 0 | moonstone silver, deep blue; one pale gold |

The fear curve rises with a breath between steps; the darkest night sits right before the release. The two blue islands (Revontuli, Mehtap) are split by Emanet's amber.

**The order of games:** place (home) → none (Koke) → **flow** debut (Çağlayan) → **recall** debut (Çanlar) → flow + light (Revontuli) → none (Olta) → the return act (Emanet) → flow + moon (Mehtap) → the four notes heard (finale).

**The duo's turns (the map's İKİLİ):** Mochi fears the drop, Pofu lays stepping stones and wants to thank the keeper (Çağlayan); Pofu cannot keep quiet, then both fall silent side by side (Revontuli); the question turns to "will Pofu go like him?" and Mochi's fear comes forward (Olta); Mochi hands over the tin, Pofu asks nothing (Emanet); Pofu finds you, not the keeper, and Mochi lets the fear go (Mehtap).

## 10. Build order

1. **Generalise the Koke model** in `PofuCore`: `WonderIslandID` gains `revontuli`, `emanet`, `mehtap` (main) and `canlar`, `martiKayasi`, `fanus`, `pervane`, `comlek` (fillers); a `filler` pacing flag (stage per round, two visits); Olta as a story event on Revontuli; a per-island spec (anchors, stage props, gift, Nazlı piece) as data so islands add content, not code.
2. **Çağlayan and the flow engine** (engine built, #297; island in flight, batch-43). Flow skins from the start (water, light, thread).
3. **Çanlar concepts** (`batch-52`) and the **recall engine + a four-tone audio sketch** in parallel; it comes right after Çağlayan now, so it is the long pole.
4. **Revontuli** (`batch-53`): the light skin, the prism piece, the island's own night grade; then **Olta** (the lantern prop, one beat).
5. **Emanet** (no new engine): the return act and the press-to-part fog; `batch-51` layout concept, then production.
6. **Arı at home**: the hive S6 and the dance.
7. **Mehtap** (`batch-55`): the moon phase in `PofuCore` (pure, from the date; tested on Linux), the door timed to the moon, the trail drawn from the player's calm nights.
8. **Nazlı** (`batch-56`): one back piece ships with each main island; form 2 and the finale last.
9. **Fillers** (Martı Kayası, Fanus, Pervane, Çömlek): one template page each when scheduled.

## Lead decisions on the open risks (2026-11-06)

1. **Mehtap's star:** it dims to a faint ember, never goes out; test the 6 s fade with five people before the art.
2. **The moon:** superseded by the map's "GERÇEK DOLUNAY"; the door is timed to the moon (open, story map §8.2).
3. **Çanlar's sound first:** keep it; the healed state also shows visually (the bells swing in time) so it never depends on audio alone.
4. **Nazlı's form:** one tap between three back gardens, default after 10 s; the map's six pieces are in every variant.
5. **Names** not on the map (apprentices, the bee keeper) are dropped; new names go through the `pofu-story` pass and the map first.
