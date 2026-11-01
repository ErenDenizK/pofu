# Roadmap

_Living document. Last updated: 2026-10-31._

Phases are sequenced by risk: the earliest phases remove the largest
unknowns. Each phase ends with something the founder can hold in their hand.

## Phase 0: Foundation (current)

Goal: every decision needed to start building is made and written down.

- [x] Competitive, platform, and monetization research
- [x] Product vision and principles
- [x] Initial ADRs (stack, architecture, verification, friend approval)
- [x] Contribution guidelines and repository templates
- [x] Name and character direction chosen: **Pofu** ([ADR-0007](adr/0007-product-name-pofu.md))
- [x] Character bible v0.1 ([character.md](brand/character.md))
- [x] Character direction explored (vector rig, 3D spike, AI illustration) and decided:
  illustrated hamster ([ADR-0010](adr/0010-illustrated-hamster-art-direction.md))
- [x] Companion motion system designed and built: web proof plus `PofuCompanion`
  ([ADR-0011](adr/0011-companion-motion-system.md))
- [ ] Companion motion validated on the founder's iPhone
- [ ] Art bible, prompt library, and asset pipeline; first production assets generated
- [ ] Design language: color, typography, motion, haptics, and sound principles
- [x] Information architecture, user flows, and a clickable prototype
  ([IA](product/ux/information-architecture.md), [flows](product/ux/user-flows.md))
- [x] Open UX questions decided ([ADR-0012](adr/0012-ux-v1-decisions.md))
- [x] Xcode project, local packages, CI on GitHub Actions (macOS runner)
  ([ADR-0009](adr/0009-xcodegen-and-package-layout.md),
  [development guide](development.md))

## Phase 1: The companion lives (pre-membership, free account)

Goal: an app on the founder's iPhone where the companion is alive and
delightful, running on the simulated Screen Time service (ADR-0003).

- [x] **Soft gate v1** ([ADR-0008](adr/0008-hybrid-intervention-delivery.md),
  [ADR-0012](adr/0012-ux-v1-decisions.md)): `CheckInIntent` with dynamic
  foregrounding, the Hop! ladder, passes with refunds and the emergency pass,
  hand-off to the target app, and a guided Shortcuts setup
- [x] Persistence (`PofuPersistence`): snapshot store and event log
- [x] Pofu's room v1: animated companion, seeds, today's beads, honor focus
  timer
- [x] Minimal onboarding: welcome, apps, name, setup
- [ ] **On-device validation by the founder** (foregrounding from the
  automation, silent pass-through, cold launch, URL schemes, Turkish
  Shortcuts labels)
- [ ] Production art from the prompt library, processed by the asset pipeline
- [ ] Daily recap and bedtime mode
- [ ] Streaks and first milestones
- [ ] Spike: iOS 27 one-tap automation import ([ADR-0013](adr/0013-zero-setup-default-gate.md))
- [ ] Practice Hop! in onboarding and the picture-in-picture setup guide

## Day 1 of the paid membership

A checklist, not a phase. These steps have long lead times.

1. Enroll in the Apple Developer Program as an individual.
2. Finalize bundle identifiers for the app and every extension.
3. Request the **Family Controls (Distribution)** entitlement for **each**
   bundle identifier.
4. Enable App Groups, Family Controls (Development), HealthKit, and Associated
   Domains.

## Phase 2: The shield (paid membership)

Goal: zero-setup onboarding (permission plus app picker,
[ADR-0013](adr/0013-zero-setup-default-gate.md)) and enforcement. Schedules and
budgets become real blocks.

- `LiveScreenTimeService`: authorization, app selection, schedules, presets
- Hard gate: shield configuration and action extensions, with Pofu's
  current mood pre-rendered into the shield
- Monitor extension: threshold ladder feeding companion health
- Report extension: screen time, pickups, top apps
- Spend flow: unlock windows bought with energy

## Phase 3: Earn for real

- HealthKit passive earning (steps, workouts, mindful minutes)
- Verified focus sessions
- Camera rep counting (on-device Vision), as a fun bonus mode

## Phase 4: The ecosystem

- Widgets (home and lock screen), Live Activity and Dynamic Island for focus
- Control Center control and App Intents / Shortcuts
- Themes and world variants unlocked by streaks

## Phase 5: Together

- Friend pairing and serverless approval (ADR-0005)
- Shared streaks and weekly leagues (CloudKit, new ADR)

## Phase 6: Launch

- TestFlight friends beta (requires the distribution entitlement)
- Monetization ADR and StoreKit 2 implementation
- App Store presence: icon, screenshots, preview video, TR and EN metadata
- Privacy policy, support page, and the domain for universal links
- Public release in Türkiye, then global

## Open questions

| Question | Owner | Needed by |
|---|---|---|
| Repository visibility before launch (founder is indifferent; public for now) | Agent proposes | Phase 6 |
| Monetization model details and prices | Agent proposes, founder decides | Phase 6 |
