> Archived 2026-11-07: an audit input to [the decisions register](../../product/decisions.md). Image paths are relative to the session scratchpad and are not in the repo.

# Area A: story, islands, characters, mini-games (audit 2026-11-07)

Auditor: Opus (area A). Repo read-only at `5a0eedda` (main, after #315). Images for this file live in
`A/` (abbreviated **`A/`** below; every
image path in §5 is written in full). Sources: FM = `founder-messages.md` (timestamp), HUB = `hub-notes.md`,
FI = `docs/product/founder-input.md` (line), MAP = the two PNGs, B1 = `docs/product/story-map/book-one.md`,
BOI = `docs/design/book-one-islands.md`, ARC = `docs/design/island-healing-arc.md`, DL = `docs/product/deep-lore.md`.

**Five findings that matter most**
1. **Çağlayan drifted from the concept he loved.** He praised "yeni Çağlayan" on 11-05 20:09; the only new
   Çağlayan merged that day was `batch-34-islands-in-game/x-caglayan-*` (merged 11-05 18:01), the very plate on
   the map. The production brief `batch-43` (written 11-06 05:51) never references it and draws a different
   island (grey stepped cliff, one big pool, no round side pools, no stone spout). That is what the game ships
   (`world-caglayan-island-0…4`, screenshot `caglayan-stages.jpg`). This is the drift he feels.
2. **There is no otter-shaped statue on the map.** At full resolution the map's stream comes from a plain
   carved stone spout in a cream boulder (`A/map-caglayan-spout-stuck.jpg`, `-healed.jpg`). The otter-and-water
   image he likely remembers is Damla's card (`x-res2-damla-grand`): Damla pours her glass into the falls.
   FI line 536 wrote his recollection down as fact. Ask him, with images (Q-A-2).
3. **The map's own pictures go from "medium" to "good".** The stuck and healed plates differ little (Mehtap
   and Revontuli most of all). His new rule, "worse at the start, much better and livelier at the end",
   applies to the map images too, so we follow the map's layouts and push both ends further (§6.3).
4. **Koke as built gives away a Book Two secret.** At stage 4 the moss hill stands up as a creature, and the
   lines say "Tepe horluyor" (the hill snores). The map keeps "tepe nefes alıyor gibi... (Kitap 2)" secret, and
   its finale beat is "Uzakta Koke bir kez nefes alır". DL §6 makes the hill Nazlı's sleeping mother. Sumi, the
   map's Koke resident, is not in the Koke scene code.
5. **Nothing says what happens on an island after it heals.** He asked twice (HUB q-island-materials: "bir
   ada bitince ne olacak kazanmak mı duracak"; q-earned-play: "her adanın bir mini-oyunu olursa o döngü
   sınırsız gidebilir"). The docs disagree. `flow-game.md` §3 says "no replay"; `home-progression.md` §7 says
   rounds keep paying one material per three rounds. No island has its own upgrades. §6.5 proposes a system per
   island.

---

## 1. Confirmed by the founder (his words only)

| # | Item | His words (verbatim) | Date · source |
|---|---|---|---|
| C1 | The two-page map is his best document, but it need not be followed one to one | "Şu an benim elimdeki en iyi dokümantasyon bu attığım sana 2 sayfalık ilerleyiş dokümantasyonu… Ama birebir uymak zorunda değiliz hani." | 11-07 06:46 FM |
| C2 | Both ends of the healing open up: worse at the start, much better and livelier at the end | "adaların işte başlangıçta bir tık daha kötü durumda olup sonradan çok daha iyi ve lively olması yönünde hani iki ucunda biraz açılması" | 11-07 FM |
| C3 | The same rule, first said: bad to good, not ruined, not "a few lights came on" | "ben sanırsam biraz daha kötüden iyi istiyorum full yıkık olmasına gerek yok… ama birkaç ışık yandı gibi de hissettirmesin… o iyileştirme hissi iki yönlü de artsın ama gereksiz abartı yapma… ada bazında" | 11-05 22:22 FM |
| C4 | The bad state is still impressive; fog can be real fog | "sis gerçek bir sis olabilir sadece solgun gelmesi yeni bir yere gelmenin büyüsünü bozmamalı kötü hali bile etkileyici olabilmeli" | 11-06 05:52 FM |
| C5 | Different moods per island (a view, explicitly not an order): one with scary fog, one a scary sound, one a ruin | "biri korkutucu ses olsun, biri yıkıntı olsun… Bu talimat değil… hepsinde aynı gitme" | 11-05 22:27 FM |
| C6 | Çağlayan's source: an otter statue on the map (his memory; see §3 X1), open to change | "Çağlayan'ın deresi hani traverten değil böyle bir samur şeklinde bir heykelden çıkıyordu ama hani olmaya da bilir… zaten adada samur var… su animasyonlarını, efektlerini, shader'larını implement etmemiz daha zor olabilir" | 11-07 FM |
| C7 | He loved the new Çağlayan, Gezgin and the Moon (batch-34, see finding 1) | "yeni Çağlayan çok güzel, Gezgin çok güzel, bu Ay çok güzel" | 11-05 20:09 FM |
| C8 | Gezgin form 1: her face turns toward the pier and is hidden | "suratı limana dönük yani o böyle iskelenin arkasında kalıyor" | 11-05 20:09 FM |
| C9 | Earlier Çağlayan concepts: unclear, overdone, a little scary | "çaplayan konseptini ise tam anlamadım… fazla abartı" (11-03 20:44); "direkt konsepti biraz korkutucuydu. Ve yeni konsepti kestiremedim" (11-05 16:24) | FM |
| C10 | Nazlı has two forms: early a whale with a piece of island on her back, grown and "godlike" near the end | "bu gezginin aslında iki versiyonu var… bir balina ve üzerinde bir ada parçası… hikaye sonuna doğru büyümüş, level atlamış halde" | 11-05 06:14 FM |
| C11 | Main islands and fillers are separate; Çanlar is a filler that arrives on a random day | "ziller, çanlar hani o bence bir filler ada… random bir gün eklenti olarak gelse daha iyi olur" | 11-05 06:14 FM |
| C12 | Four or five main islands | "Ya ana ada 4-5 tane gelebilir" | 11-05 12:35 FM |
| C13 | Not every island needs a game; story, mini-game or upgrade, as long as each is fun; about three mini-games are enough | "her ada hikaye olabilir, o mini game olabilir… upgrade… Yani 3 tane falan mini oyunumuz olsa yeter" | 11-03 20:44 FM |
| C14 | Earned play: between "earned" and "unlimited"; an island's mini-game can be its own endless loop | "evet ve sınırsız arasında bir yerdeyim… her adanın bir mini-oyunu olursa o döngü sınırsız gidebilir… Kendin düşün, kendin ele al" | 11-02 HUB q-earned-play (A) |
| C15 | When an island ends, earning should not stop; several islands run at once, without overdoing it | "bir ada bitince ne olacak kazanmak mı duracak, bir ada bitti ötekine geç değil birkaç tanesi aynı anda gidebilsin istiyorum abartmadan" | 11-02 HUB q-island-materials |
| C16 | Each island needs an activity on it, planned for | "adaların üzerinde bir oyun, belki yapılacak bir etkinlik olması lazım, planlanması gereken" | 11-03 19:54 FM |
| C17 | The lead plans each island's gameplay systems; he wants to approve "this look, these mini-games, these upgrades, this side island" | "oynanışa göre de adaları sen planlayacaksın farklı sistemlere… İşte Çağlayan'ın böyle gözükmesini istiyoruz… Bu mini game'ler, bu upgrade'lar. İşte yan adanın bu olmasını istiyoruz" | 11-07 FM |
| C18 | The curve rises: each island a little better than the one before; not every one god-tier | "her yeni gelen öncekinden biraz daha iyi olacak… gezgin… 10'da 10… Levantoli daha şey kalmış yanında. Basit." | 11-03 20:44 FM |
| C19 | Visitors come daily and for a reason, not weekly; on empty days the player might invite someone | "karakterler haftalık değil. Hani günlük olarak hani bugün şu adaya ziyarete geldi" (17:12); "güzel günlük sürprizler… belki bazı boş günler sen davet edersin" (17:33) | 11-05 FM |
| C20 | Animal Crossing spirit between characters; a resident who moves must not leave their island empty | "Adalar arasında… Animal Crossing ruhu istiyorum karakterler arasında" (20:09); "geldiği adanın da boş hissettirmemesi lazım" (16:24) | 11-05 FM |
| C21 | The garden mini-game (Block Blast family) is good | "mini game güzel olmuş, tatlı olmuş" | 11-05 09:30 FM |
| C22 | Yıldız, Kaplıca and Kitap are dropped (he corrects himself) | "Ben hala bu yıldız, kaplıca ve kitap... Ha, kalkıyor bunlar, pardon." | 11-05 16:24 FM |
| C23 | An act must really end (teasing is fine, no half story) | "Act biterken hakikaten gerçek bir şekilde bir act bitmeli" | 11-05 12:35 FM |
| C24 | Island undersides: not every island needs one; tapping a keepsake to replay a memory: yes | "her adanın ihtiyacı yok zaten" (11-06 08:00); "Evet diyelim" (08:18) | FM; FI §11-06 |
| C25 | Older concept scores (FI 324, lead's notes of his words): Gezgin 10, Revontuli 7 (fresh colour theme), Çanlar and Emanet "great", Koke (Japanese) 6, Çömlek 4 ("character and minigame are fun, the island concept is boring"), Yıldız 3, Leylek 2 | as logged; the chat (C18) confirms Gezgin 10 | 11-03 FI |
| C26 | An idea card: animated signature features, such as a waterfall pouring off an island | FI 413 (lead's paraphrase) | 11-02 |

## 2. Lead decisions he has not confirmed

| # | Decision | Where written | Did he react? |
|---|---|---|---|
| L1 | The map is "canonical" and "wins" over every doc | B1 header, CLAUDE.md | Partly. C1 calls it his best doc, but "birebir uymak zorunda değiliz". The page itself says "lead önerisi, kurucu onayına" (`A/tx/p2-06.jpg`) |
| L2 | Çağlayan's production look (cliff steps, batch-43, lead picks 11-06) | `batch-43` manifest; `lead-picks-2026-11-06-caglayan` | No. He never saw it beside the map version (finding 1) |
| L3 | Koke is the first filler and the Monday visitor, and its five-stage arc stays as built | B1 §9.1 | No |
| L4 | The seventh filler is Leylek | B1 §9.3 | No. It also contradicts the map (§3 X6) |
| L5 | The finale waits for the real full moon, and Mehtap's door is timed to it (the fallback applies only if the wait passes 7 days) | B1 §9.2, BOI §5 | No |
| L6 | Mehtap's game is flow (moon thread); Revontuli's is flow plus light; Emanet's is "one return" a day | BOI §2, §4, §5; `flow-game.md` §3 | No. The map names no game for Mehtap |
| L7 | Revontuli's wound: three dark, snow-bent lantern towers, the island keeps its own polar night, and the sound heals by subtraction | BOI §2 | No. Not on the map's plates |
| L8 | Emanet: lilac fog over the island, a hat-on-umbrella "fog shape", press to part the fog | BOI §4 | No. The map's plate has no fog |
| L9 | Mehtap: a star dims while you watch (a 6 s fade) | BOI §5, lead 11-06 | No |
| L10 | Every stage rule: one stage a day, only on a day with a resisted reach; chroma steps 0.5→1.0; one warm focal light at stage 0 | BOI §0, ARC | No (ARC derives from C3) |
| L11 | Islands never pay seeds; a healed flow island has no replay | `flow-game.md` §3-§4, Koke prototype §1 | No. It clashes with C14 and C15 |
| L12 | Nazlı form 2: one tap between three back gardens, default after 10 s | BOI §6.4 | No |
| L13 | Book One ships 16 hand-made flow boards (8 Çağlayan, 4 Revontuli, 4 Mehtap) | `flow-game.md` §3 | No |
| L14 | A fixed weekday per resident (code: own weekday weighted higher; Thursday Yosun; Saturday a "bee keeper") | B1 §6, `VisitorSchedule.swift:70` | Partly against C19 (see X9) |
| L15 | Deep lore: seven keepers (Balaban at Çağlayan, Ayaz at Revontuli, Gümüş at Emanet…), Ihlamur the dormouse, the Koke hill is Nazlı's mother | DL §3, §6 | Not answered. The tracker lists "founder's questions (Ihlamur, Koke as Nazlı's mother)" as open |
| L16 | Çanlar debuts the recall engine ("dinle ve tekrarla") | Map card (lead's map), BOI §7.1 | Indirectly. He confirmed Çanlar as a filler (C11), not the engine |

## 3. Contradictions and possibly-wrong facts

| # | Claim | Conflict and evidence | Severity |
|---|---|---|---|
| X1 | FI 536: "Çağlayan's stream came out of an otter-shaped statue" (stated as fact) | Both map plates show a plain stone spout in a cream boulder, no otter shape: `A/map-caglayan-spout-stuck.jpg`, `A/map-caglayan-spout-healed.jpg`. No take in the repo has an otter statue (all Çağlayan takes: `A/caglayan-concepts-sheet.jpg`, `A/caglayan-b34-damla-sheet.jpg`). The nearest image is Damla pouring from her glass (`x-res2-damla-grand`). His own words were tentative ("ama olmaya da bilir") | high (direction) |
| X2 | The built Çağlayan follows the approved concept | It does not: map (batch-34) vs build (batch-43 / lead picks), `A/Q-caglayan-drift.jpg`. batch-34's review even calls its own stone "warm travertine terraces", so the founder's "not travertine" means the white terrace concepts (batch-17/18), not the warm cream stone | high |
| X3 | Map: "havada donup kalmış bir şelale" (a waterfall frozen in mid-air) | The built stage 0 has a full, mirror-still pool, a dry cliff and no frozen curtain (`batch-43` brief: "the pool a dark still mirror"). The map's stuck plate has the frozen curtain with hanging drops, half-dry pools and leaf boats aground | high |
| X4 | Söz 1: "Mochi değirmen taşına çay döker, okur" | Code line `caglayan.line.3` (speaker Mochi, `CaglayanLayout.speaker`) says "Çay koyuyorum. Duvarda yazıyor…" ("the wall"); `CaglayanLayout` doc comment and the changelog say "Mochi reading the mill's wall". Reading on the mill stone through spilled tea (the DL §4 mechanic) is lost | low |
| X5 | `flow-game.md` §4: the home gift is "a waterfall off home's edge" | The map: "Evdeki havuzun çeşmesi akar". The code does the map's version (`HomeFountainView`). The doc is stale | low |
| X6 | B1 §9.3: "the seventh filler is Leylek (the seasonal one)" | The map says "+ 7 filler, **1 mevsimlik**" (`A/tx/p2-01.jpg`), so Leylek is that seasonal one and cannot also be the seventh filler. The map draws six fillers; the seventh is still undefined (likely a miscount on the lead's map) | medium |
| X7 | DL line 217: "Ihlamur's lantern, brought from Emanet, hangs on the hook" | The map has the lantern fished out at Olta (Revontuli's ice hole) and riding to the finale. DL's lore table was "unchanged" in the reconciliation (B1 §7) | medium |
| X8 | B1 §7: invented names dropped, Gümüş among them | DL §3 still has Gümüş as the 4th keeper and Boncuk's grandmother. The code still has a `.keeper` (bee keeper) visitor on Saturday (`VisitorSchedule.swift:76`), although BOI's decision 5 drops "the bee keeper" | medium |
| X9 | Map: "İyileşen her adanın sakini **kendi gününde** eve gelir" (fixed weekdays) | His words: "karakterler haftalık değil… günlük" (C19). The code is a weighted daily draw (own weekday likelier), closer to him than the map. The code comment "The seven main islands in story order" is wrong (it lists Koke, Gezgin, Arı; Gezgin before Revontuli) | medium (ask Q-A-6) |
| X10 | ARC: "Koke stands up and the island blooms around it" (as built) | Map: Koke's secret is for Book Two, and "Uzakta Koke bir kez nefes alır" at the finale; DL §6: the hill is a sleeping Carrier. The built stage 4 and "Tepe horluyor" reveal it on day ~8 (`A/shots/koke-stages.jpg`) | high (story) |
| X11 | The Koke prototype (stage 3): "Mochi reads the carved stone" | A filler "Ana hikâyeyi taşımaz" and the map has only 4 Söz lines. The built line ("Taşta yazıyor: 'Uyudum. Kusura bakmayın.'") is Sumi's apology without Sumi; Sumi is not in the Koke scene code | medium |
| X12 | ARC's variety and per-island tables | They still list Arı as an island ("tired, low hum, no bees"). Revontuli's "black night sky" clashes with BOI's "never black". Emanet's fog "parts where you look" vs BOI's "where you touch"; "residents collect" is not in BOI | low |
| X13 | BOI §2 Revontuli (dark towers; batch-45 stage 0 on an **earth** plate with a moon) | The map: "bir buz adası" with an ice body, a cabin, a lamp post and the fishing hole (`A/revontuli-sheet.jpg`, `A/map-revontuli.jpg`). The batch-45 take departs from both the ice body and the map's props | medium (Q-A-4) |
| X14 | HUB islandScores: gezgin 7, revontuli 10 | His chat says Gezgin 10/10 and Revontuli "basit" (C18), and FI 324 has Gezgin 10, Revontuli 7. The Hub data looks swapped. Trust the chat | low |
| X15 | Map card "Damla: … şaşkın **samur**" | "Samur" is a sable; an otter is "su samuru". Docs, code and art all draw a river otter. Player-facing text should not say "samur" alone | low |
| X16 | Damla's end state | The map card says "şelalenin tepesinde dolu bardak" (the code's stage 4 puts her at the top), but the map's ÇÖZÜLME and healed plate say "Damla sırtüstü süzülür" (floats in the pool). Both can be true in sequence | low |
| X17 | `content/` stale vs the map | `char-nane` "keeps the star book on Yıldız" (Mehtap now); `char-lale` "leaves one line about each city" (map: clatters her beak); `char-kil` "works when quiet" (map: a cold kiln); `island-kaplica` and `char-pamuk`/`char-bulut` are "planned" despite C22; game-plan §6 still names "Kitap" as Book Two's second island (C22) | low |
| X18 | `home-progression.md` §7: Mehtap/the finale yields "sea glass (deniz camı)" | Nothing on the map; sea glass belongs to Yakamoz (the sea), and Mehtap's map object is "ay taşı" | low |
| X19 | `flow-game.md` §3 "no replay… all caught up" vs `home-progression.md` §7 "its rounds after that pay one more now and then" | The two docs contradict each other, and both fall short of C14/C15 | high (system) |
| X20 | `tracker.md` 139: "flow and recall not started" | Flow is built (#297; 8 boards in `flow-boards.json`; the island is playable in #315) | low |
| X21 | `minigames.md` §6 "Engine: SpriteKit" vs the brief's "SpriteKit-free" | Both are true: the mini-games (`PofuGames`, garden and flow) are SpriteKit; the world (`PofuWorld`) is SwiftUI Canvas plus Metal shader effects (iOS 26 target). Water on the island is world code | info |
| X22 | `minigames.md` §8: a mechanic per island (Koke tile-match, Çömlek merge, Emanet Wordle, İskele sort…) | Superseded by "three engines" (game plan §5), but he liked Çömlek's minigame (C25). The filler template "never debut an engine" kills it silently | medium (Q-A-5) |

**Story map transcription (B1 vs the PNGs).** Checked line by line at 2x (`A/tx/p1-*.jpg`, `A/tx/p2-*.jpg`). The
Turkish is faithful: every card, Söz line, tag, gift and beat matches. Problems are in B1's lead notes,
not in the transcription itself:
(a) the status line calls the map "canonical", while the page says "ÖNERİ" and "lead önerisi, kurucu
onayına" (L1); (b) §9.3 counts Leylek as the 7th filler (X6); (c) §6 "Çarşamba Emanet's parcel (Boncuk)" (the
map says only "kapıda bir paket", not that Boncuk comes); (d) the cast table drops the species shown in the
pictures (Pofu a hamster, Mochi a lop bunny, Fındık a hedgehog, Simit a ginger kitten); (e) the page's footer
"devamı 2. sayfada…" and its source line are omitted (harmless). The founder's PNG copies (3200 px) and the
repo PNGs (2000 px) differ only in resolution as far as checked.

## 4. Built vs designed

| Node | Built (verified) | On paper only |
|---|---|---|
| Ayçiçeği home garden | The block-puzzle garden (`PofuGames/Core`, SpriteKit), painted tiles | — |
| Gezgin / Nazlı | Rig masters (`nazli-body/-fins/-tail/-eyes-closed/-island-patch`, #232); **not in the app** (tracker 131) | Back sockets N1-N6, form 2, Yosun, the memory tap |
| Koke | `WonderIslandID.koke`, five stages, plates, lines, the moss gift (screens `koke-stages.jpg`) | Sumi (not in scene code), the Monday visit exists only as a roster entry |
| Çağlayan | `CaglayanScene.swift`: 5 plates (batch-43), Damla (2 poses), the note, the pool light, **code falls off the underside at stage 4** (Canvas ribbons, scrolling highlight, mist), `HomeFountainView` gift, Tuesday visit; flow game `PofuGames/Flow` with **8 boards**, tap-to-rotate, undo, hints | The map's look, the frozen falls, leaf boats, rainbow motion, Söz on the mill stone, Damla floating |
| Çanlar | — | The recall engine, the four-tone sketch, art `batch-52` (proposal) |
| Revontuli, Olta, Emanet, Mehtap | `x-*-stuck/healed` concepts (batch-34), batch-45 wounds, resident concepts (batch-26) | Everything in code; production art; the light and moon skins |
| Fillers Martı Kayası, Fanus, Pervane, Çömlek; Leylek; Yakamoz | batch-17 concepts for Fanus, Çömlek, Leylek, Çanlar, Koke (`A/fillers-sheet.jpg`); none for Martı Kayası, Pervane, Yakamoz | Everything |
| Arı | `hive-1…3` home masters | The dance, `hive-4/5` |
| Visitors | `VisitorSchedule` (weighted weekday draw, reasons, quiet days, invitations), roster of 7 | Resident-to-resident scenes (C20) |
| Water tech | Canvas ribbons (falls, fountain); `WorldShaders.metal` (grade), `SpikeShaders.metal` (relight, depth blur) via SwiftUI `colorEffect`/`layerEffect` | No water shader, no water research doc (`docs/research` has none) |

## 5. Questions for the founder

Visual questions carry images. Paths are absolute. Turkish, short, one decision each.

**Q-A-1 · Çağlayan nasıl görünsün?**
"Haritadaki Çağlayan'ı (yuvarlak havuzlar, taş oluk, değirmen) beğenmiştin; oyuna farklı bir tane (kayalık basamaklar) girdi. Hangisi?"
- **A. Harita (batch-34).** Senin onayladığın; yuvarlak havuzlar yaprak kayık oyununa ve yükseltmelere (§6.5) yer açar. Bedeli: 5 aşamalık plaka yeniden üretilir (bir Codex turu), kod aynı kalır.
- **B. Oyundaki (kayalık).** Hazır ve çalışıyor; ama senin onaylamadığın bir görünüm ve daha "genel" bir şelale.
- **C. Karışım.** Harita düzeni, arkada basamaklı kısa bir şelale. Bedeli: yeni bir konsept turu ve risk.
- **Öneri: A.** Onayladığı görünüm o, ve oyun sistemine en uygun düzen o.
- Görseller: `A/Q-caglayan-drift.jpg`, `A/caglayan-concepts-sheet.jpg`

**Q-A-2 · Su nereden çıksın?**
"Haritaya büyüterek baktım: su, samur heykelinden değil, kayaya oyulmuş düz bir taş oluktan çıkıyor. Samurlu görüntü büyük ihtimalle Damla'nın kartı (bardaktan döküyor). Hangisi olsun?"
- **A. Taş oluk (haritadaki gibi).** En sade; Damla tek samur kalır. Teknik olarak en kolay: dar bir su şeridi.
- **B. Samur biçimli taş çeşme (yeni konsept).** Hikâyeye bağlanır: eski bekçinin Damla için oydurduğu heykel. Ama iki samur yan yana kalabalık ve konsept turu gerekir.
- **C. Damla'nın bardağı (son aşama).** Aşama 4'te Damla kayanın tepesinde, bardağından şelaleye su döker (haritadaki kart). A ile birleşir.
- **Öneri: A + C.** Oluk aşama 0-3'ün kaynağı olur, aşama 4'te Damla tepede dolu bardağıyla oturur. Teknik fark yok: suyu her seçenekte kod çizer (§6.4).
- Görsel: `A/Q-caglayan-source.jpg` (A oluk, B'ye en yakın kart, C oyundaki, D travertin), `A/map-caglayan-spout-stuck.jpg`

**Q-A-3 · "Başta daha kötü, sonda çok daha canlı": ne kadar?**
"Haritadaki tıkalı/iyileşti resimleri birbirine çok yakın. Ne kadar açalım?"
- **A. Hafif.** Harita resimleri gibi, biraz daha soluk başlar. Ucuz ama senin istediğin his gelmez.
- **B. Belirgin (öneri).** Aşama 0'da yarayı tek kelimeyle söyleyebilirsin (kuru, karanlık, sisli, yıldızsız) ama ada yine büyülü durur. Aşama 4'te imza hareket, ışıklar, kalabalık ve küçük canlılar gelir, ada evden bile görünür (§6.3 tablosu).
- **C. Sert.** Yıkıntı, kırık yapılar. Çok etkileyici ama Pofu'nun sıcaklığından uzaklaşır; sen "full yıkık olmasın" demiştin.
- **Öneri: B.** Senin 11-05 ve 11-07 sözlerine birebir uyar.
- Görseller: `A/map-mehtap.jpg` (fark çok az), `A/shots/koke-stages.jpg` (oyundaki Koke, fark büyük), `/home/user/pofu/design/art/takes/batch-45-beautiful-wounds/x-emanet-stage0-fog/contact.jpg` (sisli güzel yara örneği)

**Q-A-4 · Revontuli'nin yarası**
"Haritada Revontuli bir buz adası: kulübe, fener direği, buz deliği. Sonradan yıkık fener kuleleri ve toprak bir ada denendi. Hangisi?"
- **A. Harita (buz ada).** Senin "farklı renk, kar, su; yeni hissettiriyor" dediğin hâl; yara: aurora hiç doğmamış, direk sönük.
- **B. Yıkık kuleler (batch-45).** Senin "biri yıkıntı olsun" fikrin; ama buz adası kaybolur ve Çağlayan'a benzer bir toprak ada olur.
- **C. Buz ada + üç küçük devrik fener direği.** Buz kalır, "yıkıntı" hafif dozda gelir, her aşamada bir direk kalkar.
- **Öneri: C.**
- Görsel: `A/revontuli-sheet.jpg`

**Q-A-5 · Koke uyansın mı?**
"Oyundaki Koke son aşamada ayağa kalkıp yürüyor (çok tatlı). Ama haritada Koke'nin sırrı Kitap 2'ye saklı ve finalde 'uzakta Koke bir kez nefes alır'. Hangisi?"
- **A. Uyanık kalsın (oyundaki).** Tatlı ve hazır; ama finaldeki o anın etkisi biter.
- **B. Uyusun, çiçeklensin.** Gözü kapalı, gülümser, yosunu çiçek açar; Sumi yanında. Finalde bir kez nefes alır. Bedeli: yalnız aşama 4 resmi yeniden üretilir.
- **Öneri: B.** Kitabın en güzel son vuruşlarından biri bu, ve maliyeti tek bir resim.
- Görseller: `A/shots/koke-stages.jpg`, `/home/user/pofu/design/art/takes/batch-17-islands-v2/x2-koke-b/contact.jpg`

**Q-A-6 · Misafirler: sabit gün mü, sürpriz mi?**
"Haritada her sakinin bir günü var (Salı Damla…). Sen 'haftalık değil, günlük sürpriz' demiştin. Oyunda şu an: her gün kura, kendi gününde gelme ihtimali daha yüksek."
- **A. Karışık (şu anki).** Kendi günü en olası gün; boş günlerde sen davet edersin.
- **B. Sabit gün.** Tahmin edilebilir; ama sürpriz yok.
- **C. Tam sürpriz.** Gün kavramı yok; ama "Salı Damla gelir" gibi küçük ritüeller kaybolur.
- **Öneri: A.**
- Görsel: `A/map-sidebar1.jpg` (Günlük misafir kartı)

**Q-A-7 · Çömlek'in mini oyunu**
"Çömlek'e 4 vermiştin ama 'karakter ve mini oyun eğlenceli' demiştin (kil birleştirme, Suika gibi). Sonra '3 mini oyun yeter' dedin. Çömlek'e kendi oyunu gelsin mi?"
- **A. Hayır.** 3 oyun kalır (bahçe, akış, dinle-tekrarla), Çömlek bir şaka adası olur.
- **B. Evet, Kitap 1'de.** 4. oyun: daha çok çeşit, ama iş yükü artar.
- **C. Sonra.** Çömlek Kitap 1'de şaka adası kalır, birleştirme oyunu ilk güncellemeyle gelir.
- **Öneri: C.**
- Görsel: `A/fillers-sheet.jpg` (Çömlek a/b)

**Q-A-8 · Ada iyileşince ne olur?** (system; illustrated with the map's pools)
"Ada iyileşince oyunu bitiyor mu? Senin isteğin: 'kazanmak durmasın, birkaç ada aynı anda gitsin'. Önerim §6.5: iyileşen ada kendi oyununu korur; günün hak edilmiş turları adanın malzemesini ve adanın kendi 3 küçük yükseltmesini getirir."
- **A. Bitiyor.** Ada bir manzara olur. Basit ama senin isteğine ters.
- **B. Hak edilen turlarla devam (öneri).** Malzeme, ada yükseltmeleri ve eve hediyeler gelir; sınırsız değil.
- **C. Sınırsız ama ödülsüz.** Oynamak serbest, ödül yalnız hak edilen turlardan gelir.
- **Öneri: B + C.** Hak edilen tur ödül verir, fazlası serbest oyun olur (senin "evet ile sınırsız arası").
- Görsel: `A/map-caglayan-healed.jpg` (yaprak kayıklı yuvarlak havuzlar = yükseltme yerleri)

## 6. Proposed decisions (lead to adopt or change)

**6.1 Book One order and set (lock).** The map's order stays: Ayçiçeği → Gezgin early → Koke → Çağlayan →
Çanlar, Martı Kayası → Revontuli → Olta → Fanus, Pervane → Emanet → Çömlek, Arı (home) → Mehtap finale →
Yakamoz, Yosun's letter. Leylek is the seasonal card, not a filler. The "7 fillers" count is corrected to
**six fillers + one seasonal** on the map's legend in the next map revision. This counts honestly; adding an
island just to hit a number is worse. The four main islands (C12 allows 4-5) stay at four.

**6.2 Overlap (C15 vs "Kapı, gün değil").** Allow two islands at once, without overdoing it: the next
island's rumour shows when the current main island reaches stage 3, and the island arrives after its bloom
plus the quiet days (unchanged). Fillers may run beside a main island. A healed island keeps its loop (6.5).
At most one main island plus one filler is unhealed at any time.

**6.3 Stage 0 / stage 4 calibration (draft; Q-A-3 sets the amplitude).** Each island gets one wound word.
Stage 0 has a full value range and one warm light (C4); stage 4 adds motion, crowd and light, visible from home.
The curve rises: each stage 4 is a little bigger than the last (C18), and Nazlı's form 2 is the top.

| Island | Stage 0 (worse than the map) | Stage 4 (livelier than the map) |
|---|---|---|
| Koke (filler) | as built (grey, asleep): already strong | blooming, asleep, smiling; Sumi rakes letters; fireflies at dusk; it **breathes once** when tapped at dusk (a hint only) |
| Çağlayan | "kuru": the curtain frozen mid-air with hanging drops (the map's line), side pools dry, leaf boats aground, the wheel dusty, a dragonfly-less silence; the warm light: one sunbeam on the frozen curtain | falls pour with a rainbow, **the water also pours off the underside** (built, C26), leaf boats sail the three pools, the wheel spins, the mill window lit, dragonflies, Damla on top with a full glass, then floating |
| Revontuli | "karanlık": the ice body dull grey, the cabin snowed in except the sauna window, the lamp post dark, three toppled small lantern posts (Q-A-4 C), wind | aurora curtains moving, the ice body glowing in the aurora's colours (as the map's healed plate), every post lit along a path, steam from the sauna, Tuli's tail painting strokes, the ice hole mirroring |
| Emanet | "sisli": lilac fog (batch-45), heaps everywhere, blank tags, dark window | every thing shelved and tagged, warm window, the bell on the counter rings, small critters arrive to collect parcels (a short queue loop), the cart full |
| Mehtap | "yıldızsız": a sky with no stars, the pool pewter, the dome shut, Nane asleep, one star dims (L9) | the full chart: seven faint trails and the bright new one over the sky, the pool a silver mirror, the dome open, Nane flying, a shooting star now and then |
| Nazlı | form 1 tired, faded, face toward the camera (C8) | form 2 (the map), sings |
| Fillers | one oddity, smaller amplitude | one payoff (Çanlar's chord and bell wave) |

**6.4 Water tech (feasible in our stack; no new engine).** The world is SwiftUI with Canvas and Metal
shader effects on iOS 26. What exists: `CaglayanFalls` (tapering Canvas ribbons, a scrolling highlight, a
mist puff) and `HomeFountainView`. Recommended build, in order of cost:
(1) the **painted plate carries the water's shape** (art), and code only animates it;
(2) a **`layerEffect` shader** on a painted water mask, scrolling a small noise texture downward (falls) or
in rings (pool caustics). The shader library and the effect plumbing exist (`WorldShaders`), so this is one
shader of about 40 lines plus a mask per stage. `island-caglayan.yaml` already proposed exactly this;
(3) Canvas foam and spray dots, plus the existing mist;
(4) the frozen falls at stage 0 is the cheapest of all: a still painted curtain, with drops that bob 1-2 pt.
A statue mouth or a stone spout is a narrow stream, cheaper than a full cliff falls, so **the water source
choice (Q-A-2) is a taste question, not a tech risk**. Budget: render only while the ambient clock runs
(30 Hz when visiting, 0 when settled, as `CaglayanIsleView` does). Before any art, a one-day spike checks the
shader on device at 120 Hz and its thermal cost; it goes in `docs/research/` as "water-2d" (none exists).

**6.5 Island gameplay systems (proposal; for C16/C17).** One model for all: **heal** (stage rounds, one stage a
day on a resisted day) → **live** (after stage 4 the island keeps its game; each earned round on it pays its
material, at most 1 a day as in home-progression §7, plus an island toy for free play) → **upgrade** (three
small island upgrades bought with that material and seeds; each adds life to the island and one thing seen
from home or on Nazlı). Engines stay three (C13): place, connect, recall. Islands also get small **acts** and
**toys** that need no new engine.

| Island | Heal (stages 1-4) | Live loop after healing | Island upgrades (3) | Seeds? |
|---|---|---|---|---|
| Koke (filler) | as built: a visit advances a stage | toy: **rake the moss garden** (draw patterns that fade; brings back his liked Japanese note), Sumi answers a letter a week | none (filler) | no |
| Çağlayan | flow, 2 boards a stage (built) | **Leaf-boat run**: an earned flow board each day sends a leaf boat to a pool; pays berrak su | 1 lily pads and frogs in the side pools · 2 a second small wheel and a mill lantern · 3 Damla's slide | material only |
| Çanlar (filler) | recall debut (3-4 notes) | toy: free bell play (no reward); a new phrase from Zil on his visit day | none | no |
| Martı Kayası (filler) | act: one barter a visit (tap a trinket, the gulls answer) | none | none | no |
| Revontuli | flow + light (prism) | **Sauna sit** toy: hold to sit 10 s in silence, the aurora brightens (ties to "a minute with Pofu" on the app side); earned light boards pay ışık | 1 lantern path · 2 a second sauna bench (Tuli's grandmother's) · 3 an ice slide | material only |
| Olta (midpoint) | act: hold to fish (cannot fail), the lantern | **fishing stays** at the ice hole: one earned cast a day fishes a small keepsake or sticker (Animal Crossing's proven loop) | — | no |
| Fanus, Pervane (fillers) | one act each (open the jar's lid / Pofu's short walk) | none | none | no |
| Emanet | one return a day (drag, cannot fail) | **"Kimin bu?"**: one parcel a day, returned from three clues (the Wordle-like idea in `minigames.md` §8); pays emanet | 1 a second shelf bay with a display · 2 the bell and a queue of collectors · 3 a parcel slide to Nazlı | material only |
| Çömlek (filler) | one act (light the kiln) | merge pottery later (Q-A-7 C) | none | no |
| Mehtap | flow (moon thread), lead L6 | **star-joining** stays: each calm night adds a star to the player's trail (map BASAMAK); an earned thread board joins a named constellation | 1 telescope views of other islands · 2 a hammock · 3 the moon pool reflects home | material only |
| Arı (home) | — | the bee dance over the garden; Saturday honey | home ladder (area B) | — |

Why: it answers C14/C15 exactly ("between earned and unlimited", "earning does not stop", several islands at
once) without a fourth engine. It keeps seeds out of islands (ADR-0015 is untouched: seeds never buy screen
time), and every upgrade is something visible (Cats & Soup). Doc changes: `flow-game.md` §3 drops "no replay";
home-progression §7 states "one material a day from a healed island's earned round".

**6.6 Characters (lock).** Names and species as the map shows them: Pofu (hamster), Mochi (lop bunny), Fındık
(hedgehog), Simit (ginger kitten), Nazlı (cloud whale), Yosun (tortoise), Damla (river otter; player text
"su samuru"), Tuli (white arctic fox), Boncuk (magpie), Nane (owl), Sumi (dormouse), Zil (bell-ringer
mouse), Zümrüt (glass frog), Kil (potter mole), Lale (old stork), the gulls, the moths, Ihlamur (the old keeper,
dormouse, never seen in Book One). Drop the Saturday `.keeper` visitor (Arı's honey arrives as an object).
Mark `char-pamuk`, `char-bulut`, `island-kaplica`, `island-kitap`, `island-yildiz` as cut or Book Two (C22).
Fix `char-nane`, `char-lale`, `char-kil` to the map.

**6.7 Story fixes (lock).** Söz 1 is read on the mill stone through spilled tea (fix `caglayan.line.3`: "stone", not
"wall"). DL line 217: the lantern comes from Olta. ARC: drop Arı's row and point at BOI. Koke stage
3: move the stone line to Sumi herself (she apologises), keep no Söz at fillers. HUB scores: record Gezgin 10 /
Revontuli 7 from his words.

**6.8 Mehtap's moon (keep L5).** A fixed moon is the map's tag and a strong real-world ritual; the door timing
absorbs the wait. The lead keeps it without asking, because it is the map's own word.

## 7. Next steps (by value)

1. Put Q-A-1, Q-A-2, Q-A-3 to him on one visual sheet (the Çağlayan page first; his three Çağlayan words
   decide most of the art).
2. On his answer: a Codex batch that re-roots Çağlayan's five plates in `batch-34/x-caglayan-healed` (the
   stuck plate as an edit) with the frozen-curtain stage 0 and the livelier stage 4; the code keeps its anchors,
   so only `CaglayanLayout` positions move.
3. The water spike (6.4): one `layerEffect` shader on the healed plate's falls and pool, on device,
   with frame time and thermal numbers; write `docs/research/water-2d.md`.
4. Write the per-island systems (6.5) into `book-one-islands.md` as a "Live and upgrade" row per island;
   fix `flow-game.md` §3-§4 and home-progression §7 (X5, X18, X19).
5. The text fixes in 6.6 and 6.7 (strings, `content/`, DL, ARC, B1 §6/§9.3, tracker 139), as one docs PR.
6. Koke stage 4 regen (if Q-A-5 B), plus Sumi in the scene (rake, letters).
7. Concept-first batches for Revontuli (Q-A-4) and Emanet/Mehtap stage 0 and 4 at the calibrated amplitude,
   each judged against the map plates on the lookdev sheet.
8. The recall engine and the four-tone sketch for Çanlar (the long pole; recommend after the Çağlayan rework).
9. The Nazlı rig in the app at the harbor (form 1, face to camera, C8), with the first back piece (the pool).
