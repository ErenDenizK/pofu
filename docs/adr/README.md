# Architecture Decision Records

An Architecture Decision Record (ADR) captures one decision that is expensive
to reverse, along with its context and consequences. ADRs are immutable once
accepted: to change a decision, write a new ADR that supersedes the old one.

Format: a lightweight variant of [MADR](https://adr.github.io/madr/). Use
[`template.md`](template.md) for new records.

**Only for decisions that cost weeks to undo** (decision audit, 2026-11-01).
Tunable values (breath seconds, thresholds, seed amounts, names) live in
`PofuCore` configuration, the [game plan](../product/game-plan.md) and the
[economy](../product/economy.md), not in ADRs. Prefer deciding from real use over deciding from prototypes.

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
| [0010](0010-illustrated-hamster-art-direction.md) | Illustrated hamster art direction | Accepted, amended by 0011 |
| [0011](0011-companion-motion-system.md) | Companion motion system | Accepted |
| [0012](0012-ux-v1-decisions.md) | UX v1 decisions | Accepted, amended by 0015 and 0016 |
| [0013](0013-zero-setup-default-gate.md) | Zero-setup default gate, live Pofu as an enhancement | Accepted (the Shortcuts path is frozen: no new features) |
| [0014](0014-quiet-time-earning.md) | Quiet-time earning | Accepted, amended by 0015 |
| [0015](0015-care-over-currency.md) | Care over currency: seeds as world material | Accepted |
| [0016](0016-pre-planned-idle-archipelago.md) | Pre-planned idle archipelago | Accepted, amended by 0019 |
| [0017](0017-pofu-never-dies.md) | Pofu never dies | Accepted |
| [0018](0018-visual-system-v1.md) | Visual system v1: balanced diorama, Glass++, continuous camera | Accepted, amended by 0020 and 0021 |
| [0019](0019-home-cluster-and-wonder-islands.md) | Home cluster and wonder islands: station islands retired | Accepted |
| [0020](0020-painted-surfaces-native-behaviour.md) | Painted surfaces, native behaviour | Accepted (amends 0018; the founder's menu-material view is open, see the decisions register D8) |
| [0021](0021-reference-light-targets.md) | Reference light targets: the light standard follows the liked references; night is a hue change | Accepted (amends 0018 §5; replaces the light standard v1's value rules) |
| [0022](0022-plate-first-islands.md) | Plate-first islands: the painted plate is the final picture; the runtime adds only light and life (hybrid: upgrades cut from plate edits) | Accepted (amends 0018 and lock-light for plate-first islands; amended by 0023) |
| [0023](0023-colour-lives-in-the-painting.md) | Colour lives in the painting: plates are painted at final colour, no runtime grade, style lock `plate-final`, full-size delivery, colour ladder and metric bands | Accepted (amends 0022) |
| [0024](0024-shipped-plate-layers-are-heic.md) | Shipped plate layers are HEIC q70 with alpha (plates, islands, occluders; backdrops stay JPEG) | Accepted (amends 0022 delivery) |

**Read an ADR's status line and this table first; do not load ADR bodies
you do not need.** A status here that says "amended" or "superseded" means
the later ADR wins on that point; the older body stays unchanged as history.

- **0018** is amended by [0020](0020-painted-surfaces-native-behaviour.md): surfaces may be painted; behaviour stays native; and by [0021](0021-reference-light-targets.md): §5's style target is the reference envelope, not "never lifted blacks".
