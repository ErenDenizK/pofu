> Archived 2026-11-07: an audit input to [the decisions register](../../product/decisions.md). Image paths are relative to the session scratchpad and are not in the repo.

# C. The app, UI, tech and process (audit 2026-11-07)

Auditor C (Opus). Read-only. Sources: `founder-messages.md` (FM, by UTC
timestamp), `hub-notes.md` (HUB), `docs/product/founder-input.md` (LOG, the
lead's paraphrase), docs, code on `main` at `8746fc3d`, open PRs via the REST
API, screenshots from `origin/screenshots/main` (rendered 2026-11-06 19:33 at
`8746fc3`, i.e. current main). Extracted images and contact sheets:
`C-shots/`
(below: `C-shots/<file>`). I looked at every image I cite.

Limits: the Hub's question texts (what "q-monetization D" etc. mean) are
not in the repo (`design/hub/index.html` loads them from the Hub db), so
option letters are reported, not interpreted. No onboarding, Earn, Passes
or Hop! rung screenshot exists on any screenshots branch.

## 1. Confirmed by the founder (his words)

| # | Item | His words (verbatim) | Date, source |
|---|---|---|---|
| F1 | The wall must be a wow design masterpiece, not a flat wall with plain text | "Duvarın hala düz duvar ve plain text olmasını istemiyorum. Yani o özellikle duvar ekranı gibi ekranların wow etkisi yaratan tasarımsal bir masterpiece gibi olmasını istiyorum." | 11-06T06:58 FM |
| F2 | What matters before membership: screens, UI, usage, the wall, the shield | "Önemli olan hani ekranlar, UI, oyunun kullanımı, uygulamanın kullanımı, o açılan duvar, kalkan menüsü vesaire." / "Bana üyelik geldikten sonra bile bir iki gün içerisinde çözebiliriz." | 11-06T06:58 FM |
| F3 | A background made for the Hop! screen (assets or Codex), so it is whole | "hop ekranına özel, hani tam fixleyemeyiz çünkü POF'un hareket animasyonları vesaire var ama arka plan tarafında ... kodekse de yaptırabiliriz o ekrana, en azından bütün olur." | 11-06T08:29 FM |
| F4 | "Boş ver" screen as stunning as the break screen; every UI component world-class | "Boşver ekranı da mola ekranı gibi aşırı harika göz alıcı bir tasarım ve görsel olmalı. Ben böyle olmasını istemem. ... her bir uı menü açılır ekran uygulamaya ait her bir bileşen harika gözükmeli hissettirmeli kullanılmalı" | 11-06T09:47 FM |
| F5 | Shield, breath, gate feel the same; decide how many screens; criticise the gate harshly | "Shield breath gate benim için 3'ü çok yakın ... temiz kafayla kaç ekran olacak nasıl ne zaman niçin olacak bir öncekinde breath derken shield'ı kastetmiştim ama gate'i de sertçe eleştir" | 11-06T10:10 FM |
| F6 | Asked why Apple allows only one template (no recorded reaction to the answer) | "niye Apple tek bir şeye izin veriyor? Bu kalkan değil, öbürü mü, hangisi bu? ... Sonuç olarak bizim ekranımız değil mi?" | 11-06T11:49 FM |
| F7 | The bottom-right icon is very bad; flat menu icons fine, need not be glass; vectorise later | "görsellerde sağ alttaki ikon çok kötü ... illa hani camı bırakmana gerek yok ... Normal düz menü ikonu tarzı ikonlar da üretebiliyor ... gerekirse sonrasında vektöre geçiririz" | 11-06T06:52 FM |
| F8 | Keep glass AND custom painted menus together | "Yaptığımız custom menüleri kesinlikle ekleyelim. Ama hani camı da tamamen kaldırmayalım. Cam ve hani custom'ı birleştirmek her zaman bizim unique şeylerimizden biri." | 11-05T17:12 FM |
| F9 | All menus top quality; shield and loading screen too; use Codex art; approves the lead's ideas | "tüm menüler genel olarak şık temiz ve üst kalite olmalı ... bir de kalkan olur loading screen olur menüleri de çok iyi hale getir gerekirse codex görselleri kullan ... fikirlerini onaylıyorum" | 11-05T17:25 FM |
| F10 | Menus stutter on open/close; menus too simple; wants to see Codex's icons in menus | "menü açıp kapanırken kasmalar var ... açılan menülerin de UI'ni iyileştirebiliriz. Çok hani simple kaldı ... bir sürü ikon vesaire yaptırmıştık kodekse. Onlar gelmedi" | 11-05T16:24 FM |
| F11 | No makeshift buttons; fit the whole UI | "Tüm UI'yi ona göre uygun yap. Uyduruk tuşlar kalmasın." | 11-05T22:27 FM |
| F12 | Performance: stutter and heat; next build must be optimized; not playable without dev menu; app logo ready | "Optimizasyon kötü ... kasıyor ve telefon ısınıyor ... geliştirici menüsü olmadan ne oyunu açabiliyordum ... uygulama logosu vesaire ... hazır hale gelsin" | 11-05T09:30 FM |
| F13 | 60 fps is good for beta; 120 Hz vs battery is an open question (not a decision) | "60 FPS bence çok iyi bir hedef ... acaba hani 120'ye çıkarsak ... pil olarak daha mı iyi olur? Bilmiyorum. Bu konuda da konuşabiliriz." | 11-05T17:12 FM |
| F14 | Strengthen both sides: the blocking app and the game | "hem hani bunun uygulama tarafını hani Android tarafını, Doom Scrolling tarafını, engelleme kısmını ... hem de ... oyun işlevini" ("Android" is very likely a dictation slip for the app side; the product is iOS-only, ADR-0002) | 11-05T17:12 FM |
| F15 | Navigation: map button + three-way dial is broken UI; an idea, not an order | "hem harita butonu var hem üstte 3 tane tuşlu dial var" / "Navigasyon ... sadece bir fikir belirttim" | 11-05T17:12, 17:33 FM |
| F16 | Study Apple Design Award apps, to learn | "Apple'ın Design Award'u almış bir takım uygulamaları var ... Bunlara bak" | 11-05T17:12 FM |
| F17 | A doomscroller must see the effect, game and app | "iyi bir oyuncunun da her şeyi deneyimlemesi lazım ama çok doomscrollayan kişi de etkisini görmeli. Hem oyun hem uygulama tarafı." | 11-06T06:08 FM |
| F18 | In the game, the UI is the game; current left-hand UI not OK | "soldaki UI'a okey olmadığımı belirtmek isterim ... özellikle oyun kısmında UI'ın doğrudan oyunun da kendisi olduğunu unutmayalım" | 11-02 HUB r-rehearsal |
| F19 | UI direction: B, but "something different"; find the middle way | "bu konuda korkumu belirttim, tekrar değerlendirelim doğru orta yolu bulalım" / "daha farklı bir şey istiyorum ... eski bir soru kaldı" | 11-02 HUB q-ui-direction, r-ui-direction-b |
| F20 | Sound B; supports procedural music from chords | "akorlar progresyonlar kullanarak müzik ve ses efektleri yapmanı da destekliyorum sanırsam, sadece aradaki ince çizgiyi konuşalım" | 11-02 HUB q-sound |
| F21 | Prices: ~350/year, ~1000 lifetime "like", DLC not tips; free core vs membership to feed the game | "yıllık 350 (ya da 349), tek seferlik 1000 (ya da 999) gibi yapabiliriz, bahşiş değil dlc satabiliriz ... ana özellik tamamen ücretsiz mi ya da feature ücretsiz ama oyuna işlenmesi için üyelik gerekli" | 11-02 HUB q-monetization (answer D) |
| F22 | Where to charge is open; fun first | "inanılmaz acil değil, şimdilik açıkta bırakabiliriz ... ücret her zaman daha sonra" (q-paywall-cut C); "fiyatlar zaten hemen hemen okay hani Nerede Ücret isteyeceğimiz kısmı net değil sadece" | 11-02, 11-03 HUB |
| F23 | Pricing doubts after the story got shorter: one-time? acts (350, 450)? subscription? what happens to the island at lapse? 350 TL feels right; abroad priced differently | "oyunu direkt one time payment'a mı çeksem? ... act mi satsam? Mesela her act 350 TL ... üyeliğin bitti. Direkt kilitleniyor mu? ... 300-350 TL bence hani bu tarz bir ürünün tam hakkı" | 11-05T20:09 FM |
| F24 | Pricing details come later, from him | "fiyat noktasında detayı sonra vermek istiyorum" | 11-07T06:46 FM |
| F25 | Hub answers in my area (letters only; meanings not in repo) | q-minute A, q-earned-play A ("evet ve sınırsız arasında bir yerdeyim ... her adanın bir mini-oyunu olursa o döngü sınırsız gidebilir"), q-economy-scale A, q-friends B ("B daha sonra C önerisi güzel"), q-sound B, q-ui-direction B | 11-02 HUB |
| F26 | Never ask visual questions without visuals; no PDFs for now | "Bir daha görselsiz sorma" (q-plate); "şu anlık bir PDF ihtiyacı yok" | 11-03 HUB; 11-06T11:49 FM |

Log-only (his verbatim is not in my sources; LOG states it): free `Pofu`
build and the Shortcuts path get no new features (LOG "Standing decisions",
2026-11-02); targets Instagram, YouTube, TikTok (LOG); prices "approved"
(LOG 2026-11-02 "Money"; see X12).

## 2. Lead decisions he has not confirmed

| # | Decision | Where | His reaction |
|---|---|---|---|
| L1 | **The Door:** two places (Apple's shield + one in-app scene); six screens become states Arrive, Breath, Choose, Boş ver, A minute, Hand-off; payoff as `DoorStamp` | `docs/design/the-door.md` (11-06) | None recorded. 11-06T11:19 "Burayı baştan yapılacak değil mi? Bana hazırla tüm raporlarını çıkar bakıcam" is the next message; its referent is unclear. Big: needs his yes (Q-C-1) |
| L2 | **Round door** as the gate direction (`batch-48` t1, production `batch-58`) | gate-v2.md §v2.1; tracker §6.2 "decided ... shown to the founder" | No reaction in FM. Taste: Q-C-2 |
| L3 | **ADR-0020**: painted surfaces, paper at every sheet detent; glass kept only "if the founder misses it" for round chrome | ADR-0020; ui-v3 §5, §7 | Conflicts with F8 (X3). Q-C-3 |
| L4 | One verb colour (honey), retire system violet; Baloo 2 for titles | ui-v3 §1 | None (consistent with F9/F11) |
| L5 | Breath haptics on by default (Settings toggle), amends gate v2 §6.5 | ui-v3 "Lead decisions" | None; "the founder feels it on device" not done |
| L6 | Shield: round mood medallions, hour colours, copy rewrite, drop "Huzur ×1,4" | ui-v3 §3 | None; F1 asked for more than the template allows |
| L7 | Door stamp built as wax seals on the earth that stay all day (not the doc's plaque/card) | ui-v3 §3b "Built"; #303 | None |
| L8 | Icon style: two-tone flat take 2 (#269), sliced into the place control and menus | tracker "Added 11-06" | Not shown to him after F7. Q-C-4 |
| L9 | Settings night rows warm instead of purple-indigo; drop the duplicate "Ayarlar" title | tracker "Added 11-06" | None (small; lead's call) |
| L10 | 120 Hz while touching, 30-60 ambient, 0 settled, written as "agreed plan" | LOG 11-05 night | He only asked (F13). Lead's call, but not "agreed" |
| L11 | **Monetization v2**: one membership 129,99/349,99/999,99 TL, $5.99/$29.99/$89.99; gate free; nothing taken back; acts sold one by one rejected; free cut after Act I (at Olta) | monetization-v2.md; story-map §9 follow-ups; tracker §6.1 | Open; he defers pricing (F24). Only listed (Q-C-5) |
| L12 | No naming step in onboarding | gate-v2 §16 Q3 | Asked in the doc; no answer recorded |
| L13 | Notification content extension (long-press Door), Live Activity paper strip, "today's pots" widget, week page sharing the sky | ui-v3 §3c-d; LOG 11-06 fourth | None |
| L14 | Pofu Hub frozen; chat is the channel | tracker §5 | None needed |

## 3. Contradictions and possibly-wrong facts

**X1. Seeds still buy screen time in the built gate (most serious).**
ADR-0015 ("Seeds never buy screen time"), CLAUDE.md ("seeds never buy
screen time"), the story map §1.3 ("Tohum ekran süresi satın almaz") say
no. Code: `PofuCore/Gate/FrictionLadder.swift` keeps rungs pause → intent →
**pay** → askFriend; `EconomyConfiguration.swift:155` defaults
`highestAttemptRung: .pay`; `Gatekeeper.beginCheckIn` registers every Hop!
on the ladder; `App/Hop/HopView.swift` renders "Spend %lld seeds for %lld
min" (TR "%1$lld çekirdeğe %2$lld dk al") on the pay rung. A second reach
within the cooldown therefore climbs to intent, a third to paying seeds for
minutes, in both builds. Gate v2 §14 E9 ("Hop! v2: care rung ... no intent
rung", depending on `CareLedger`/`CalmAccrual`/`BreathRules`) is unbuilt;
`economy.md` admits "PofuCore still implements v0 until the change lands".
Neither the tracker nor the roadmap lists it. (Verified by reading code; not
run on device.)

**X2. The built gate breathes on every open and says "Vazgeç".** The pause
rung (first reach) shows "Önce bir nefes." and a `BreathOpenButton` that
fills for 5 s ("5 dakikalığına aç" looks disabled) before you may open
(`HopView.swift:333-363`; `C-shots/sheet-gate.jpg`). ADR-0015/gate v2 §6.5
keep the breath for past the daily threshold only. The skip button is
"Vazgeç"; the shield says "Boş ver"; the shield subtitle itself says "Bugün
2 kez vazgeçtin." (`ShieldCopy.swift:381`). Breaks the Door's one-word rule
in three places.

**X3. Glass.** He said keep glass with custom (F8). ui-v3/ADR-0020 put paper
at every detent; current sheets are paper (`C-shots/sheet-glass-old.jpg`:
old glass sheets left, paper right). Tracker §2.5 still says "Menus: painted
plus glass ... built".

**X4. The "wall" he wants as a masterpiece is Apple's shield.** F1 names "duvar"
and "kalkan menüsü"; the shield cannot be a masterpiece (one colour, ~60 pt
icon, two labels, two buttons; `C-shots/19-shield-day.jpg`). The lead moved
the wow into the Door (LOG 11-06 noon), and answered F6 in chat. He has not
said he accepts the trade. Needs Q-C-1.

**X5. The Door is blocked on art, and no doc says so.** the-door.md §4 builds
`DoorScene` "when batch-58 lands". PR #312 (gate-door-repost): only the
composite scene is delivered, with palette_drift **forced**, at **512 × 768**
(half resolution, too small for a full-screen hero); `gate-door-bank`,
`-interior`, `-leaf` skipped after retry; `-plaques` and `-grass` pending;
mergeable_state dirty. No `DoorScene`/`DoorState` exists in code.

**X6. The breath room redesign has no art.** PR #299 (batch-62): `breath-scene`
failed palette_drift on all four takes, so `breath-isle`, `-isle-night` and
all cloud layers are dependency-skipped; only `breath-halo` and
`breath-ring-spark` promoted. The built breath room uses a code isle and
grey pill clouds (`C-shots/sheet-breath.jpg`). ui-v3 §4's layer list cannot
be built as written.

**X7. UI kit v3 art is half there.** PR #296: 16 masters, 5 skips, 13 pending.
Every **night** surface failed (`ui-sheet-paper-v3-night`,
`ui-card-stitched-night`, `ui-face-disc-v2-night`), so ui-v3 principle 9
("lamplit paper at night") has no art; `ui-plaque-honey-pressed` and
`ui-stamps` skipped; bubbles, chips, tags, toasts, groove pending. The kit on
main is code-drawn (`KitMaterial.swift`; `C-shots/kit-v3-day-large.jpg`).

**X8. Empty states are exploration, not production.** PR #298 (batch-63) is
"EXPLORATION ONLY, never promoted"; ui-v3 §5/§6 treat it as the empty-state
art. `x-pofu-yawn`, `x-settings-header`, `x-shield-icons-night` pending.

**X9. ui-v3 §6 numbering:** the table names batch "63" twice (breath room and
empty states); a footnote fixes it (62, 63) but the table is unchanged.

**X10. Tracker: English rename is wrong.** §2.17 ("never opened as a PR"), §3
#25, §6 #6 and the roadmap Process row say the rename waits for a window. It
merged: #130 (map), #132 (Swift ids, 11-03), #137 (assets, 11-04);
`docs/development/rename-map.md` shows no remaining layer rows.

**X11. Tracker/roadmap stale elsewhere.** "The world is almost silent" (§1,
§2.13, §3 #6) vs `d06769fe feat(sound): the world's first sound pass`
(`SoundCue` has levelUp, doorKnock, kettle, waterWheel/Splash/Pour; four
ambience beds). §2.4 "pick a direction from #268" and §5 "the gate v2 spec
was never written" vs #268 merged and gate-v2.md §v2.1 (11-06). §2.12 "flat
icons in PR #269", §2.14 open-PR list (#253, #259, #264, #266, #268-#270 all
merged), §3 #7, #24 (flow game #297, Çağlayan #315 built). Roadmap: header
"Last updated 2026-11-05"; "In review: #212"; the tracks table still says
"Spec the gate v2 ... batch-48", "Icons: the flat icon sheets", "Çağlayan:
a game-design note first", "Merge SW-1/SW-3", "English rename"; it never
mentions the Door or UI v3 waves.

**X12. "Prices approved" overstates him.** LOG says "Prices approved: 349,99 TL
a year, 999,99 TL lifetime" and tracker §2.16 "approved by the founder". His
words: "gibi yapabiliriz" (F21), "hemen hemen okay" (F22), then "detayı sonra
vermek istiyorum" (F24). The monthly 129,99 TL and all US prices are the
lead's alone.

**X13. Free cut fixed by the lead vs "leave it open / by data".** Story map §9
follow-ups and monetization v2 §2.1 set "free cut after Act I, at Olta"; he
said "şimdilik açıkta bırakabiliriz" (F22) and LOG 11-02 records "decided
by data". Roadmap "Open questions" still says "measured in the beta":
three docs, two positions.

**X14. "Agreed" 120 Hz plan** (LOG 11-05 night): he asked a question (F13).

**X15. Violet is not retired.** ui-v3 says one honey verb colour, but main
shows the violet "Topla" pill and paw pin (`C-shots/sheet-world-ui.jpg`:
`01-home-visit-light`, `07-map-light`), a violet SF smiley on the resident
card (`08`), a violet teacup glyph on Today v3 and purple-indigo Settings
night rows (`C-shots/sheet-menus.jpg`). Wave 3 (home chrome, world cards) is
unbuilt; tracker lists only the Settings rows.

**X16. Station sheet (world path) still overlaps.** `17-sheet-station-medium-glass.jpg`
on main: a text line sits under the build plaque (a "Ç…" glyph peeks out,
`C-shots/crop-sheet-stray.jpg`), and the plaque shows a live price "İnşa et ·
14" above "İnşa etmek yakında açılıyor". The v3 harness shot
(`17-sheet-station-v3-*`, drawn on a flat grey/black backdrop) does not show
it. Tracker §3 #10 "never clips" may be true only in the v3 harness: verify
in the app.

**X17. ADR index and old headers.** `docs/adr/README.md` has no 0020 row and
0018's row lacks "amended by 0020". `app-game-boundary.md` says "No ADR-0019
for now" (ADR-0019 now exists for another topic). gate-v2.md header says
"Last updated 2026-11-01, proposal" though §v2.1 was added 11-06 and most of
it is built.

**X18. Unverified platform claims the Door depends on.** gate-v2 §1.1-1.2 and
ui-v3 §3: iOS 26.4 `secondaryButtonSubmenuItems` (three strings) and iOS 26.5
`.openParentalControlsApp` ("may finally open Pofu directly ... spike on day
1"). If the latter works, the Door opens straight from the shield and the
notification hop disappears; the-door.md does not mention this branch. Both
are "verify on device".

**X19. Ambiguity in F4.** LOG reads "Boşver ekranı da mola ekranı gibi" as
"the shield should be as stunning as the break screen". Given 10:10 ("breath
derken shield'ı kastetmiştim"), it may instead mean "the skipped (Boş ver)
screen, like the shield, must be stunning". The Door covers both readings;
no question needed, but the LOG's "Handled" is an interpretation.

**X20. Settings shows the frozen Shortcuts layer in the Screen Time build.**
`SettingsView.swift:43-67`: "Canlı Pofu (isteğe bağlı)" lists all seven
`ProtectedApp` cases (incl. X, Snapchat) and "Set up automations" whenever
`screenTime.isAvailable` (`C-shots/sheet-menus.jpg`). Not a new feature, but
it is the most prominent block of Settings for a path we freeze and for apps
outside the three targets.

**X21. ADR-0018 vs ui-v3 on glass, and ui-system-v2 (11-02, "proposal")**
describes Glass++ as the direction; superseded in practice by ADR-0020 and
ui-v3 but not marked.

## 4. Built vs designed

Screens (state on main `8746fc3d`; image = what I looked at)

| Screen / system | Built | Designed only / missing | Evidence |
|---|---|---|---|
| Shield (Apple template) | Hour palettes, round mood medallion icon (`ShieldMoodIcon`, 180 px), copy engine, "Boş ver"/"Açmam lazım", Huzur removed | Night medallion set (pending #298), 26.4 submenu, `.openParentalControlsApp` spike; only on device after membership | `ShieldStyle.swift`, `C-shots/19-shield-day.jpg` |
| Notification | Text notification to Hop! | Mood-medallion attachment, content extension (Door on long-press) | `GateNotificationContent.swift` (28 lines, no attachment) |
| Hop!/gate landing | Painted postcards by hour (+rain, mist), plaque buttons, old friction ladder (pause, intent, pay, askFriend), skipped state with "Pofu'yla bir dakika", hand-off text, `ResistPayoffStore` | The Door (`DoorScene`, state machine, door swing, rope plaques), care rung (3 dk/15 dk), E9 | `GateScene.swift`, `HopView.swift`, `C-shots/sheet-gate.jpg` |
| Breath room | v3 layout: ring (`BreathRing`), `BreathHaptics` (Core Haptics swell, Settings toggle), `PofuBreathing`, code isle + code clouds, sound tone | Painted isle/clouds/Pofu breath poses (batch-62 failed) | `BreathRoom.swift`, `BreathScene.swift`, `C-shots/sheet-breath.jpg` |
| Payoff | Wax seals on the home earth, stay all day; screen haze parts | Painted `seal-resist` (in #296 as `ui-seals`, unmerged) | `PofuDoorStamp.swift`, `C-shots/payoff-door-day-3.jpg` |
| Launch | Sky + "Pofu uyanıyor…" | Sleepy Pofu peeking, Baloo 2 line, yawn (`x-pofu-yawn` pending) | `C-shots/21-launch-curtain-and-line.jpg` |
| Onboarding | 8 steps (welcome, Screen Time, apps, name, setup, notifications, try it, caught); Live build skips naming | Gate-look redesign (wave 3C), 55 s target; **no screenshot exists** | `OnboardingView.swift` |
| Today | v3 day card: code-drawn island sketch, "Henüz açma isteği yok", seed count, Pofu bubble, violet teacup | Wax seals per resist, jar, painted strip, empty-state art, motion | `TodaySheet.swift`, `C-shots/sheet-menus.jpg` |
| Settings | Painted header (Pofu badge), sections Pofu, Screen Time, Live Pofu (Shortcuts), Sound, Breath, Rehearsal; night = purple-indigo; duplicate "Ayarlar" | Warm night rows, painted Settings header art, real app icons, flat-duo row icons | `SettingsView.swift`, `C-shots/sheet-menus.jpg` |
| Station sheet | Paper v3, five pot pips, never clips in v3 harness | Build out of the sheet (camera to stake, dust, card); X16 | `StationSheet.swift` |
| Home chrome | Gear disc, glance pill "Bugün 3/4 · 15 dk", violet "Topla", white speech bubble, place control (white disc + duo glyph) | Wave 3A: clay disc, honey plaque, paper bubble, chrome follows world light | `C-shots/sheet-world-ui.jpg` |
| Map / archipelago | One camera, place control morphs; home + İskele; Çağlayan map shot | Paper name flags, drawn Pofu pin, rumours, empty-map art | `C-shots/07-map-light.jpg`, `caglayan-map.jpg` |
| Resident card | System-like popover, SF smiley, grey capsule | Paper tag on string, sticker face, honey plaque | `C-shots/sheet-world-ui.jpg` |
| Passes, Earn, Setup guide | Built (old style) | Wave 3C restyle; no screenshots | `App/Home/PassesSheet.swift`, `App/Earn/EarnSheet.swift` |
| Live Activity, widgets, week page | none (no widget extension) | ui-v3 §3d, LOG 11-06 | `Extensions/` has only DeviceActivityMonitor, ShieldAction, ShieldConfiguration |
| Component kit | Code-drawn kit (`Kit/`: plaque, paper, sheet, material, components, BreathRing) | Painted faces from #296 (day only; night failed) | `C-shots/kit-v3-day-large.jpg` |
| Icons | Duo glyphs sliced (`paint-duo-*`: add, close, gift, home, island, letter, map, settings, shield); app icon (#167) | 18-glyph set, clay disc; vectors | `PofuDesignSystem/Resources` |
| Sound (`PofuSound`) | Garden cues, collect, skip chime, Pofu hop, level-up, door knock, kettle, water, 4 ambience beds; stops 3 s after last cue | Procedural chord music (F20), visitor/gift/evening bell, breath pad beyond a tone | `SoundCue.swift`, `Resources/` (43 files) |
| Haptics | `PofuHaptics` palette in sheets, Koke, Hop; breath swell | Full moment table; one TODO (`WorldHome.swift:122`) | tracker §3 #18 |
| Accessibility | Reduce Motion widely; XXL shots for Today/Settings/station | VoiceOver sweep on the world; AX audit; onboarding/Door at XXL | tracker §3 #19 |
| Performance | Frame policy (#194), freeze world under sheets, MetricKit telemetry (dev), audio engine sleeps | No device measurement since 11-05; 120 Hz waits | tracker §2.15 |
| Screen Time | `PofuLive` target + 3 extensions, ledger, lift, breath plan past daily hour | Membership day 1 (after 11-24); merge `Pofu`+`PofuLive` | roadmap App track |
| Monetization | nothing (no StoreKit) | monetization v2 (proposal) | — |

**Tech debt.** (1) Economy v0 friction ladder inside the gate (X1).
(2) Two app targets (`Pofu`, `PofuLive`) with `FeatureFlags` and Rehearsal
mocks until day 1. (3) Shortcuts layer in Settings (X20). (4) Code-drawn
stand-ins everywhere the painted kit failed (night UI, breath room, Door).
(5) `BreathRoom` and the skipped screen still separate views; the-door.md
retires them. (6) Notification path to Hop! relies on time-sensitive
notifications (gate v2 §1.2 failure modes). (7) Only one TODO in Swift: debt
is in docs drift, not code comments.

**Open PRs (describe only).**
- **#135** docs/lore-loop-decisions (11-03): folds loop-1/2 decisions into
  lore bible and story delivery; "leave open: needs the founder's agreement";
  stale (tracker §3 #20 recommends close and carry two ideas). Its worktree
  `/home/user/wt-lore` is the only extra worktree.
- **#108** tooling/art-operator-recovery (11-03): SQLite-backed imagegen
  recovery CLI, 3 files, +1048; pipeline ran without it; tracker recommends
  close unmerged.
- **#296** batch-61 UI kit v3: see X7; draft, CI interim pass, not final.
- **#298** batch-63 empty states: exploration only; 6 done, 3 pending (X8).
- **#299** batch-62 breath room: see X6.
- **#309** batch-64 flow pieces: 8 promoted, bend/rock/flowered grass skipped,
  rest in progress (story/game area; not mine).
- **#312** gate-door-repost: see X5; mergeable_state dirty.
- **#317** docs/tracker-caglayan: one tracker line.

**Branches and worktrees.** `git worktree list`: main checkout (on
`chore/day-plan-2026-11-07`) and `/home/user/wt-lore` (#135). Remote: 199
non-screenshot branches, **166 already merged and not deleted** (incl.
`refactor/english-rename-map`, `feat/growth-readable`), 32 unmerged (11
design/docs branches from 10-31/11-01, 5 `backup/*`, `chore/batch-19-loop-2-manifest`,
`docs/art-queue-status-2026-11-05`, an `archive/koke-repost` ref, the open
PRs). About 66 `screenshots/*` branches. 63 local branches.

**Docs hygiene.** Stale or superseded, not marked: `docs/design/ui-system-v2.md`
(proposal 11-02; Glass++), `docs/product/ux/user-flows.md` and
`information-architecture.md` (proposals 10-31, pre-ADR-0015 ladder),
`docs/design/design-language.md` (v1.0 proposed 10-31), gate-v2 §6.1-6.5
(superseded by the-door.md for the in-app screens; the-door.md says so, gate
v2 does not). Tracker/roadmap: X10, X11. ADRs: keep immutable; do not
archive. Fix the index (X17); 0008/0012/0014 are "amended by 0015" and the
code still runs their old rule (X1), so the honest fix is code, not docs.

## 5. Questions for the founder

**Q-C-1. Kalkan ve Kapı (the "wall").**
TR: "Kalkan Apple'ın ekranı: tek renk, küçük ikon, iki yazı, iki düğme. Onu
masterpiece yapamayız. 'Vay' etkisini nereye koyalım?"
- **A.** Kalkan sade ve özenli kalır (saate göre renk, Pofu madalyonu, iyi
  söz); bütün vay bizim **Kapı** sahnemizde (açılan yuvarlak kapı, Pofu,
  ip üstünde tabelalar) + ertesi açılışta mühürler. Boş ver hâlâ tek dokunuş.
- **B.** Kalkan sadece "Pofu'ya git" der; her uzanışta Kapı açılır. Vay her
  seferinde, ama Boş ver 1 dokunuştan 3-4 adıma çıkar ve kalkan uygulamayı
  açamadığı için bildirime basmak gerekir (iOS 26.5'te değişebilir).
- **C.** Kısayollar yolu: tamamen bizim ekranımız, ama her uygulama için
  kurulum, sistem bandı, uygulamanın bir an görünmesi, kolay atlanır; ve
  "Kısayollar'a yeni özellik yok" kuralını bozar.
- **Öneri: A.** Ürünün kalbi tek dokunuşla Boş ver; vay, istediğinde ve
  tamamen bizim olan yerde. B'yi `.openParentalControlsApp` ilk gün
  çalışırsa yeniden açarız.
- Görseller: `C-shots/19-shield-day.jpg` (kalkan bugün),
  `C-shots/sheet-gate.jpg` (bugünkü Hop!), `/home/user/pofu/design/art/takes/batch-58-gate-round-door/gate-door-scene/contact.jpg`
  (Kapı sahnesi), `C-shots/payoff-door-day-3.jpg` (mühürler).

**Q-C-2. Kapı'nın görünüşü.**
TR: "Uygulama içi Kapı ekranı hangi dünyada olsun?"
- **A. Yuvarlak kapı** (Pofu'nun evinin kapısı, içeride sıcak oda, ipte
  tabelalar). Kalkan madalyonu ve evdeki kapıyla aynı yer; içeri girip "bir
  dakika" geçirmeye uygun. Sanatı yeniden, tam çözünürlükte, katmanlı
  çizdirmek gerekiyor (ilk deneme yarım çözünürlük, katmanlar düştü).
- **B. Hale ve adacık** (gözleri kapalı Pofu, ışık halkası, gün batımı).
  Nefes için çok güzel, ama "kapı" hissi yok; nefes odasıyla aynı ekrana döner.
- **C. İskele ve gökyüzü** (Pofu kenarda çayla, fenerler). Sakin ve geniş;
  seçenek tabelalarına yer az, ev ve kalkanla bağı zayıf.
- **Öneri: A**, B'nin halkası Kapı'nın Nefes durumu olarak içinde.
- Görseller: `/home/user/pofu/design/art/takes/batch-58-gate-round-door/gate-door-scene/contact.jpg`,
  `/home/user/pofu/design/art/takes/batch-48-gate-scenes/x-gate-round-door/contact.jpg`,
  `/home/user/pofu/design/art/takes/batch-48-gate-scenes/x-gate-breath/contact.jpg`,
  `/home/user/pofu/design/art/takes/batch-48-gate-scenes/x-gate-pier-sky/contact.jpg`.

**Q-C-3. Cam mı kâğıt mı (menüler).**
TR: "'Cam ve custom birlikte' demiştin. Şu an menüleri kâğıda çevirdik. Ne
yapalım?"
- **A. Her yer kâğıt** (sıcak, tek aile; arkadaki dünya görünmez).
- **B. Karma:** dünyanın üstündeki paneller cam, Pofu'nun içerikleri (kart,
  balon, tabela) kâğıt/ahşap. "Unique" dediğin birleşim; gece camı bulanık
  kalabilir, iyi ayar ister.
- **C. Yuvarlak düğmeler ve üst şerit cam, paneller kâğıt.** Cam az ama hep
  görünür; en temiz okuma.
- **Öneri: C**, sonra B'yi bir panelde deneyip sana iki görüntü yollarız.
- Görseller: `C-shots/sheet-glass-old.jpg` (soldaki iki: eski cam; sağdaki
  iki: şimdiki kâğıt), `C-shots/sheet-menus.jpg` (Bugün ve Ayarlar şimdi).

**Q-C-4. Sağ alttaki ikon ve ikon stili.**
TR: "Sağ alttaki düğme hâlâ beyaz daire. Hangisi?"
- **A. İki renkli düz ikon + boyalı kil daire** (kahve çizgi, krem, yosun
  yeşili; ahşap/kil disk). Oyunun dokusuna uyar, vektöre çevrilir.
- **B. Tek renk düz ikon** (en sade, en okunur; biraz "sistem" hissi).
- **C. Şimdiki gibi** beyaz daire + küçük ikon.
- **Öneri: A** (disk sanatı hazır: `ui-face-disc-v2`; ikonlar uygulamada).
- Görseller: `C-shots/crop-place-control-now.jpg` (bugün),
  `/home/user/pofu/design/art/takes/batch-46-flat-icons/x-icons-flat-duo/contact.jpg`,
  `/home/user/pofu/design/art/takes/batch-46-flat-icons/x-icons-flat-solid/contact.jpg`,
  `C-shots/pr296-ui-face-disc-v2-contact.jpg`.

**Q-C-5. Fiyat: sen detayı verdiğinde cevaplanacaklar (karar yok, sadece liste).**
TR: "Fiyatı sen vereceksin; şu soruların cevabı lazım olacak:"
1. Yıllık ~349,99 ve ömür boyu ~999,99 TL kalıyor mu? Aylık olacak mı, ne kadar?
2. Tek üyelik mi, yoksa act/kitap satışı mı (senin 350/450 TL act fikrin)?
3. Ücretsiz kısım nerede biter: Act I sonu (Olta), ev adası sonu, yoksa
   beta verisine göre mi?
4. Kullanıcı kesim noktasını önceden bilsin mi?
5. Üyelik bitince: ada ve kazanılanlar kalır, yeni hikâye durur (öneri
   böyle); başka bir şey mi istersin?
6. Kapı/kalkan her zaman ücretsiz mi (Apple 4.10 bunu zaten ister), yoksa
   "özellik ücretsiz, oyuna işlemesi üyelikle" fikrin mi?
7. Yurt dışı fiyatları ve deneme/indirim teklifleri.
8. Aile Paylaşımı açık mı?
- Görsel gerekmez (görsel soru değil).

## 6. Proposed decisions (lead adopts or changes)

1. **Remove the pay rung now** (X1): the Screen Time and free builds stop
   letting seeds buy minutes; build gate v2 E9 as the Door's Choose state
   (Boş ver · 3 dk bak · 15 dk aç). This is his rule (ADR-0015), not a
   question. Add it to the tracker as the top app item.
2. **Breath only past the daily threshold** (X2); delete the 5 s breath on
   every first open; one word "Boş ver" in Hop!, shield copy
   (`ShieldCopy.swift:381` → "Bugün 2 kez boş verdin."), notification, toasts.
3. **Lock the Door's structure** (two places, six states) pending Q-C-1;
   add the `.openParentalControlsApp` branch to the-door.md (X18).
4. **Unblock the Door's art** (X5): one Codex job for the round door at full
   resolution (1179 × 2556 canvas or 2× layers) with an acceptance profile
   that allows the warm interior (the palette_drift failures are the
   profile, not the painting); meanwhile build `DoorScene` on the composite
   with a code door leaf and the code plaques, so the state machine ships
   and the art swaps by file name.
5. **Night UI**: write a `night` acceptance profile for #296's night jobs
   (the README says they omit it) before re-running; until then night
   surfaces are code-drawn paper-night, never purple-indigo (X7, X15).
6. **Breath room**: drop the full composite; ask Codex for the isle and the
   cloud bands as independent jobs (no parent), keep halo and spark (X6).
7. **Glass**: adopt Q-C-3 C as the default until he answers; update ADR-0020's
   wording only through a new ADR if he picks B.
8. **Violet out** (X15): one PR swaps the remaining violet (Topla, paw pin,
   resident smiley, Today teacup) for honey/cocoa; Settings night rows warm;
   duplicate "Ayarlar" title removed.
9. **Settings, Shortcuts layer** (X20): keep the path (frozen), but collapse
   "Canlı Pofu" into one "Kısayollar (isteğe bağlı)" row in the Screen Time
   build; list only Instagram, YouTube, TikTok there. Removal, not a feature.
10. **Pricing**: record his position honestly (X12, X13): "approved" →
    "his working numbers (~349,99/year, ~999,99 lifetime); details from
    him"; the free cut stays a default to test, not a decision.
11. **120 Hz**: lead's plan stands (touch 120, ambient 30-60, settled 0), worded
    as the lead's, measured on device before shipping.
12. **Onboarding**: no naming step (gate v2 §16 Q3); rebuild in the Door's
    look after the Door; add onboarding to the screenshot harness first.
13. **Docs**: rewrite the roadmap's Status and tracks from the tracker; fix
    tracker X10/X11; mark ui-system-v2, user-flows, information-architecture,
    design-language "superseded" and move to `docs/archive/`; add the ADR
    index row for 0020; fix gate-v2's header; fix ui-v3 §6's batch numbers.
14. **Repo hygiene**: delete the 166 merged remote branches and stale local
    ones; close #108 and #135 (carry #135's two live ideas per tracker §3
    #20) and remove `/home/user/wt-lore`; keep `backup/*` until Codex
    confirms they are not needed.
15. **Device ritual**: the next phone build carries a checklist (gate, breath
    haptic, menus open/close stutter, heat, seals) since nothing since 11-05
    is device-checked (F12, F10).

## 7. Next steps (ordered by value)

1. Send Q-C-1 to Q-C-4 with the listed images (one sheet each); Q-C-5 only
   as a list for when he gives prices.
2. PR: remove the pay and intent rungs from the Hop! path, breath only past
   the threshold, "Boş ver" everywhere (decisions 1-2), with `PofuCore`
   tests; screenshot sheet of the new landing at 07:00/12:00/22:30.
3. PR: `DoorScene` state machine (`App/Hop`) on the composite + code
   leaf/plaques; retire `BreathRoom`/skipped as states; sheet per the-door.md §4.
4. Codex: round door at full resolution with a fitted acceptance profile;
   breath isle/cloud bands as independent jobs; night profile for #296.
5. PR: violet out, Settings warm night, Shortcuts block collapsed
   (decisions 8-9); check X16 in the app and fix the overlap.
6. Docs PR: tracker and roadmap corrections, ADR index, archive moves
   (decision 13); log the Door/glass/icon answers in founder-input.md.
7. Onboarding and Hop! rungs into the screenshot harness; then onboarding
   in the Door's look.
8. Merge #296 day pieces and swap the code kit's faces; empty states only
   after a production pass on #298's picks.
9. Branch and worktree prune; close #108, #135.
10. Device build with the checklist; frame meter at night; decide 120 Hz.
11. Notification attachment (mood medallion), then the Live Activity and the
    widget with the membership build.
