# Iteration Plan: Gate First, Then Pofu's World

_Living document. Last updated: 2026-11-01 (reordered after the
[decision audit](../product/decision-audit.md))._

The prototypes proved the idea; they did not prove the craft. More
importantly, **the gate has not yet caught one real reach** on the founder's
phone. Every world, art, and game number depends on a gate that works and
measures honestly. So the plan has two stages: **G**, make the gate real
and live with it, then **W**, build the world on evidence. Decisions it
builds on: [ADR-0013](../adr/0013-zero-setup-default-gate.md) and
[ADR-0015](../adr/0015-care-over-currency.md) to
[ADR-0018](../adr/0018-visual-system-v1.md).

## What it can become

| Horizon | What the founder holds in their hand |
|---|---|
| **Gate week** (now) | The current app on the iPhone: a working automation for Instagram, YouTube, and TikTok, Hop!, honest measurement, and a daily readout |
| **Vertical slice** | Shield-based zero-setup gate (membership), the 5 s breathing break, and Ayçiçeği island at stages 1–3 with the çay ocağı and Mochi |
| **Friends beta** | The Glass++ frame (painted domain icons, the jar and the lantern), widgets, the layered app icon, Turkish and English |
| **Launch and year one** | More islands as evidence allows, seasonal skins as edits, friends visiting each other's islands ([ADR-0005](../adr/0005-serverless-friend-approval.md)), Live Activity for quiet time, an ambient soundscape per island |

The north star does not change between horizons: a calm, legible world
that feels hand-made, where every visual change is earned by not opening
an app, and which never becomes a new thing to scroll.

## How a micro-iteration works

- **One question, one artifact, one check.** Each iteration answers one
  question, produces one thing the founder can open on the phone, and ends
  with a pass or fail check written in advance.
- **Two days at most.** Anything bigger is split.
- **The loop:** build → automatic QA (CI, pipeline checks) → the founder
  uses it on the iPhone → the decision goes into the PR, the game design,
  or (only if it costs weeks to undo) an ADR → next iteration.
- **Kill early.** If a check fails twice, the approach changes, not the
  polish.

## Stage G: the gate

| # | Question | Artifact | Check | Who |
|---|---|---|---|---|
| G1 | Does the automation fire on the founder's phone? | One "Instagram is opened → Hop in" automation, created with the local agent guiding live; screen recording; every screen captured in Turkish; the T3 report | Hop! fires from a real reach on Instagram, YouTube, and TikTok | Founder + Mac |
| G2 | Is the measurement honest and the setup guide followable? | Time after a pass expires counts as unobserved; pass-expiry notification; setup guide v2 in "when Instagram opens, Pofu hops in" language, rebuilt from G1's screenshots | Tests pass; a friend sets it up from the guide alone | Cloud |
| G3 | Does the gate change behavior? | A 7-day dogfood on the current gate, with no feature changes during the week, plus a daily readout from the event log | Resisted share of reaches, time to Hop!, and silent days, against the goal of half | Founder |
| G4 | Can we use Screen Time? | Membership day 1: enroll, request Family Controls distribution, enable capabilities ([roadmap](../roadmap.md)) | Request submitted; date recorded | Founder |
| G5 | Does the zero-setup gate work? | Authorization, app picker, a shield with Pofu's line, resist counting, DeviceActivity thresholds | The founder's second week runs on the shield; minutes are measured, not estimated | Cloud + Founder |
| G6 | What does the data ask for? | The smallest ADR-0015 slice the week shows is needed (likely the breath and the removal of prices) | Week 2's resisted share against week 1 | Cloud |

Design and game work does not stop during stage G, but it stays on paper
and in prototypes: no production art, no `PofuWorld` code.

## Stage W: the world (after two weeks of daily use)

| # | Question | Artifact | Check | Depends on |
|---|---|---|---|---|
| W1 | Can we make on-style art on the founder's own account? | Batch 01: the first 8 images ([game design §15](../product/game-design.md)) | Pipeline QA passes; the founder judges the phone composite "not AI-looking" | Account decision |
| W2 | Can SwiftUI carry the world? | `PofuWorld`: `IslandScene` with layered plates, slot anchors, the three camera framings | CI green; simulator screenshots match the prototype framings | G6 |
| W3 | Is the game model right in code? | `PofuCore`: `CareLedger`, `CalmAccrual`, `StationLedger`, the breath, with tests mirroring an honest `tools/sim` | Tests pass; game design in sync | G6 |
| W4 | Does Home feel alive, and stay short? | Home with batch 01 art, native glass, Hop! landing per opening intent | 60 fps idle; VoiceOver reads every state; **Pofu opens a day outside Hop! stay below reaches, and the median visit stays under 90 s** | W1–W3 |
| W5 | Do the key moments feel good in the hand? | Camera springs, seed collection, level-up, haptics (the interaction spec, in progress; [review 01 §3](review-01.md#3-choreography)) | The founder repeats one without being asked; the visit-length guardrail still holds | W4 |
| W6 | Does the product look like one thing? | Glass++ production: icon family with vector twins, jar and lantern, widgets, the layered app icon ([ADR-0018](../adr/0018-visual-system-v1.md)) | Icons named correctly at 30 pt by someone who has not seen them | Friends beta |
| W7 | Do new islands earn their cost? | Island 2 and the map, only if friends still use the gate after two weeks | Friends' D7 and resisted share | Friends beta |

## What stays rough on purpose

Until W4, menus, copy, and transitions in the prototypes are stand-ins.
Feedback on them is collected, not acted on, so that the gate and the model
are not blocked by polish that real use will change anyway.
