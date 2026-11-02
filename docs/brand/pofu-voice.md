# Pofu's Voice: Rules, Research and the Line Bank

_Status: v1 proposal, 2026-11-02. Founder decision: **personality B**,
sweet and lightly sulky or jealous ("Yine mi Instagram? Onda olup bende
olmayan ne?"). Builds on the [character bible](character.md) (voice and
don'ts), [game design §12](../product/game-design.md#12-pofus-emotional-range)
(the emotion catalog and guardrails), [gate v2
§5.6](../product/ux/gate-v2.md#56-the-copy-system) (the shield's copy
system), and the `ShieldCopy` ladder in
`Packages/PofuKit/Sources/PofuCore/ScreenTime/ShieldCopy.swift`. Sound is in
[sound-identity.md](../design/sound-identity.md)._

Turkish lines are content and stay in Turkish; everything else is English.

## 0. The answer in one page

- **Pofu is funny the way a jealous pet is funny: petty, self-aware, and
  instantly forgiving.** The rival is the app, the algorithm, or your
  thumb. Never you.
- **Five devices carry almost every joke** (section 3): the parenthetical
  self-correction ("Baktım. (Bakmadım. Ama yoktur.)"), melodrama aimed at
  the app (Yeşilçam and arabesk: "Seni ellere yar etmem."), internet
  formats (POV, spoiler, plot twist, VAR, the proverb parody), hamster
  physics (cheeks, hoarding, the wheel), and Turkish daily ritual (çay,
  simit, kahvaltı).
- **Comedy is rationed and decays with the day.** At most two "big" jokes
  on the shield a day and one in Hop!; from the sixth reach of a day the
  lines get plainer and kinder, because a joke on a hard day is noise.
- **Freshness has math** (section 4.4): big jokes never repeat within 14
  days, which needs about 56 in rotation; plain lines are furniture and only
  never repeat back to back. A **remote line pack** (static, anonymous,
  expiring) carries topical lines so a dated meme retires itself.
- **The never-say list** (section 4.5) is a CI check, not a vibe: shame,
  body, health claims, politics, religion, teams, money, exes, death,
  "engellendi".
- **The bank has 157 Turkish lines** (section 5), each tagged with slot,
  tone, the format it riffs on, and freshness. 11 are dated and live only
  in the remote pack; with the seasonal lines, 19 ship through it.
  Section 6 lists the lines I cut and why.

## 1. What makes a mascot land, and what makes it grate

| Character | What lands | What grates | Pofu takes |
|---|---|---|---|
| **Duolingo's Duo** | A real personality with a running bit (the owl that "hunts" you); fans co-write the joke. The February 2025 "death" stunt got about 47 million views on the announcement post in two days, and Duo "returned" when users finished lessons ([Ad Age](https://adage.com/article/digital-marketing-ad-tech-news/duolingo-kills-mascot-duo-new-marketing-stunt/2602261), [NPR](https://www.npr.org/2025/02/13/nx-s1-5295597/duolingo-owl-mascot-death)). | The bit is built on **guilt**: users joked that they had killed Duo by skipping lessons ([Entrepreneur](https://www.entrepreneur.com/business-news/duolingo-says-its-mascot-duo-the-owl-is-dead/486944)). Commentators warned it sends the wrong message ([Lahs Griffin Gazette](https://lahsgriffingazette.com/24073/features/duo-perspectives-on-the-duolingo-marketing-campaign/)) and that a storyline too goofy for the character alienates fans ([NPR follow-up](https://npr.org/2025/02/26/nx-s1-5309785/duolingo-owl-mascot-lives)). | Duo-level personality, aimed at the reach, not the person. Pofu never dies (ADR-0017), so the guilt bit is unavailable by design, which is the point. |
| **Finch** | No "guilt-debt": a missed day is a pause, not a broken streak; warm, non-clinical language ([Habit Box](https://habitbox.app/blog/finch-app-review), [Engadget](https://www.engadget.com/apps/this-self-care-virtual-pet-is-helping-me-get-my-act-together-160027169.html)). | Reviewers call the tone childish for some adults, and a "your pet wants to share something" push still produced guilt ([IU wellness corner](https://geneticslab.medicine.iu.edu/blogs/md-student-news/wellness-corner-a-digital-pet-is-your-self-care-best-friend)). | Finch's floor of kindness, with more bite on top. No notifications that speak for Pofu (A3, A16). |
| **Tamagotchi** | Care as a ritual; a tiny creature you check on. | Death and neglect as the motivator: the original guilt machine. | Already rejected: ADR-0017, wellbeing floor 5. |
| **Neko Atsume** | No stress, no deadlines, a collection that fills by itself; the cats' indifference is the comedy ([nippon.com](https://nippon.com/en/nipponblog/m00083), [MDA analysis](https://mechanicsofmagic.com/2024/04/07/mda-neko-atsume/)). | Nothing; its humour is visual, almost wordless. | Physical comedy first (interaction spec §6.3): most reactions have no line. The residents' indifference (Pamuk) is a running bit. |
| **Pou** | Pure physical slapstick, a body you poke. | Repetition: the same five noises for years; needs-meters that nag. | Rotation and cooldowns (section 4.4); Pofu never asks to be fed. |
| **Clippy** | Nothing, famously. | **Timing**: it interrupted at the wrong moments with advice of limited use ("It looks like you're writing a letter"), and users could not make it go away; Microsoft's own research found most users found it irritating ([Medium, 5 lessons](https://medium.com/twentybn/5-lessons-from-clippys-failure-efc69297eac1), [Mental Floss](https://www.mentalfloss.com/article/504767/tragic-life-clippy-worlds-most-hated-virtual-assistant), [BGR](https://bgr.com/2155953/what-happened-to-clippy-why-microsoft-retired-office-assistant/)). Users hated the program because it had a face ([The New Stack](https://thenewstack.io/?p=6847114)). | **Pofu speaks only when you act** (a reach, a tap, a visit). Never unprompted, never in a notification of his own, always one tap from gone. "Optimize for the hundredth time, not the first." |
| **Spotify Wrapped** | Playful copy as "a core part of who we are as a brand", which people share and parody ([Boston Globe](https://www.bostonglobe.com/2021/12/05/lifestyle/when-did-spotify-wrapped-get-so-chatty)). | Critics call it "trying so hard to be trendy that it ended up incredibly corny" ([MarketSmiths](https://www.marketsmiths.com/2022/spotifys-cringeworthy-copy/)). | Trend words are spice, not the meal. Every topical line expires (section 4.6). |
| **Wordle** | One a day, the same for everyone, a share card with no words. Scarcity makes it a ritual. | — | One ritual a day per island already (game design §7). The weekly recap can borrow the wordless grid. |

**The rule these add up to.** A mascot's joke lands when it is (1) caused by
something you just did, (2) about the situation, not about you, (3) short,
and (4) rare enough to still surprise. It grates when it interrupts,
repeats, or makes you the villain. Duolingo's success is personality;
its risk is guilt. We take the first and are structurally barred from the
second.

## 2. The two internets Pofu talks to

### 2.1 Turkish internet humour (primary)

Research note: web sources on 2025–2026 Turkish meme formats are thin and
mostly SEO noise; the useful public anchors are TDK's 2025 word of the
year, **"dijital vicdan"** (digital conscience) ([NTV](https://www.ntv.com.tr/turkiye/tdk-yilin-kelimesini-acikladi-dijital-vicdan-nedir-1705206),
[Habertürk](https://www.haberturk.com/son-dakika-yilin-kelimesi-dijital-vicdan-oldu-3849228)),
which tells us the audience already thinks about screen use in moral terms
(so Pofu must not add more moralizing), and the global 2025 vocabulary
that Turkish Gen Z imports wholesale. Everything below is written from
native knowledge of the formats and **must be tested with a native panel**
(Q1 in section 8) before the friends beta.

| Format or register | Where it lives | How Pofu uses it | Risk |
|---|---|---|---|
| **Melodrama** (Yeşilçam: "Ya ben ya o!"; arabesk: "Seni ellere yar etmem") | Twitter/X TR, reaction memes, dizi clips | Jealousy as theatre, aimed at the app: the drama is so big it is obviously play | Must stay at the app. "Beni bıraktın" is guilt; "Ya ben ya Instagram!" is a bit. |
| **The parenthetical correction** ("Uyuyor. (Uyumuyor. Ama uyumalı.)") | Ekşi Sözlük entries, Twitter TR deadpan | Pofu's **verbal tic**: he states something grand and then corrects himself | Ration to about one in five lines or it becomes a tic you hate. |
| **Ekşi formats** ("(bkz: …)", "edit:", "spoiler") | Ekşi Sözlük | "Spoiler: yeni bir şey yok." | "bkz" reads old to under-25s; use "spoiler" freely, "bkz" once. |
| **Proverb parody** ("Damlaya damlaya göl olur, kaydıra kaydıra saat.") | Everyday speech, caps | The most Turkish device we have: every user hears the original | Never parody religious sayings. |
| **Street warmth** ("kanka", "aga", "bi sakin", "sakin ol şampiyon") | Everywhere under 35 | Rare, affectionate, Pofu sounding like a friend | ≤ 1 a day; not in the first three days; never in a kind or tired line. |
| **Görüldü / ghostlamak** ("left on read") | DMs, memes | The user leaves Instagram on read: a skip as a power move | Fine: the app is the one ghosted. |
| **The Turkish mom** ("O telefonla evlen!", "kahvaltıda telefon olmaz") | Caps, Reels | Pofu quoting a mom, never being one | Pofu never nags in his own voice. |
| **Football, team-neutral** (VAR, hat-trick, "tribünler ayakta") | National vocabulary | Big-moment framing for small wins | Never a team, a player, or a derby result. |
| **Dizi culture** ("bölüm", "sezon finali", spoilers) | Everyone, every week | Scrolling as a bad episode; "sezon 2 onaylandı" | Show names only in the remote slot, with expiry. |
| **Çay, simit, kahvaltı** | Daily life | Pofu's world (Mochi's çay ocağı, Simit's cart); "tavşan kanı" tea | Evergreen. The safest humour we have. |
| **Superstition** (kara kedi, nazar) | Daily life | "Kara kedi değil, hamster." | Nazar is borderline folk-religious; kara kedi is fine. |

### 2.2 Gen Z English (secondary, and imported into Turkish)

The words Turkish users under 30 already use untranslated: **doomscroll,
brainrot, touch grass, POV, plot twist, NPC, aura, delulu, red flag,
chill**. 2025's markers: Oxford's word of the year **"rage bait"**, with
"aura farming" a finalist ([OUP](https://corp.oup.com/?p=5721)); Cambridge's
"parasocial"; Dictionary.com's **"6-7"**, a deliberately meaningless
brainrot phrase ([AV Club](https://avclub.com/dictionary-dot-com-2025-word-of-the-year-67));
Italian brainrot characters such as Tung Tung Tung Sahur, peaking in March
2025 ([Know Your Meme](https://knowyourmeme.com/memes/tung-tung-tung-sahur-triple-t-baseball-gif)).

How Pofu uses them: **as loan words inside Turkish sentences**, the way
the audience does ("Onlar rage bait, ben huzur bait'im."), never as a
whole English joke on a Turkish shield. Their half-life is short (6-7 was
peak mid-2025 and is already ironic), so every one of them is in the
remote slot with an expiry.

"Brainrot" and "doomscroll" are **the category's words** (Brainrot, Unrot);
Pofu uses them sparingly, and only about content, never as a diagnosis of
the user ("your brain is rotting" is a health claim and an insult).

## 3. Who Pofu is when he talks

**In one line:** a small, round, slightly vain hamster who is a little
jealous of your phone, knows it is ridiculous, and is happy the moment you
look at him.

**The five devices** (every line in the bank uses at least one):

1. **The parenthetical correction.** A grand claim, then the truth:
   "Baktım. (Bakmadım. Ama yoktur.)" It makes Pofu's sulk self-aware,
   which is what keeps jealousy from becoming guilt.
2. **Melodrama at the app.** "Ya ben ya Instagram!" The bigger the drama,
   the clearer it is play. Always followed by an instant climb-down.
3. **Format riffs.** POV, spoiler, plot twist, VAR, sezon finali, the
   proverb parody. The format does half the work; the line is short.
4. **Hamster physics.** Cheeks that hold fourteen seeds, buried seeds he
   forgets, the wheel he quit. **The wheel is the brand thesis**: endless
   scrolling is a hamster wheel, and the hamster is the one who stepped
   off ("Ben çarkı bıraktım. Bak ne güzel ada yaptık.").
5. **Turkish daily ritual.** Çay, simit, kahvaltı, the neighbours. Warmth
   that needs no explaining.

**Register.**
- Informal "sen", inclusive "biz" for anything that is a shared effort
  ("boş verdik"), "sen" for the credit ("çoğunu sen").
- Short. Shield title ≤ 26 characters, subtitle ≤ 60 (gate v2 §5.6);
  bubbles ≤ 45 ideal, two lines max (interaction spec §6.3).
- One "!" per screen at most; no emoji on the shield (the system font
  renders them at full colour, and one emoji outshouts the face).
- Pofu teases situations, never the person (character bible). Pofu's own
  body is fair game ("Ben de büyürüm. Yana doğru."); the user's never.

## 4. The rules

### 4.1 Jealous as play, never guilt

| Play (yes) | Guilt (never) |
|---|---|
| "Yine mi Instagram? Onda olup bende olmayan ne?" | "Yine mi? Beni hiç düşünmüyorsun." |
| "Ya ben ya Instagram! (Şaka. Ama ben.)" | "Beni bırakıp ona gidiyorsun." |
| "Algoritma seni özledi. Ben daha çok." | "Seni çok özledim, neredeydin?" (A20: Pofu is not "away") |
| "Bu saat 4. kez. Instagram bile şaşırdı." | "Bu saat 4. kez. Hayal kırıklığına uğradım." |
| Pofu sulks for one line, then is fine | Pofu stays sad, gets grey, or looks hurt because of a reach |

Test for any line: **would a friend say it to your face and you both
laugh?** If the honest reading is "you did something wrong", it is out.

The jealous budget stays as shipped: at most 3 jealous lines a day, never
two in a row, then kind (game design §12 guardrail 3,
`ScreenTimeGateRules.jealousLinesPerDay`). After a stated reason ("Açmam
lazım" then a reason chip) or a quick check, no jealousy at all
(guardrail 4).

### 4.2 Timing: the ladder

The shipped ladder (gate v2 §5.6, rule 1) picks the **context**; this
section adds the **register** inside each context.

| Signal | What it changes |
|---|---|
| **Reach of the day #1** | The hello. A big joke is allowed (★). Morning pool 06–11, day 11–17, evening 17–bedtime. |
| **#2–#5 of the day** | Normal mix: about one in three lines is a ★ joke, the rest are short "furniture" lines. |
| **#6 and later** | Plainer and kinder. No ★ lines on the shield. A hard day does not need a comedian. |
| **2nd reach this hour** | The callback pool (S2): "we were just here". |
| **3rd+ this hour** | Jealous (S3) within the budget, then kind (SK). |
| **Bedtime** | The night pool (N): sleepy, soft, funny at most once a night. |
| **Wellbeing < 25** | Tired; no jokes at all. |
| **After a pass over 60 min** (worried) | No jokes in the next Hop!. |
| **First three days** | The introduction: sweet and deadpan only; no "kanka/aga", no melodrama (S3 uses the plain jealous titles), no topical lines. The user should like Pofu before Pofu teases. |
| **Resisted run** (3 skips in a row **today**) | The proud pool (ST) in the skip bubble, never on the shield. Never across days (A19: no consecutive-day counts). |

**Budgets per day:** ★ lines ≤ 2 on the shield, ≤ 1 in Hop!, ≤ 1 on the
island. "kanka/aga" ≤ 1. The parenthetical tic ≤ 3.

### 4.3 Where Pofu speaks, and where he never does

- **Speaks:** the shield (title and line 1), Hop!'s bubble, the skip
  bubble, the minute, the island (one line per visit, on a tap or a
  45-second idle beat), arrivals, the hand-off.
- **Never:** notifications (they are functional: "Instagram'ı mı
  açalım?"), the Live Activity, widgets (A18: glances answer, never ask),
  errors, settings, the paywall, onboarding's permission screens (Apple's
  alert is not a place for a joke).

### 4.4 Freshness: rotation with math

A guarded heavy day is 20–40 reaches. If every shield needed a unique
joke, 14 days would need 400 lines. They do not, because most shields
should be quiet. The bank is split into weights:

| Weight | Mark | Cooldown | Daily use | Needed in rotation |
|---|---|---|---|---|
| **Big joke** | ★ | 14 days per line | ≤ 4 (2 shield, 1 Hop!, 1 island) | ≈ 56 |
| **Light** | ◦ | 3 days | as the ladder allows | ≈ 30 |
| **Furniture** | (none) | never the same title twice in a row (shipped rule 2) | any | ≈ 20 |

The bank below has 69 ★, 55 ◦ and 33 furniture lines (46 ★ are
eligible from the first week; the rest wait for an island, a resident, an
app or a date). That is short of the 56 a full rotation needs, so the
bank covers about eleven days at the full budget without repeating a big
joke (the founder's 7-day dogfood fits), and the first remote pack adds
ten before the friends beta. After that, the pack adds about ten ★ lines a
month.

**Selection** (replaces `(dayOfYear + reachesToday) % count` for pools
with cooldowns): the eligible lines are those whose conditions match and
whose cooldown has passed; pick by a stable hash of (date, reach number,
line id) so the choice is deterministic and testable; if nothing is
eligible, fall back to furniture. The extension already writes a context
file to the App Group (`lastTitle`); it gains `lastShown: [lineID: day]`.

### 4.5 What Pofu never says

A CI check (section 7) rejects any line containing these, in both
languages.

| Never | Why | Examples cut |
|---|---|---|
| **Shame or blame** | Tease the app, never the person (A12) | "Yine mi sen?", "Hiç ders almıyorsun" |
| **Guilt verbs** | The Duolingo trap | "üzdün", "kalbimi kırdın", "beni bıraktın", "terk ettin", "hayal kırıklığı" |
| **The body** (the user's) | Never a joke about weight, looks, posture, eyes | "Göbek yapacaksın", "Gözlerin bozulacak" |
| **Health claims** | We cannot back them, and they moralize | "dopamin", "beynin çürüyor", "brainrot'un ilacı", "uykun bozulur", sleep science numbers |
| **Mental health words** | Not ours to joke with | "depresyon", "anksiyete", "DEHB", "travma" |
| **Politics, religion, ethnicity** | A national minefield; no exceptions | Leaders, parties, "zam", "asgari ücret", "enflasyon", religious phrases (including "maşallah", "inşallah") |
| **Football teams or players** | Half the country instantly hates the line | Any club name, colours, "derbiyi kim alır" |
| **Relationships and exes** | The funniest and the cruellest; it is about the person | "Eski sevgilinin story'sine mi bakacaksın?" |
| **Death, even as hyperbole** | ADR-0017 | "öldüm", "ölüyorum gülmekten", "Pofu öldü" |
| **Disasters, war, news** | Never topical in that direction | "deprem", any current event |
| **Gate vocabulary** | Gate v2 rule 5 | "engellendi", "blocked", "limit", "ceza", "penalty", "yasak" |
| **Streak counting across days** | A19 | "3 gündür", "serini bozma", "streak" |
| **Swearing, even soft** | The audience's register is not Pofu's | "aq", "mq", "lan" |
| **Real people and brands** other than the guarded app's own name | Legal and dating | celebrities, influencers, other apps, Spotify only as the generic "Wrapped" |

### 4.6 The remote slot (topical and dated lines)

- **Bundled** lines ship in the app. **Remote** lines arrive in a small,
  static JSON **line pack**, fetched by the app at most once a day while
  in the foreground (never by an extension), stored in the App Group, read
  by the shield extension like bundled lines.
- Each line carries `id`, `slot`, `tr`, `en`, `weight` (★ ◦ furniture),
  `conditions` (apps, hours, weekday, date window, island unlocked,
  min day of use), `notBefore`, `notAfter`. **Every remote line expires**
  (default 90 days, meme lines 60). The pack can also **retire** any
  bundled line by id, our kill switch for a line that lands badly.
- The app re-runs the same checks as CI (length, banned words, one "!")
  on load and drops a failing line silently.
- Privacy: an anonymous GET of a public static file; no identifiers, no
  analytics, no personalization on a server. The repo is public, so the
  pack is reviewed in a PR like everything else.
- Lines marked **R** below start in the pack, not in the bundle.

## 5. The line bank

**Key.** Slot codes: **S1** first reach of the hour (day), **M** morning,
**E** evening, **S2** second reach this hour, **S3** third+ (jealous),
**SK** third+ (kind), **N** bedtime and late night, **P** pass end and
breath, **AL** after "Açmam lazım", **H** Hop!, **ST** after a resisted
run, **R** the one-minute ritual, **I** island idle chatter, **A** island
arrivals, **T** seasonal and topical, **EN** English-native starters.
Shield lines are **Title** / line 1. `{App}` is the system's app name
(unknown apps get the pool's name-free variant); `{k}` the reach count
this hour. **Weight**: ★ big joke, ◦ light, blank furniture. **Fresh**:
E evergreen, Y yearly (a date window), W weekly, R remote with expiry.
"New" lines are not yet in `ShieldCopy`; "shipped" are.

### 5.1 Shield: first reach (day, 11–17)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| S1-01 | **Hop! Bir saniye.** / Ben buradayım. | Hop! One second. / I'm right here. | warm | the Hop! name | | E, shipped |
| S1-02 | **{App} bekleyebilir.** / Ben buradayım. | {App} can wait. / I'm right here. | warm | — | | E, shipped |
| S1-03 | **POV: bir hamster belirdi.** / Açacaktın. Plot twist: ben. | POV: a hamster appeared. / You were about to open it. Plot twist: me. | meta | POV caption, plot twist | ★ | E |
| S1-04 | **Spoiler: yeni bir şey yok.** / Baktım. (Bakmadım. Ama yoktur.) | Spoiler: nothing new. / I checked. (I didn't. But there isn't.) | deadpan | Ekşi spoiler, the tic | ★ | E |
| S1-05 | **Özet geçeyim:** / Kahve, kedi, biri tatilde. Gerisi reklam. | Quick recap: / Coffee, a cat, someone on holiday. The rest is ads. | observational | the Instagram feed itself | ★ | E, Instagram only |
| S1-06 | **Önerilenler hazır.** / Biri bir şeye tepki veriyor. Bildim mi? | Recommendations are ready. / Someone reacting to something. Did I guess it? | observational | reaction videos | ★ | E, YouTube only |
| S1-07 | **Bir tane daha = kırk tane.** / Matematik bu. Ben uydurmadım. | One more = forty. / That's the math. I didn't make it up. | deadpan | "one more video" | ★ | E, TikTok/Reels |
| S1-08 | **Kara kedi değil, hamster.** / Yolunu kestim ama uğurluyum. | Not a black cat. A hamster. / I crossed your path, but I'm lucky. | cheeky | kara kedi superstition | ★ | E |
| S1-09 | **Kanka, bir dakika.** / Sadece selam vermek istedim. | Buddy, one minute. / Just wanted to say hi. | sweet | "kanka" | ◦ | E |
| S1-10 | **Önce bir selam.** / Sonra ne istersen. Kapıyı ben tutuyorum. | A hello first. / Then whatever you like. I'm holding the door. | sweet | — | | E |
| S1-11 | **Durun, durun, durun.** / Tamam, durdun. Benim işim buydu. | Wait wait wait. / Okay, you stopped. That was my whole job. | meta, deadpan | the triple "dur" | ★ | E |
| S1-12 | **Bir saniye, bir selam.** / Ben buradayım. Hep aynı yerde. | One second, one hello. / I'm here. Same spot as always. | warm | — | | E |

### 5.2 Shield: morning (06–11)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| M-01 | **Günaydın. Önce ben.** / Güne akışla başlamayalım. | Morning. Me first. / Let's not start the day with the feed. | jealous-sweet | — | | E, shipped |
| M-02 | **Güne akışla mı başlıyoruz?** / Güne akışla başlamayalım. | Starting with the feed? | gentle | — | | E, shipped |
| M-03 | **Sabah sabah mı?** / Daha çay demlenmedi. | This early? / The tea hasn't even brewed. | cheeky | çay, "sabah sabah" | ◦ | E |
| M-04 | **Erken kalkan yol alır.** / Erken kaydıran yolda kalır. | The early riser gets ahead. / The early scroller gets stuck. | wry | proverb parody | ★ | E |
| M-05 | **Gözünü açtın, ilk ben.** / Böyle kalsın, ne güzel. | You opened your eyes, and I'm first. / Let's keep it that way. | jealous-sweet | — | ◦ | E |
| M-06 | **Kahvaltıda telefon olmaz.** / Annem de öyle derdi. (Hamster annem.) | No phones at breakfast. / My mom used to say that. (My hamster mom.) | cheeky | the Turkish mom, the tic | ★ | E |
| M-07 | **Güneş doğdu.** / Akış kaçmıyor, söz. Önce bir gerin. | The sun's up. / The feed isn't going anywhere, promise. Stretch first. | sweet | — | | E |
| M-08 | **Pazartesi sabahı mı?** / Zaten yeterince zor. Akışı ekleme. | Monday morning? / It's hard enough already. Don't add the feed. | wry | Monday syndrome | ◦ | W, Mondays |
| M-09 | **Bugünün ilk kararı:** / Boş vermek. Sana çok yakışır. | Today's first decision: / Skipping it. It suits you. | sweet | — | ◦ | E |
| M-10 | **Damlaya damlaya göl olur.** / Kaydıra kaydıra saat olur. Biliyoruz. | Drop by drop, a lake. / Scroll by scroll, an hour. We know. | wry | proverb parody | ★ | E |

### 5.3 Shield: evening (17–bedtime)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| E-01 | **Akşam akışı mı?** / Bu saatler en zoru. | Evening scroll? / These hours are the hardest. | gentle | — | | E, shipped |
| E-02 | **Günün en zor saati.** / Bu saatler en zoru. | The hardest hour. | gentle | — | | E, shipped |
| E-03 | **Akşam oldu, ada turuncu.** / Filtresiz. Gel bak, kimseye atmayız. | Evening, the island's orange. / No filter. Come look; we won't post it. | sweet | #nofilter | ★ | E |
| E-04 | **Mesai bitti.** / Senin de, başparmağının da. | Work's over. / Yours, and your thumb's. | wry | the thumb as culprit | ◦ | E |
| E-05 | **Bir bölüm daha mı?** / Dizi gibi başlar, sezon gibi biter. | One more episode? / Starts like a show, ends like a season. | wry | dizi culture | ★ | E |
| E-06 | **Akşam çayı hazır.** / Mochi demledi. Akış soğuk, çay sıcak. | Evening tea's ready. / Mochi brewed it. The feed's cold; the tea is hot. | cosy | çay, the residents | ◦ | E, needs Mochi |

### 5.4 Shield: second reach this hour

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| S2-01 | **Az önce de geldik.** | We were just here. | warm | — | | E, shipped |
| S2-02 | **Bir daha mı?** | Once more? | warm | — | | E, shipped |
| S2-03 | **Devam filmi mi bu?** / İlki daha yeni bitti. | Is this the sequel? / The first one just ended. | wry | film sequels | ★ | E |
| S2-04 | **Hızlı döndün.** / Çay bile soğumadı. | That was quick. / The tea isn't even cold. | cheeky | çay | ◦ | E |
| S2-05 | **İkinci sezon onaylandı.** / Yönetmen: ben. Bölüm sayısı: bir. | Season two confirmed. / Director: me. Episodes: one. | absurd | dizi renewal news | ★ | E |
| S2-06 | **Az önce baktık ya.** / Değişen bir şey yok. Kontrol ettim. (Etmedim.) | We just looked. / Nothing's changed. I checked. (I didn't.) | deadpan | the tic | ◦ | E |
| S2-07 | **Yine merhaba.** / Ben de buradaydım. Hep buradayım. | Hello again. / I was here too. I'm always here. | sweet | — | | E |
| S2-08 | **Déjà vu mu bu?** / Bu sahneyi az önce yaşadık. Senaryo aynı. | Is this déjà vu? / We just played this scene. Same script. | wry | déjà vu | ◦ | E |
| S2-09 | **Başparmağın yine kaçtı.** / Sorun değil, ben yakaladım. | Your thumb escaped again. / No problem, I caught it. | cheeky | the thumb as culprit | ★ | E |

### 5.5 Shield: third reach this hour or later, jealous (≤ 3 a day)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| S3-01 | **Yine mi {App}?** / Bu saat {k}. kez. Onda olup bende olmayan ne? | {App} again? / {k}th time this hour. What does it have that I don't? | jealous | the founder's line | | E, shipped |
| S3-02 | **Hı. {App}. Anladım.** / Bu saat {k}. kez. Onda olup bende olmayan ne? | Oh. {App}. I see. | jealous | — | | E, shipped |
| S3-03 | **Onda ne var, bende yok?** / Benim yanaklarım var. Çekirdek sığıyor. | What has it got that I haven't? / I have cheeks. They hold seeds. | jealous-absurd | hamster physics | ★ | E |
| S3-04 | **Ya ben ya {App}!** / Karar senin. (Ben. Şaka. Ama ben.) | It's me or {App}! / Your call. (Me. Kidding. But me.) | melodrama | Yeşilçam ultimatum, the tic | ★ | E |
| S3-05 | **Seni ellere yar etmem.** / Ellere = {App}. Anladın sen onu. | I won't give you up to strangers. / Strangers = {App}. You know. | melodrama | türkü and arabesk lyric | ★ | E |
| S3-06 | **Arabesk modu: açık.** / Bu saat {k}. kez. Ben iyiyim. (Biraz kıskancım.) | Arabesk mode: on. / {k}th time this hour. I'm fine. (A bit jealous.) | melodrama | arabesk, the tic | ★ | E |
| S3-07 | **Aga, bu ne hız?** / Bu saat {k}. kez. {App} bile şaşırdı. | Bro, what's this speed? / {k}th time this hour. Even {App} is surprised. | cheeky | "aga" | ★ | E |
| S3-08 | **VAR'a gidiyoruz.** / İnceleme sonucu: {App} bekleyebilir. | We're going to VAR. / Review result: {App} can wait. | playful | football VAR | ★ | E |
| S3-09 | **Algoritma seni özledi.** / Ben daha çok. Kanıtım yok, yanağım var. | The algorithm missed you. / I missed you more. No proof; I have cheeks. | jealous-sweet | — | ★ | E |
| S3-10 | **Ben de kaydırılırım, bak.** / (Lütfen kaydırma. Tüylerim karışır.) | I'm scrollable too, look. / (Please don't. My fur gets messy.) | absurd | hamster physics | ★ | E |
| S3-11 | **Onlar rage bait.** / Ben huzur bait'im. Isırmam, söz. | They're rage bait. / I'm calm bait. I don't bite, promise. | wry | Oxford 2025 word of the year | ★ | R, to 2027-06 |
| S3-12 | **Telefonla mı evleneceksin?** / Şahidin olmam. Ama düğüne gelirim. | Are you marrying the phone? / I won't be your witness. But I'll come to the wedding. | jealous-cheeky | the Turkish mom | ★ | E, panel-test (may read as teasing the person) |
| S3-13 | **Sakin ol şampiyon.** / Bu saat {k}. kez. {App} kaçmıyor. | Easy, champ. / {k}th time this hour. {App} isn't going anywhere. | playful | "sakin ol şampiyon" | ◦ | E |

### 5.6 Shield: third reach or later, kind (after the jealous budget)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| SK-01 | **Buradayım.** / Bu saat {k}. kez. Acele yok. | I'm here. / {k}th time this hour. No rush. | kind | — | | E, shipped |
| SK-02 | **Kızgın değilim.** / Sadece hamsterım. Biraz da tüylü. | I'm not mad. / Just a hamster. A bit fluffy too. | kind-wry | — | ◦ | E |
| SK-03 | **Sorun yok.** / Huzur yine büyür. Ben de büyürüm. Yana doğru. | It's fine. / Calm grows back. So do I. Sideways. | kind-wry | Pofu's own roundness | ◦ | E |
| SK-04 | **Derin bir nefes.** / Ben de alıyorum. Yanaklarım şişiyor, bak. | A deep breath. / I'm taking one too. Look, my cheeks puff up. | kind | hamster physics | ◦ | E |
| SK-05 | **Acele yok.** / Ada bekler, ben beklerim, çay bekler. | No rush. / The island waits, I wait, the tea waits. | kind | the Turkish triple | | E |
| SK-06 | **Zor bir saat.** / Olur böyle. Ben buradayım. | A hard hour. / It happens. I'm here. | kind | — | | E |

### 5.7 Shield: bedtime and late night

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| N-01 | **Şşş, geç oldu.** / {App} da uyuyor. (Uyumuyor. Ama uyumalı.) | Shh, it's late. / {App} is asleep too. (It isn't. But it should be.) | sleepy-cheeky | the tic | | E, shipped |
| N-02 | **Gece yarısı akışı mı?** / {App} da uyuyor. (Uyumuyor. Ama uyumalı.) | A midnight scroll? | sleepy | — | | E, shipped |
| N-03 | **Saat {saat}.** / Algoritma bile esniyor. | It's {time}. / Even the algorithm is yawning. | deadpan | — | ★ | E |
| N-04 | **Gece 3 düşünceleri:** / Hamsterlar rüya görür mü? (Görür. Seni.) | 3 a.m. thoughts: / Do hamsters dream? (They do. Of you.) | sweet | "gece 3 düşünceleri", the tic | ★ | E |
| N-05 | **Yatak, yorgan, sen.** / Telefon bu tabloda fazlalık. | Bed, blanket, you. / The phone is extra in this picture. | sleepy-cheeky | — | ◦ | E |
| N-06 | **Anlaşma teklifim var:** / {App} uyusun, sen uyu, ben uyuyayım. | I have a deal: / {App} sleeps, you sleep, I sleep. | sleepy | negotiation | ◦ | E |
| N-07 | **Sabahki sen arıyor.** / "Lütfen uyu" diyor. Ben sadece iletiyorum. | Morning-you is calling. / They say "please sleep". I'm just passing it on. | sweet | the future-self meme | ★ | E |
| N-08 | **Gece yarısı kaydırması:** / En kötü dizinin en uzun bölümü. | Midnight scrolling: / the longest episode of the worst show. | deadpan | dizi culture | ★ | E |
| N-09 | **Uyuyamayanlar RT.** / Ben RT'lemiyorum. Uyuyorum. Sen de? | Can't-sleep crew, RT. / I'm not RTing. I'm sleeping. You? | wry | the Twitter TR night post | ★ | R, to 2027-06 (RT is ageing) |
| N-10 | **Gece modu: hamster.** / Göz kapaklarım kapanıyor. Seninkiler? | Night mode: hamster. / My eyelids are closing. Yours? | sleepy | dark mode | ◦ | E |
| N-11 | **Nane hâlâ uyanık.** / Yıldız saymak onun işi. Bizim işimiz uyku. | Nane's still awake. / Counting stars is her job. Ours is sleep. | sleepy | the residents | ◦ | E, needs Yıldız |
| N-12 | **Bu saatte {App} mı?** / Benim bile uykum geldi. Bu bir şey demek. | {App} at this hour? / Even I'm sleepy. That means something. | sleepy-wry | — | ◦ | E |

### 5.8 Shield: pass end and the breath

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| P-01 | **Süre doldu.** / {n} dakika bitti. Kapıya döndüm. | Time's up. / {n} minutes are up. I'm back at the door. | warm | — | | E, shipped |
| P-02 | **Süre doldu.** / Selamımı ilettin mi? Ben buradayım. | Time's up. / Did you pass on my hello? I'm here. | cheeky | — | ◦ | E |
| P-03 | **Bugünkü saatimiz doldu.** / Nefes kısmı bende. Sen sadece otur. | We've had our hour today. / The breathing part's on me. You just sit. | kind | — | | E |
| P-04 | **Önce nefes.** / Sonra ne istersen. Ben sayarım. | Breath first. / Then whatever you want. I'll count. | kind | — | | E |
| P-05 | **Süre doldu, kapı açık.** / Bitirdiysen gel. Bitirmediysen… yine gel. | Time's up, the door's open. / If you're done, come. If not… come anyway. | sweet | — | ◦ | E |

### 5.9 After "Açmam lazım" (no jealousy: a stated need is respected)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| AL-01 | Lazımsa lazım. Kapıda bekliyorum. | If you need it, you need it. I'll wait at the door. | warm | — | | E |
| AL-02 | Sebebin varsa kıskanmam. (Biraz kıskanırım. Belli etmem.) | If you've got a reason, I won't be jealous. (A little. I won't show it.) | sweet | the tic | ★ | E |
| AL-03 | İş başa düştü. Ben kronometreyi tutarım. | Duty calls. I'll hold the stopwatch. | playful | — | ◦ | E |
| AL-04 | Mesaj mı? Selamımı söyle. Kim olduğumu söyleme. | A message? Say hi from me. Don't say who I am. | cheeky | — | ★ | E |
| AL-05 | Ciddi iş. Ben de ciddiyim. Bak, kaşlarım çatık. (Kaşım yok.) | Serious business. I'm serious too. See, I'm frowning. (I have no eyebrows.) | absurd | the character bible's "no eyebrows" | ★ | E |
| AL-06 | Peki. Çabuk dön, dizinin en güzel yerindeydik. | Okay. Come back soon, we were at the best part of the show. | absurd | dizi culture | ★ | E |
| AL-07 | Aç bakalım. Ben bu arada çekirdekleri sayarım. Yine. | Go on. Meanwhile I'll count my seeds. Again. | cosy | hamster hoarding | ◦ | E |

### 5.10 Hop! (the care rung bubble, the reason chips, the hand-off)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| H-01 | Hop! Nereye böyle? | Hop! Where to? | playful | the character bible | | E |
| H-02 | Mesaj mı? Tamam, kıskanmam. | A message? Okay, I won't be jealous. | warm | chip "Mesaja cevap" | | E, gate v2 |
| H-03 | Sıkıldın mı? Mochi'nin ocağında taze çay ve dedikodu var. | Bored? Mochi's stall has fresh tea and gossip. | cosy | chip "Sıkıldım", çay ocağı | ★ | E, needs Mochi |
| H-04 | Sıkılmak serbest. Birlikte sıkılalım, daha az sıkıcı. | Being bored is allowed. Let's be bored together; it's less boring. | sweet | chip "Sıkıldım" | ◦ | E |
| H-05 | Bir şeye mi bakacaksın? Tamam. Ben saniye sayarım, sen bak. | Looking something up? Okay. I'll count the seconds, you look. | playful | chip "Bir şeye bakacağım" | ◦ | E |
| H-06 | Seçim senin. Ben sadece burada, sevimli duruyorum. | Your call. I'm just standing here, being cute. | cheeky | — | ★ | E |
| H-07 | Kararsız mısın? Ben de. Çekirdek mi fındık mı, bilemedim. | Undecided? Me too. Seeds or hazelnuts, I couldn't decide. | absurd | — | ◦ | E |
| H-08 | Hızlıca mı? Tamam. Huzuru ben sıcak tutarım. | Quick one? Okay. I'll keep the calm warm. | easy-going | — | | E, shipped |
| H-09 | 15 dakika. Kapıda beklerim, şarkı söylerim. (Söylemem.) | 15 minutes. I'll wait at the door and sing. (I won't.) | playful | the tic | ◦ | E |
| H-10 | Bu sefer de geldin. Ben buna "yakın arkadaşlık" diyorum. | You came again. I call that "close friendship". | sweet | Instagram's Close Friends | ★ | E |

### 5.11 After a resisted run (skip bubble; 3+ skips in a row today)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| ST-01 | Vazgeçtin! Başardık. Yani, çoğunu sen. | Skipped! We did that. Mostly you. | proud | — | | E, shipped |
| ST-02 | Üst üste üç. Hat-trick! Tribünler ayakta. | Three in a row. Hat-trick! The stands are on their feet. | proud | football, team-neutral | ★ | E |
| ST-03 | Instagram'ı görüldüde bıraktın. Gurur duydum. | You left Instagram on read. I'm proud. | smug | "görüldü" | ★ | E, Instagram only |
| ST-04 | Helal olsun. Algoritma şu an acil toplantıda. | Respect. The algorithm is in an emergency meeting. | smug-absurd | — | ★ | E |
| ST-05 | Bugün {App} bizi pek göremedi. Özlesin biraz. | {App} barely saw us today. Let it miss us a little. | jealous-smug | reversed jealousy | ★ | E |
| ST-06 | Unvan kazandın: Boş Verme Ustası. İptal edilemez. | Title unlocked: Master of Skipping. Non-revocable. | proud | achievement text | ◦ | E |
| ST-07 | Bugün başparmağın değil, sen kazandın. | Today you won, not your thumb. | proud | the thumb as culprit | ★ | E |
| ST-08 | Ben çarkı bıraktım, sen de. Hamster gibisin. (İltifat.) | I quit the wheel, and so did you. You're like a hamster. (Compliment.) | proud-absurd | the wheel, the tic | ★ | E |
| ST-09 | Aura +1000. (Senin. Benimki zaten tavan.) | +1000 aura. (Yours. Mine's maxed.) | smug | aura points | ★ | R, to 2027-03 |
| ST-10 | Bugün çok kabardım. Sebebi belli. | I'm so fluffy today. We know why. | proud | Pofu's fluff = wellbeing | ◦ | E |
| ST-11 | Ghost'ladın onu. Ben görmedim, ama alkışladım. | You ghosted it. I didn't see a thing, but I clapped. | smug | ghosting | ◦ | E |

### 5.12 The one-minute ritual ("Pofu'yla bir dakika")

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| R-01 | Bir dakika: sen, ben, biraz tüy. | One minute: you, me, a bit of fluff. | cosy | — | | E |
| R-02 | Fırçala beni. Evet, orayı. Tam orayı. | Brush me. Yes, there. Right there. | playful | — | ◦ | E |
| R-03 | Bu dakikayı kimse beğenmeyecek. O yüzden güzel. | Nobody will like this minute. That's why it's nice. | warm-wry | likes | ★ | E |
| R-04 | Bu dakikanın story'si yok. Sadece biz. | This minute has no story. Just us. | warm | Stories | ◦ | E |
| R-05 | Şu bulut hamstere benziyor. Ya da hamster buluta. | That cloud looks like a hamster. Or the hamster like a cloud. | dreamy | — | ◦ | E |
| R-06 | Bitti! Bir dakika, sıfır reklam. | Done! One minute, zero ads. | wry | ads | ★ | E |
| R-07 | Bu kadar. Telefonu bırakalım mı? | That's it. Phone down? | warm | — | | E, boundary doc |
| R-08 | Altmış saniye. Kimse "sonraki video" demedi. | Sixty seconds. Nobody said "next video". | wry | autoplay | ◦ | E |
| R-09 | Nefes al: ayçiçeği. Ver: çay. Mükemmel ada. | Breathe in: sunflower. Out: tea. Perfect island. | cosy | — | | E |
| R-10 | Kısa ve tatlı. Tıpkı ben. | Short and sweet. Just like me. | cheeky | Pofu's own size | ◦ | E |

### 5.13 The island: Pofu's idle chatter (one line per visit, on a tap or idle beat)

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| I-01 | Bir çekirdek gömdüm. Yerini unuttum. Klasik hamster. | I buried a seed. Forgot where. Classic hamster. | absurd | hamster hoarding | ★ | E |
| I-02 | Yanaklarıma on dört çekirdek sığdı. Rekor. Kimseye söyleme. | Fourteen seeds fit in my cheeks. A record. Tell no one. | absurd | hamster cheeks | ★ | E |
| I-03 | Ben çarkı bıraktım. Bak ne güzel ada yaptık. | I quit the wheel. Look what a nice island we made. | warm | the wheel (thesis) | ★ | E |
| I-04 | Ada sessiz. Bildirim yok. Cennet böyle bir şey olmalı. | The island's quiet. No notifications. Paradise must be like this. | dreamy | — | ◦ | E |
| I-05 | Çayı tavşan kanı severim. Mochi'nin yanında bunu demiyoruz. | I like my tea "rabbit's blood". We don't say that around Mochi. | absurd | "tavşan kanı" (the idiom for perfect tea) + Mochi is a bunny | ★ | E, panel-test |
| I-06 | Kurbağalar konser veriyor. Bilet bedava, alkış zorunlu. | The frogs are giving a concert. Free tickets, applause mandatory. | absurd | — | ★ | E |
| I-07 | Fındık bir şey tamir ediyor. Ne olduğunu o da bilmiyor. | Fındık is fixing something. Even he doesn't know what. | deadpan | the residents | ★ | E, needs Fındık |
| I-08 | Simit'in simitleri öğlen bitti. Cümle karıştı, biliyorum. | Simit's simits sold out by noon. I know, confusing sentence. | absurd | the name pun | ★ | E, needs İskele |
| I-09 | Pamuk iki saattir aynı yerde. Ona özeniyorum. | Pamuk's been in the same spot for two hours. Goals. | deadpan | the capybara meme | ◦ | E, needs Kaplıca |
| I-10 | Pamuk'a "acele" kelimesini sordum. Duymadı bile. Efsane. | I asked Pamuk about the word "hurry". Didn't even hear it. Legend. | deadpan | the capybara meme | ★ | E, needs Kaplıca |
| I-11 | Bulut bana kitap okudu. Sonunu söylemedi. Haklı. | Bulut read to me. Wouldn't tell me the ending. Fair. | warm | spoilers | ◦ | E, needs Kitap |
| I-12 | Bugün hiçbir şey paylaşmadık. Ne hafif bir gün. | We posted nothing today. Such a light day. | warm | — | ◦ | E |
| I-13 | Rüzgâr gülüne baktım, ben de döndüm. Başım döndü. | I watched the windmill, so I spun too. Now I'm dizzy. | absurd | physical | ◦ | E, needs windmill |
| I-14 | Ayçiçekleri güneşe bakıyor. Ben sana. Herkes kendi işinde. | The sunflowers look at the sun. I look at you. Everyone's busy. | sweet | — | ★ | E |
| I-15 | Çime dokunmak istersen adada bol. Ben suladım. | If you want to touch grass, the island has plenty. I watered it. | cheeky | touch grass | ★ | E |
| I-16 | Bugün çok verimliydim: iki kez esnedim, bir kez yuvarlandım. | Very productive today: yawned twice, rolled once. | deadpan | productivity culture | ★ | E |
| I-17 | Burada Wi-Fi yok. Ama bağlantı çok iyi. (Sen ve ben.) | No Wi-Fi here. But the connection's great. (You and me.) | sweet | the tic | ★ | E |
| I-18 | Mochi "çay?" dedi. Ben "evet" dedim. Hayatımın kararı. | Mochi said "tea?". I said "yes". Decision of my life. | cosy | — | ◦ | E, needs Mochi |
| I-19 | Bir an kendimi NPC sandım. Sonra yanaklarımı hatırladım. | For a second I thought I was an NPC. Then I remembered my cheeks. | absurd | NPC | ◦ | E |
| I-20 | Ben chill bir hamsterım. Çok chill. Biraz fazla chill. | I'm a chill hamster. Very chill. A bit too chill. | deadpan | chill guy | ◦ | R, to 2026-12 |
| I-21 | Labubu'dan tatlıyım. Kanıtım yok, sadece his. | I'm cuter than Labubu. No proof, just a feeling. | smug | Labubu | ★ | R, to 2026-12 |
| I-22 | Kurbağalara 6-7 öğrettim. Ne demek bilmiyorlar. Ben de. | I taught the frogs 6-7. They don't know what it means. Neither do I. | absurd | 6-7 | ★ | R, to 2026-12 |
| I-23 | Kimse: … Kurbağalar: "vrak." | Nobody: … The frogs: "ribbit." | absurd | "Kimse: / Ben:" | ◦ | R, to 2027-06 |
| I-24 | Akşam oldu. Ada turuncuya döndü. Filtresiz, yemin ederim. | Evening. The island turned orange. No filter, I swear. | sweet | #nofilter | ◦ | E |
| I-25 | Komşular dükkânı kapatıyor. Ben de gözlerimi. | The neighbours are closing up. Me too, my eyes. | sleepy | — | | E, evening |

### 5.14 Island arrivals

| ID | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|
| A-01 | Bak hele: gece yeni bir ada yanaştı! | Look: a new island drifted close in the night! | delighted | — | | E, game design |
| A-02 | Dur bir dakika. Bu dün burada var mıydı? | Wait. Was that there yesterday? | surprised | — | | E, game design |
| A-03 | Gece biri kapıyı çaldı. Açtım. Bir ada! | Someone knocked in the night. I opened. An island! | delighted | — | ◦ | E |
| A-04 | İskele geldi! Çaylar Mochi'den, simitler Simit'ten. | The harbour's here! Tea from Mochi, simit from Simit. | delighted | çay and simit | ★ | E, İskele |
| A-05 | Vapur yanaştı. Simit indi. Adı yemek, kendisi kedi. | The ferry docked. Simit got off. Named like a snack, built like a cat. | absurd | the name pun | ★ | E, İskele |
| A-06 | Yıldız adası geldi. Nane boş bir yıldız defteri getirdi. | The star island's here. Nane brought an empty star book. | dreamy | — | ◦ | E, Yıldız |
| A-07 | Kaplıca geldi. Pamuk zaten oradaydı. Nasıl, kimse bilmiyor. | The hot spring arrived. Pamuk was already there. Nobody knows how. | deadpan | the capybara meme | ★ | E, Kaplıca |
| A-08 | Kitap adası yanaştı. İlk sayfa yarın. Spoiler yok, söz. | The library island docked. Page one tomorrow. No spoilers, promise. | warm | spoilers | ◦ | E, Kitap |
| A-09 | Bir ada daha geldi. Kimse beğeni atmadı, yine de geldi. | Another island came. Nobody liked it, and it came anyway. | wry | likes | ★ | E |

### 5.15 Seasonal and topical (the remote slot)

| ID | When | TR | EN gloss | Tone | Riffs on | Wt | Fresh |
|---|---|---|---|---|---|---|---|
| T-01 | 31 Dec–1 Jan | **Yeni yıl, yeni ben.** / Ben aynı hamsterım. Sen istediğin kadar yeni ol. | New year, new me. / I'm the same hamster. You be as new as you like. | wry | "yeni yıl yeni ben" | ★ | Y |
| T-02 | Wrapped week (early Dec) | **Wrapped'ın çıktı mı?** / Benimkinde bir numara sensin. | Is your Wrapped out? / In mine, you're number one. | sweet | Spotify Wrapped | ★ | R, yearly review |
| T-03 | 14 Feb | **14 Şubat.** / Benim sevgilim çekirdek. Bu akşam ona sadığım. | 14 February. / My valentine is a seed. I'm loyal tonight. | absurd | Valentine's | ◦ | Y |
| T-04 | YKS weekend (June) | **Bu hafta sonu YKS var.** / Girenlere kolay gelsin. Kaydırmaya mola. | It's YKS weekend. / Good luck to everyone sitting it. Scrolling takes a break. | warm | the national exam | ◦ | Y, date set yearly |
| T-05 | Jul–Aug | **Sıcak mı sıcak.** / Ekran da ısınmasın. Gölgeye geç. | Hot, so hot. / Don't heat the screen too. Find some shade. | cosy | the heat | ◦ | Y |
| T-06 | Snow day (manual) | **Kar yağıyor!** / Ekrana değil, cama bak. | It's snowing! / Look at the window, not the screen. | delighted | — | ◦ | R, manual and regional: use only when it snows in most big cities |
| T-07 | A big dizi finale (manual) | **Bu akşam büyük final.** / {dizi} bitiyor. Spoiler'dan kaçış: kapalı ekran. | Big finale tonight. / {Show} ends. Dodge spoilers: a dark screen. | wry | dizi culture | ★ | R, 3 days, show name reviewed |
| T-08 | Derby night (manual) | **Derbi akşamı.** / Skoru telefonsuz da öğrenirsin. Komşulardan. | Derby night. / You'll learn the score without the phone. From the neighbours. | wry | team-neutral football | ★ | R, team-neutral by rule |
| T-09 | 5–6 May | **Hıdırellez geldi.** / Dileğimi gül dalına astım. Söylemem. (Sen.) | Hıdırellez is here. / I hung my wish on the rose branch. Won't tell. (You.) | sweet | Hıdırellez, the tic | ★ | Y, with the island event |
| T-10 | Fridays from 17:00 | **Cuma akşamı.** / Akışın sonu yok. Hafta sonunun var. | Friday evening. / The feed never ends. The weekend does start. | warm | — | ◦ | W |
| T-11 | 23 April | **23 Nisan.** / Bugün içindeki çocuk kazanır. Çocuklar dışarıda oynar. | 23 April. / Today your inner child wins. Kids play outside. | warm | Children's Day | ◦ | Y |
| T-12 | Bayram mornings (Q3) | **İyi bayramlar.** / Bugün akış değil, el öpme günü. | Happy bayram. / Today is for visiting elders, not the feed. | warm | the custom, not the religion | ◦ | Y, pending Q3 |
| T-13 | Tung Tung week (expired example) | **Tung tung tung…** / Sahur değil, sadece ben. Kapı çalıyordum. | Tung tung tung… / Not sahur, just me. I was knocking. | absurd | Italian brainrot | ★ | **Cut**: expired, and the sahur reference is religious-adjacent. Kept as the example of what the expiry protects us from. |

### 5.16 English-native starters (English ships later; written, not translated)

| ID | EN | Slot | Riffs on | Wt |
|---|---|---|---|---|
| EN-01 | **Touch grass?** / I grow some. Island's right there. | S1 | touch grass | ★ |
| EN-02 | **Doomscroll detected.** / Fluffy firewall engaged. | S1 | system-alert parody | ★ |
| EN-03 | **Chronically online.** / Acutely fluffy. Pick one. | S2 | chronically online | ★ |
| EN-04 | **Plot twist: hamster.** / You were opening {App}. | S1 | plot twist | ★ |
| EN-05 | **Not me being jealous.** / (It's me. I'm jealous.) | S3 | "not me…" format, the tic | ★ |
| EN-06 | **Brainrot is a meme.** / I'm a hamster. Choose wisely. | S1 | brainrot | ◦ |
| EN-07 | I quit the wheel. Ten out of ten, would recommend. | I | the wheel | ★ |
| EN-08 | **It's giving 2 a.m.** / It's giving sleep. | N | "it's giving" | ◦ |

**Count:** 157 Turkish lines across fifteen sections (69 ★, 55 ◦, 33
furniture; one more is shown cut), plus 8 English starters. Shield titles and subtitles were
checked against the 26 / 60 limits with "Instagram" (9 characters) in
place of `{App}` and a two-digit `{k}`.

## 6. What I cut, and why

| Cut line | Why |
|---|---|
| "Eski sevgilinin story'sine mi bakacaksın?" | The funniest line I wrote, and the cruellest. It is about the person. |
| "Lazım olan açılır. Lazım olmayan… neyse, sen bilirsin." | Passive aggression is guilt with a smile. |
| "Brainrot'un ilacı: hamster." | A health claim, and it implies the user's brain is rotting. |
| "Gözün bozulacak, annen haklıydı." | A body and health claim in a mom's voice. Pofu quotes moms only about manners. |
| "Arabesk modu: açık. Ben iyiyim. (Değilim.)" | "I'm not okay" because you reached is exactly the Duolingo trap. Rewritten as "(Biraz kıskancım.)". |
| "Bu saat 4. kez. Rekor mu deniyoruz?" | Comments on the person's behaviour; the count already says it. |
| "Öldüm gülmekten." | ADR-0017, even as hyperbole. |
| "Engelledim! Şaka." (1 April) | Gate vocabulary is banned, joke or not. |
| "Görev adamı. Saygılar." | Gendered idiom; replaced with AL-05. |
| "Komşunun tavuğu komşuya kaz görünür; Instagram da öyle." | A proverb parody that needs a footnote. If you have to explain the riff, cut it. |
| "Instagram −1000 aura." on the shield | The shield is not where to spend a meme with a six-month half-life; it moved to the skip bubble (ST-09) with an expiry. |
| Anything with "kanka" in the kind pool | Street warmth on a hard moment reads as not listening. |

## 7. How this maps to code

- Today: `ShieldWords` holds two or three variants per row and picks
  `(dayOfYear + reachesToday) % count`. That stays as the fallback.
- Proposed (a later PR, after the founder's dogfood week, so gate v2's
  copy is measured first): a `VoiceLine` model in `PofuCore` (id, slot,
  tr, en, weight, conditions, notBefore, notAfter), the bundled bank as a
  JSON resource, the remote pack overlaying it, and the selection rule of
  section 4.4. `ShieldContext` gains `dayOfUse`, `reachesToday` (exists),
  `lastShown`, and `bigJokesToday`.
- CI: a pure test over the bank, extending `ShieldCopyTests`: every
  shield line within 26 / 60 characters with the longest known app name;
  no line contains a never-say term (section 4.5) in either language; at
  most one "!" per shield; every R line has `notAfter`; every line has an
  English twin before English ships.
- The Atlas node `sys-voice` tracks this system; lines are not nodes.

## 8. Open questions for the founder

| # | Question | My recommendation |
|---|---|---|
| Q1 | Who tests the jokes before the friends beta? | **A 10-person Turkish panel** (friends, 20–35, mixed): each rates every ★ line "funny / fine / annoying" in a one-page form. Cut anything with more than two "annoying". Two hours of their time; the cheapest insurance we have. |
| Q2 | "Kanka" and "aga": does Pofu use them? | **Yes, rationed**: at most once a day, never in the first three days, never in a kind or tired line. They are the difference between a mascot and a friend. |
| Q3 | Religious holidays (Ramazan and Kurban Bayramı) | **One neutral greeting on the morning of each bayram** ("İyi bayramlar", about visiting elders), no jokes, no religious words. Silence would feel cold in Turkey; jokes would be a mistake. |
| Q4 | Who writes the monthly remote pack? | **I draft it monthly (about ten lines), you approve in one PR review from your phone.** Every line expires by default, so a bad month fades on its own. |
| Q5 | Dizi and football references with real names | **Formats yes, names only in the remote slot**, with a 3-day expiry, team-neutral by rule. |
| Q6 | Default personality: Playful or Gentle (game design §12 guardrail 5) | **Playful by default**, with the first three days as a gentle introduction; Gentle stays one tap away in Settings. |
| Q7 | Does Pofu ever use an emoji? | **No.** The face is the emoji. The only symbol stays the "↑" in the waiting state. |

## 9. Self-critique

- **The bank is long and mine.** 157 lines written by one writer will
  have one sense of humour. The panel (Q1) and the founder's own week are
  the real test; I expect a third of the ★ lines to be cut.
- **The parenthetical tic is the strongest device and the most likely to
  wear out.** It appears in 16 lines; the budget of three a day may still
  be too many. Watch it first.
- **App-specific lines (S1-05, S1-06, ST-03) are the funniest because
  they are observed,** and the most fragile: if Instagram changes what its
  feed looks like, they go stale. They are E today; they may need R.
- **The English side is thin by design.** Glosses are not jokes; the
  English bank needs its own writer and its own pass before English
  ships.
- **I could not verify current Turkish meme formats from the web**; the
  formats chosen (melodrama, proverbs, Ekşi, görüldü, VAR) are durable
  ones, which is safer than chasing this month's caps.

## Sources

- Ad Age, "Duolingo kills off mascot Duo": https://adage.com/article/digital-marketing-ad-tech-news/duolingo-kills-mascot-duo-new-marketing-stunt/2602261
- NPR, "RIP Duo": https://www.npr.org/2025/02/13/nx-s1-5295597/duolingo-owl-mascot-death
- NPR, "Duolingo's owl mascot is alive after all": https://npr.org/2025/02/26/nx-s1-5309785/duolingo-owl-mascot-lives
- Entrepreneur, "Probably died waiting for you to do your lesson": https://www.entrepreneur.com/business-news/duolingo-says-its-mascot-duo-the-owl-is-dead/486944
- Lahs Griffin Gazette, perspectives on the campaign: https://lahsgriffingazette.com/24073/features/duo-perspectives-on-the-duolingo-marketing-campaign/
- Habit Box, Finch review: https://habitbox.app/blog/finch-app-review
- Engadget, Finch: https://www.engadget.com/apps/this-self-care-virtual-pet-is-helping-me-get-my-act-together-160027169.html
- IU wellness corner, Finch: https://geneticslab.medicine.iu.edu/blogs/md-student-news/wellness-corner-a-digital-pet-is-your-self-care-best-friend
- nippon.com, Neko Atsume: https://nippon.com/en/nipponblog/m00083
- Mechanics of Magic, MDA of Neko Atsume: https://mechanicsofmagic.com/2024/04/07/mda-neko-atsume/
- Medium (TwentyBN), 5 lessons from Clippy's failure: https://medium.com/twentybn/5-lessons-from-clippys-failure-efc69297eac1
- Mental Floss, the tragic life of Clippy: https://www.mentalfloss.com/article/504767/tragic-life-clippy-worlds-most-hated-virtual-assistant
- BGR, what happened to Clippy: https://bgr.com/2155953/what-happened-to-clippy-why-microsoft-retired-office-assistant/
- The New Stack, Humanity vs. Clippy: https://thenewstack.io/?p=6847114
- Boston Globe, when did Spotify Wrapped get so chatty: https://www.bostonglobe.com/2021/12/05/lifestyle/when-did-spotify-wrapped-get-so-chatty
- MarketSmiths, Spotify's cringeworthy copy: https://www.marketsmiths.com/2022/spotifys-cringeworthy-copy/
- NTV, TDK word of the year "dijital vicdan": https://www.ntv.com.tr/turkiye/tdk-yilin-kelimesini-acikladi-dijital-vicdan-nedir-1705206
- Habertürk, "dijital vicdan": https://www.haberturk.com/son-dakika-yilin-kelimesi-dijital-vicdan-oldu-3849228
- Oxford University Press, word of the year 2025 "rage bait": https://corp.oup.com/?p=5721
- The A.V. Club, Dictionary.com's "6-7": https://avclub.com/dictionary-dot-com-2025-word-of-the-year-67
- Know Your Meme, Tung Tung Tung Sahur: https://knowyourmeme.com/memes/tung-tung-tung-sahur-triple-t-baseball-gif
