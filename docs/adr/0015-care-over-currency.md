# 0015. Care over currency: seeds as world material

- **Status:** Accepted
- **Date:** 2026-11-01
- **Amends:** [0004](0004-trust-first-activity-verification.md) (what verification earns),
  [0008](0008-hybrid-intervention-delivery.md) (the ladder's cost rung),
  [0012](0012-ux-v1-decisions.md) (decisions 3 and 5, as they concern seeds),
  [0014](0014-quiet-time-earning.md) (what quiet seeds buy)

## Context

Economy v0 ([economy.md](../product/economy.md)) made seeds a currency for
screen time: earn seeds by living (activity, steps, quiet time), spend
them on unlock windows with escalating and night prices. It works, is
implemented in `PofuCore`, and is well tested. In playtesting the island
direction, the founder named its cost: every reach became a price check,
and a currency turns the most emotional moment of the product into math.
It also creates a hoarding problem (a quiet week banked for one evening)
and invites "earning" scrolling time.

The founder's decisions of 2026-11-01:

1. **Seeds stay, but only as world material.** The user must feel "I did
   something": time away and resisted reaches accumulate seeds, and the
   user actively spends them on pre-planned station levels and island
   growth. Seeds never buy screen time.
2. **The hard limit is a breathing break,** not a price: past a daily
   threshold, every open waits for a short, calm breath with Pofu.
3. **Measure honestly.** Intent cannot be verified, so short opens are
   treated as quick checks by their pass length.
4. Pofu's wellbeing and the calm multiplier stay as designed in
   [game-design.md](../product/game-design.md); "sleeps it off" stays.

## Options considered

1. **Keep economy v0** and add the island as a second sink. Keeps a hard,
   tested limit, but keeps the price check at every reach and splits
   seeds between two meanings.
2. **Pure care, no currency** (game-design v1): opens cost wellbeing and
   calm, the island runs on "goodies". Intimate, but it removes the only
   hard limit besides the friend rung and leaves "I did something"
   implicit.
3. **Seeds as world material, care at the gate, a breath as the limit.**
   Seeds are earned by staying away and spent only on the world. Opening
   costs calm and wellbeing. Past the daily threshold, a bounded breathing
   break adds real friction without a price.

## Decision

Option 3.

- **Seeds** (`Energy` stays the domain type; the user sees seeds /
  çekirdek) are credited by Pofu's quiet gathering (ADR-0014's accrual,
  unchanged in its rules), by the stations' idle production (only while no
  guarded app is open, times the calm multiplier), and by resisted reaches
  (+3, at most 5 a day). They are debited **only** by station builds.
  **No gate path reads or writes seeds.**
- **The ladder** becomes pause → intent → **care** → askFriend. The care
  rung shows what an open would cost in calm and wellbeing and offers a
  **quick check** (a pass of 3 minutes or less: the calm bonus halves, no
  jealousy; a second within 20 minutes counts as a full open) or a full
  open (15 minutes: calm resets to ×1.0). "Skip it" stays primary
  (ADR-0012 decision 4). The fourth rapid reach still requires a friend
  (`highestAttemptRung = askFriend`); the free daily emergency pass is
  unchanged.
- **The breathing break.** Once a day's guarded time reaches the
  threshold (default 60 minutes; pre-membership estimated from granted
  pass minutes, later measured by DeviceActivity), every open first waits
  for a breathing break with Pofu: 10 s for the first two over-limit opens
  of the day, 20 s for the next two, 30 s from then on, **never more**.
  "Not now" is always available and counts as a skip; there is no way to
  skip the breath and open. The emergency pass is never breathed.
- **What leaves the gate:** the daily allowance, prices, escalation and
  night pricing (their intent moves into wellbeing drain and the breath),
  refunds, and the hoarding question.
- **Verified activity** (ADR-0004) makes calm grow 1.5× faster instead of
  earning 1.5× currency. Honor timers remain for people who like them.

What each amended ADR keeps and loses:

| ADR | Keeps | Changes |
|---|---|---|
| 0004 | Trust first; verification levels | Verification boosts calm, not currency |
| 0008 | Hybrid delivery; soft gate and shield | The "cost" step is care, and past the daily threshold a breath, not a price |
| 0012 | Emergency pass; skip-first; seeds / çekirdek naming; vitality freezing on blind days | Decision 3's "skips never earn currency" becomes "skips earn a capped few seeds of world material"; refunds go away with prices. Decision 5's first neighbor at 100 skips is replaced by residents arriving with island stages (ADR-0016). |
| 0014 | The accrual, the 72-hour window, held seeds | Quiet seeds buy station levels, not unlock windows |

## Consequences

- The most emotional moment is about Pofu and calm, never a price. The
  breath gives a real, bounded hard limit that spends attention instead
  of currency.
- **We lose a tested mechanism and must build new ones.** `Wallet`
  purchases, `Gatekeeper` pricing, refunds and their tests are retired
  when this is implemented; `CareLedger`, `CalmAccrual`, `BreathRules`,
  `StationLedger` and a `SeedsNeverBuyTimeTests` suite replace them.
  `docs/product/economy.md` keeps v0 as history with "superseded" notes
  until then.
- **Skip gifts reintroduce a small incentive to trigger the gate.** Capped
  at 15 seeds a day (1–2 % of week-1 income in the simulation), they are a
  thank-you, not a reason. Watch skips per day for gaming.
- **Quick checks are unverifiable by design.** Defined by pass length, not
  intent, halving rather than exempting, and capped by the chain rule and
  the breath.
- **The breath's effect is an assumption** (20 % of over-limit opens
  abandoned in the simulation). The founder's own on-device week is the
  first real test.
- Pre-membership, the daily threshold counts granted minutes and so errs
  toward care; with DeviceActivity it becomes measured.

## Amendment (2026-11-01): breathing break v2

Founder decision, the same day: the break is **user-initiated and
short**. Past the threshold, the break screen shows Pofu and a single
button, "Breathe with Pofu" (TR "Pofu'yla nefes al"); the breath starts
only when the user taps it, so the pause is owned, not imposed. It lasts
**5 seconds** (one breath, in 2 s, out 3 s) for the 1st to 3rd over-limit
open of the day and **10 seconds** (one deep breath, in 4 s, out 6 s)
from the 4th on, **never more than 10 seconds**. After it: "I'm good,
skip it" (primary, a skip) or "Open". "Not now" stays available before and
during the breath and counts as a skip; there is still no way to open
without breathing. This replaces the 10 / 20 / 30 s ladder above. The
simulation keeps its 20 % assumption for over-limit opens that end
without opening; the heavy scroller's week-1 breathing time falls from
about 7.7 minutes to about 2.7 minutes a day
([game-design.md](../product/game-design.md), section 5).
