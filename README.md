# Pofu

> A character-driven iPhone app that stands between you and the reflexive
> scroll. Pofu, a small fluffball, gets fluffier when you live and wilts
> when you doomscroll.

**Status:** Phase 0, Foundation. Product research and architecture decisions
are in place; app development has not started yet.

## The idea in one loop

**Protect** distracting apps with schedules and a graduated friction ladder →
**Earn** energy through real-life activities (verified ones earn a bonus) →
**Spend** energy on bounded unlock windows → **Nurture** a companion whose
wellbeing mirrors yours → **Together**, with friends who can approve your
emergency unlocks.

The core experience is free, forever.

## Documentation

| Document | Purpose |
|---|---|
| [Product vision](docs/product/vision.md) | Problem, audience, core loop, principles, non-goals |
| [Roadmap](docs/roadmap.md) | Phases, the day-one membership checklist, open questions |
| [Competitive analysis](docs/research/competitive-analysis.md) | Unrot, Brainrot, and the adjacent market |
| [Platform constraints](docs/research/platform-constraints.md) | What Apple's Screen Time APIs allow, and the workarounds |
| [Monetization research](docs/research/monetization.md) | Paywall data and the recommended model |
| [Character bible](docs/brand/character.md) | Who Pofu is: anatomy, states, motion, voice |
| [Naming exploration](docs/brand/naming-exploration.md) | How the name Pofu was chosen |
| [Architecture decisions](docs/adr/README.md) | ADR index |
| [Contributing](CONTRIBUTING.md) | Branching, commits, PRs, releases |

## Tech stack

Swift 6 · SwiftUI · iOS 26+ · FamilyControls · ManagedSettings ·
DeviceActivity · HealthKit · WidgetKit · ActivityKit · App Intents

See [ADR-0002](docs/adr/0002-native-swiftui-ios-first.md) and
[ADR-0003](docs/adr/0003-modular-architecture-and-screen-time-boundary.md).

## Author

Built by [Eren Deniz Kuyucaklıoğlu](https://github.com/ErenDenizK).
