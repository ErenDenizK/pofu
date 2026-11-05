# Monetization: what we sell, and how

> **Superseded in part (2026-11-05):** the recommendation and prices are
> replaced by [monetization-v2.md](monetization-v2.md) after the game became
> compact (station islands retired). The market data, Türkiye notes, the
> fair-lock test (§6) and the sources below still hold.

_Status: proposal for the founder's decision, 2026-11-02. It builds on the
[monetization research](../research/monetization.md) (2026-11-01) and the
founder's "Hybrid (D)" input from the Hub. Nothing here is implemented.
After the founder decides, the free/paid boundary becomes an ADR (it is
expensive to reverse: see section 9), and
[game-design.md](game-design.md) pillar 7 and rule A6 are amended._

## 0. The short answer

**Recommended: "Free home, paid voyage."** The gate, Pofu, every seed you
earn, the home island (Ayçiçeği) and the first new island (İskele) are
free forever. **Pofu Plus** opens the rest of the archipelago (Yıldız,
Kaplıca, Kitap) and **every island that arrives with the seasons**, plus
the cosmetic extras. One membership, two ways to pay:

| | Türkiye | US | Notes |
|---|---|---|---|
| Plus, yearly | **349,99 TL** | **$29.99** | No monthly, no weekly |
| Plus, lifetime | **999,99 TL** | **$89.99** | Includes every future island, forever |

"Expansions" are the right idea with the wrong packaging: an island **is**
the expansion unit, but it belongs **inside** Plus and lifetime, not on
top of them. Selling islands separately to members would double-charge
our most loyal users. A one-off purchase for non-members ("buy just this
season") is a year-2 experiment, not a launch product.

The paywall first appears on **day ~22**, when Yıldız drifts close, while
the free player still has about three to six weeks of free building left
on the home island and İskele. That timing is the difference between "you
liked the demo, here is the full game" and "pay or your progress stops".

The rest of this document shows the options, the evidence, the numbers,
and the rules that keep this honest.

## 1. Fixed rules (unchanged by any model)

These are not up for A/B testing:

1. **The gate is free forever.** Shield, Hop!, the ladder, the care rung,
   the breathing break, the emergency pass, schedules, bedtime, history of
   the last 7 days ([ADR-0012](../adr/0012-ux-v1-decisions.md),
   [ADR-0015](../adr/0015-care-over-currency.md)).
2. **Pofu is free forever**, with all his emotions, his wellbeing, and
   "sleeps it off". Pofu never dies ([ADR-0017](../adr/0017-pofu-never-dies.md)).
3. **Seeds never buy screen time, and money never buys seeds**, calm,
   wellbeing, speed, waiting, or production (game-design A6, A13).
4. **Earning is identical for free and paid players.** Two people who
   behave the same earn the same seeds and calm. Plus adds places to
   *spend* them, never a faster rate.
5. **Nothing you have is ever taken away** (A4). No trial that expires
   onto something you built; a lapsed member keeps every built level.
6. **No ads, ever** (vision non-goals).

## 2. What the market does

Prices are list prices found through web search on 2026-11-02. The App
Store itself is not reachable from the agent environment, so **Turkish
storefront prices for competitors could not be read directly**; TL
equivalents below are conversions at **49.8 TL/USD** (free-market rate,
27 Oct 2026, [Türkgün][fx]) for scale only, not their actual TR prices.
The founder can screenshot the real TR in-app purchase lists from his
iPhone in ten minutes; that is action 1 in section 10.

### Screen time and habit apps

| App | Model | US price (date of source) | ≈ TL at 49.8 | Lesson |
|---|---|---|---|---|
| **Opal** | Freemium, hard upsell | $99.99/yr, $8.99/mo, $4.99/wk, family $149.99/yr; lifetime reported at $399 (2026) [opal] | 4,980 TL/yr | Weekly plans and $399 lifetime exist; TR reviewers complain about no Turkish. |
| **one sec** | Free tier (one app), Pro | $19.99/yr; lifetime $99.99; family $29.99/yr, $149 lifetime (May–Jun 2026) [onesec] | 995 TL/yr | Lifetime at **5×** yearly. The only product in the category with peer-reviewed evidence. |
| **ScreenZen** | Free, tip jar | Tips $7 / $14 / $25 [screenzen] | — | Free and loved (30K+ ratings), but tips fund one developer, not an art pipeline. |
| **Brainrot** | Hard paywall after onboarding | Not found this session; earlier audit: $19.99–$29.99/yr [audit] | — | The camp our vision criticizes. |
| **Unrot** | Mandatory subscription | IAPs $9.99–$69.99; reviews complain the price appears after a long onboarding [unrot] | — | The exact dark pattern to avoid. |
| **Jomo** | Free tier, one-time Plus | $99.99 one-time (family of 5), student $14.99/yr [jomo] | 4,980 TL | A one-time "single purchase" as the main offer. |
| **Freedom** | Subscription + lifetime | $39.99–$47.99/yr, "Forever" $199 (Oct 2026) [freedom] | — | Lifetime at ~**4–5×** yearly. |
| **Forest** | Was $3.99 paid; reportedly moved to a subscription | Conflicting sources; the switch is its top user complaint (May 2026) [forest] | — | Changing the deal after people paid is the fastest way to lose trust. |
| **Flora** | Free, small one-time unlock | ~$1–2 one-time [flora] | — | Generous, tiny revenue. |
| **Finch** | Free core, Plus for extras | $69.99/yr, $9.99/mo (verified Jul 2026) [finch] | 3,485 TL/yr | The closest emotional analogue; Plus sells mostly the pet's world. |
| **Duolingo** | Freemium, Super | $83.88/yr ($6.99/mo) (2026) [duo] | — | Turkish prices are low enough that Europeans buy through TR accounts [mydealz]: regional arbitrage is real. |
| **Headspace / Calm** | Hard-ish paywall, yearly | $69.99/yr each (2026) [subger-hs] [subger-calm] | 3,485 TL/yr | Annual-first. |
| **Sleep Cycle** | Freemium, Premium | ~$39.99/yr (2026) [sleepcycle] | — | |
| **Pokémon Sleep** | Free to play + Premium Pass + shop | $9.99/mo, $49.99/6 mo; >$100M in its first year (Jul 2024) [poke] [vgc] | — | A behavior game monetized hard. Its pass sells data history and bonuses; we will not sell bonuses. |

### Cozy premium games and their expansions

| Game | Model | What sold | Lesson |
|---|---|---|---|
| **Stardew Valley** | $4.99 on mobile, pay once | Every update free; the creator pledged in July 2024 never to charge for DLC or updates [stardew] [stardew-mobile] | The cozy audience's baseline expectation is "pay once, updates free". |
| **Spiritfarer** | Pay once | Three free updates in 2021; sales went from 500K (Apr 2021) to 1M (Dec 2021) [spirit-500k] [spirit-1m] | Free content updates drive sales of the base purchase. |
| **Monument Valley** | Premium, then Apple Arcade, then Netflix | *Forgotten Shores*: a paid level pack (~$1.99 today); *Ida's Dream*: a free chapter [mv-shores] [mv-ida]; MV3 launched as a Netflix exclusive (Dec 2024) [mv3] | A paid expansion works when it is a whole new chapter, cheap, and clearly "more of what you loved". |
| **Cozy Grove** | Pay once | *Camp Spirit*, a full sequel at $19.99 (July 2026) [cozygrove] | Big, story-shaped add-ons sell; small ones are free. |
| **A Short Hike, Alba, Alto's, Tiny Glade** | Pay once, free updates | Not re-verified this session | Same pattern. |

**What the market says, in one line:** habit apps sell **subscriptions
and lifetimes** (lifetime at 3–5× yearly), and cozy games sell **one
purchase with free updates**, with paid expansions only when they are big
and story-shaped. We are both, so we should look like both: one
membership that behaves like "buy the full game, get every update".

## 3. Türkiye specifics

- **Purchasing power.** Net minimum wage in 2026 is **28.075,50 TL** a
  month [wage]. 349,99 TL is 1.25 % of it; the same share of a US
  full-time federal-minimum month (~$1,257) is about **$16**. So 349,99 TL
  is not "a coffee" in Turkish terms; it is a considered purchase, and
  about **1.35 months of Netflix Basic** (259,99 TL since 3 Oct 2026
  [netflix]). It is still far below the reference apps (Finch ≈ 3,485 TL
  a year at the exchange rate).
- **Price inflation.** Netflix raised TR prices 26–37 % in October 2026
  [netflix]; YouTube Premium in June 2026 [ytp]; ChatGPT Plus on the App
  Store in TR is 999,99 TL a month [chatgpt]. Turkish users are used to
  yearly price rises, and they resent them. A **lifetime** purchase is
  attractive precisely because it is inflation-proof for the buyer; for
  us it is a loan against future costs paid in USD. That is why the TL
  lifetime must be reviewed every six months for *new* buyers.
- **Subscription fatigue.** We found no Turkish dataset on lifetime vs
  yearly preference (the earlier research found none either). The
  hypothesis that Turkish buyers prefer one-time purchases is plausible
  (inflation, recurring price-hike news) but **unmeasured**. The friends
  beta measures it (section 10).
- **Taxes in the price.** TR App Store prices include **20 % VAT**, and
  Türkiye's digital services tax is **5 % in 2026, 2.5 % from 2027**
  (Presidential Decision 10767, 25 Dec 2025) [dst]. Apple historically
  raised TR prices or adjusted proceeds for this tax [apple-dst]. App
  Store Connect shows exact proceeds per price point; the figures below
  are a range until we read them there.
- **Apple's cut.** The App Store Small Business Program takes **15 %**
  for developers under $1M a year [sbp].
- **Income tax.** Income from app-store sales may qualify for the
  article 20/B exemption with bank withholding (see the
  [research](../research/monetization.md)); confirm with an accountant
  before the first payout.
- **Price points.** Apple sets TRY price points (ending in ,99); confirm
  that 349,99 and 999,99 are available points in App Store Connect and
  **set TL prices manually**, not by Apple's automatic equalization from
  USD, which tracks the exchange rate, not purchasing power.
- **Arbitrage.** TR prices at about a quarter of US prices invite region
  hopping (the Duolingo "Turkey trick" [mydealz]). It is a small leak,
  not a reason to raise TR prices.

## 4. Patterns and benchmarks

| Pattern | Benchmark | Source |
|---|---|---|
| Hard paywall vs freemium | Median download-to-paid by day 35: **~10.7 %** vs **~2.1 %**; year-one subscriber retention about the same (27 % vs 28 %); hard paywalls refund more | RevenueCat SOSA 2025/2026 [rc-hard] [rc-2026] |
| Trials | Health and fitness median trial-to-paid **39.9 %** (2025); trials of 17–32 days **~42.5 %**; trials of 4 days or less **26.8 %** | RevenueCat [rc-2025] [rc-trends] |
| Category | Health and fitness trial-to-paid **35.0 %**; the only category where annual plans dominate (**60.6 %** of plans) | Adapty 2026 [adapty] |
| Early revenue | Health and fitness median revenue per install **$0.48 at day 14, $0.66 at day 60** | RevenueCat 2026 via secondary summary [rc-sum] |
| Lifetime | One-time and lifetime purchases grew from 6.4 % to **10.3 %** of monetization models (2023–2025); subscription + lifetime is the second most common mix | Adapty via secondary; RevenueCat [rc-life] [airbridge] |
| "Free to start, buy the full game" | Super Mario Run: **~3 %** of downloads paid (Jan 2017); lite-to-full conversions reported **1–10 %** | [mario] [lite] |
| Family | one sec and Opal sell family plans at ~1.5× yearly | [onesec] [opal] |

Our case is neither a hard paywall nor a classic freemium: it is a
**content gate after N days**. The closest analogues are "free to start"
premium games (1–10 %, ~3 % typical, of *all* downloads) and long trials
(~40 % of *trial starters*, who are self-selected). We use the first as
the floor and the second as an upper bound on how well an engaged user at
day 22 converts.

## 5. The four models

Common to all: the fixed rules of section 1. The island pacing is the
current simulation's ([game-design.md](game-design.md) section 14):
İskele arrives on day 9, Yıldız on day 22, Kaplıca around day 35, Kitap
with a season update (simulated at day 50); the home island is finished
between day 42 (never opens) and day 64 (heavy scroller).

### Model A: Beauty Plus (the earlier recommendation)

- **Free:** everything in section 1, **every island**, station, level,
  resident, ritual, and seasonal island.
- **Paid (Plus, yearly 349,99 TL / lifetime 999,99 TL):** style variants,
  extra cosmetic residents that produce nothing, seasonal station skins,
  island themes, full history, extra widgets and icons.
- **Paywall moment:** contextual only: tapping a Plus style in a station
  sheet, Settings → Plus, one quiet row in the first weekly recap.
- **Copy:** "Make the islands yours. Plus adds styles, themes and seasonal
  looks. Every island stays free."
- **Conversion (assumption):** **0.5–1.5 %** of installs. Freemium
  medians are ~2.1 % across all categories; a cosmetic-only upsell in a
  price-sensitive market sits below that. Finch proves cosmetics can sell,
  but at a scale and attachment we will not have in year 1.
- **Risks:** the purest ethically and the weakest commercially. It also
  forces the art pipeline to make **two** kinds of art (islands for free,
  variants for Plus), and variants are the art people value least.

### Model B: Free home, paid voyage (recommended)

- **Free:** everything in section 1, **Ayçiçeği** (all five stages, all
  stations, Mochi, Fındık, the frogs) and **İskele** (the ferry, Simit,
  the postcards). Free seasonal touches for everyone (snow, blossoms,
  fireflies, Hıdırellez).
- **Paid (Pofu Plus):** Yıldız, Kaplıca, Kitap, **every future island**,
  plus all cosmetics from Model A. Yearly 349,99 TL / $29.99; lifetime
  999,99 TL / $89.99. Family Sharing on.
- **Paywall moment:** Yıldız drifts close on day ~22 (21 tended days and
  10 calm nights, cumulative). It appears on the map for everyone, and
  the morning bubble mentions it once in the same words for everyone.
  Tapping it opens the island card (its ritual, Nane the owl, the three
  stations). For a free player the card ends with one line and two
  buttons. The free player still has **3–6 weeks** of free building left
  on Ayçiçeği and İskele, so the offer never coincides with "nothing left
  to do".
- **Copy** (EN; TR drafted natively, to be polished):

  > **More islands are out there.**
  > Ayçiçeği and İskele are yours, free, forever. Plus opens Yıldız,
  > Kaplıca, Kitap, and every island that arrives with the seasons.
  > Everything that helps you put the phone down stays free.
  > [349,99 TL a year] [999,99 TL once, yours for good] [Not now]

  > **Ötede başka adalar da var.**
  > Ayçiçeği ve İskele senin; ücretsiz, sonsuza dek. Plus; Yıldız'ı,
  > Kaplıca'yı, Kitap'ı ve mevsimlerle gelecek her adayı açar.
  > Telefonu bırakmana yardım eden her şey ücretsiz kalır.
  > [Yıllık 349,99 TL] [Bir kez 999,99 TL, hep senin] [Şimdi değil]

- **Conversion (estimate):** 20–30 % of installs are still active at day
  22 (an assumption; the friends beta target is D30 > 40 %), and 8–15 %
  of them buy → **~1.6–4.5 % of installs**, centred near 3 %. That sits
  inside the premium-game range (1–10 %, ~3 % for Super Mario Run) and
  well under trial-starter conversion (~40 %).
- **Risks:** (1) the free player's seeds lose their last sink after the
  home island and İskele are done (day ~60): the island system must give
  free players a gentle, finite sink there (see section 7). (2) It
  reverses pillar 7's "never islands": that needs an ADR and must happen
  **before** the public launch, never after (section 9). (3) A content
  promise: members pay for islands that arrive "with the seasons", so we
  must ship them.

### Model C: Premium unlock plus paid expansions (no subscription)

- **Free:** as Model B.
- **Paid:** "The full archipelago", a one-time non-consumable (499,99 TL
  / $14.99) that unlocks the launch islands; **each seasonal island sold
  separately** (99,99–149,99 TL / $3.99–$4.99), or a non-renewing "season
  pack".
- **Paywall moment:** the same day-22 card; each new season shows its own
  card once.
- **Conversion (estimate):** 2–5 % of installs for the unlock (one-time
  purchases are an easier yes in Türkiye; unmeasured), and perhaps 30–50 %
  of buyers per expansion (assumption).
- **Risks:** revenue is a staircase: each season has to sell again, and
  every expansion is a new purchase decision for the user, which is the
  "nickel-and-dime" feeling cozy players punish. Year-2 revenue depends
  entirely on shipping and marketing new islands. Simple for the buyer,
  hard for the business.

### Model D: The founder's full hybrid (membership + separate expansions)

- **Free:** the gate, Pofu, and the home island; game content locks at a
  point.
- **Paid:** yearly 349,99 TL and lifetime 999,99 TL membership, **and**
  expansions (big island packs) sold separately on top, possibly at a
  member discount.
- **Paywall moment:** the content lock, then each expansion launch.
- **Conversion:** like B for the membership; expansions might add **0–20
  %** revenue from members.
- **Why I recommend against it as written:**
  1. **It double-charges the people who love us most.** A member who pays
     every year and then meets a price tag on the next island learns that
     "Plus" did not mean "the full game".
  2. **It breaks "lifetime".** If lifetime excludes expansions, it is not
     lifetime, and Turkish reviews will say so loudly. If lifetime
     includes them, the separate expansion only charges yearly members,
     which is backwards.
  3. **Three products are hard to explain** on one sheet, and the
     paywall's job is to be understood in five seconds.
  4. **App Review fit:** a subscription must give ongoing value (guideline
     3.1.2(a)); if the ongoing content is sold separately, what does the
     subscription renew for?

  Model B keeps D's intent (a free gate, a game that eventually asks for
  money, a membership, and expansions as the content unit) and removes
  the double charge.

### Rejected outright

- **"The gate is free, but turning it into game progress needs
  membership"** (no game at all for free users). The game is the reason
  to press "skip"; the home island is the demo that makes people want
  more and tell friends. Without it, the free product is ScreenZen
  without its generosity, and word of mouth, our only growth channel,
  dies.
- **Weekly or monthly plans.** Weekly plans are a dark pattern in a
  wellbeing product; a monthly plan at ~50 TL would mostly add churn
  (and the founder already ruled it out).
- **Tips at launch.** The founder ruled them out; agreed. Tips fund
  ScreenZen's single developer at a scale of hundreds of thousands of
  users; they do not fund an art pipeline.
- **A time-limited free trial of Plus.** A trial lets someone build on
  Yıldız and then locks what they built when it ends. That is the
  definition of punishment. The free three weeks *are* the trial.
- **Selling seeds, boosts, skips of waiting, or "rescue Pofu" items.**
  Never (A6).

## 6. Fair lock or dark pattern: the test

Locking game content in an anti-addiction product is fair when it reads
as "you finished the demo, here is the full game", and a dark pattern
when it reads as "pay or the thing you care about suffers". The test for
every paid line, in this order:

1. **Does paying change the gate, Pofu's wellbeing, calm, or what
   resisting earns?** If yes, it is forbidden. Under Model B, a free and a
   paid player who behave the same earn the same seeds, have the same
   calm, and Pofu feels the same.
2. **Is the locked thing a new place, or the continuation of something
   the player is in the middle of?** A new island is a new place. A home
   island stage, a station's next level, or a resident who already lives
   with you is a continuation and must never lock.
3. **Is the free part complete on its own?** The home island has an
   ending (stage 5 and its celebration); İskele has its postcard set. A
   free player can finish something real.
4. **When the offer appears, is there still free work to do?** At day 22
   the free player has weeks of building left. The offer must never be
   the only thing on screen when the seeds have nowhere to go.
5. **Is it sold by the character?** **Pofu never sells.** Not in a
   bubble, not in a sad face, not "Pofu wants to visit Yıldız". The
   paywall is a plain native sheet in our voice, not his. Monetizing the
   character's affection is the line we will not cross.
6. **Where can it appear?** Only in the world (the island card on the
   map), Settings → Plus, and one quiet row in the weekly recap
   (ADR-0012). **Never** on the shield, Hop!, the care rung, the breathing
   break, the emergency pass, bedtime, onboarding, or a notification.
7. **How often?** Opened only by a tap, except the one weekly-recap row.
   No re-prompt after "Not now" until a new island arrives.
8. **What does the copy never say?** No countdowns, "today only",
   struck-through fake prices, "you're missing out", or guilt ("don't let
   Pofu down"). No discount that expires.
9. **Can the decision be undone kindly?** Seeds never expire; if someone
   buys a year later, everything they banked is spendable. A lapsed
   member keeps every island and level built, residents stay, rituals
   continue; only new building on Plus islands and new Plus islands wait.

The behavioral risk worth naming: if the game is the main motivation to
skip, a free player who has finished the free islands has less reason to
skip. That is why Pofu's care, calm, and the morning number stay free and
central, and why the free player needs a gentle seed sink after day ~60.
The metric that tells us whether we got it wrong: **resisted-reach ratio
of free players in weeks 9–12 vs weeks 3–6**. If it falls more for free
players than for members, the lock is hurting the product's purpose, and
we move the line.

### App Store rules that apply

- **3.1.1 In-App Purchase:** unlocking content or features must use IAP;
  no license keys or external unlocks. Non-consumables (lifetime) must be
  restorable. A zero-price "N-day trial" non-consumable is allowed
  (2018 change) but we are not using one [trial] [guidelines].
- **3.1.2(a) Subscriptions:** must provide ongoing value; Apple's own
  examples of permissible subscription content include new game levels
  and episodic content, which is exactly seasonal islands. Do not take
  away primary functionality existing users already paid for when
  changing a business model: another reason to set the free/paid line
  **before** public launch [guidelines] [rc-312].
- **3.1.2(c) Subscription information:** the sheet must clearly state
  what the user gets, the price, and the renewal period before purchase.
- **Family Sharing:** can be enabled per subscription and non-consumable;
  once enabled for a product it cannot be turned off. Turn it on at
  creation.

## 7. Islands as the expansion unit

The island system is being designed in parallel; this is what
monetization needs from it.

### What an expansion is

An expansion is **one island**: a theme, a resident with a personality,
three stations with five designed levels, one finite ritual, and a thread
of story. It arrives for members in a seasonal update and stays forever
(A7: no FOMO; a member who joins in year 2 gets every past island, which
drift close one per night, a small "voyage" beat).

What people would actually pay for, ranked by evidence and instinct:

1. **A new place with a new friend and a ritual** (Yıldız's stars,
   İskele's postcards). This is what cozy expansions sell: more of the
   world you love, with a face.
2. **Story.** Bulut's library (Kitap) is the most "expansion-like"
   island: a book read one page a day is content people finish and
   remember. Seasonal islands should each carry a short story.
3. **Collections that mean something** (a postcard set of real places,
   a constellation you name). Finite, completable, shareable.
4. **A season of two or three connected islands** with a shared story,
   once there are enough of them (e.g. an Aegean season). Big enough to
   make a trailer and a press moment.
5. **Pure cosmetics** (themes, skins). Lowest willingness to pay, except
   for the already-attached; kept in Plus as a bonus, not the reason.

Never an expansion: residents or stations that **produce** more seeds
(pay to progress), time-limited islands, or anything the gate touches.

### Should expansions be separate from membership, and in lifetime?

- **Included in yearly Plus: yes.** That is what the subscription renews
  for (and what 3.1.2(a) wants).
- **Included in lifetime: yes, every future island, forever.** Lifetime
  that excludes expansions is not lifetime. We price for it (section 8)
  and review the TL price for new buyers every six months.
- **Sold separately: not at launch.** In year 2, if the beta and launch
  data show people who will not subscribe but would buy, test a
  **non-member season pack** (a non-consumable, e.g. 149,99 TL / $4.99,
  "this season's islands, yours for good"). Members and lifetime owners
  get it included, always.

### What the island system needs to support this

1. A clean **free/Plus flag per island** in `ArchipelagoCatalog`, with the
   arrival rules identical for both (tended days, calm nights, levels).
2. The **island card** carries the paywall's content (ritual, resident,
   stations), so the offer is the island itself, not an ad.
3. **Lapsed-member state:** built levels stay, residents stay, rituals
   continue; new levels and new Plus islands wait.
4. **A free, finite seed sink after the free islands are done** (around
   day 60): for example, decorations for the home island or gifts for
   residents built with seeds. Without it, a free player's seeds pile up
   with nowhere to go, which reads as pressure to buy.
5. **A content cadence we can keep:** the promise is "new islands with
   the seasons", without a number in the copy. Internally, plan two to
   four islands a year; each is roughly 15–20 painted images plus the
   template code. Missing a season hurts members (they pay for this) and
   lifetime owners (they bet on it).
6. Art for Plus islands can ship as **on-demand assets** later, so free
   installs stay small; not a launch requirement.

## 8. Unit economics

Per sale, Türkiye (price includes 20 % VAT; Apple's commission 15 %;
digital services tax 5 % in 2026 [dst], range shown because how Apple
passes it through must be read in App Store Connect):

| | Sticker | Net of VAT | Proceeds after 15 % | After DST (if deducted) | ≈ USD at 49.8 |
|---|---|---|---|---|---|
| Plus yearly | 349,99 TL | 291,66 TL | 247,91 TL | ~233 TL | **$4.70–$4.98** |
| Plus lifetime | 999,99 TL | 833,33 TL | 708,33 TL | ~667 TL | **$13.40–$14.22** |

US (prices exclude sales tax): yearly $29.99 → **$25.49**; lifetime
$89.99 → **$76.49**. Euro area (VAT included, ~20 %): €29.99 → about
**€21**.

### Per 10,000 installs, year 1 (Model B, estimates)

Assumptions: 1.6–4.5 % of installs buy; Türkiye mix 60 % yearly, 40 %
lifetime (unmeasured; we expect lifetime to be popular in TR); US mix
75/25.

| Market | Buyers | Average proceeds per buyer | Year-1 proceeds |
|---|---|---|---|
| Türkiye | 160–450 | ~420 TL | **67K–189K TL ($1.3K–$3.8K)** |
| US | 160–450 | ~$38 | **$6.1K–$17.2K** |

Compared with the other models, Türkiye, per 10,000 installs: Model A
(0.5–1.5 %) about **19K–57K TL**; Model C about **69K–173K TL** from the
unlock, plus expansions that must each sell again; Model D about Model B
plus 0–20 %, minus the trust it costs.

**The honest reading:** Türkiye validates the product and the price; it
will not fund development on its own, even under the best model. A US
buyer is worth about **eight** Turkish buyers. That fits the vision
(most revenue from outside Türkiye) and argues for shipping English at
launch with the same model. Renewals: RevenueCat reports year-one
subscriber retention around 27–28 % regardless of paywall type [rc-hard];
treat yearly renewals as a bonus, not the plan, which is another reason
lifetime is worth selling.

Fixed costs to cover: the Apple Developer Program ($99 a year), the
domain and privacy pages, and the time of making two to four islands a
year.

## 9. Recommendation

**Model B, "Free home, paid voyage", with these prices:**

| Region | Yearly | Lifetime | Multiple |
|---|---|---|---|
| Türkiye | **349,99 TL** | **999,99 TL** | 2.9× |
| US | **$29.99** | **$89.99** | 3.0× |
| Euro area | **€29.99** | **€89.99** | 3.0× |
| UK | **£24.99** | **£79.99** | 3.2× |
| Other storefronts | Set manually by purchasing power, reviewed yearly | | |

Why these numbers:

- **Türkiye:** the founder's numbers are right. 349,99 TL is under
  Netflix Standard for a month (389,99 TL) for a year of islands;
  999,99 TL lifetime is the "pay once, keep it" answer to inflation and
  subscription fatigue. The 2.9× multiple is low next to one sec (5×) and
  Freedom (~4–5×), and lifetime here includes a promise of future content,
  so **raise the lifetime for new buyers with inflation** (review every
  six months; existing owners are never affected).
- **US:** $29.99 a year is a third of Opal, under Finch ($69.99) and
  Headspace ($69.99), in line with Brainrot's reported range, above one
  sec ($19.99), which sells a utility, not a world. $89.99 lifetime is
  under one sec's $99.99 and well under Opal's $399.

Why B, in one paragraph: it is the only model that makes money *from the
game people already love* without touching the reason they downloaded
the app. The free player gets a complete, generous, finishable game and
the full gate; the paid player gets more places, never a better rate.
It gives the subscription a real reason to renew (seasonal islands),
gives Türkiye a lifetime that respects inflation-weary buyers, and has
one sentence of explanation: "Ayçiçeği and İskele are free forever; Plus
opens every other island."

**This must be decided before the public launch.** Once islands have been
free for the public, locking them would take away what people already
had, which is both a trust breach and against the spirit of 3.1.2. The
friends beta is the last moment to set the line.

## 10. Decisions for the founder

| # | Decision | My recommendation |
|---|---|---|
| 1 | Which model? | **B: free home and İskele, Plus opens every other island.** |
| 2 | Where does the free game end? | After **İskele**; the first Plus island is **Yıldız** (day ~22). Not after the home island: by day 45–65 most users are gone and the offer would arrive when free work runs out. |
| 3 | Türkiye prices | **349,99 TL a year, 999,99 TL lifetime**; lifetime reviewed every six months for new buyers. |
| 4 | Global prices | **$29.99 / $89.99**, €29.99 / €89.99, £24.99 / £79.99; others set manually. |
| 5 | Monthly or weekly plans? | **No.** |
| 6 | Free trial of Plus? | **No.** The free three weeks are the trial; a trial would lock what people built. |
| 7 | Expansions: separate or included? | **Included** in yearly and lifetime, always. A non-member season pack is a year-2 experiment. |
| 8 | Does lifetime include future islands? | **Yes, forever.** |
| 9 | Tips? | **No** at launch (agreed). |
| 10 | Family Sharing? | **On** for yearly and lifetime, no separate family plan. |
| 11 | Who sells? | **Never Pofu.** A plain native sheet, opened by a tap. |
| 12 | Lapsed members | **Keep everything built**, residents and rituals included; new building on Plus islands waits. |
| 13 | Friends beta | Everyone gets Plus free via sandbox; show the real day-22 card and measure taps on each price (fake door, decision audit U13). Beta testers keep Plus for life at launch, as a thank-you (offer codes; confirm non-consumable support in App Store Connect). |
| 14 | Paperwork | After decisions 1–8: an **ADR** for the free/paid boundary; amend game-design pillar 7 ("Plus sells places and beauty, never speed or relief") and A6/A7; update [research](../research/monetization.md) and [vision](vision.md) principle 3. |
| 15 | Competitor TR prices | Founder screenshots the TR in-app purchase lists of Opal, one sec, Finch, Duolingo, and Headspace from his iPhone (10 minutes); I add them here. |

### What would change my mind

- The friends beta shows most testers stop caring about the game after
  week 3 → the game is not the value; fall back to **Model A** and sell
  beauty.
- Free players' resisted-reach ratio falls after the free islands end,
  more than members' does → the lock hurts the mission; move the line
  later (free Yıldız) or add free islands.
- Day-22 taps on "999,99 TL once" are several times those on "yearly" →
  lead with lifetime in Türkiye, or test Model C's one-time unlock there.

## Sources

Accessed 2026-11-02 through web search (several pages were read only
through search snippets; the App Store and some trackers are blocked from
the agent environment). Dates in brackets are the source's date where
known.

- [opal]: Opal pricing (USD storefront listing and reviews, 2026):
  [community](https://community.opal.so/t/pricing-is-too-high/3246),
  [Autonomous review 2026](https://www.autonomous.ai/de-CH/ourblog/opal-app-review),
  [TR listing via AppTail](https://apptail.io/app/opal-screen-time-control-Rmu/turkey)
- [onesec]: one sec prices (May–Jun 2026):
  [Forepause comparison](https://forepause.pages.dev/vs/one-sec/),
  [Adapty paywall library](https://adapty.io/paywall-library/one-sec-screen-time-focus/),
  [one sec help](https://help.1se.co/articles/2701115-is-there-a-fee-for-this-app)
- [screenzen]: [Habit Doom on ScreenZen](https://habitdoom.com/blog/screenzen-alternative-iphone),
  [ScreenZen blog](https://www.screenzen.co/blog)
- [audit]: [decision-audit.md](decision-audit.md) (2026-11-01)
- [unrot]: [MWM listing](https://mwm.ai/apps/unrot-earn-your-screentime/6746537171),
  [ScreensDesign](https://screensdesign.com/showcase/unrot-earn-your-screentime)
- [jomo]: [Jomo pricing](https://jomo.so/pricing)
- [freedom]: [G2 Freedom pricing](https://g2.com/products/freedom-to/pricing)
- [forest]: [Toolradar](https://toolradar.com/tools/forest/pricing),
  [Marlvel audit (May 2026)](https://marlvel.ai/api/llm/apps/productivity/forest-focus-for-productivity)
- [flora]: [AlternativeTo](https://www.alternativeto.net/software/flora-focus-trees/about/)
- [finch]: [Recurdash (verified Jul 2026)](https://recurdash.com/subscription-pricing/finch),
  [Gerald 2026](https://joingerald.com/learn/financial-wellness/finch-app-cost)
- [duo]: [The Pricer](https://www.thepricer.org/how-much-does-super-duolingo-cost/)
- [mydealz]: [mydealz: Duolingo Super via Türkiye](https://www.mydealz.de/magazin/duolingo-super-fuer-20-euro-jahr-so-funktioniert-der-tuerkei-trick-ohne-vpn-angebot-42759)
- [subger-hs]: [Subger: Headspace](https://subger.com/tr/service/headspace-meditation);
  [subger-calm]: [Subger: Calm](https://subger.com/tr/service/calm-meditation)
- [sleepcycle]: [Sleep tracker review 2026](https://sleep-tracker-worth-it.pages.dev/best/sleep-cycle-app-worth-it)
- [poke]: [Game8: Pokémon Sleep premium](https://game8.co/games/Pokemon-Sleep/archives/418502);
  [vgc]: [VGC: $100M in a year (Jul 2024)](https://videogameschronicle.com/news/pokemons-sleep-tracking-app-has-generated-100m-in-a-year)
- [stardew]: [TouchArcade: free DLC forever (22 Jul 2024)](https://toucharcade.com/2024/07/22/stardew-valley-free-dlc-updates-always-concernedape-promises/);
  [stardew-mobile]: [Game8: Stardew price](https://game8.co/articles/latest/stardew-valley-dlc-and-preorder)
- [spirit-500k]: [Nintendo Life (Apr 2021)](https://www.nintendolife.com/news/2021/04/spiritfarer_celebrates_500000_sales_with_free_lily_update_out_today);
  [spirit-1m]: [Nintendo Wire (Dec 2021)](https://nintendowire.com/news/2021/12/14/spiritfarer-surpasses-1-million-copies-sold/)
- [mv-shores]: [Macworld: Forgotten Shores](https://www.macworld.com/article/224558/if-you-ve-played-monument-valley-you-have-to-play-forgotten-shores.html);
  [mv-ida]: [Android Police: Ida's Dream (Jun 2015)](https://www.androidpolice.com/2015/06/25/monument-valley-idas-dream-chapter-now-available-on-android-at-no-extra-cost-plus-the-game-is-free-on-amazon-today/);
  [mv3]: [mobilegamer.biz: MV3 on Netflix (Dec 2024)](https://mobilegamer.biz/monument-valley-3-is-coming-to-netflix-on-december-10/)
- [cozygrove]: [Game Developer: Camp Spirit](https://www.gamedeveloper.com/press-release/cozy-grove-camp-spirit-is-now-available-on-pc-and-consoles),
  [Nintendo Life eShop](https://www.nintendolife.com/eshop/cozy_grove_camp_spirit)
- [fx]: [Türkgün: 27 Oct 2026 exchange rates](https://www.turkgun.com/ekonomi/27-ekim-2026-dolar-euro-ne-kadar-guncel-doviz-kurlari/410590)
- [wage]: [İşçi Haber: 2026 minimum wage](https://www.iscihaber.net/ekonomi/2026-yili-brut-ve-net-asgari-ucret-ne-kadar-asgari-ucrete-yuzde-kac-zam-yapildi/194873)
- [netflix]: [Evrensel: Netflix TR prices (3 Oct 2026)](https://www.evrensel.net/haber/6003250/netflix-abonelik-ucretlerine-zam-yapti-en-dusuk-paket-25999-tlye-yukseldi)
- [ytp]: [Politikam: YouTube Premium TR (Jun 2026)](https://www.politikam.com/youtube-premiuma-buyuk-zam-iste-yeni-fiyat-listesi-bireysel-aile-ve-ogrenci-paketleri-ne-kadar-oldu)
- [chatgpt]: [Politikam: ChatGPT Plus TR on the App Store](https://www.politikam.com/yapay-zekada-yerel-fiyatlandirma-donemi-bitti-chatgpt-plus-turkiye-abonelik-ucretine-dev-zam-iste-yeni-fiyati)
- [dst]: [Bloomberg HT: DST 5 % from 2026](https://www.bloomberght.com/dijital-hizmet-vergisi-2026-dan-itibaren-yuzde-5-oraninda-uygulanacak-3764708),
  [Alo Maliye (25 Dec 2025)](https://www.alomaliye.com/2025/12/25/dijital-hizmet-vergisi-oranlari-tablosu-ve-aciklamalar/)
- [apple-dst]: [Habertürk: Apple starts deducting DST in Türkiye](https://www.haberturk.com/apple-turkiyede-dijital-hizmet-vergisini-kesmeye-basliyor-2790685-teknoloji),
  [9to5Mac (Sep 2020)](https://9to5mac.com/2020/09/01/app-store-prices-increase-chile-mexico-saudi-arabia-turkey/)
- [sbp]: [Adapty: Small Business Program 2026](https://adapty.io/blog/app-store-small-business-program/),
  [MacRumors (Nov 2020)](https://www.macrumors.com/2020/11/18/apple-drops-app-store-fees/)
- [rc-hard]: [RevenueCat: hard paywall vs freemium](https://www.revenuecat.com/blog/growth/hard-paywall-vs-freemium);
  [rc-2026]: [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps);
  [rc-2025]: [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025);
  [rc-trends]: [RevenueCat 2026 trends](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026);
  [rc-sum]: [SaaStr summary of SOSA 2026](https://saastr.com/the-top-10-learnings-from-revenuecats-state-of-subscription-apps-how-115000-mobile-apps-deliver-16b-in-revenue-whats-working-whats-quietly-killing-growth);
  [rc-life]: [RevenueCat: lifetime subscriptions](https://www.revenuecat.com/blog/growth/lifetime-subscriptions.md)
- [adapty]: [Adapty: State of in-app subscriptions 2026](https://adapty.io/state-of-in-app-subscriptions-2026)
- [airbridge]: [Airbridge: should you offer a lifetime subscription](https://www.airbridge.io/en/blog/should-you-offer-a-lifetime-subscription)
- [mario]: [9to5Mac: Super Mario Run conversion (Jan 2017)](https://9to5mac.com/2017/01/03/super-mario-run-revenue-conversion/);
  [lite]: [Pocket Gamer: lite-version conversion](https://www.pocketgamer.com/articles/023477/r/),
  [Mobile Dev Memo: low conversion in free to play](https://test.mobiledevmemo.com/low-conversion-free-play-feature-bug/)
- [guidelines]: [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (3.1.1, 3.1.2);
  [rc-312]: [RevenueCat community: 3.1.2 ongoing value](https://community.revenuecat.com/general-questions-7/app-review-rejection-guideline-3-1-2-ongoing-value-6617);
  [trial]: [MacRumors: free trials for paid apps (Jun 2018)](https://www.macrumors.com/2018/06/05/app-store-app-free-trials-now-available/amp)
