# Roadmap

_Living document. Last updated: 2026-11-05 (rebuilt in the housekeeping
pass; the stage G/W plan of 2026-11-02 is in the
[archive](archive/iteration-plan.md))._

## Status (2026-11-06)

- **Built and merged:** the Screen Time gate v2 as the `PofuLive` target
  with its extensions (#34, #41; it waits for the membership); the game
  model in `PofuCore` with island level 1 to 10, station caps, the harbor
  on tended day 3 and the station islands retired (#182,
  [ADR-0019](adr/0019-home-cluster-and-wonder-islands.md)); playable build
  v1 (performance, a playable flow, the icon, day and night: #166, #167,
  #174); [experience v1](design/experience-v1.md) (#189): one camera and
  one place control with taps and brushing (#193), the light field and
  the frame-rate policy (#194), menus, shield and an honest launch (#192),
  daily visitors and fullness as data (#201); vivid sprites (#200);
  painted menus (#183); approved art in the app (#185).
- **In review:** experience v1 wave 2 (#212): visitors drawn, the lawn's
  dressing and critters, three fixes.
- **Plans in place:** the [game plan](product/game-plan.md) (canonical),
  [home progression](product/home-progression.md),
  [home layout](product/home-layout.md), [deep lore](product/deep-lore.md),
  [monetization v2](product/monetization-v2.md) (proposal).
- **Membership:** expected after 2026-11-24. The Screen Time core waits for
  it; everything else is tested now in the free build's Rehearsal mode.
  New work targets the Screen Time product; the free `Pofu` target and the
  Shortcuts path get no new features.
- **Packages** (`Packages/PofuKit`): `PofuCore`, `PofuScreenTime`,
  `PofuPersistence`, `PofuDesignSystem`, `PofuCompanion`, `PofuWorld`,
  `PofuGames`, `PofuSound`, `PofuTuning`. Keep [economy.md](product/economy.md) in sync with
  `PofuCore`.

## The principle: everything grows a little, in parallel

Founder, 2026-11-05: never finish one thing before the next starts. Each
week ships a little of every kind, so the founder sees the whole world
grow, and each week ends with a screenshot sheet or a short video for him.

| Each week | From |
|---|---|
| One station level (a station's next look on the home cluster) | [home progression §4](product/home-progression.md#4-stations), the [art queue](design/art-production-plan.md) |
| One new resident, or one resident relationship scene | [home progression §6](product/home-progression.md#6-residents-cats--soup-assignment-without-the-gacha), [experience v1 §5](design/experience-v1.md#5-visitors-someone-comes-every-day) |
| One island stage or one filler | [game plan §4](product/game-plan.md#4-book-one-the-islands-rising-curve), the story map |
| One decor set, or part of one | [home progression §8](product/home-progression.md#8-decor-sets) |
| One system polish, from the app or the game track | the tracks below |

## Tracks

### App side

- **Membership day 1:** the Screen Time gate on the founder's iPhone
  ([checklist](#day-1-of-the-paid-membership),
  [script](local/membership-day-1.md)); from then on a daily readout of
  resisted reaches. Afterwards `Pofu` and `PofuLive` collapse into one app
  target with the entitlements.
- **Shield:** the painted shield (#192) meets the real Screen Time shield;
  the breathing break stays the hard limit
  ([ADR-0015](adr/0015-care-over-currency.md)).
- **Onboarding:** pick the apps, the first resisted reach, Pofu wakes
  ([game plan §3](product/game-plan.md#3-day-by-day-the-typical-user)).
- **Accessibility:** a full pass (VoiceOver, Dynamic Type, Reduce Motion)
  over every screen.
- **Haptics:** the `PofuHaptics` palette applied as
  [experience v1 §3.3](design/experience-v1.md#33-haptics-and-sound-palette-pofuhaptics)
  says: haptics confirm, never decorate.

### Game side

- **Home growth:** island level and station ladders per
  [home progression](product/home-progression.md); later a **level-up
  ceremony with glowing lights** (founder note).
- **Visitors and residents:** **residents visit daily** (founder); then
  Animal Crossing–style relationships: residents talk to each other, visit
  each other, have small scenes (wave 3).
- **Book One islands in story-map order:** a wonder-island model in
  `PofuCore` (arrival by order and gates, stages, engine, beats, gift;
  [game plan §10](product/game-plan.md#10-what-changes-in-code-and-docs-in-order)),
  the map with rumours, then the main islands one by one with fillers
  drifting in between. The story map poster (commissioned 2026-11-05)
  fixes the order; until then the provisional acts in
  [monetization v2 §2.1](product/monetization-v2.md#21-units) apply.
- **Gezgin (the whale Nazlı) as a layered rig:** body, tail, fins and the
  island patch painted as separate parts, moved in code, not one flat
  sprite. Form 1 humble, form 2 grown at the end of Book One. **Next
  variation: form 1 faces the camera, clear of the pier.**
- **Three games:** place (the garden, built), connect (flow, with
  Çağlayan), recall (bells).

### Art pipeline

- **Codex never idles** ([AGENTS.md](../AGENTS.md)): `READY` rows, then the
  backlog, then fresh `-v2` variations. The lead reviews its PRs in its own
  rounds; pilot, then scale; a grade or a fit before a regeneration.
- **Batch order** ([the queue](design/art-production-plan.md#the-queue)):
  the experience art (batch-35, its pilot merged in #202), the home
  showcase (batch-33), the hive and moss retries, the workshop retry, the
  islands in the game camera; then the Gezgin rig parts, residents at
  work, decor sets, and island batches in story-map order.

### Business

- **Monetization v2** (proposal, the founder decides): one membership,
  *Pofu Üyelik*, at 129,99 TL a month, 349,99 TL a year or 999,99 TL for
  life; the gate is always free; nothing is taken back when a membership
  lapses. After a yes: a monetization ADR (it replaces ADR-0016's "Plus"
  clause), then the game design, then `PofuCore` tests before StoreKit 2
  and UI.
- **Beta:** a TestFlight friends beta once the Family Controls
  distribution entitlement arrives; the free/paid line is measured there.
- **App Store:** icon, screenshots, preview video, TR and EN metadata,
  privacy policy, support page, the domain for universal links; art
  provenance (a written assignment or masters regenerated on the founder's
  plan). Release in Türkiye, then global.

## Next, in order (plan of 2026-11-06)

The founder (2026-11-06): plan everything worth doing (technical, game
design, flow and progression, the app) and drive the scope. Four phases;
inside a phase the tracks run in parallel (at most three agents), and
Codex works its queue the whole time.

### Phase A, the look foundation (to 2026-11-09)

1. **Light and colour:** merge SW-1 harmony (#258) and SW-3 sky and fog
   (#256, after its Koke stage-0 tuning); then SW-2 weather and the screen
   haze ([sky and weather v1](design/sky-and-weather-v1.md) §2.2, §2.2b).
2. **Night lighting:** tune nightlab (#257) against the painted night key
   (batch-45) and real normals from the light-direction pilot
   (batch-47); then an ADR (delit then relit, per-pixel lights, hemisphere
   ambient, cached composite) and the Metal port in two PRs (the shader
   and the baked companions; per-class and Pofu-specific normal tuning).
   Founder notes to meet: no hard-edged light (soft round falloff, never a
   diagonal cut), Pofu's form not angular, the island's underside takes
   light as a volume, characters and effects seated in the night light.
3. **Icons:** the flat icon sheets (batch-46); the winner replaces the
   place control's glyph and the SF Symbols in menus, vectorised if it
   pays.
4. **Koke finished:** integrate the four promoted takes (row 0-k); one
   Koke on screen (the plate's Koke and the pose sprites never overlap).

### Phase B, the Book One spine (to 2026-11-16)

5. **Flow engine and Çağlayan:** a game-design note first (pieces,
   puzzles per stage, the difficulty ramp, no fail state, hints, 60-90 s a
   puzzle), then `PofuGames` flow, then Çağlayan on the wonder-island
   model with its batch-43 art and the dry-rock echo.
6. **The flow audit:** a `PofuCore` test that plays a typical player
   through days 1-21 and asserts every beat lands (the harbor on day 3,
   Koke, Çağlayan on day 10, a gift or a change every day, no dead day),
   plus one for a heavy scroller (the screen haze shows, nothing is lost).
7. **Every level a living change:** a screenshot sheet of home at IL1 to
   IL10; each step must add something you can see and something that
   moves; IL1 gets its decor (it is sparse).
8. **Residents, wave 3:** resident-to-resident scenes (ten, written with
   the `pofu-story` skill), residents visit daily, reactions by mood.

### Phase C, ready for membership day 1 (to 2026-11-24)

9. **App:** onboarding (pick the apps, the first resisted reach, Pofu
   wakes); the painted shield meets the real Screen Time shield; a widget
   and the week page that share the sky and count the clear days; the
   accessibility pass (VoiceOver, Dynamic Type, Reduce Motion); haptics.
10. **Business:** the membership day-1 checklist (founder); the TestFlight
    friends beta; monetization v2 waits for the founder's yes.
11. **Health:** the frame meter after weather and the night relight
    (settled frames 0 Hz); the snail drift in `integrate.py`; prune merged
    worktrees and branches.

### Phase D, after the membership

12. **Emanet** (the fog island, the screen haze's language at its most
    beautiful), **Çanlar** (the recall game with bells), **Revontuli**, the
    Gezgin rig, sound (weather and the arc), the App Store assets.

## Day 1 of the paid membership

A checklist; these steps have long lead times.

1. Enroll in the Apple Developer Program as an individual.
2. Finalize bundle identifiers for the app and every extension.
3. Request the **Family Controls (Distribution)** entitlement for **each**
   bundle identifier.
4. Enable App Groups, Family Controls (Development), HealthKit, and
   Associated Domains.

## Later

- **The ecosystem:** widgets, Live Activity for quiet time, Control Center
  and App Intents.
- **Together:** postcards, a friend's boat at your pier, shared streaks
  ([ADR-0005](adr/0005-serverless-friend-approval.md); CloudKit needs a new
  ADR).
- **Earning extras:** HealthKit passive earning and verified focus, only
  as calm boosts.
- **Book Two** and the long tail: mastery, seasons, the hilltop add-ons
  ([home progression §9-§10](product/home-progression.md#9-mastery-levels-l6-to-l10-the-long-tail)).

## Open questions

| Question | Owner | Needed by |
|---|---|---|
| Monetization v2: one membership and its prices | Agent proposed, founder decides | Before StoreKit work |
| Where the free part ends (after Act I) | Measured in the beta | Launch |
| Repository visibility before launch (public for now) | Agent proposes | Launch |
