# Iteration Plan: From Prototype to Pofu's World

_Living document. Last updated: 2026-11-01._

The prototypes proved the idea; they did not prove the craft. Rough art,
placeholder menus, and stand-in motion are expected at this stage. This plan
says what the world can become and how it gets there in small, checkable
steps. Decisions it builds on: [ADR-0015](../adr/0015-care-over-currency.md)
to [ADR-0018](../adr/0018-visual-system-v1.md).

## What it can become

| Horizon | What the founder holds in their hand |
|---|---|
| **Vertical slice** (Phase 1) | Ayçiçeği island at stages 1–3 with the çay ocağı, Pofu with real expressions, the Glass++ frame, the jar and the lantern, Hop! and the 5 s breathing break, all on the iPhone with the simulated Screen Time service |
| **Launch** (Phase 6) | Five islands with 8 stations × 5 levels, four residents, painted widgets that show Pofu's island live, a layered Liquid Glass app icon, the map with island arrivals, Turkish and English |
| **Year one** | Seasonal skins as edits (spring blossoms, a winter lantern festival), friends visiting each other's islands ([ADR-0005](../adr/0005-serverless-friend-approval.md)), new islands as updates, Live Activity for quiet time, an ambient soundscape per island |

The north star does not change between horizons: a calm, legible world
that feels hand-made, where every visual change is earned by not opening
an app.

## How a micro-iteration works

- **One question, one artifact, one check.** Each iteration answers one
  question ("Does the jar read at a glance?"), produces one thing the
  founder can open on the phone, and ends with a pass or fail check written
  in advance.
- **Two days at most.** Anything bigger is split.
- **The loop:** generate or build → automatic QA (pipeline checks, CI) →
  the founder looks at it on the iPhone → the decision goes into the PR or
  an ADR → next iteration.
- **Kill early.** If a check fails twice, the approach changes, not the
  polish.

## The iterations

| # | Question | Artifact | Check | Depends on |
|---|---|---|---|---|
| I1 | Can Codex make on-style art with the ChatGPT login? | Batch 01: the first 8 images ([game design §15](../product/game-design.md)) | Pipeline QA passes; the founder judges the phone composite "not AI-looking" | Founder: ChatGPT login on the Mac |
| I2 | Does the balanced diorama hold with real art? | Review page and island prototype re-skinned with batch 01 | Pofu ≈ 20 % of width; chrome bands stay calm; no station lost behind glass | I1 |
| I3 | Do painted icons read as one family at small sizes? | Batch 02 (Glass++): 6 domain icons, jar ×2 states, lantern off/on, one medium widget, an app icon draft | Contact sheet at 24, 30, and 60 pt on light and dark glass; every icon named correctly by someone who has not seen it | I1 |
| I4 | Can SwiftUI carry the world? | `PofuWorld` module: `IslandScene` with layered plates, slot anchors, three camera framings | CI green; local agent's simulator screenshots match the prototype framings within a few points | none |
| I5 | Is the game model right in code? | `PofuCore`: `CareLedger`, `CalmAccrual`, `StationLedger`, breathing break v2, with tests mirroring `tools/sim` | Tests pass; [economy](../product/economy.md) and game design in sync | none |
| I6 | Does Home feel alive on the device? | Home with batch 01 art, the Glass++ frame, the jar, and the lantern | On the iPhone: 60 fps idle, legible at the largest Dynamic Type size, VoiceOver reads every state | I2, I3, I4, I5 |
| I7 | Do the key moments feel good in the hand? | Camera springs, seed collection, level-up, haptics ([companion motion](companion-motion.md), [review 01 §3](review-01.md#3-choreography)) | Each moment within its timing in review 01 §3; the founder repeats one without being asked | I6 |
| I8 | Does the gate still work with the new world? | Hop! and the breathing break wired to `CheckInIntent` | Device validation T3 cases pass with the new screens | I6, T3 |
| I9 | Does the product look like one thing outside the app? | Widgets v1 (small, medium, Lock Screen) and the app icon in Icon Composer | Home Screen screenshot next to Instagram, YouTube, TikTok: Pofu reads at a glance | I3 |
| I10 | Do island arrivals feel like an event? | Map, archipelago arrival with the cloud pass, the 30 pt Pofu pin | Arrival plays once, is skippable, respects Reduce Motion | I7 |
| I11 | Does it change behavior? | The founder's 7-day dogfood with the event log | Share of resisted reflexive opens against the goal of half | I8 |
| I12 | What hurts after a week? | Polish pass from the dogfood notes | The three worst frictions fixed; the next plan written | I11 |

I4 and I5 do not wait for art; they run in the cloud while the founder and
the local agent handle I1.

## What stays rough on purpose

Until I6, menus, copy, and transitions in the prototypes are stand-ins.
Feedback on them is welcome but is collected, not acted on, so that art and
model work are not blocked by polish that the real assets will change
anyway.
