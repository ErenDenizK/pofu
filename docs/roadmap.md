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
- [ ] Name and character direction chosen (see [naming](brand/naming-exploration.md))
- [ ] Character concept sheet (AI-assisted concepts, then code-native prototype)
- [ ] Design language: color, typography, motion, haptics, and sound principles
- [ ] Xcode project, local packages, CI on GitHub Actions (macOS runner)

## Phase 1: The companion lives (pre-membership, free account)

Goal: an app on the founder's iPhone where the companion is alive and
delightful, running on the simulated Screen Time service (ADR-0003).

- Companion rig v1: idle, thriving, tired, wilting, sleeping, celebrating
- Home scene with world state driven by `RotCore`
- Economy engine in `RotCore` with simulation tests (earn rates, prices,
  inflation control, daily caps)
- Activities: focus timer, breathing, honor-based activities
- Streaks and first milestones
- Onboarding (without the real Screen Time permission step)

## Day 1 of the paid membership

A checklist, not a phase. These steps have long lead times.

1. Enroll in the Apple Developer Program as an individual.
2. Finalize bundle identifiers for the app and every extension.
3. Request the **Family Controls (Distribution)** entitlement for **each**
   bundle identifier.
4. Enable App Groups, Family Controls (Development), HealthKit, and Associated
   Domains.

## Phase 2: The shield (paid membership)

Goal: the founder uses the app for real, every day.

- `LiveScreenTimeService`: authorization, app selection, schedules, presets
- Shield configuration and action extensions with the full friction ladder
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
| Final name and character direction | Founder | Start of Phase 1 |
| Repository visibility (public or private) once real product code lands | Founder | Start of Phase 1 |
| Weekly time budget for testing and feedback | Founder | Phase 1 |
| Monetization model details and prices | Agent proposes, founder decides | Phase 6 |
