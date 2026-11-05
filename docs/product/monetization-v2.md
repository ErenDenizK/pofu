# Monetization v2: one membership for a compact game

_Status: proposal for the founder, 2026-11-05. It replaces the
recommendation of [monetization.md](monetization.md) (v1, 2026-11-02),
whose market tables, Türkiye tax notes, fair-lock test (§6) and sources
still hold. Why a v2: the game changed under v1. The station islands it
sold (Yıldız, Kaplıca, Kitap) are retired ([game plan §2](game-plan.md#2-structure-two-layers));
Book One is a short story that ends near day 45; home ends in Tam Çiçek
near day 60 and then lives on through mastery and seasons
([home-progression](home-progression.md)). The founder asked (2026-11-05)
how to sell that: monthly, one-time, acts, expansions, and what happens to
the island when a membership ends. His prices and the four ethics
conditions (gate never weaker, Pofu never suffers at a lock, a lock only
at a chapter end, honesty) are inputs, not open questions._

## 0. The answer

**Recommended: "Pofu Üyelik", one membership that is the whole story.**
Free forever: the gate, Pofu and Mochi, every seed, the whole home
(Ayçiçeği and İskele up to Tam Çiçek), the friends features, and the
Prologue plus **Act I** of Book One. The membership opens **the rest of
every Book** (Act II onward, and every Book after), the fillers, mastery
L6 to L10, and the season sets. Future content is **included**, never sold
on top.

| | Türkiye | US | Role |
|---|---|---|---|
| Yearly | **349,99 TL** | $29.99 | The default; the one we recommend on the sheet |
| Lifetime | **999,99 TL** | $89.99 | "Pay once, every Book forever" |
| Monthly | **129,99 TL** | $5.99 | The honest trial: "try a chapter"; never the default |

**Lapse rule in one line:** nothing you have is taken away, the act you
are in plays to its end, and only the *next* chapter and new mastery
levels wait (§4).

**Acts sold one by one (350 / 450 TL) are rejected** as the main model:
two paywalls inside one short book, a Book One that costs more than a
year of everything, and a staircase where each act must sell again
(§2.4). One-time Books are Alternative A (§7) and the fallback if the
beta shows Turkish buyers refuse subscriptions.

## 1. What is free, what is paid

### Free forever (never A/B tested)

| Area | What | Why |
|---|---|---|
| The gate | Shield, Hop!, the ladder, care rung, breathing break, emergency pass, schedules, bedtime, history | The product's purpose (ADR-0012, [ADR-0015](../adr/0015-care-over-currency.md)); also App Store **4.10**: Screen Time APIs are a built-in capability that may not be monetized |
| The companion | Pofu and Mochi, every emotion, wellbeing, the morning number, "sleeps it off", daily resident visits | [ADR-0017](../adr/0017-pofu-never-dies.md); Pofu's affection is never for sale |
| Earning | Seeds, calm, rounds: identical for free and paid | v1 §1 rule 4 |
| The home | Ayçiçeği and İskele, all eight stations to L5, island levels 1 to 10, **Tam Çiçek**, decor sets 1 Bahçe and 4 Liman, the garden game | A complete, finishable game; a station's next level is a continuation and never locks |
| Story | The Prologue and **Act I** (Koke, Çağlayan; the waterfall restored), the flow game | A real first chapter with a real ending |
| Seasons | Every season's look and its visitor, every year | Code-first, no FOMO |
| Friends | Postcards, a friend's boat at your pier, shared streaks | Social grows the product; paywalling it shrinks it |
| Memory | The Seyir defteri: re-read every scene you have seen, forever | Memories never lock |

**The materials problem, solved.** Home levels need materials from story
islands (keepsake, light, wax; [home-progression §7](home-progression.md#7-materials-from-the-wonder-islands)).
If Act II is paid, a free home would stall at workshop L4, which breaks
"a continuation never locks". So **Simit's cart trades** one material a
week for seeds, for everyone, once that material's island has appeared
in the world. A free player reaches Tam Çiçek around day 70 instead of
60. Seeds stay world material (ADR-0015); members get materials earlier
because they visit the places, not because they earn faster. This is the
one asymmetry, and it is bounded.

### Paid: Pofu Üyelik

1. **Book One from Act II** (Emanet onward to the Gezgin finale) and
   **every later Book**, with each Book's wonder islands, residents and
   hilltop add-ons.
2. **Fillers** (Çanlar and the rest), the random-day add-ons.
3. **Mastery L6 to L10** and **Altın Ada**, opening one cap a season.
4. **Season decor sets** (Bahar, Yaz, Güz, Kış and their successors) and
   the hive.

Never paid, in any model: speed, seeds, calm, materials as a purchase,
waiting, a stronger or weaker gate, or anything Pofu feels.

## 2. Product structure for a compact game

### 2.1 Units

- **Book**: one season of the big story, one layer of the
  [deep-lore iceberg](deep-lore.md#1-the-iceberg), about six to eight
  weeks of tended days. Book One ships at launch; later Books ship as app
  updates.
- **Act**: two or three main islands that end on a real ending (the
  founder: "every act must truly end"). Book One's acts follow the main
  islands once their order is settled (4 or 5 mains, under rewrite):
  provisionally **Prologue** (home, days 1 to 3), **Act I** (Koke,
  Çağlayan; ends ~day 14 with the waterfall), **Act II** (Emanet,
  Revontuli; ~day 33), **Act III** (Arı, Gezgin; ~day 45).
- **Filler**: a small island on a random day; never moves the story, never
  gates home ([founder 2026-11-05](founder-input.md#2026-11-05-game-plan-v1-and-the-story-flow)).
- **Season**: the real calendar's look, visitor and decor set.

### 2.2 The rule that keeps a buyer busy

**A member is never more than a week from something new, and never has a
daily obligation.** What a yearly member has in each stretch:

| Months | Story | Home and long tail |
|---|---|---|
| 1 to 2 | Book One, Acts II and III | Island levels to Tam Çiçek; residents' hearts; decor |
| 2 to 4 | Fillers; the first Book Two island (target: launch + 10 weeks) | The hilltop, the hive, mastery cap 6 then 7, a season set and visitor |
| 4 to 12 | Book Two, one main island every ~6 weeks; fillers between | Mastery to L10, Altın Ada near month 9; four seasons; friends |

"When content ends the user needs something to play" has a structural
answer: the story ends, the island does not. Mastery opens one level a
season, so there is always one more thing to build and never a reason to
play more than a visit a day.

### 2.3 How future content ships: included, always

- **Included in yearly, monthly and lifetime.** That is what renewal pays
  for, and what Apple's 3.1.2(a) wants from a subscription (new levels and
  episodic content are its own examples).
- **Lifetime includes every future Book, forever.** A lifetime that
  excludes expansions is not lifetime. The price for *new* lifetime
  buyers is reviewed every six months (inflation); owners are never
  touched.
- **Cadence we can keep:** one main island every ~6 weeks, one filler
  and one decor set a season; about 15 to 20 painted images per island
  through the Codex queue. The copy never promises a number ("new islands
  with the seasons").

### 2.4 The options the founder named, judged

| Option | Verdict | Why |
|---|---|---|
| **Monthly** | **Yes, as a third, quiet option** | The game is ~2 months of story; a monthly matches "finish it in two months" honestly. Priced so two months (260 TL) is close to a year (350 TL): the yearly is the obvious deal for anyone who stays |
| **Yearly 349,99 TL** | **Yes, the default** | The founder's "I use it, I keep earning, it is good for the developer" price. 1.25 % of the net minimum wage (v1 §3); under a cinema ticket |
| **Lifetime 999,99 TL** | **Yes** | The inflation-weary buyer's answer and the "I love it" purchase; 2.9× yearly |
| **One-time "buy the game"** | Alternative A | Clean, cozy-game-like, but no income for ongoing art, and every Book sells again |
| **Acts (350 / 450 TL)** | **No** | Book One would cost 800 TL, more than two years of membership, with two paywalls in 45 days. Per-act decisions are the nickel-and-dime feeling cozy players punish |
| **Expansions sold to members** | **No** | Double-charges the most loyal people |
| **Expansion for non-members** | Year 2 experiment | A "Book Two, yours forever" non-consumable (~299,99 TL) for people who will not subscribe; members always have it included |
| **Tips, ads, weekly plans, seed packs** | No | v1 §5 "Rejected outright" |

## 3. Pricing

### 3.1 Türkiye

The founder's numbers are right and stay: **349,99 TL a year, 999,99 TL
lifetime**, plus **129,99 TL a month**. Context: a coffee ~250 TL, a
cinema ticket 500 to 700 TL, Netflix Basic 259,99 TL a month (v1 §3).
Rules:

- Set TRY prices **manually** in App Store Connect; do not let Apple
  equalize from USD (it tracks the exchange rate, not purchasing power).
  Confirm 129,99, 349,99 and 999,99 exist as TRY points (Apple's point
  list could not be read from the agent environment).
- Review every six months. Raise for **new** subscribers only when Netflix
  or YouTube Premium move; existing subscribers keep their price for a
  year (App Store "preserve current price" option), and lifetime owners
  are never touched.
- Arbitrage (EU buyers on TR accounts, v1 §3) is a small leak; not a
  reason to raise TR prices.

### 3.2 Abroad

One logic: **yearly ≈ the price of two cinema tickets, lifetime ≈ 3×
yearly, monthly ≈ a fifth of yearly** (a monthly that is a bad deal on
purpose, never a trap). Reference points: Structured $6.99 / $29.99 /
$99.99 lifetime ([Habitbox, Sep 2026](https://habitbox.app/blog/structured-app-review));
one sec $19.99 / $99.99; Finch $9.99 / $69.99 ([Recurdash, Jul 2026](https://recurdash.com/subscription-pricing/finch));
Opal $99.99 a year (v1 §2).

| Storefront | Monthly | Yearly | Lifetime | Note |
|---|---|---|---|---|
| Türkiye | 129,99 TL | **349,99 TL** | **999,99 TL** | Manual |
| US | $5.99 | **$29.99** | **$89.99** | Base storefront |
| Euro area | €5.99 | €29.99 | €89.99 | VAT included; one price across the euro area |
| UK | £4.99 | £24.99 | £79.99 | |
| Sweden, Norway | 69 kr | 349 kr | 999 kr | Strong income; matches the US in value |
| Denmark | 45 kr | 229 kr | 699 kr | |
| Switzerland | CHF 6.– | CHF 29.– | CHF 89.– | |
| India, Brazil, Indonesia, Mexico | auto, then checked | | | Apple's equalization, reviewed once a year |

Euro, Nordic and Swiss points are proposals to confirm against App Store
Connect's point list. Per buyer, after Apple's 15 % (Small Business
Program), a US yearly nets **$25.49**, a TR yearly about **$4.70 to
$5.00** (VAT and the 5 % digital services tax, v1 §8): one US buyer is
worth about five Turkish buyers, so **English ships at launch** with the
same model.

### 3.3 Family Sharing

**On** for all three products, at creation (it cannot be turned off later
once on). No separate family plan: one sec and Opal charge 1.5× for one,
which adds a fourth price to explain. Each family member gets their own
island and their own gate; the membership is shared, nothing else.

### 3.4 Intro and win-back offers without dark patterns

- **No free trial that converts.** The free Prologue and Act I are the
  trial, and a trial that ends onto something you built breaks "nothing
  is taken away". The monthly is the paid trial.
- **No launch countdown, no struck-through price, no "today only".**
- **Beta thank-you:** friends-beta testers get lifetime through offer
  codes (confirm code support for non-consumables; otherwise a 12-month
  subscription code renewed by hand).
- **Win-back:** one App Store win-back offer (first year at 249,99 TL /
  $19.99) to people lapsed 60+ days, shown only by the App Store and in
  Settings, never in the world, never with a timer.

## 4. Lapse rules

The principle: **a membership opens doors; it never holds anything
hostage.** These rules apply to an expired subscription, a refund, a
family member leaving the family, and a failed renewal after the billing
grace period.

### What never changes

- The gate, Pofu, Mochi, earning, calm: exactly as before. Pofu does not
  notice the membership; no line of his ever refers to it.
- Everything built **stays and never decays**: stations, mastery levels,
  hilltop add-ons, the hive, decor and season pieces, residents (they keep
  visiting), materials and seeds (they never expire).
- Free building continues: every free station level, decor sets 1 and 4,
  Simit's trades.
- The Seyir defteri keeps every scene seen, re-readable.

### What waits (frozen, not locked away)

- **Starting** the next act, Book or filler.
- **Building** a new mastery level (L6+) or a new season-set piece.

### Mid-story: the act you are in plays to its end

If the membership ends while an act is under way, **that act stays open
until its ending**. The store sets one flag, "acts started", at the first
step of each act; entitlement is checked only when an act would start.
So a lock can only ever fall at a chapter end (the founder's condition 3),
by construction, never mid-scene. The next act's rumour can still drift in
(the world keeps talking), and its island card shows one quiet line:
"Bir sonraki perde üyelikle açılır."

### After finishing a Book

The member keeps everything; the next Book's first island appears on the
map when it ships, like for everyone, and waits. Home, mastery already
built, seasons' looks and visitors, residents and friends carry on.

### Returning

Everything resumes exactly where it paused: the story at its bookmark,
banked seeds spendable at once, any mastery caps opened while away
available immediately (caps rise for everyone by season; they never had
to be "there"). No "you missed" copy, no catch-up grind, no penalty. The
first screen back is Pofu's normal morning, not a store.

**Cost of generosity:** a monthly member who starts Act III on day 29 and
cancels finishes Act III free. We accept that: it costs one act and buys
trust that no single rule could buy.

## 5. Where the free part ends, and the paywall moment

### 5.1 Launch default and the test

**Default: the end of Act I** (the waterfall restored, ~day 14). It is a
peak: the signature animation, a material, a gift to home, an ending.
Peak-end logic says people judge the experience by it; reach says more
people are still active at day 14 than at day 33. After it, the free
player still has weeks of home building toward Tam Çiçek, so the offer
never arrives when free work runs out.

The founder wants the cut **decided by data**. Plan:

| Phase | Who | What we measure | Decision |
|---|---|---|---|
| Friends beta | Everyone a member (codes) | Retention by tended day; a one-tap question at each act end ("Devamını merak ediyor musun?" yes / bir bakarım / hayır); resisted-reach ratio by week | Which act end is the happiest point; does interest fall after any act |
| Public TestFlight (target 200 to 500) | Two arms: cut after **Act I** vs after **Act II** | The real sheet as a **fake door**: taps on each price, then "Beta teşekkürü: üyelik senin" grants it. Primary: intent taps per install (reach × tap rate). Guardrails: free players' resisted-reach ratio in the 3 weeks after the cut vs the 3 weeks before; uninstalls within 3 days of the sheet | Pick the arm with more intents per install, unless its guardrail falls ≥ 10 % relative more than the other arm's |
| Launch | Everyone | Real conversion; monthly vs yearly vs lifetime mix | Lead the sheet with lifetime in TR if lifetime taps ≥ 2× yearly |

Analytics are opt-in, on-device aggregated, and never include which apps
or how long (Screen Time data never leaves the device). With beta-sized
samples the result is directional: we look for a large difference, and
without one we keep Act I.

**Must be fixed before public launch.** Moving the line later is a gift;
moving it earlier after launch takes away what people had (3.1.2, and
trust). The test runs only in the beta.

### 5.2 Should users know the cut in advance?

**Yes, in one honest line, in two places:** the App Store description
("Ön söz ve Birinci Perde ücretsiz; üyelik hikâyenin devamını ve her yeni
kitabı açar") and the Seyir defteri's table of contents, where later acts
carry a small "Üyelik" tag. Never in onboarding: the first minutes belong
to the gate and Pofu.

### 5.3 The moment

1. Act I's ending plays **whole**: the waterfall, the gift to home, the
   week page. Nothing interrupts it.
2. **The next morning**, the Seyir defteri shows a new page: Act II's
   title, a painted vignette, two lines of what is next. For a member it
   is just the next page. For a free player the page ends with the offer.
3. The offer is a plain native sheet in our voice, **never Pofu's**:

   > **Hikâye devam ediyor.**
   > Ön söz, Birinci Perde ve evin tamamı senin; ücretsiz, sonsuza dek.
   > Üyelik, kitabın kalanını ve gelecek her kitabı açar.
   > Telefonu bırakmana yardım eden her şey ücretsiz kalır.
   > [Yıllık 349,99 TL] [Bir kez 999,99 TL, hep senin]
   > Aylık 129,99 TL · Şimdi değil

   > **The story goes on.**
   > The Prologue, Act I and the whole home are yours, free, forever.
   > Membership opens the rest of the book and every book to come.
   > Everything that helps you put the phone down stays free.
   > [$29.99 a year] [$89.99 once, yours for good]
   > $5.99 a month · Not now

4. After "Şimdi değil": no re-prompt. The page stays in the book; the
   island card shows the quiet line; Settings → Üyelik is always there;
   one row in the weekly recap, once a month at most.
5. **Never** on the shield, Hop!, the care rung, the breathing break, the
   emergency pass, bedtime, onboarding, or a notification (v1 §6).

## 6. StoreKit 2 and App Review

### 6.1 Products

| Product ID (proposal) | Type | Notes |
|---|---|---|
| `pofu.membership.yearly` | Auto-renewable, group "Pofu Üyelik" | Same service level as monthly (crossgrade at renewal) |
| `pofu.membership.monthly` | Auto-renewable, same group | |
| `pofu.membership.lifetime` | Non-consumable | Family Sharing on |

### 6.2 Entitlements

- One function, `Membership.isActive`, true if any verified entry in
  `Transaction.currentEntitlements` is the lifetime or an unexpired,
  unrevoked subscription (including billing grace). It lives in the app
  target and `PofuWorld` only. **The gate's code (`PofuLive`, the shield
  and DeviceActivity extensions) never imports it**; a test fails the
  build if it does. That makes "the gate is never paywalled" structural.
- `PofuCore` holds the gating rules as pure, tested logic: `actsStarted`,
  `canStartAct`, `canBuildMastery`; the entitlement is an input. The lapse
  rules (§4) become unit tests.
- Listen to `Transaction.updates` from launch; `finish()` every verified
  transaction; on `revocationDate`, apply the lapse rules (never remove).
- A buyer of lifetime with a running subscription: show
  `manageSubscriptionsSheet` with one line ("Yıllık üyeliğini iptal
  edebilirsin; ömür boyu artık senin"). Apple does not cancel it for us.

### 6.3 Offline, restore, Ask to Buy

- **Offline:** StoreKit 2 verifies JWS on device and caches entitlements;
  also cache the last known state with its expiry. Offline past expiry
  only means the next act waits until the device is online; nothing
  already open closes.
- **Restore:** a "Satın alımları geri yükle" button in Settings calls
  `AppStore.sync()` (required for the non-consumable).
- **Ask to Buy:** `purchase()` returns `.pending`; the sheet says "Ailene
  soruldu" and closes; approval arrives via `Transaction.updates`.
- **Family Sharing:** `ownershipType == .familyShared` counts as active;
  leaving the family is a revocation, handled by the lapse rules.
- **Billing:** turn on Billing Grace Period (16 days) and use Billing
  Retry; no server at launch. App Store Server Notifications v2 come with
  analytics later.
- **Testing:** a `.storekit` configuration file for local tests and
  Rehearsal; sandbox for renewal timing; TestFlight purchases are free.

### 6.4 Review risks for a Screen Time app

| Risk | Rule | Mitigation |
|---|---|---|
| Monetizing Screen Time itself | 4.10 (built-in capabilities, Screen Time APIs named) | The gate is free and works with no purchase; say so in review notes |
| Subscription without ongoing value | 3.1.2(a) | Episodic Books and seasons; a dated content plan in the review notes for the first submission |
| Unclear terms | 3.1.2(c), 3.1.1 | The sheet shows price, period, renewal, and links to terms and privacy; restore visible |
| Reviewer cannot reach the paywall | 2.1 | A reviewer cannot wait 14 days: the notes explain how to jump to Act I's end in Rehearsal mode, and where Settings → Üyelik is |
| Family Controls entitlement | Distribution entitlement | Already required for the gate; request early; unaffected by the model |
| Changing the deal later | 3.1.2 "do not take away" | Fix the free line before public launch (§5.1) |

Guideline numbers as of the 2025 text; re-read before submission.

## 7. Alternatives

### Alternative A: Buy the Book (one-time, no subscription)

Free part as recommended. **Book One** is a non-consumable,
**449,99 TL / $14.99**; each later Book **299,99 TL / $9.99**; a
"Complete" bundle for the then-current Books; mastery and season sets
come free with any Book owned.

- **For:** the cozy-game norm (pay once, keep it); no subscription
  fatigue; simplest lapse story (nothing lapses); likely strong in
  Türkiye, unmeasured.
- **Against:** income only when a Book ships; every Book is a new purchase
  decision; 3.1.2 does not apply, but the art pipeline is paid monthly; a
  buyer who finishes Book One owes nothing for the long tail we keep
  building.
- **Switch to it if** the beta's fake door shows lifetime taps several
  times yearly *and* monthly taps near zero in TR.

### Alternative B: Free story, paid beauty

All Books free; the membership (same prices) sells season sets, mastery
L6 to L10, hilltop add-ons, Pofu's outfits and home themes.

- **For:** no story lock at all, so the product's purpose never meets a
  paywall; the widest audience and word of mouth.
- **Against:** cosmetics convert lowest (v1 estimates 0.5 to 1.5 % of
  installs, a third of the recommendation); the story, our most costly
  content, earns nothing directly.
- **Switch to it if** the guardrail fails in both beta arms: free players
  resist less after any story cut.

### Why the recommendation wins

It is the only model where the thing people love (the story and the
growing island) pays for itself, the free player still owns a complete
game and the full gate, the lock can only fall at a chapter end by code,
and the founder's own yearly price is the default.

## 8. Decisions for the founder (recommendation first; unanswered ones proceed)

| # | Question | Recommendation |
|---|---|---|
| 1 | Model | Pofu Üyelik, future content included |
| 2 | Free cut | End of Act I at launch; beta tests Act I vs Act II |
| 3 | Prices TR | 129,99 TL / 349,99 TL / 999,99 TL |
| 4 | Abroad | §3.2 table, US base |
| 5 | Acts sold separately | No |
| 6 | Lapse | §4: nothing removed, the current act finishes |
| 7 | Announce the cut | Yes, App Store text and the book's contents |
| 8 | Paperwork after a yes | An ADR for the free/paid line; amend game-design pillar 7 and A6/A7; mark v1 superseded; add `Membership` logic to `PofuCore` tests before any UI |
