# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Product foundation: vision, competitive research, platform constraints,
  monetization research, naming exploration, roadmap.
- Architecture Decision Records 0001–0008.
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
