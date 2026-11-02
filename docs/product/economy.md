# The Energy Economy (v0)

> **Status update, 2026-11-01: largely superseded by [ADR-0015](../adr/0015-care-over-currency.md), "Care over
> currency: seeds as world material".** Seeds no longer buy screen time.
> They are world material: gathered while the phone is down (quiet time,
> the stations' idle production) and a little per skip, and spent only on
> station levels and islands ([game-design.md](game-design.md)). Opening a guarded app costs calm and
> Pofu's wellbeing; past a daily threshold (60 guarded minutes) every open
> offers a short breathing break (5 s, at most 10 s, started by the user). This page is kept as the
> record of economy v0, which the app still runs; sections that
> no longer apply carry a "Superseded" note and are otherwise unchanged.
> **The v2 game model is implemented in `PofuCore/Game`** (W3, 2026-11-02)
> but not yet wired into the app: see [the last section](#the-game-model-v2-pofucoregame)
> and [game design §13](game-design.md#13-mapping-to-pofucore).

_Status: v0, implemented in `PofuCore`. Every number on this page is a
default in `EconomyConfiguration` and can be tuned without code changes._

The economy exists to serve one moment, the reflexive reach for a feed
([vision](vision.md)). Its job is to make resisting feel good, make giving
in cost something real but never shameful, and make it impossible to buy
an evening of scrolling with a morning of fake activity.

## Design goals

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). Goals 1 and 2 (living pays for scrolling) no longer hold: nothing pays for scrolling. Never stuck still holds through free rungs, a friend, and the emergency pass. Goals 3–5 carry over to seeds as world material.

1. **Never stuck.** A user with zero energy can still get through the
   day: a daily allowance, free friction rungs, a friend, and one free
   emergency pass a day. Nobody should have to delete Pofu's automation
   to get into an app they truly need.
2. **Living pays for scrolling, not the other way round.** An honest hour
   of activity buys half an hour of feed at the base price, a verified
   hour buys 45 minutes, and repeated or late-night unlocks cost
   progressively more.
3. **Trust first, reward proof** (ADR-0004). Self-reported activity
   always earns; verified activity earns 1.5×. Only self-reports are
   capped. Staying away earns by itself (quiet time, ADR-0014).
4. **Bounded cheating.** The worst a cheater can do is bounded per day
   and gets more expensive to spend.
5. **Deterministic and testable.** Integer energy, explicit rounding, no
   hidden clock. Same inputs, same outputs, on every platform.

## Currency

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). `Energy` stays the domain type and the user still sees **seeds / çekirdek**, but seeds are world material: they never convert into minutes.

`Energy` is a whole number. The domain name is final; the user sees
**seeds** (Turkish: **çekirdek**), stored in Pofu's cheeks. At the base
price one seed buys one minute. Fractions never exist: **earning rounds down, prices round up**,
each exactly once per operation. To keep tuning readable, multipliers are
decimals (`1.25`), and rounding tolerates floating-point noise of up to
10⁻⁹, so `10 × 1.1` costs 11, not 12.

## Daily allowance

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). There is no allowance: nobody needs seeds to open an app.

| Rule | Default |
|---|---|
| Granted at the first interaction of each local day | 15 energy |

- A local day starts at midnight in the user's time zone.
- The balance carries over between days; there is no balance cap in v0.
- Days the user was away are **not** back-filled: the allowance is a floor
  so nobody is stuck, not income that accrues while the app is unused.
- A clock that moves backwards never grants twice.

## Earning

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). Activity no longer earns seeds. A verified focus session makes the calm multiplier grow 1.5× faster; honor timers stay for reflection. Seeds come from quiet time, the stations, and skips (+3, at most 5 a day).

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

## Quiet time

> **Amended by [ADR-0015](../adr/0015-care-over-currency.md).** The accrual rules below are unchanged and become **Pofu's quiet gathering**; the seeds they produce buy station levels, not unlock windows. The stations' idle production follows the same quiet stretch (they work only while no pass is running).

Staying away from the guarded apps earns seeds by itself (ADR-0014). The
user may have gone to the gym without telling Pofu; the absence is the
proof. `QuietTimeAccrual` implements this section; every number is in
`QuietTimeRules`.

| Rule | Default |
|---|---|
| Rate | 1 seed per whole 10 continuous quiet minutes (`blockMinutes`, `seedsPerBlock`) |
| Daily cap | 48 quiet seeds per local day (`dailyCap`), separate from the honor cap |
| Excluded | the bedtime window, 23:00–06:00 (the same window as night pricing) |
| Slept-on-it bonus | +10 for a whole bedtime window without an open (`sleepBonus`), not counted toward the cap |
| Observation window | 72 hours after each sign of life from the automation (`observationWindow`) |

**The quiet stretch.** Quiet is time with no pass running.

- A pass starting (any opened outcome: a free rung, a purchase, a friend's
  approval, the emergency pass) **breaks** the stretch. The stretch up to
  that moment is credited; the partial block in progress is lost.
- Quiet **resumes at the next sign of life after the pass**, not at its
  expiry (decision audit C1, 2026-11-01). Before Screen Time, nothing
  closes the guarded app when a pass expires, and the "App is opened"
  automation does not fire while the user stays in it. The time from the
  expiry to the next sign of life is **unobserved** and never counts. A
  sign of life is a check-in or another automation run, Pofu coming to the
  foreground (or staying on screen past the expiry), or a tap on the
  pass-expiry reminder; the new stretch starts at that moment.
- Ending a pass early in Pofu resumes quiet **at once**, unless another
  pass is still running; then quiet waits for a sign of life after that
  one. A voided pass (the app never opened) gives quiet back from the
  moment of the grant.
- A **resisted attempt does not break quiet**: resisting is the point.
- Pass-throughs, like every sign of life while a pass runs, keep Pofu
  observing but resume nothing; the pass already broke the stretch.

**The pass-expiry reminder.** At grant time Pofu schedules one local
notification for the pass's expiry ("Time's up. Back to me?"). Tapping it
opens Pofu, which is a sign of life. Ending a pass early withdraws it.
Permission is asked at the first pass; if it is denied, the rules above
still hold, there is just no nudge.

**What counts.** A minute counts when it is quiet, outside bedtime, and
observed. Counting minutes form segments; each segment earns
⌊length ÷ 10 min⌋ blocks, aligned to its own start. So bedtime, a pass, or a
lapse in observation each start the block count afresh.

- **Midnight** does not split a segment: continuity is about the person, not
  the calendar. Each block is credited to the local day it **started** on,
  and that day's cap applies. With the default bedtime, blocks never cross
  midnight.
- **The cap.** Blocks past 48 on a day earn nothing; the accrual reports
  them as `forfeitedToCap`.

**Slept on it.** When a whole bedtime window passes with no pass running at
any point in it and Pofu observing all of it, +10 goes into the cheeks the
first time quiet time is computed after the window ends (the first
foreground, or an earlier check-in). A pass that started before bedtime and
runs into it forfeits that night's bonus. Each night is rewarded once,
attributed to the local day the window ends on. A bedtime window that
crosses midnight is one night; a switched-off window has no nights.

**Observation and held seeds.** Pofu cannot yet see usage without the
automation (DeviceActivity needs the paid membership), and a deleted
automation looks exactly like perfect discipline. So:

- Every **sign of life from the automation** (a check-in, a pass-through,
  or any automation run) keeps Pofu observing for the next 72 hours.
  Nothing counts before the first one. Opening Pofu or tapping the expiry
  reminder restarts a quiet stretch after a pass but does **not** extend
  observation or release held seeds: it says nothing about whether the
  automation still guards the apps.
- After 72 hours of silence, **accrual stops**. Seeds already in the cheeks
  are **held, not lost**: they cannot be collected, and Home asks the user
  to check the setup (the setup guide's test).
- The next sign of life **releases** the held seeds and starts a new
  observation. The silent time in between never counts.
- The worst case for someone who deletes the automation and scrolls is
  three days of quiet seeds, about 174, and only after re-enabling it. They
  already bypass Pofu entirely, so this buys them nothing new.

**Collecting.** Accrual is computed on launch, on foreground, every 30
seconds while Home is open, and at every check-in. It is prefix-consistent:
computing it in many small steps credits exactly what one computation over
the same span does. Seeds wait in Pofu's cheeks until the user collects
them on Home; collecting adds them to the balance. Quiet seeds are
structural (ADR-0004), so the honor cap does not apply, but they do not
feed vitality's activity score: quiet time is already rewarded through the
usage and resistance components, and counting it twice would let a blind
day look healthy.

Worked examples:

- A check-in at 12:00 that the user resists, nothing else until 14:00:
  120 quiet minutes, **12 seeds**. "You stayed away for 2 hours. I saved 12
  seeds in my cheeks."
- Quiet from 12:00, an open at 12:25 with a 5-minute free pass that
  expires at 12:30, nothing heard until a skip at 12:40, quiet again until
  13:10: two blocks before the open and three from 12:40, **5 seeds**.
  12:30–12:40 is unobserved: the user may still have been in the app.
- A 5-minute free pass at 12:00 and no sign of life until 13:00: **0
  seeds** for that hour, however quiet it really was. Opening Pofu at 13:00
  starts the count again.
- A paid 15-minute pass at 12:00 ended early at 12:03: quiet resumes at
  12:03, and 12:33 completes **3 seeds**.
- Last check-in at 21:00, quiet until 08:00 the next morning: 21:00–23:00
  and 06:00–08:00 are **24 seeds**, plus **10** for the night.
- An open at 02:00 in the middle of the night: no bonus that night, and
  nothing counts until the next sign of life after the pass, at 06:00 at
  the earliest.
- With bedtime switched off, a whole quiet day is 144 blocks: **48 seeds**,
  96 forfeited to the cap. A stretch from 23:55 to 00:25 credits one seed to
  the first day and two to the next.
- Last check-in Monday at noon, Pofu opened Friday: Monday noon to Thursday
  noon counted (capped per day) and the seeds are held; the next check-in
  releases them, and Thursday noon until then never counts.

## Spending

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). Seeds no longer buy unlock windows; prices, escalation and night pricing leave the gate. Their intent moves into Pofu's wellbeing drain (×1.25 per recent open, ×2 at night) and the breathing break.

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

> **Amended by [ADR-0015](../adr/0015-care-over-currency.md).** The ladder becomes pause → intent → **care** → askFriend. The care rung shows the cost in calm and wellbeing and offers a quick check (≤ 3 min, halves the calm bonus) or a full open (resets it); past 60 guarded minutes a day, either one first waits for a breathing break. Skips still never earn currency, but now earn a few seeds of world material (+3, at most 5 a day).

Every open of a protected app goes through the soft gate (ADR-0008).

```
pause → intent → pay → askFriend
```

| Rung | The user may |
|---|---|
| `pause` | breathe, then continue for free (5-minute pass) or pay |
| `intent` | say why, then continue for free (5-minute pass) or pay |
| `pay` | buy an unlock window, or use the daily emergency pass |
| `askFriend` | ask a friend to approve a window (ADR-0005), or use the daily emergency pass |

- An attempt less than 60 minutes after the previous attempt climbs one
  rung; a gap of 60 minutes or more resets to `pause`. The cooldown counts
  from the last attempt, not the first.
- Repeated attempts alone climb no higher than `pay`
  (`highestAttemptRung`). `askFriend` is required when paying is due and
  the balance cannot cover the cheapest window. Setting
  `highestAttemptRung = askFriend` makes the fourth rapid attempt require a
  friend even when the user can pay.
- Resisting is always available, and **resisting never earns energy**.
  Paying for skips would turn the gate into a slot machine (open, skip,
  collect). Skips feed Pofu's vitality through the resistance component and
  fill a bead on Home, which the user sees as fluff, not a number.
  `Gatekeeper.resolve(_:with: .resist, …)` never touches the wallet, and
  `SkipsNeverEarnTests` holds it to that on every rung.
- Opening an app while a valid pass covers it is not an attempt: the gate
  lets it through silently and the ladder does not move.
- The ladder is shared across all protected apps: the reflex is the same
  whether it reaches for Instagram or TikTok.
- If the clock moves backwards, the attempt counts as inside the cooldown,
  erring toward more friction.

Outcomes are `resisted`, `proceeded(pass)`, or `friendApproved(pass)`. An
intervention the user leaves without choosing is recorded as `resisted`:
the app did not open. On the `intent` rung, the reason the user gives
(`IntentReason`: reply, look something up, post, bored, habit, need a
break) is recorded with the outcome, whatever it is.

### The emergency pass

| Rule | Default |
|---|---|
| Length | 3 minutes (`emergencyPassMinutes`; 0 switches it off) |
| Frequency | once per local day |
| Rungs | `pay` and `askFriend` only |
| Price | free; it does not count toward escalation |

The soft gate can always be bypassed by deleting the automation, and many
people who do that never come back. A free, logged, short pass once a day
keeps an honest way through when someone has no seeds and no friend at
hand. It is short enough that it is not a scrolling session, and it is
recorded as `proceeded` with a pass whose source is `emergency`, so it
counts as an open in the impulse metrics. Availability resets at local
midnight; a clock that moves backwards never grants a second one.

## Passes

A pass grants one target group (for example "Instagram") access from
`grantedAt` (inclusive) to `expiresAt` (exclusive). Sources: a free rung,
a purchase, a friend's approval, or the emergency pass. `PassLedger`
answers "is there a valid pass for X at time T", preferring the
longest-lasting one. Opening an app under a valid pass is recorded as a
**pass-through** (not an attempt), which also proves that app's automation
is alive.

### Ending a pass early

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). Refunds go away with prices. Ending a pass early still restores protection at once and resumes quiet time.

The user can end a pass from Pofu at any time. Protection comes back at
once, and the unused whole minutes are refunded **at the per-minute price
actually paid**:

```
refund = ⌊ unusedWholeMinutes × price ÷ minutes ⌋
```

- Only purchased passes refund. Free, friend-approved, and emergency
  passes simply end.
- The price paid already includes escalation and night pricing, so the
  refund never exceeds what was paid and shrinks as the pass is used.
- The purchase still counts toward escalation: stopping early is rewarded,
  but it does not reset prices.
- Refunds are not activity: they do not feed vitality or the honor cap.

Worked examples: a 10-minute pass bought for 10 and ended after 3.5
minutes refunds ⌊6 × 10 ÷ 10⌋ = 6. The same window bought second in the
escalation window (13) and ended after one second refunds ⌊9 × 13 ÷ 10⌋ =
11. A night pass (20 for 10 minutes) ended halfway refunds 10.

If Pofu cannot open the app after granting a pass (the app was deleted),
the pass is **voided**: the full price comes back and the purchase stops
escalating prices; a voided emergency pass becomes available again.

## Impulse metrics

The north-star metric is **impulses resisted**. Per local day (attributed
to the day the attempt started), `ImpulseMetrics` counts `attempts`,
`resisted`, `proceeded`, and `friendApproved`, and reports
`resistedRatio = resisted / attempts`, which is `nil` on a day without
attempts: no impulses is not the same as zero percent resisted.

## Companion vitality

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). Vitality becomes Pofu's **wellbeing**, a continuous 5–100 meter with a floor and "sleeps it off" ([ADR-0017](../adr/0017-pofu-never-dies.md), [game-design.md](game-design.md)). Blind time still freezes it.

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

### Blind days freeze vitality

Pofu must never look healthier because it cannot see. Without check-ins,
resistance has no attempts (it scores 1) and usage is estimated from
passes (none), so a user who deleted the automation would watch Pofu
thrive. Every day therefore carries an `isObserving` flag; when it is
false, vitality **carries forward unchanged**:

```
V(d) = V(d−1)                     when day d is not observed
```

Until DeviceActivity can show usage without check-ins (paid membership),
a day counts as observed when the automation reported anything that day: a
check-in or a pass-through. A day without a single reach cannot be told
apart from a deleted automation, so it freezes instead of rewarding
blindness.

`VitalityLedger` settles each finished day once, in order, the first time
the app runs after it ends (at most 400 days are walked; older absences are
unobserved anyway), and keeps 35 days of history. Today is never settled:
the live value is today's running input applied to the settled value.

Mood bands: `thriving` ≥ 0.75, `content` ≥ 0.5, `tired` ≥ 0.25,
`wilting` below.

## Invariants (enforced by tests)

> **Amended by [ADR-0015](../adr/0015-care-over-currency.md).** Balance, refund and honor-cap invariants retire with prices. New: no gate outcome changes seeds except a capped skip gift; a breath is never longer than 10 s and starts only on the user's tap; calm stays in 1.0…2.0 and never resets without an open.

- The balance is never negative.
- Energy is conserved: balance = allowances + earnings − spending +
  refunds + collected quiet seeds.
- Resisting never changes the balance.
- A refund never exceeds the price paid.
- An unobserved day never changes vitality.
- Honor earnings never exceed the daily cap.
- Quiet seeds never exceed their daily cap, and held seeds cannot be
  collected.
- Vitality and every component score stay in 0…1.
- Each day's attempts equal resisted plus opened.
- The ladder never skips a rung.

`SimulationTests` runs multi-week synthetic users (a resister, a scroller,
an honor-time farmer) through the whole domain and checks these after
every event, and checks that resisting keeps Pofu clearly healthier than
scrolling. `QuietTimeSimulationTests` runs sixteen days of opens, resists,
passes, early endings, a silence longer than the observation window, and
collections under three bedtime settings, and checks quiet seeds and
bonuses against an independent minute-by-minute reference model.

## Open questions for tuning

> **Superseded by [ADR-0015](../adr/0015-care-over-currency.md)** (accepted 2026-11-01; `PofuCore` still implements v0 until the change lands). Hoarding, refunds and friend-escalation questions disappear with prices. The observation and DeviceActivity questions remain and are tracked in [game-design.md](game-design.md), section 6.

- **Hoarding.** There is no balance cap, and quiet time adds up to about
  58 effortless seeds a day. A user can bank a quiet week and
  spend it in one evening, though escalation and night pricing blunt it.
  Consider a soft cap or decay if simulations or real use show binges.
- **Per-level multipliers.** Active verification (camera reps) may deserve
  more than 1.5×.
- **Kind-specific rates.** Exercise may deserve more per minute than
  chores.
- **Friend approvals and escalation.** Friend-approved windows are free and
  do not escalate prices; if friends approve too readily, they could.
- **Distracting minutes** are approximated today from granted pass length;
  real usage will come from the Screen Time report extension. Ending a
  pass early does not shorten the estimate yet.
- **Quiet-time tuning.** 1 seed per 10 minutes and a cap of 48 (8 quiet
  waking hours) are first guesses. Watch whether quiet seeds crowd out
  honor and verified earning, and whether 72 hours is the right window.
- **Observation.** "A day with no check-ins is blind" is a stopgap, and so
  is the 72-hour window for quiet time. Once
  DeviceActivity threshold events are available, a day is observed when
  usage is measured, whether or not the automation fired.

## Measured guarded minutes (Screen Time build)

With the live Screen Time gate (the `PofuLive` build,
[development.md](../development.md#membership-day-1-the-screen-time-build)),
guarded minutes are measured, not estimated. `GuardedUsageLadder` schedules
DeviceActivity events every **15** guarded minutes up to the **daily hour**
(60 by default, so 15, 30, 45, and 60; a 50-minute hour adds 50 as its
last step); the app keeps the highest step reached today
(`ScreenTimeLedger`), so it knows "at least 30 minutes" rather than a
pass-based guess. The last step is the breath limit of
[ADR-0015](../adr/0015-care-over-currency.md): past it, every open starts
with a breath (5 s, 10 s from the fourth over-limit open of the day). The
daily hour is a setting (15–180 minutes, `UserProfile.dailyHourMinutes`),
never a constant in code.

## The Screen Time gate (gate v2)

Every number is a default in `ScreenTimeGateRules`
(`EconomyConfiguration.gate`); see
[gate v2](ux/gate-v2.md), sections 5 and 12.

| Rule | Default |
|---|---|
| Daily hour (breath limit) | 60 guarded minutes; the user picks 15–180 |
| Measuring step | 15 minutes |
| Quick check from the shield | 3 minutes, a pass with no app round trip |
| Chain rule | No quick check within 20 minutes of the last one's end |
| "Open with Pofu" lifetime | 10 minutes |
| Silent leave | A shield with no tap and nothing else for 60 s |
| Same reach | The same app's shield within 10 s; a Hop! within 5 s of a shield for the same app |
| The returning shield speaks of the ended pass | 2 minutes |
| Breath | 5 s; 10 s from the 4th over-limit open of the day |
| Jealous lines on the shield | At most 3 a day, never two in a row |

**Every reach is counted once.** Each reach at the shield becomes exactly
one check-in with `channel: .shield` and a `ShieldResolution`, so it
counts in the day's metrics and vitality like a reach in Hop!; it climbs
no ladder and earns no seeds.

| What happened | Counts as | `ShieldResolution` |
|---|---|---|
| "Boş ver" on the shield | Resisted | `skipped` |
| Shield left without a tap | Resisted | `silentLeave` |
| "Pofu'yla aç", then no Hop! within the lifetime | Resisted | `abandonedRequest` |
| "Boş ver" while the shield waits for the notification tap | Resisted | `requestCancelled` |
| "3 dakika bakacağım" | Opened (a 3-minute pass) | `quickCheck` |
| "Pofu'yla aç", then Hop! | Counted by Hop! alone | none |
| The shield that returns when a pass ends, and its "Bitti, kapat" | Not a reach | none |
| The waiting shield after "Pofu'yla aç" | Not a new reach | none |

The developer readout shows each kind separately, with "resisted by tap"
(skips and cancellations only) next to the full count.

## The game model v2 (`PofuCore/Game`)

Implemented and tested; the app does not run it yet. Every number is a
default in `GameRules` (`CareRules`, `CalmRules`, `SeedRules`,
`BreathRules`, ADR-0014's `QuietTimeRules`, `ArchipelagoCatalog`); the
full rules are [game design §5](game-design.md#5-mechanics-and-numbers).

| Part | Type | What it holds |
|---|---|---|
| Wellbeing | `CareLedger` | 5–100 (start 70); −0.35 a minute in a guarded app (×2 at night, ×1.25 per earlier open in 3 h), −1.5 per open; +5 a calm waking hour, +1 a skip (6 a day), +10 a calm night; below 60, 30 % of the way back each night |
| Calm | `CalmAccrual` | ×1.0–×2.0 in integer tenths; +0.1 per 20 observed calm waking minutes; a quick check (≤ 3 min) halves the bonus, a second within 20 min of the last one's end resets it; any other open resets; +0.2 a calm night |
| Seeds | `StationLedger` | A pouch by source, collected into a jar, spent only on builds. Stations: designed ladders × calm × care (×0.6 below 25), only while away and observed, fractions carried. Pofu's gathering: 1 per 10 quiet waking minutes, 48 a day, +10 a calm night. Skips: +3, 5 a day |
| The breath | `BreathRules` | Past the daily hour: 5 s for the 1st–3rd over-limit open, 10 s from the 4th, never more than 10 s; the fourth rapid reach falls back to the 10 s breath; never for the emergency pass; "Not now" is a skip |
| The facade | `WorldClock`, `GameState` | A deterministic minute grid fed by `GameEvent`s (from the gate's event log); `advance`, `collect`, `build`, `breath`, `snapshot` |

**What counts as away.** A minute is away only when no pass runs, Pofu is
observing, and the user is not looking at Pofu past A20's 2-minute grace.
Under the soft gate, the time from a pass's expiry to the next sign of
life (a check-in, a skip, Pofu in the foreground, the expiry notification)
is **unobserved** and earns nothing; with Screen Time the shield ends each
pass, so the time after it is observed. Pre-membership, today's guarded
time for the breath is the granted pass minutes; with DeviceActivity, the
measured step when higher.
