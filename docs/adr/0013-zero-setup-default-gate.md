# 0013. Zero-setup default gate, live Pofu as an enhancement

- **Status:** Accepted
- **Date:** 2026-11-01
- **Amends:** [0008](0008-hybrid-intervention-delivery.md) (which layer is the default)

## Context

ADR-0008 made the Shortcuts-triggered soft gate the animated heart of the
product and the Screen Time shield the enforcement layer. The soft gate v1
(#14) requires one personal automation per app, created by hand with four
or more steps each. The founder flagged this as one of the most important UX
problems: a mainstream user will not set up three automations by hand.

Market evidence:

- **Brainrot, Opal, and Unrot** use only the Screen Time API. Setup is one
  system permission plus the app picker, two or three taps in total, and no
  Shortcuts.
- **one sec** uses Shortcuts for its animated intervention and Screen Time
  for blocks. Its help center reports that **from iOS 27, Apple allows apps to
  install automations for the user**: the user taps "Add to Shortcuts" and
  confirms in an import sheet. On iOS 26 and earlier the setup is manual.
  This is reported by one sec, not yet verified by us.
- Personal automations cannot be created programmatically through a public
  API on iOS 26 as far as we know.

## Decision

Onboarding is **zero-setup by default** and gets richer progressively.

1. **Default gate: Screen Time** (needs the paid membership and the Family
   Controls entitlement).
   - Onboarding asks for one system permission and shows the app picker.
     Nothing else.
   - The shield carries Pofu's pre-rendered mood and its line ("Hop!
     Nereye?").
   - The primary button resists, and the resist is counted in
     `ShieldAction`. The secondary button ("Talk to Pofu") posts a
     notification that opens the full animated Hop! ladder.
   - Every app the user picked is covered at once, and its identity is known
     from the token.
2. **Live Pofu: the Shortcuts soft gate as an opt-in enhancement.** It is
   offered after the user has seen value (around day 3, or from settings) as
   "Let Pofu jump in live".
   - **iOS 27+:** one tap per app through the system automation import flow
     (to be verified by a spike).
   - **iOS 26:** the guided manual setup from #14.
   - When an automation is active for an app, it takes over that app's
     intervention from the shield; the shield remains the safety net.
3. **Pre-membership (now):** the founder uses the Shortcuts soft gate alone,
   because Screen Time cannot run on a free account. This is a development
   stopgap and not the product's onboarding.

## Consequences

- Onboarding for launch is rewritten: permission and picker first, Live Pofu
  later. `docs/product/ux/user-flows.md` is updated when this is implemented.
- Phase 2 (Screen Time) becomes the path to launch onboarding, not only to
  enforcement.
- A spike verifies the iOS 27 automation import mechanism (how an app
  triggers it, whether one import can cover several apps, and the failure
  modes) and records the result.
- Copy and metrics distinguish "resisted at the shield" from "resisted in
  Hop!", so both paths feed the north-star metric.
