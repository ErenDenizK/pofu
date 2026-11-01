# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Gate v2 ([spec](docs/product/ux/gate-v2.md)): the shield speaks. A copy
  engine in `PofuCore` (`ShieldCopy`) picks Pofu's line by reach count,
  time of day, bedtime, pass expiry, and the daily hour, with today's
  tally ("Bugün 5 / 7 boş verdin.") and Pofu's mood as the icon, in
  Turkish and English, within the shield's length limits. The secondary
  button is the honest **Açmam lazım**, with the iOS 26.4 submenu: a
  3-minute quick check that lifts the shield on the spot, or **Pofu'yla
  aç**, which posts a time-sensitive notification and redraws the shield
  into a waiting state. Past the daily hour the only way through is
  **Pofu'yla nefes al**, and Hop! opens in a new breathing room.
- Every reach at the shield counts once: leaving the shield without a tap
  and open requests never followed are resisted reaches; the shield that
  returns when a pass ends is not a reach, and its **Bitti, kapat** is not
  a skip. Each kind is logged and shown in a developer readout.
- The daily hour is a setting (15–180 minutes) that drives the
  DeviceActivity ladder; the gate's timings live in `ScreenTimeGateRules`.
- Onboarding with Screen Time explains the permission, primes the picker
  and notifications, handles denial, an empty pick, and a whole category,
  and ends on the real shield ("Hadi dene." → "Yakaladım!"). No naming
  step in the live build.
- Settings shows when notifications are off or Focus may hide Pofu's
  notification. Day-1 cases 20–28.

### Changed

- Without notifications, "Pofu'yla aç" is never a dead end: the shield
  says "Pofu'yu kendin aç", and opening Pofu within 10 minutes starts
  Hop!. The notification tap is routed by the notification delegate; the
  scene-phase path stays as that fallback.
- The live build sends no pass-expiry push while the shield is on: the
  shield's return is the cue.

- The pass-expiry reminder, Pofu's only notification: "Time's up. Back to
  me?" when a pass ends. Permission is asked at the first pass; tapping
  it counts as a sign of life.

- Product foundation: vision, competitive research, platform constraints,
  monetization research, naming exploration, roadmap.
- Architecture Decision Records 0001–0012.
- Pofu character bible v0.1.
- Contribution guidelines, pull request and issue templates.
- Engineering foundation: an XcodeGen-generated iOS 26 app project
  (`project.yml`) with a placeholder home screen in English and Turkish,
  and signing settings in `Config/` with git-ignored local overrides.
- `PofuKit` local package: `PofuCore` (energy economy, friction ladder,
  passes, impulse metrics, companion vitality), `PofuScreenTime`
  (`ScreenTimeService` and a deterministic simulator), and
  `PofuDesignSystem` (palette, spacing, type, motion tokens), with Swift
  Testing suites and multi-week economy simulations.
- Energy economy rules v0 ([economy.md](docs/product/economy.md)).
- ADR-0009: XcodeGen and the single-package layout.
- Development guide ([development.md](docs/development.md)).
- GitHub Actions CI: package tests and an unsigned simulator build of the
  app on every pull request, with Swift warnings treated as errors.
- Character exploration: v0.1 vector rig, a procedural 3D Blender spike, and
  GPT Image concepts. Pofu is an illustrated fluffy hamster (ADR-0010).
- `PofuCompanion`: an animated companion view driven by springs and a Metal
  deformation shader (cheek pouches, tap dent, fur ripple, vitality grade),
  plus a WebGL motion proof and sprite-sheet tooling (ADR-0011).
- UX: information architecture, eight user flows with English and Turkish
  copy, and a clickable high-fidelity prototype of the core loop.
- Design language, art bible, a prioritized GPT Image prompt library, color
  tokens with a contrast report, and an asset pipeline for processing
  generated art and slicing sprite sheets.
- Soft gate v1: `CheckInIntent` (one Shortcuts automation per app, dynamic
  foregrounding, silent pass-through), the Hop! ladder with passes,
  refunds, and a daily emergency pass, hand-off to the target app, and a
  guided Shortcuts setup.
- `PofuPersistence`: an atomic JSON snapshot store and an append-only event
  log.
- Pofu's room v1, minimal onboarding, and a full English and Turkish string
  catalog.
- Quiet-time earning (ADR-0014): staying away from guarded apps fills
  Pofu's cheeks by itself, one seed per 10 quiet waking minutes up to 48 a
  day, plus a +10 bonus for a quiet night. Seeds are collected on Home with
  a hop and a haptic; Home shows how long it has been quiet, and holds the
  seeds and asks to check the setup when the automation has been silent
  for three days.
- Diagnostics: `os.Logger` channels under `com.erendenizk.pofu` (`intent`,
  `hop`, `economy`, `persistence`, `routing`), with user data private.
- Game design v2: Pofu's archipelago ([game-design.md](docs/product/game-design.md)).
  Seeds become world material that never buys screen time (ADR-0015), a
  breathing break with Pofu is the hard limit past 60 guarded minutes a
  day, quick checks halve the calm multiplier, five islands each with its
  own small loop (ADR-0016), and Pofu never dies (ADR-0017). Re-tuned
  archipelago simulation (`tools/sim/island_economy.py`).
- Island game prototype v3: mobile-first full-screen layout with safe
  areas and a touch-scrollable demo drawer, the archipelago map, İskele,
  the breathing break, quick checks, and an automated phone and desktop
  check (`design/prototypes/island-game/tools/check-mobile.js`).
- Design review 01 ([review-01.md](docs/design/review-01.md)): three
  radically different alternatives each for proportion and framing, the
  UI language over the world, and choreography, with a measured spec, a
  timing spec, and a combined recommendation; a mobile-first animated
  review page in Turkish (`design/prototypes/review-01/`).
- ADR-0018, visual system v1: the balanced diorama, Glass++ (native glass
  with painted domain icons, vector twins, the seed jar and the calm
  lantern, painted widgets, a layered app icon), and the continuous camera;
  matching design language amendments.
- Iteration plan ([iteration-plan.md](docs/design/iteration-plan.md)): the
  path from prototype to launch in twelve checkable micro-iterations.
- Decision audit ([decision-audit.md](docs/product/decision-audit.md)):
  an independent red-team review of every decision, research claim, and
  plan.
- Art test 01: the founder's first island and çay ocağı takes, kept as
  references.
- Art direction study ([art-direction-study.md](docs/design/art-direction-study.md))
  with a phone-friendly comparison page (`design/prototypes/art-study/`):
  measured why the props read as "AI", three treatments, and the
  recommended soft lock (props and plates pulled toward R1; Pofu
  untouched).
- Image pipeline (`tools/imagegen/`, [art-pipeline.md](docs/design/art-pipeline.md)):
  manifests composed from verbatim prompt blocks, `codex`, `openai-api`
  and `manual` backends, the style lock, QA (station anchor, edit
  alignment, palette drift, detail at display size, icon legibility on
  glass), contact sheets, a review file and promotion with provenance.
  Batch 01 (vertical slice) and batch 02 (Glass++ UI art) are defined and
  blocked until the founder's account decision and the 7-day dogfood.
  `AGENTS.md` briefs OpenAI Codex as the local operator.
- Art bible v1.1: amendment A1 (prop style block v2, one diorama camera,
  the style lock, the `world-props` palette, level-chain alignment, the
  generating-account rule).
- Screen Time gate for membership day 1 (ADR-0013): a separate `PofuLive`
  scheme with the Family Controls and App Group entitlements, so the
  default `Pofu` scheme still signs with a free account.
  `LiveScreenTimeService` (individual authorization, the app picker, a
  named shield, DeviceActivity thresholds at 15, 30, 45 and 60 guarded
  minutes); shield configuration, shield action and device activity
  monitor extensions talking to the app through versioned records in an
  App Group inbox; shield skips counted as resisted reaches; "Talk to
  Pofu" answered by a notification that opens Hop! for that app, whose
  pass lifts the shield until it ends; permission-plus-picker onboarding
  with Shortcuts as "Live Pofu (optional)"; a CI build of the live scheme;
  and a device script ([membership-day-1.md](docs/local/membership-day-1.md)).

### Fixed

- The gate's measurement hole (decision audit C1): quiet time no longer
  accrues after a pass expires. Before Screen Time nothing closes the app
  at expiry, so the time until the next sign of life (a check-in, Pofu in
  the foreground, or a tap on the expiry reminder) is unobserved. Seeds
  already in the cheeks are still held, never lost. Economy, ADR-0014
  (dated note), and game design §6 are corrected to match.
- Setup guide v2: the automation is framed as a rule ("when Instagram
  opens, Pofu hops in"), step 1 says not to search and to tap Automation,
  search happens only inside Add Action ("Hop"), every step shows a
  schematic of its screen with a slot for a device screenshot, and "Test
  it" is the only primary action. Turkish Shortcuts labels that no source
  confirmed are marked for checking on a device.

Polish from the first simulator run
([report](docs/local/reports/2026-11-01-simulator-run.md)):

- The setup guide's footer is opaque with a hairline edge, and the guide
  shows one primary action at a time, always the next real step; "Done"
  appears only once the automations work.
- The halo behind Pofu is a soft radial glow, also in dark mode.
- Unselected tiles and chips keep a visible edge in dark mode.
- Fill my cheeks: Start no longer covers the duration chips, which now
  show their unit.
- No white flash on launch: the launch screen uses the day wash color.
- Home: the bubble's tail points at Pofu; the seed pill and the settings
  button share a height and shape.
- Onboarding: selected apps keep their icon, long names wrap instead of
  shrinking, the naming title reads naturally, the name field uses the
  display font, and quick taps during a step's cross-fade are not lost.
- Sheets share one surface, close button, and section header style;
  Settings rows are plum-tinted in dark mode.
- Turkish copy: the Today card no longer repeats "Bugün", and "Üretmek"
  is now "Üretim".

### Changed

- The iteration plan now puts the gate first (stage G: the automation
  live, honest measurement, setup guide v2, a 7-day dogfood, the Screen
  Time shield) before the world (stage W). ADR-0018's Glass++ production
  waits for the friends beta. Room-era UX documents and the vision's core
  loop are marked superseded; ADR-0010, 0015, and 0018 are amended; the
  roadmap reflects the new order.

- Breathing break v2 (founder decision): the user starts the breath with
  one tap ("Breathe with Pofu"); 5 seconds, 10 from the 4th over-limit
  open of the day, never more (ADR-0015 amendment, game design, the
  simulation, and the island prototype).
- The repository is `ErenDenizK/pofu`; docs link there. The development
  guide covers the Metal Toolchain download and the simulator-only App
  Shortcut limitation.
