# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Look round 3 (`docs/design/look-dev.md`, "Round 3";
  `docs/design/colour-script.md`): the **Island framing** fits the large
  plate (batch 05's `island-main-l-v3`) to 88 % of the width with nothing
  cropped, centred between the chrome, and the empty bands are composed
  with the batch-04 far isles, painted clouds and cloud sea (`FarSkyLayout`);
  **real art** for every generated station level, Mochi v2 and Fındık on
  a layout where nothing overlaps or overhangs; the **colour script v1**
  (`design/art/colour-script.json`, five hour cells and the unwell state,
  generated into Swift) and the **material library**
  (`design/art/materials.json`): harmony now corrects technical defects
  only and the çaydanlık keeps its rose copper, lit by the ember; Pofu and
  the residents keep their warmth at night under the character light; the
  unwell sky turns overcast; the sky's own full-screen grade pass is gone;
  `frame_metrics.py` measures empty rows, the sky and Pofu's hue.

- Pro game craft research (`docs/research/pro-game-craft.md`): how cozy
  and mobile studios work (engines, colour scripts and lighting keys,
  skeletal rigs, juice systems, UI kits, tuning tools, playtests), an
  honest gap analysis for Pofu, a ranked upgrade plan for our constraints
  (CI motion videos, colour script with harmony v2, an on-device tuning
  panel, a juice library with sound, a JSON skeletal rig), and Pofu's
  colour and light approach (rose copper as a protected accent). Content
  node `idea-pro-craft-upgrades`.

- UI system v2 (`docs/design/ui-system-v2.md`): a hybrid of native Liquid
  Glass and painted craft. Every component is Native, Crafted or Drawn,
  with a decision table; one `PofuSkin` switch (glass / crafted) on four
  over-world roles for an A/B on the founder's iPhone and in the friends
  beta; glass legibility rules L1–L12 for the pastel world; a component
  inventory for Home, the island, the map, an island game round, the
  shield, Hop!, Today, build and decor sheets, the paywall, settings and
  onboarding; Pofu's cheek pouches as the uncollected balance (founder
  idea); a 46-item art list (14 pilot) for the Codex queue; proposed
  ADR-0018 amendments; four mockup boards in `docs/design/ui-system-v2/`.

- UI critique 01 (`docs/design/ui-critique-01.md`): a review of the game
  screen and its neighbours, a reference study, three directions for Home
  as annotated mockups (Living Diorama recommended) and a fix list in
  two-day iterations.

- Look round 2 (`docs/design/look-dev.md`, "Round 2"): **containment**
  (the pipeline measures the plate's walkable polygon and every sprite's
  ground footprint; `IslandFootprint` validates and clamps every slot,
  resident and Pofu, and a test fails on any overhang), **asset harmony**
  (`tools/assets/harmony.py` measures every master against the approved
  island, Pofu for characters and each station level against its chain's
  L1, scores it, and writes corrections that `preblur.py app` bakes; QA
  scores each take at promote time and CI fails a stale manifest; the
  çaydanlık's copper is warmed and the faded station chains restored),
  **true darks** for night and unwell (`WorldGrade` input levels, measured
  with `tools/assets/frame_metrics.py` against
  `design/art/harmony/grade-targets.json`), **depth in motion**
  (velocity-driven parallax and depth of field that settle to zero), and
  a `depth_floor` QA check so a plate that is too squashed fails (set on
  batch 05's `island-main-l-v3`). The terrarium rim is removed.

- Pofu's voice (`docs/brand/pofu-voice.md`): research on what makes a
  mascot's humour land or grate, the rules for personality B (jealous as
  play, never guilt; comedy rationed per day and decaying with the reach
  count; cooldowns; an expiring remote line pack; a never-say list), and a
  tagged Turkish line bank of 157 lines with English glosses.

- Sound identity (`docs/design/sound-identity.md`): when sound plays and
  when it never does, Pofu's micro-sounds and how each is made, island
  music in one key (a mode per island, calm opening the voicing), and the
  iOS path (stems plus a runtime composer on `AVAudioEngine`). The proof
  renderer `tools/sound/render.py` synthesizes 9 sounds and 4 seamless
  island loops into `design/sound/proof/` and measures them (true peak,
  BS.1770 loudness, spectra, seams). Content nodes `sys-voice` and
  `sys-sound`.

- Look-dev for the world (`docs/design/look-dev.md`): a reversible color
  pipeline, "painted HD-2D lite" and the terrarium. The art is baked with
  the new `lock-light` style-lock preset (the default for new jobs;
  `soft-lock` stays available), and saturation, contrast and the value
  range move into `WorldGrade`, a Metal color grade with a vignette on
  the world layer only, with presets for day, golden hour, night, Pofu
  unwell and high calm, driven by the snapshot's clock and wellbeing and
  eased over 2.5 s. `WorldLight` adds bloom on emissive points, golden-hour
  light shafts, pollen by day and fireflies at night, and a stronger
  tilt-shift per framing; the layers run only while the camera moves or
  during a 6 s visit. At the Island and Map framings the world sits in a
  terrarium: a Metal glass rim with thin Liquid Glass strips as its lip. Celebration
  moments get a painted `CelebrationCard` (system UI is glass,
  celebration is painted). All of it is behind `WorldLook` flags, on in
  the world scene only; a `FrameMeter` debug overlay measures frame
  intervals and CPU. `lock-light` versions of `island-main-s` and
  `cay-1` are re-locked from their raws with the new
  `tools/imagegen/relock.py`; the app also carries the soft-lock bake to
  compare until the founder chooses. The look sits on round 2's living
  sky: `WorldLight` follows the sky's keyframes, the cloud drift holds
  still once the world settles, and the build's level tag is painted.

- Pofu Hub (`design/hub/index.html`): the founder's phone-first surface,
  replacing the canvas atlas as his daily view (the atlas stays as a linked
  deep map). One column of cards with a sticky segmented control: Sorular
  (the lead's questions with options, pros, cons, cost, a recommendation,
  the founder's pick and a notes thread with dictation), Şu an (doing, done
  today, next, and the founder's ideas), Yol haritası (a status timeline)
  and Onay (review items with Beğendim, Yeniden and Not), plus a floating
  Fikir sheet. All content lives in the artifact `db`, so the lead updates
  it without republishing. `design/hub/tools/check.js` drives it with a mock
  `window.claude` at phone and desktop sizes in light and dark.
- `PofuWorld` round 2: Home per the app–game boundary (`WorldHome`, behind
  `FeatureFlags.worldHome`, off until the gate's dogfood week ends). Five
  chrome items in native glass: the wellbeing pill in the art's warm
  palette, the calm chip (its dot breathes while calm grows), the gear,
  the Today card (beads, guarded minutes in honest 15-minute steps) and one
  contextual primary that gives way to "Ada sensiz de çalışıyor." once the
  visit settles. The visit queue (§6.2: repair banner, care, collect, news,
  one affordable build, the weekly recap; at most three beats; nights and
  reopens within 15 minutes land settled) is a pure, tested type. The
  collect moment flies up to 24 seeds from the stations into a seed pill
  whose counter rolls and pops, with tap, tick and success haptics; the
  build moment pushes the camera in under a compact sheet, squashes the
  station, swaps its art inside the squash with puffs and sparkles, pops
  "Seviye n!", hops Pofu and the resident, and settles back. Both commit
  through `WorldClock.collect` and `WorldClock.build` first. Reduce Motion
  cross-fades camera moves (200 ms) and drops particles, squash and hops.
  A living sky follows the snapshot's clock (dawn, day, golden hour,
  night; dark mode is a night sky) with drifting cloud layers, a sun or
  moon glow and a cloud sea that keeps the bottom band calm. Stations
  whose art is a shared stand-in wear a small level badge.

- Rehearsal mode (Prova modu): the Screen Time product on the free build,
  with the system parts simulated in the app. It is the default in the
  `Pofu` scheme and a developer toggle, off by default, in `PofuLive`.
  Onboarding is gate v2's O1 to O8 with labelled stand-ins for Apple's
  Screen Time alert and app picker. A glass, draggable Prova panel reaches
  for Instagram, YouTube or TikTok: a replica of the shield, drawn by the
  new `ShieldExtensionCore` that the shield extensions now share, answers
  "Boş ver", the 3-minute quick check, "Pofu'yla aç" (a real local
  notification that opens Hop!), the breath past the daily hour, and the
  shield's return when a pass ends, through the real inbox, ingestion,
  event log and game. Time controls: "+15 dk kullanım", "1 saat ileri",
  "Gece/Sabah", "Sıfırla". Rehearsal mode keeps its own store and tags
  every event `simulated` (`EventSource` on `LoggedEvent`); the developer
  readout filters by source. The founder's install guide in Turkish is
  `docs/local/ucretsiz-kurulum.md`.

- Pofu Atlas, the content system: `content/` holds one YAML node per
  island, station (with its five levels), character and emotion, system,
  storyboard moment, theme, idea and image asset (270 nodes seeded from the
  game design, the app and game boundary, gate v2, the interaction spec,
  ADR-0015 to ADR-0018, the roadmap, the decision audit, the iteration plan
  and all four art manifests, plus ten lead-brainstorm ideas).
  `tools/content/validate.py` (run in CI's Python job; `content/` never
  triggers macOS) checks ids, links, art paths, manifest jobs and source
  anchors; `sync_assets.py` keeps asset nodes in step with promoted art;
  `build_atlas.py` renders `design/atlas/index.html`, a phone-first
  pannable board with a detail drawer and founder notes through the
  artifact runtime.

- Art batches 03 and 04 for Codex (open): `batch-03-home-island`
  completes Ayçiçeği for stages 1–5 (lily pond, workshop and windmill
  L1–L5, garden L3–L5, simit cart L2–L5, `mochi-v2` without Pofu's curl,
  Fındık, working poses, the large island about 40 % larger, the terrace,
  the east islet and bridge; 30 jobs) and `batch-04-sky` the living sky
  (five clouds, a sun glow, three distant islands, a tiling sea of clouds;
  10 jobs). Manifests can continue another batch's chains through
  `external` jobs, and `check_upload.py` reads pushed art back to catch
  the connector's silent 768 KB truncation; uploads stay under 600 KB.

- `PofuWorld`, Pofu's island in SwiftUI (iteration W2): `IslandScene`
  reads only a `WorldSnapshot` and stacks the batch 01 island plate (cut
  into four depth bands), the station vignettes at fixed slots (Mochi's
  çay ocağı L1 from batch 01, prototype stand-ins for the rest), Mochi,
  and Pofu's live companion view. One continuous camera through Home,
  Island and Map: a pinch scrubs the rail 1:1 with a rubber band at the
  ends and lands on the nearest framing with velocity projection; a
  double tap steps in; a drag peeks. A station tap focuses the camera and
  raises a stub sheet (42 % and large detents, the world live behind it);
  a resident tap shows a card with "Tezgâha git". The depth lens blurs by
  distance from an animated focus plane (a rack focus) by cross-fading
  pre-blurred variants, with contact shadows and parallax (device tilt
  behind a flag, off). Home shows the island behind
  `FeatureFlags.islandHome`, on in both builds; Hop!, the gate and
  onboarding are unchanged. `preblur.py app` bakes the art into the
  package's asset catalog. CI renders ten simulator screenshots (five
  states, light and dark, in Turkish) as the `world-screenshots` artifact.

- The game state is saved with the snapshot (schema version 2, versioned
  and tolerant: a store from before the game starts one, an unreadable game
  never costs the gate its state) and follows the gate's event log on every
  refresh, tick, log entry and Screen Time ingestion, plus Pofu's own
  foreground time (A20). The shield and Hop!'s skip screen show the live
  calm multiplier (gate v2 E9); the developer readout shows the world.

- The game model in `PofuCore/Game` (iteration W3, not yet wired into the
  app): `CareLedger` (Pofu's wellbeing, 5–100, never below 5, "sleeps it
  off"), `CalmAccrual` (×1.0–×2.0, quick checks halve, the 20-minute
  chain, resets), `StationLedger` and `ArchipelagoCatalog` (the 17
  designed station ladders, idle production × calm only while away and
  observed, seeds as world material, capped skip gifts, collection,
  builds, island arrivals), `BreathRules` (5 s, 10 s from the 4th
  over-limit open, capped at 10 s), and one deterministic facade,
  `WorldClock` with `GameState`, fed by the gate's event log. Measurement
  is honest: after a pass expires under the soft gate the time is
  unobserved until the next sign of life, and past 2 minutes in Pofu's
  foreground the world waits (A20). Swift Testing suites mirror the
  economy simulation's archetypes and check the guardrails as properties.

- App and game boundary ([app-game-boundary.md](docs/product/app-game-boundary.md)):
  opening intents, the finished visit, "Pofu'yla bir dakika" as a bounded
  substitute, and anti-compulsion guardrails with measurable targets.
- Interaction spec ([interaction-spec.md](docs/design/interaction-spec.md))
  v1 and v2: the detented camera, station and resident focus, glass morph
  menus, reactions, and depth as a lens (blur by distance from the focus
  plane) with parallax, haze, contact shadows, foreground bokeh, tilt-shift
  and a depth-map plate, plus internal touch prototypes.
- Gate v2 UX spec ([gate-v2.md](docs/product/ux/gate-v2.md)) and an
  internal day-1 prototype (`design/prototypes/gate-v2/`).
- CI classifies changed files on Linux first: the macOS build runs only
  when something outside `docs/`, `design/`, `tools/` and Markdown changed,
  and the Python tools get their own job.
- Batch 01 of the image pipeline is open for the eight-image W1 test on the
  founder's own ChatGPT plan, operated by Codex in the cloud.
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

- The image pipeline never drops a raw: `promote` keeps the unlocked
  take as `raw.webp` (lossless under 600 KB, otherwise WebP q95), and
  `check_upload.py` fails a master folder without one (AGENTS.md,
  Uploads).

- The Island framing is fitted, not fixed: the station row fills the width
  (×1.25 at 402 pt, was ×1.06) and the island is centred between the
  chrome bands; the neighbouring islands sit in an X close enough to peek
  in at the corners, and the Map frames all five larger (×0.56). A
  station focus nudges the camera so Pofu and the residents are whole or
  out of frame, never cut by the edge. Screenshots render still frames
  (no blinks, no cloud drift) and cover thirteen states.

- One quiet hour lifts Pofu out of the two lowest bands, from the floor
  too (ADR-0017): there, calm waking time heals 1/60 of the band's width a
  minute; from "tired" up it stays 5 an hour. The economy simulation uses
  the same rule.
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
([report](docs/archive/local-reports/2026-11-01-simulator-run.md)):

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
