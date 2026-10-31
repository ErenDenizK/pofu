# 0004. Trust-first activity verification

- **Status:** Accepted
- **Date:** 2026-10-31

## Context

Earning energy through real-life activities is the positive half of the core
loop. Unrot relies purely on self-reported timers, which makes cheating
trivial. Pushscroll relies purely on camera-counted exercise, which is proven
and well liked (13.6K ratings at 4.7★) but narrows earning to workouts and
demands phone placement every time.

Verification has costs: permissions, friction, and the feeling of being
policed, which contradicts the product principle "care over control". On the
other hand, the person most likely to cheat is the user's own impulse at
11 p.m.; some verification protects users from themselves.

## Options considered

1. **Honor only.** Zero friction, no integrity.
2. **Verification required.** High integrity, high friction, and many
   real-life activities (study, chores, music) cannot be verified at all.
3. **Trust first, verification as a bonus.** Every activity earns a base rate
   on self-report. Verified activities earn a multiplier.

## Decision

Option 3. Verification sources, in order of preference:

1. **Passive (zero friction):** HealthKit steps, workouts, mindful minutes.
   Earned automatically, with no user action beyond the initial permission.
2. **Structural:** a focus session verifies itself. During the session, the
   distracting apps are shielded; completing it without breaking out is the
   proof.
3. **Active (optional):** camera-counted reps through on-device Vision body
   pose detection. Frames are processed in memory and never stored or
   transmitted. This is offered as a fun mode with a strong bonus, never as a
   requirement.
4. **Honor:** timer-based self-report for everything else, at the base rate.

Self-reported earnings are subject to daily soft caps that verified earnings
are not. The exact rates and caps are tuned in `RotCore` with simulation tests.

## Consequences

- Nobody is ever blocked from earning by the absence of a sensor.
- Honest users and verified users both feel rewarded; cheating is possible but
  bounded and unrewarding.
- HealthKit and camera permissions are requested contextually, at the moment
  of first use, never during onboarding.
