# Iteration Plan: Gate First, Then Pofu's World

_Living document. Last updated: 2026-11-02. Reordered 2026-11-01 after the
[decision audit](../product/decision-audit.md); dates refreshed 2026-11-02:
the membership is expected **after 2026-11-24**, and new work targets the
Screen Time product (the Shortcuts path, G1, is dropped)._

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
| **Gate week** (from membership day 1, after 2026-11-24; Rehearsal mode until then) | The Screen Time gate on the iPhone for Instagram, YouTube, and TikTok, Hop!, honest measurement, and a daily readout |
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

The paid membership (expected after 2026-11-24) turns on the Screen Time shield
for development builds on the founder's own iPhone on day 1; TestFlight
waits for Apple's separate distribution approval. So the cloud builds the
shield path **now**, and the founder's real test week starts on membership
day 1 instead of fighting the manual Shortcuts setup (founder's call,
2026-11-01).

| # | Question | Artifact | Check | Who |
|---|---|---|---|---|
| G1 | Does the manual automation fire? (**dropped 2026-11-02**: the free Shortcuts path gets no new features) | One "Instagram is opened → Hop in" automation, created with the local agent guiding live; a screen recording | Hop! fires from a real reach. Worth one 30-minute try for early data on Hop!; not a blocker | Founder + Mac |
| G2 | Is the measurement honest and the setup guide followable? | Post-expiry time counts as unobserved; pass-expiry notification; setup guide v2 in "when Instagram opens, Pofu hops in" language. Still needed for Live Pofu (ADR-0013) | Tests pass; later, a friend sets it up from the guide alone | **Done** (#32) |
| G3 | Is the zero-setup gate ready for day 1? | `LiveScreenTimeService`, shield, shield action, and monitor extensions behind a separate signing configuration; a day-1 test script | CI green; the free build still signs with a Personal Team | **Done** (#34, gate v2 #41) |
| G4 | Can we use Screen Time? | Membership day 1: enroll, request Family Controls distribution for every bundle ID, switch to the live configuration, build to the iPhone (`docs/local/membership-day-1.md`) | The shield appears on Instagram; distribution request date recorded | Founder (Xcode on the Mac, once) |
| G5 | Does the gate change behavior? | A 7-day dogfood on the shield (plus Live Pofu if G1 worked), with no feature changes during the week, and a daily readout | Resisted share of reaches, measured minutes, against the goal of half | Founder |
| G6 | What does the data ask for? | The smallest ADR-0015 slice the week shows is needed | Week 2's resisted share against week 1 | Cloud |

While the founder waits, the cloud also writes the game model in
`PofuCore` (W3) against measured minutes, and the 8-image art test (W1)
may run as soon as the account is decided, because art has the longest
lead time.

_Update 2026-11-02:_ the membership is expected after 2026-11-24, about
three weeks of waiting. Because nothing can be dogfooded before then, the
wait is used for code-only, low-regret stage W work: W3 (game model), W2
(`PofuWorld` skeleton with stand-in art), widgets, and regenerating Pofu
on the founder's own account. No production art batches and no islands
2+ until G5 has data.

## Stage W: the world (after two weeks of daily use)

_Code-only stage W work runs during the membership wait; production art waits for G5 data._

| # | Question | Artifact | Check | Depends on |
|---|---|---|---|---|
| W1 | Can we make on-style art on the founder's own account? | Batch 01: the first 8 images ([game design §15](../product/game-design.md)), a test, not production | Pipeline QA passes; the founder judges the phone composite "not AI-looking" | Account decision (may run during stage G) |
| W2 | Can SwiftUI carry the world? | `PofuWorld`: `IslandScene` with layered plates, slot anchors, the three camera framings | CI green; simulator screenshots match the prototype framings | G6 |
| W3 | Is the game model right in code? | `PofuCore`: `CareLedger`, `CalmAccrual`, `StationLedger`, the breath, with tests mirroring an honest `tools/sim` | Tests pass; game design in sync | G2 (may run during stage G) |
| W4 | Does Home feel alive, and stay short? | Home with batch 01 art, native glass, Hop! landing per opening intent | 60 fps idle; VoiceOver reads every state; **Pofu opens a day outside Hop! stay below reaches, and the median visit stays under 90 s** | W1–W3 |
| W5 | Do the key moments feel good in the hand? | Camera springs, seed collection, level-up, haptics (the interaction spec, in progress; [review 01 §3](review-01.md#3-choreography)) | The founder repeats one without being asked; the visit-length guardrail still holds | W4 |
| W6 | Does the product look like one thing? | Glass++ production: icon family with vector twins, jar and lantern, widgets, the layered app icon ([ADR-0018](../adr/0018-visual-system-v1.md)) | Icons named correctly at 30 pt by someone who has not seen them | Friends beta |
| W7 | Do new islands earn their cost? | Island 2 and the map, only if friends still use the gate after two weeks | Friends' D7 and resisted share | Friends beta |

## What stays rough on purpose

Until W4, menus, copy, and transitions in the prototypes are stand-ins.
Feedback on them is collected, not acted on, so that the gate and the model
are not blocked by polish that real use will change anyway.
