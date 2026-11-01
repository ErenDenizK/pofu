# 0014. Quiet-time earning

- **Status:** Accepted
- **Date:** 2026-11-01
- **Amended by:** [0015](0015-care-over-currency.md) (quiet seeds are world material and buy station levels, not unlock windows)
- **Amends:** [0004](0004-trust-first-activity-verification.md) (adds absence as a structural verification source)

## Context

Until now, seeds came from logging something: an honor timer, a verified
focus session, or steps. The founder pointed out the gap: someone who goes
to the gym, reads a book, or simply lives their evening without telling
Pofu earns nothing, although that is exactly the behavior Pofu exists for.
Logging also asks for attention at the moment we want the phone forgotten.

Pofu already sees the one thing that matters: every reach for a guarded app
passes through the soft gate (ADR-0008). A stretch without an opened app is
therefore observable, and the absence itself is the proof.

Two forces pull against each other:

- **Generosity.** Quiet time should feel like a gift that arrives by itself,
  and it should not punish someone for a quiet day.
- **Integrity.** Before DeviceActivity is available (paid membership), Pofu
  can only see what the Shortcuts automation reports. A deleted automation
  looks exactly like perfect discipline. ADR-0012 already freezes vitality
  on blind days for this reason.

## Options considered

1. **Keep earning activity-only.** Simple and safe, but it misses the
   founder's point and keeps logging as the only way to earn.
2. **Quiet time earns, observed by day.** Reuse the per-day `isObserving`
   flag of vitality: earn only on days with a check-in. This defeats the
   feature: a perfectly quiet day has no check-ins, so it would earn nothing.
3. **Quiet time earns, observed by a window after each sign of life.** Every
   check-in or pass-through proves the automation is alive for the next 72
   hours. Quiet time inside that window earns; past it, accrual stops and
   seeds already earned are held until the next sign of life.

## Decision

Option 3, with these rules (constants in `QuietTimeRules`, documented in
[economy.md](../product/economy.md#quiet-time)):

- **1 seed per 10 continuous quiet minutes** of waking time, in whole
  blocks, **capped at 48 seeds per local day**, separate from the honor cap.
- A quiet stretch is broken by an opened outcome (a pass starting) and
  resumes when the pass ends, early or on time. **A resisted attempt does
  not break it**; resisting is the point. Pass-throughs during a pass change
  nothing.
- **Bedtime does not count.** A whole bedtime window without an open earns a
  one-time **+10 "slept on it" bonus**, credited after the window ends.
- **Observation.** Quiet time counts only within **72 hours** of the last
  sign of life from the automation. Seeds already in the cheeks are **held,
  not lost**, once that window lapses: Home asks the user to check the
  setup, and the next check-in releases them. Silent time never counts.
- Quiet seeds are **structural** (ADR-0004): the stretch proves itself, so
  the honor cap does not apply. They do not take the 1.5× multiplier,
  because they have their own rate.
- Seeds accrue into Pofu's cheeks and the user **collects** them on Home.
  Collected quiet seeds do not feed vitality's activity score: quiet time is
  already rewarded there through the usage and resistance components.

This amends ADR-0004 by adding **absence** to the structural verification
sources: like a shielded focus session, an unbroken quiet stretch proves
itself.

## Consequences

- Earning no longer requires logging. Honor timers remain for people who
  like them, and for proof of effort the gate cannot see.
- **Bounded exploit.** Someone who deletes the automation and scrolls
  freely could collect at most 72 hours of quiet seeds (about 3 × 48 + 3 ×
  10 = 174) before accrual stops, and only after re-enabling the automation.
  Anyone who deletes the automation already bypasses Pofu entirely, so the
  seeds buy them nothing they did not already have. We accept this until
  DeviceActivity can measure real usage, at which point observation should
  come from measured usage instead of check-ins (see the open questions in
  economy.md).
- **Hoarding grows.** A quiet user can now bank up to about 58 seeds a day
  without effort. Escalation and night pricing still apply; watch real use
  for evening binges before adding decay or a balance cap.
- Users who used Pofu before this change start observed from their last
  check-in, quiet from the end of their last pass.
- `PofuState` gains a `quietTime` ledger, decoded tolerantly so older
  snapshots load.
