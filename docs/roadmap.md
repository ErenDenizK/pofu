# Roadmap

_Living document. Last updated: 2026-11-07 (adds the Door and UI v3 tracks;
the stage G/W plan of 2026-11-02 is in the
[archive](archive/iteration-plan.md)). What is decided and what is open:
[the decisions register](product/decisions.md)._

Every thread, decision and half-finished item, with its status: [the tracker](tracker.md).

## Status (2026-11-07)

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
- **Since then:** the English rename (#130, #132, #137), the world sound
  pass, the gate v2.1 spec and concepts (#268), the flow game and Çağlayan
  (#297, #315), UI v3 waves 1-2 ([UI v3](design/ui-v3.md)).
- **Plans in place:** the [game plan](product/game-plan.md) (canonical),
  [home progression](product/home-progression.md),
  [home layout](product/home-layout.md), [deep lore](product/deep-lore.md),
  [monetization v2](product/monetization-v2.md) (proposal; prices are his working numbers, not approved).
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
| One island stage or one filler | [game plan §4](product/game-plan.md#4-book-one-the-islands-rising-curve), [book-one-islands](design/book-one-islands.md) |
| One decor set, or part of one | [home progression §8](product/home-progression.md#8-decor-sets) |

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

### Game side

- **Home growth:** island level and station ladders per
  [home progression](product/home-progression.md); later a **level-up
  ceremony with glowing lights** (founder note).
- **Visitors and residents:** **residents visit daily** (founder); then
  Animal Crossing–style relationships: residents talk to each other, visit
  each other, have small scenes (wave 3).
- **Book One islands in the order of the canonical
  [Book One story map](product/story-map/book-one.md)** (layouts and
  stages in [book-one-islands](design/book-one-islands.md)): a wonder-island model in
  `PofuCore` (arrival by order and gates, stages, engine, beats, gift;
  [game plan §10](product/game-plan.md#10-what-changes-in-code-and-docs-in-order)),
  the map with rumours, then the main islands one by one with fillers
  drifting in between. The story map fixes the order; the
  acts in [monetization v2 §2.1](product/monetization-v2.md#21-units)
  follow it.
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
  *Pofu Üyelik*, at about 349,99 TL a year or 999,99 TL for life (his
  working numbers; the monthly 129,99 TL is the lead's; he gives details
  later); the gate is always free; nothing is taken back when a membership
  lapses. After a yes: a monetization ADR (it replaces ADR-0016's "Plus"
  clause), then the game design, then `PofuCore` tests before StoreKit 2
  and UI.
- **Beta:** a TestFlight friends beta once the Family Controls
  distribution entitlement arrives; where the free part ends is open; Act I is a default to test there.
- **App Store:** icon, screenshots, preview video, TR and EN metadata,
  privacy policy, support page, the domain for universal links; art
  provenance (a written assignment or masters regenerated on the founder's
  plan). Release in Türkiye, then global.

## Next: every track, in parallel (plan of 2026-11-06)

The founder (2026-11-06): no dated phases and no betting on one thing for
long; every track takes a step every round unless it truly waits on
another. Membership day needs no big preparation (a day or two after it
arrives); what matters is the screens, the UI, how the game and the app
are used, and the gate and shield, which must be a design masterpiece.
The lead keeps this list current: each track names its next step only.

| Track | Next step | Waits on |
|---|---|---|
| **The gate fix** | Seeds must stop buying minutes (the built pay rung); breath only past the daily threshold; "Boş ver" everywhere (PR in flight) | nothing |
| **The Door** (the top design priority) | `DoorScene` per [the Door](design/the-door.md): one scene, six states; the look waits for his Q-12 and Q-13; the shield stays Apple's | his answers, the batch-58 art |
| **UI v3** | Waves 1-2 merged; wave 3 (home chrome, world cards), violet out, the menu material after Q-14 ([UI v3](design/ui-v3.md)) | his Q-14, Q-15 |
| **Light and colour** | Soft light: the hard diagonal haze shaft goes; weather and the screen haze are in (#275) | nothing |
| **Night lighting** | The relight is a spike, off by default; the ADR comes after his Q-10 answer, then the Metal port. No hard-edged light; Pofu's form round; the island's underside lit as a volume; characters and effects seated | his Q-10 |
| **Icons** | The two-tone take replaces the place control's glyph and menu symbols, once he picks the style (Q-15) | his Q-15 |
| **Koke** | Integrate row 0-k's takes; one Koke on screen; stage 0-2 plates repainted under the beautiful-wound rule (code grading of the pale, high-key plates stops short: #256's sheet), after the `x-koke-stage0-mist` concept | 0-k, batch-45 |
| **Çağlayan and flow** | Built (#297, #315). Next: the plates and water source (Q-1, Q-2), a one-day water spike | his answers |
| **Game flow** | The flow audit: a `PofuCore` test that plays days 1-21 for a typical player and for a heavy scroller; no dead day | nothing |
| **The roots** (island undersides) | Concepts (batch-49), then `UndersideLayout` and the first pieces by island level; the keepsakes arrive with each healed island ([the roots](design/island-undersides.md)) | the concepts |
| **Home growth** | A screenshot sheet of IL1 to IL10; every level adds something seen and something moving; IL1's decor | nothing |
| **Residents** | Wave 3: ten resident-to-resident scenes (`pofu-story`), daily visits | nothing |
| **App** | Onboarding (pick the apps, the first resisted reach, Pofu wakes); the widget and the week page sharing the sky; accessibility; haptics | the gate spec for the onboarding's look |
| **Health** | The frame meter after weather and night; the snail drift in `integrate.py`; prune worktrees | nothing |
| **Pofu** | Wire the rig parts (mouths, ears, paws on main) into `PofuCompanion` by mood; Pofu's normal tuning | nothing |
| **Story and lore** | Close #135 and carry its live ideas into the lore bible; Book One follows the [story map](product/story-map/book-one.md) (the base we follow, not law) | nothing |
| **Sound** | A world pass is on main; the missing cues (visitor, Koke, evening bell) | nothing |
| **Business** | His prices and answers (decisions register §8), then the ADR | the founder |
| **Process** | Close #108; a weekly device install with a checklist | nothing |
| **Later** | Emanet, Çanlar (recall), Revontuli, the Gezgin rig, sound, App Store assets; membership day 1 when the account arrives | the membership |

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
| Monetization v2: prices and the shape of the membership | Founder, details later | Before StoreKit work |
| Where the free part ends | Open; Act I (Olta) is a default to test | Launch |
| Repository visibility before launch (public for now) | Agent proposes | Launch |
