# 0012. UX v1 decisions

- **Status:** Accepted
- **Date:** 2026-11-01
- **Amended by:** [0015](0015-care-over-currency.md) (decision 3: seeds no longer buy passes, skips earn a few capped seeds, refunds go away; decisions 1 and 5 are amended by [0016](0016-pre-planned-idle-archipelago.md))

## Context

The UX work ([information architecture](../product/ux/information-architecture.md),
[user flows](../product/ux/user-flows.md), and the clickable prototype)
raised open questions. The founder delegated product decisions to the
agent, except for radical direction changes. None of these is radical; they
refine choices already made in the vision and ADR-0004, ADR-0005, and
ADR-0008.

## Decisions

1. **Single home, no tab bar.** Home is Pofu's room; everything else opens
   as a sheet or a full-screen flow. The product's job is short visits, and
   the most important screen ("Hop!") arrives from iOS, not from navigation.
2. **No paywall in onboarding.** Plus is first offered after the first weekly
   recap, and contextually when the user reaches for a Plus item. This
   overrides the soft-paywall-at-onboarding suggestion in
   [monetization research](../research/monetization.md). Trust comes first in
   a wellbeing product, growth comes from friends, and the core is free
   forever.
3. **Economy additions** (specified in [economy.md](../product/economy.md)):
   - A free **emergency pass** (3 minutes, once per day), so that nobody
     has to delete the automation to escape.
   - **Refund** of unused whole minutes when a pass is ended early.
   - **Vitality freezes** on days Pofu cannot observe usage, so that
     disabling Pofu never makes it look healthier.
   - **Skips never earn currency.** Resisting is rewarded through vitality
     and the day's beads, which removes any incentive to open apps just to
     skip them.
4. **"Skip it" is the primary button on every rung.** This serves the user's
   own stated goal. Opening always stays visible and reachable, with no trick
   timers and no guilt copy.
5. **Naming:** the currency is **seeds / çekirdek** (the domain type stays
   `Energy`). Other species are **neighbors / komşular**, so "friends"
   always means real people. The first neighbor unlocks for free at 100
   skips, as a proposal to confirm with monetization.
6. **One Shortcuts automation per app.** `CheckInIntent` takes the target
   app as a parameter, because Shortcuts does not reliably report which app
   triggered a multi-app automation. The intent uses `supportedModes`
   `[.background, .foreground(.dynamic)]`, so passes are honored silently
   in the background.

## Consequences

- Setup takes one automation per chosen app (three for the founder). The
  guided setup must make this quick and verifiable.
- Monetization revenue starts later in the user lifecycle; we accept this
  in exchange for trust and word of mouth.
- PofuCore gains the emergency pass, refunds, and the observing flag, each
  with tests.
