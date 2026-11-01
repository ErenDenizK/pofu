# Monetization Research

_Last updated: 2026-11-01. Status: research complete; decision deferred to the
launch phase, constrained by the principles below. Paywall timing decided
in [ADR-0012](../adr/0012-ux-v1-decisions.md): no paywall in onboarding._

## Founder constraints

- The core experience is never paywalled, especially in Türkiye.
- The product should be an affordable alternative to the reference apps and
  surpass them on quality.
- Most long-term revenue is expected from outside Türkiye.

## What the data says

### Hard paywall vs freemium (global)

RevenueCat's State of Subscription Apps, the largest public dataset on the
topic (100K+ apps):

| Metric | Hard paywall | Freemium |
|---|---|---|
| Median download-to-paid conversion by day 35 | ~10.7% (2026 report; ~12.1% in 2025) | ~2.1% |
| Refund rate | 5.8% | 3.4% |
| Year-one subscriber retention | 27% | 28% |

**Reading:** hard paywalls extract roughly five times more paying users per
install, but they do **not** retain subscribers better, and they refund more.
Their advantage is in acquisition economics for apps that grow through paid
ads. Our growth engine is word of mouth among friends and social features,
where every free user is a distribution channel. A hard paywall would cut the
very mechanic we rely on to grow.

### Trials

- Longer trials convert better: a median of ~42.5% trial-to-paid for trials of
  17–32 days (2026 report).
- Short trials are fragile: 55% of 3-day trial cancellations happen on day 0.
- Across the industry, the overwhelming majority of trial starts happen during
  the first session, usually at the end of onboarding.

**Reading:** if we offer a trial, it should be long (around a month), so the
user experiences a full habit cycle before deciding, and it should be
presented at the end of onboarding, when intent is highest, as a skippable
offer rather than a wall.

### Character-driven freemium

Finch, the closest analogue in emotional design, keeps the core self-care loop
free and monetizes through a subscription that unlocks cosmetics and extras
for the companion. Its retention (estimated D1/D7 of 54%/37%) is comparable
to Duolingo's.

### Türkiye

We found **no reliable public data** on subscription conversion or price
sensitivity specific to Türkiye. Indirect signals (telecom churn behavior,
widespread complaints about subscription prices) point to high price
sensitivity. App Store regional pricing lets us set Turkish prices
independently of the US price.

**Action:** treat Türkiye pricing as an experiment. Measure it during the
friends beta and the local launch instead of assuming.

## Recommendation (to be confirmed in an ADR before launch)

**Generous free core + optional "Plus" membership + lifetime option.**

| Free forever | Plus |
|---|---|
| App blocking, schedules, presets | Companion cosmetics: outfits, accessories, homes |
| Full friction ladder | World themes and seasonal scenes |
| The companion and its world (base) | Advanced insights and history |
| Streaks and core rewards | Extra widget and app icon styles |
| Earn/spend economy | Larger friend groups and leagues |
| Friend approval (one partner) | Priority access to new features |

Mechanics:

- **Monetize delight, not relief.** Nothing that helps someone stop scrolling
  sits behind the paywall.
- **Soft paywall at the end of onboarding** with a long trial and a
  prominent "Not now". **Contextual paywalls** appear when the user reaches
  for a Plus item.
- **Annual-first pricing with a lifetime option.** No weekly plans: they
  convert well but read as a dark pattern in a wellbeing product.
- **Regional pricing:** Türkiye priced as an accessible impulse purchase.
  Positioning anchor: a year of Plus should cost less than one month of a
  mainstream streaming subscription. Global pricing remains competitive with
  the reference apps.
- **Optional tip jar** for users who want to support development without
  subscribing.

## Founder input (2026-10-31)

Initial ideas from the founder, to be finalized in the launch-phase ADR:

| Offer | Türkiye | Notes |
|---|---|---|
| Plus, annual only | ~350 TL / year | "The price of a coffee." No monthly plan: nobody should pay 50 TL a month. |
| Plus, lifetime | ~1,000 TL | |
| Tip jar | Small amounts | Support without subscribing, with a thank-you bonus. |
| Global | Higher, set per region | Apple allows independent prices per storefront. |

Evaluation:

- **Annual-only is sound at this price.** Around 29 TL a month equivalent sits
  below the impulse threshold. A monthly plan would mostly add churn.
- **Lifetime at roughly 2.9 times the annual price** is within the usual
  range (2.5–4×). It suits Türkiye, where subscription fatigue is high and
  inflation makes one-time purchases attractive. Revisit the TL price at
  least yearly because of inflation.
- **The tip jar must use In-App Purchase.** App Store guidelines require
  digital tips inside the app to go through IAP; an external "Buy Me a
  Coffee" link is not allowed for in-app content. A culturally native twist:
  _"Pofu'ya bir simit ısmarla"_ ("buy Pofu a simit"), where each tip gives
  Pofu a small cosmetic thank-you (a simit, a tea glass) that the user
  keeps. In English: "buy Pofu a snack".
- Set TL prices manually instead of relying on Apple's automatic
  currency-based equalization, which tracks exchange rates rather than local
  purchasing power.

## Business and legal notes (verify with an accountant before revenue)

- An individual Apple Developer Program enrollment publishes the founder's
  legal name as the seller on the App Store.
- Türkiye's Income Tax Law, article 20/B, provides an income tax exemption for
  individuals earning from mobile applications sold through app stores,
  conditional on a dedicated bank account and an exemption certificate from
  the tax office, with withholding applied by the bank. Rates, limits, and
  social security implications must be confirmed with a professional before
  the first payout.
- Any backend that stores personal data must comply with KVKK (Türkiye) and
  GDPR (EU users).

## Sources

- [RevenueCat: State of Subscription Apps 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- [RevenueCat: Subscription app trends and benchmarks for 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026)
- [RevenueCat: Hard paywall vs freemium](https://www.revenuecat.com/blog/growth/hard-paywall-vs-freemium)
- [Airbridge: Hard paywall vs freemium 2026](https://www.airbridge.io/en/blog/hard-paywall-vs-freemium-2026)
- [Deconstructor of Fun: How Finch drives retention](https://www.deconstructoroffun.com/blog/x0hd2ssr80y5n7gv0w967pg7hwd7tl)
- [Adapty: State of in-app subscriptions 2025](https://adapty.io/tr/reports/state-of-in-app-subscriptions-2025/)
- [Mobile app developer tax guide 2026 (Vergi Merkezi)](https://vergimerkezi.com.tr/?p=4673)
- [Social media and mobile app tax exemption (Kazım Ceylan Law Office)](https://www.kazimceylan.av.tr/sosyal-medya-ve-mobil-uygulama-vergi-istisnasi)
