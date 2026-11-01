# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

### Fixed

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

- The repository is `ErenDenizK/pofu`; docs link there. The development
  guide covers the Metal Toolchain download and the simulator-only App
  Shortcut limitation.
