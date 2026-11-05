# Architecture Decision Records

An Architecture Decision Record (ADR) captures one decision that is expensive
to reverse, along with its context and consequences. ADRs are immutable once
accepted: to change a decision, write a new ADR that supersedes the old one.

Format: a lightweight variant of [MADR](https://adr.github.io/madr/). Use
[`template.md`](template.md) for new records.

**Only for decisions that cost weeks to undo** (decision audit, 2026-11-01).
Tunable values (breath seconds, thresholds, seed amounts, names) live in
`PofuCore` configuration and the [game design](../product/game-design.md),
not in ADRs. Prefer deciding from real use over deciding from prototypes.

| # | Title | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-native-swiftui-ios-first.md) | Native Swift and SwiftUI, iOS first | Accepted |
| [0003](0003-modular-architecture-and-screen-time-boundary.md) | Modular architecture and a Screen Time boundary | Accepted |
| [0004](0004-trust-first-activity-verification.md) | Trust-first activity verification | Accepted, amended by 0015 |
| [0005](0005-serverless-friend-approval.md) | Serverless friend approval | Accepted |
| [0006](0006-code-native-companion-rendering.md) | Code-native companion rendering | Superseded by 0010 |
| [0007](0007-product-name-pofu.md) | Product and character name: Pofu | Accepted |
| [0008](0008-hybrid-intervention-delivery.md) | Hybrid intervention delivery | Accepted, amended by 0015 |
| [0009](0009-xcodegen-and-package-layout.md) | XcodeGen project and a single local package | Accepted |
| [0010](0010-illustrated-hamster-art-direction.md) | Illustrated hamster art direction | Accepted |
| [0011](0011-companion-motion-system.md) | Companion motion system | Accepted |
| [0012](0012-ux-v1-decisions.md) | UX v1 decisions | Accepted, amended by 0015 and 0016 |
| [0013](0013-zero-setup-default-gate.md) | Zero-setup default gate, live Pofu as an enhancement | Accepted |
| [0014](0014-quiet-time-earning.md) | Quiet-time earning | Accepted, amended by 0015 |
| [0015](0015-care-over-currency.md) | Care over currency: seeds as world material | Accepted |
| [0016](0016-pre-planned-idle-archipelago.md) | Pre-planned idle archipelago | Accepted, amended by 0019 |
| [0017](0017-pofu-never-dies.md) | Pofu never dies | Accepted |
| [0018](0018-visual-system-v1.md) | Visual system v1: balanced diorama, Glass++, continuous camera | Accepted |
| [0019](0019-home-cluster-and-wonder-islands.md) | Home cluster and wonder islands: station islands retired | Accepted |
