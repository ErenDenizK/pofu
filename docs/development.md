# Development Guide

How to build, run, and test Pofu. For how work enters the codebase
(branches, commits, pull requests), see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Repository layout

```
project.yml                 XcodeGen spec; generates Pofu.xcodeproj (not committed)
Config/                     App identity and signing xcconfig, plus your local overrides
App/                        iOS app target: SwiftUI entry point and screens
  Resources/                Asset catalog (app icon, accent color), String Catalog (en, tr)
Packages/PofuKit/           Local Swift package with every module below the app
  Sources/PofuCore/         Pure domain: economy, friction ladder, passes, vitality
  Sources/PofuScreenTime/   Screen Time boundary and its simulator
  Sources/PofuDesignSystem/ Design tokens: colors, spacing, type, motion
  Tests/                    Swift Testing suites
.github/workflows/ci.yml    CI: package tests and an app build on every PR
docs/                       Product, research, brand, ADRs, and this guide
```

Why it is shaped this way: [ADR-0003](adr/0003-modular-architecture-and-screen-time-boundary.md)
(modules) and [ADR-0009](adr/0009-xcodegen-and-package-layout.md)
(XcodeGen, one package).

## First-time setup on the Mac

1. **Install Xcode 26 or newer** from the Mac App Store, open it once, and
   let it install its components. Make sure the iOS 26 platform is
   installed (Xcode, Settings, Components).
2. **Point the command-line tools at it:**
   ```sh
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -version   # should print Xcode 26.x
   ```
3. **Install XcodeGen** with [Homebrew](https://brew.sh):
   ```sh
   brew install xcodegen
   ```
4. **Clone and generate the project:**
   ```sh
   git clone https://github.com/ErenDenizK/rot.git
   cd rot
   xcodegen generate
   open Pofu.xcodeproj
   ```

Run `xcodegen generate` again whenever you pull changes that add, move, or
remove files, or change `project.yml`. It is fast and safe; the project is
always rebuilt from the spec.

## Running the app

### In the simulator

Choose the **Pofu** scheme and any iPhone simulator, then Run (⌘R). No
signing setup is needed.

### On your iPhone with a free Apple account

Until the paid Apple Developer membership is active, the app runs on device
with a free Personal Team. Screen Time features are simulated in this mode
([ADR-0003](adr/0003-modular-architecture-and-screen-time-boundary.md)).

1. Xcode, Settings, Accounts: add your Apple ID. Select it and note the
   **Personal Team** ID (10 characters).
2. Create your local signing file, which git ignores:
   ```sh
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```
   Set `DEVELOPMENT_TEAM` to your team ID. Keep the development bundle
   identifier `com.erendenizk.pofu.dev` while you use the free team:
   identifiers registered by a Personal Team can stay reserved to it, and
   the final `com.erendenizk.pofu` must remain available for the paid team
   ([ADR-0007](adr/0007-product-name-pofu.md)).
3. Run `xcodegen generate` and open the project. Signing & Capabilities
   should show your team with "Automatically manage signing" on.
4. Connect the iPhone 17 by cable (or pair it over Wi-Fi in Window,
   Devices and Simulators), enable **Developer Mode** on the phone
   (Settings, Privacy & Security, Developer Mode) when iOS asks, and Run.
5. The first launch is blocked until you trust the developer on the phone:
   Settings, General, VPN & Device Management, your Apple ID, Trust.

`Config/Local.xcconfig` survives `xcodegen generate`; a team picked in the
Xcode UI does not, because the project is regenerated from the spec.

Limits of the free account:

- **Apps expire after 7 days.** Run from Xcode again to reinstall; app data
  survives as long as you do not delete the app.
- At most three apps signed with a free team can be installed at once.
- Capabilities that need the paid program (Family Controls, App Groups,
  push notifications) cannot be enabled yet.

Once the paid membership is active, put the paid team ID in
`Config/Local.xcconfig` and delete the `PRODUCT_BUNDLE_IDENTIFIER` line so
the final identifier applies.

## Running the tests

The fastest loop needs no simulator:

```sh
swift test --package-path Packages/PofuKit
```

To run a single suite or test, filter by name:

```sh
swift test --package-path Packages/PofuKit --filter "Spending"
```

In Xcode, open `Packages/PofuKit/Package.swift` directly to work on the
package alone, or press ⌘U in the Pofu project, whose scheme includes the
package test targets.

Tests use [Swift Testing](https://developer.apple.com/xcode/swift-testing/)
(`import Testing`, `@Test`, `#expect`). Domain logic never reads the
system clock: pass explicit dates and a fixed `Calendar`, as the existing
tests do.

`PofuCore` depends on Foundation only, so it also builds and tests on
Linux with a Swift 6.2 toolchain. `PofuDesignSystem` compiles to an empty
module where SwiftUI is unavailable.

## Continuous integration

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs on every
pull request and on every push to `main`, on a GitHub-hosted macOS 26
runner with Xcode 26 or newer:

1. `swift test --package-path Packages/PofuKit`
2. `brew install xcodegen` and `xcodegen generate`
3. `xcodebuild build` of the Pofu scheme for the iOS Simulator, with code
   signing disabled

A newer push to the same branch cancels the run in progress. A pull request
must be green before it merges.

## Conventions worth knowing

- **Swift 6 language mode with complete strict concurrency** everywhere.
- **Time is injected.** Domain code takes `Date` parameters; the app asks a
  `WallClock` for "now". Only `SystemWallClock` calls `Date()`.
- **Every economy constant lives in `EconomyConfiguration`.** The rules
  are documented in [economy.md](product/economy.md); change both together.
- **No Screen Time framework imports** outside the future
  `LiveScreenTimeService` (FamilyControls needs the paid membership).
- **User-facing strings** go through the String Catalog
  (`App/Resources/Localizable.xcstrings`) with English and natively
  written Turkish.
