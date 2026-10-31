# The Energy Economy (v0)

_Status: v0, implemented in `PofuCore`. Every number on this page is a
default in `EconomyConfiguration` and can be tuned without code changes._

The economy exists to serve one moment, the reflexive reach for a feed
([vision](vision.md)). Its job is to make resisting feel good, make giving
in cost something real but never shameful, and make it impossible to buy
an evening of scrolling with a morning of fake activity.

## Design goals

1. **Never stuck.** A user with zero energy can still get through the
   day: a daily allowance, free friction rungs, and a friend.
2. **Living pays for scrolling, not the other way round.** An honest hour
   of activity buys half an hour of feed at the base price, a verified
   hour buys 45 minutes, and repeated or late-night unlocks cost
   progressively more.
3. **Trust first, reward proof** (ADR-0004). Self-reported activity
   always earns; verified activity earns 1.5×. Only self-reports are
   capped.
4. **Bounded cheating.** The worst a cheater can do is bounded per day
   and gets more expensive to spend.
5. **Deterministic and testable.** Integer energy, explicit rounding, no
   hidden clock. Same inputs, same outputs, on every platform.

## Currency

`Energy` is a whole number. The domain name is final; the user-facing name
is not. Fractions never exist: **earning rounds down, prices round up**,
each exactly once per operation. To keep tuning readable, multipliers are
decimals (`1.25`), and rounding tolerates floating-point noise of up to
10⁻⁹, so `10 × 1.1` costs 11, not 12.

## Daily allowance

| Rule | Default |
|---|---|
| Granted at the first interaction of each local day | 15 energy |

- A local day starts at midnight in the user's time zone.
- The balance carries over between days; there is no balance cap in v0.
- Days the user was away are **not** back-filled: the allowance is a floor
  so nobody is stuck, not income that accrues while the app is unused.
- A clock that moves backwards never grants twice.

## Earning

| Rule | Default |
|---|---|
| Base rate | 1 energy per 2 whole minutes (`energyPerMinute = 0.5`) |
| Verified multiplier (passive, structural, active) | 1.5× |
| Honor (self-reported) soft cap | 120 energy per local day |
| Steps (passive) | 1 energy per 500 steps |

Activity kinds: `focus`, `study`, `exercise`, `walk`, `chores`, `creative`,
`custom`. The kind does not change the rate in v0; it is recorded for
reflection and future tuning.

Verification levels (ADR-0004): `honor` (timer, self-report), `passive`
(observed, e.g. HealthKit workouts), `structural` (proves itself, e.g. a
shielded focus session), `active` (e.g. camera-counted reps).

```
gross = ⌊ wholeMinutes × energyPerMinute × (verified ? 1.5 : 1) ⌋
```

- Only whole minutes count, and each session is rounded on its own. This is
  intentional: splitting an hour into sixty one-minute sessions earns
  nothing, so there is no incentive to game the timer.
- A session is credited to the local day it **ended** on.
- **Honor cap.** Honor earnings past 120 on a day are forfeited and
  reported in the result (`forfeitedToCap`) so the app can say so kindly
  instead of failing silently. Verified earnings are never capped and do
  not use up the honor allowance.
- **Steps** arrive as cumulative daily totals from health data. Only
  energy not yet credited for that day is granted, so the same total can be
  reported any number of times; a total that shrinks never takes energy
  back. Steps are passive by nature: they use their own rate, without the
  verified multiplier, and are not capped.
- Per-day history is kept for 7 days. Sessions and step totals for older
  days are not credited.

Worked examples: a 25-minute honor study session earns ⌊12.5⌋ = 12. The
same session as a structural focus session earns ⌊18.75⌋ = 18. Four hours
of honor activity earn 120; a fifth hour earns nothing and reports 30
forfeited. 8,000 steps earn 16.

## Spending

Energy buys **unlock windows** of 5, 10, 15, or 30 minutes.

| Rule | Default |
|---|---|
| Base price | 1 energy per minute |
| Escalation | × 1.25 per earlier paid unlock in the last 3 hours, compounding |
| Night multiplier | × 2 inside bedtime, 23:00–06:00 local time |

```
price = ⌈ minutes × pricePerMinute × 1.25^k × (night ? 2 : 1) ⌉
```

`k` is the number of paid unlocks in the rolling window `(now − 3 h, now]`.
Escalation decays one unlock at a time as each purchase leaves the window,
and carries across midnight. Rounding up happens once, after all
multipliers.

| Window | 1st | 2nd (k = 1) | 3rd (k = 2) | At night, k = 0 | At night, k = 1 |
|---|---|---|---|---|---|
| 5 min | 5 | 7 | 8 | 10 | 13 |
| 10 min | 10 | 13 | 16 | 20 | 25 |
| 15 min | 15 | 19 | 24 | 30 | 38 |
| 30 min | 30 | 38 | 47 | 60 | 75 |

The bedtime window is half-open: 23:00 is night, 06:00 is not. A window
whose end is before its start crosses midnight; a window whose start
equals its end is switched off. Bedtime is evaluated in local wall-clock
time, so it follows DST changes naturally.

A purchase fails without charging if the duration is not on offer or the
balance cannot cover the price. The balance therefore never goes negative.

## The friction ladder

Every open of a protected app goes through the soft gate (ADR-0008).

```
pause → intent → pay → askFriend
```

| Rung | The user may |
|---|---|
| `pause` | breathe, then continue for free (5-minute pass) or pay |
| `intent` | say why, then continue for free (5-minute pass) or pay |
| `pay` | buy an unlock window |
| `askFriend` | ask a friend to approve a window (ADR-0005) |

- An attempt less than 60 minutes after the previous attempt climbs one
  rung; a gap of 60 minutes or more resets to `pause`. The cooldown counts
  from the last attempt, not the first.
- Repeated attempts alone climb no higher than `pay`
  (`highestAttemptRung`). `askFriend` is required when paying is due and
  the balance cannot cover the cheapest window. Setting
  `highestAttemptRung = askFriend` makes the fourth rapid attempt require a
  friend even when the user can pay.
- Resisting is always available.
- Opening an app while a valid pass covers it is not an attempt: the gate
  lets it through silently and the ladder does not move.
- The ladder is shared across all protected apps: the reflex is the same
  whether it reaches for Instagram or TikTok.
- If the clock moves backwards, the attempt counts as inside the cooldown,
  erring toward more friction.

Outcomes are `resisted`, `proceeded(pass)`, or `friendApproved(pass)`. An
intervention the user leaves without choosing is recorded as `resisted`:
the app did not open.

## Passes

A pass grants one target group (for example "Instagram") access from
`grantedAt` (inclusive) to `expiresAt` (exclusive). Sources: a free rung,
a purchase, or a friend's approval. `PassLedger` answers "is there a valid
pass for X at time T", preferring the longest-lasting one.

## Impulse metrics

The north-star metric is **impulses resisted**. Per local day (attributed
to the day the attempt started), `ImpulseMetrics` counts `attempts`,
`resisted`, `proceeded`, and `friendApproved`, and reports
`resistedRatio = resisted / attempts`, which is `nil` on a day without
attempts: no impulses is not the same as zero percent resisted.

## Companion vitality

Vitality, in 0…1, drives Pofu's look (`docs/brand/character.md`). Each day
gets a score from three components, each in 0…1:

| Component | Formula | Default anchors |
|---|---|---|
| Usage `U` | `clamp(1 − (minutes ÷ budget) ÷ 2)` | 1 at no use, 0.5 at the 60-minute budget, 0 at 120 minutes |
| Resistance `R` | `resisted ÷ attempts`, or 1 without attempts | no reflex at all is the best case |
| Activity `A` | `energy ÷ (energy + 30)` | 0.5 at 30 energy (an honest hour), diminishing returns |

```
S(d) = 0.5·U + 0.25·R + 0.25·A          (weights normalized to sum to 1)
V(d) = V(d−1) + 0.3 · (S(d) − V(d−1))   (exponential moving average)
V(0) = 0.6
```

- Because every term is in 0…1, `S` and `V` are too; inputs and
  configuration are clamped so that even a broken configuration cannot
  escape the range.
- With α = 0.3, one day moves vitality by at most 0.3. A thriving Pofu
  survives one terrible evening as "content", and a week of better habits
  visibly revives a wilting one.
- During the day, the live value is the EMA of yesterday's settled
  vitality and today's running score.
- Activity energy includes honor, verified, and step energy, but not the
  allowance.

Mood bands: `thriving` ≥ 0.75, `content` ≥ 0.5, `tired` ≥ 0.25,
`wilting` below.

## Invariants (enforced by tests)

- The balance is never negative.
- Energy is conserved: balance = allowances + earnings − spending.
- Honor earnings never exceed the daily cap.
- Vitality and every component score stay in 0…1.
- Each day's attempts equal resisted plus opened.
- The ladder never skips a rung.

`SimulationTests` runs multi-week synthetic users (a resister, a scroller,
an honor-time farmer) through the whole domain and checks these after
every event, and checks that resisting keeps Pofu clearly healthier than
scrolling.

## Open questions for tuning

- **Hoarding.** There is no balance cap. A user can bank a quiet week and
  spend it in one evening, though escalation and night pricing blunt it.
  Consider a soft cap or decay if simulations or real use show binges.
- **Per-level multipliers.** Active verification (camera reps) may deserve
  more than 1.5×.
- **Kind-specific rates.** Exercise may deserve more per minute than
  chores.
- **Friend approvals and escalation.** Friend-approved windows are free and
  do not escalate prices; if friends approve too readily, they could.
- **Distracting minutes** are approximated today from granted pass length;
  real usage will come from the Screen Time report extension.
