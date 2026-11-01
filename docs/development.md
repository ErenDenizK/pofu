# Development Guide

How to build, run, and test Pofu. For how work enters the codebase
(branches, commits, pull requests), see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Repository layout

```
project.yml                 XcodeGen spec; generates Pofu.xcodeproj (not committed)
Config/                     App identity and signing xcconfig, local overrides, extra Info.plist keys
App/                        iOS app target: SwiftUI screens and the app model
  Intents/                  CheckInIntent (the soft gate) and the App Shortcuts provider
  Hop/                      The Hop! intervention: rungs, celebration, hand-off
  Home/, Earn/, Setup/, ... Pofu's room, the focus timer, the setup guide, settings, onboarding
  Resources/                Asset catalog, String Catalogs (en, tr) for the app and App Shortcuts
Packages/PofuKit/           Local Swift package with every module below the app
  Sources/PofuCore/         Pure domain: economy, friction ladder, passes, vitality, routing
  Sources/PofuScreenTime/   Screen Time boundary and its simulator
  Sources/PofuPersistence/  JSON snapshot and append-only event log (App Group or Application Support)
  Sources/PofuDesignSystem/ Design tokens (from design/tokens) and core components
  Sources/PofuCompanion/    The living companion: motion model, CompanionView, Metal shader
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
3. **Download the Metal Toolchain.** Xcode 26 ships it as a separate
   component, and `PofuCompanion`'s shader cannot compile without it (the
   build fails with "cannot execute tool 'metal' due to missing Metal
   Toolchain"). It is about 700 MB, once per Xcode install:
   ```sh
   xcodebuild -downloadComponent MetalToolchain
   ```
4. **Install XcodeGen** with [Homebrew](https://brew.sh):
   ```sh
   brew install xcodegen
   ```
5. **Clone and generate the project:**
   ```sh
   git clone https://github.com/ErenDenizK/pofu.git
   cd pofu
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

**Known limitation: App Shortcuts do not run in the simulator.** Running
Pofu's App Shortcut, or adding the **Hop in** action to a shortcut, fails
with "Couldn't find AppShortcutsProvider" (`linkd` rejects the simulator
build with `requiresValidBundle`). The same build works on a device, so
this is a simulator problem, not a product bug. Test the check-in and the
Hop! flow on the iPhone; everything else (onboarding, Home, the sheets)
works in the simulator. Pofu logs under the `com.erendenizk.pofu`
subsystem (categories `intent`, `hop`, `economy`, `persistence`,
`routing`); filter Console by it when diagnosing a device run.

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

## Use Pofu daily (free account)

The soft gate works without the paid membership: a Shortcuts automation
runs Pofu's **Hop in** action whenever a guarded app opens
([ADR-0008](adr/0008-hybrid-intervention-delivery.md)). This is the setup
for daily use on the iPhone.

### 1. Install the build

1. Follow [On your iPhone with a free Apple account](#on-your-iphone-with-a-free-apple-account)
   above: `Config/Local.xcconfig` with your team and
   `com.erendenizk.pofu.dev`, then `xcodegen generate`.
2. Choose the **Pofu** scheme, your iPhone as the destination, and Run.
   For daily use, prefer the Release configuration (Product, Scheme,
   Edit Scheme, Run, Build Configuration: Release): it is faster and
   closer to what ships.
3. Open Pofu once. Onboarding asks which apps pull you in, a name, and
   then shows the setup guide.

### 2. Create one automation per app

iOS does not let apps create automations, so this is done by hand, once
per app. Pofu's setup guide shows the same steps for the app you pick.

1. Open **Shortcuts** and tap **Automation** at the bottom.
2. Tap **+** (or **New Automation**).
3. Scroll down and tap **App**.
4. Tap **Choose**, pick **Instagram**, then **Done**. Keep **Is Opened**
   selected.
5. Choose **Run Immediately** and turn **Notify When Run** off. Tap
   **Next**.
6. Tap **New Blank Automation**, then **Add Action**. Search **Pofu** and
   tap **Hop in**.
7. Tap **App** in the action and pick the same app (Instagram). Tap
   **Done**.

Repeat for YouTube and TikTok. Each automation must pass its own app: the
app identity never comes from Shortcuts input, so a mismatch makes Pofu
guard the wrong app.

Then, in Pofu, tap **Test it: open Instagram** in the setup guide. Hop!
should appear within about a second; the guide then shows "It works".

The labels above are the English iOS 26 ones. With the phone in Turkish,
Shortcuts is **Kestirmeler**; the guide's Turkish wording follows the
user flows and has not been checked against a Turkish device yet.

### 3. Every 7 days: re-sign

Apps signed by a free Personal Team expire after **7 days**: Pofu stops
launching, and the automation then fails to run its action. Before day 7,
connect the iPhone and Run from Xcode again. The data and the automations
survive a reinstall over the existing app; deleting the app deletes its
data, and the automations then need their **Hop in** action re-added.

A calendar reminder every 6 days is the simplest way not to miss it.

### Known limitations of this slice

- **It is a soft gate.** Deleting or disabling the automation, or opening
  the app from the app switcher, gets past Pofu. The shield (hard gate)
  needs the paid membership.
- **Foreground behavior is unproven on a device.** `CheckInIntent` asks
  the system to continue in the foreground (`IntentModes` with
  `.foreground(.dynamic)`), and the reopen during a pass is meant to stay
  in the background. If either misbehaves on iOS 26, that is a
  launch-blocking finding to report.
- **Vitality freezes on days without any check-in**, because Pofu cannot
  tell a quiet day from a deleted automation without DeviceActivity.
- **No notifications yet.** Pofu does not tap your shoulder when a pass
  ends; it simply guards the app again.
- **Asking a friend is a placeholder.** The emergency pass (3 minutes,
  once a day) is the way through when no seeds are left.
- **URL schemes** used to hand back to an app are listed in
  `ProtectedApp`; if one fails, Pofu tries the app's universal link, and
  if that fails too it refunds the pass.
- **Storage** is Application Support until the paid team enables the App
  Group `group.com.erendenizk.pofu`; the files then move over once,
  automatically.

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

`PofuCore` and `PofuPersistence` depend on Foundation only, so they also
build and test on Linux with a Swift 6.2 toolchain. `PofuDesignSystem`
keeps only its color primitives where SwiftUI is unavailable; its tests
check them against `design/tokens/pofu-tokens.json`.

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
- **The soft gate's decisions are pure.** `CheckInIntent` only asks
  `CheckInRouter` (PofuCore) what to do and then does it; test routing
  changes there, not through the intent.
- **URL schemes live in one place.** `ProtectedApp.allQueriedSchemes`
  and `LSApplicationQueriesSchemes` in `Config/Info.plist` must match; a
  test fails when they drift.
- **User-facing strings** go through the String Catalog
  (`App/Resources/Localizable.xcstrings`) with English and natively
  written Turkish.
