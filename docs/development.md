# Development Guide

How to build, run, and test Pofu. For how work enters the codebase
(branches, commits, pull requests), see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Repository layout

```
project.yml                 XcodeGen spec; generates Pofu.xcodeproj (not committed)
Config/                     App identity and signing xcconfig, local overrides, extra Info.plist keys
  Entitlements/             Family Controls and App Group entitlements (PofuLive only)
App/                        iOS app target (Pofu and PofuLive): SwiftUI screens and the app model
  Intents/                  CheckInIntent (the soft gate) and the App Shortcuts provider
  Hop/                      The Hop! intervention: rungs, celebration, hand-off
  ScreenTime/               The live Screen Time gate: permission, picker, inbox, settings
  Home/, Earn/, Setup/, ... Pofu's room, the focus timer, the setup guide, settings, onboarding
  Resources/                Asset catalog, String Catalogs (en, tr) for the app and App Shortcuts
Extensions/                 Screen Time extensions, embedded only in PofuLive
  ShieldConfiguration/      The shield's look and Pofu's line
  ShieldAction/             The shield's buttons: a resist, or "Talk to Pofu"
  DeviceActivityMonitor/    Usage thresholds, and the shield's return when a pass ends
Packages/PofuKit/           Local Swift package with every module below the app
  Sources/PofuCore/         Pure domain: economy, friction ladder, passes, vitality, routing
  Sources/PofuScreenTime/   Screen Time boundary, its simulator, and LiveScreenTimeService (iOS)
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
([ADR-0003](adr/0003-modular-architecture-and-screen-time-boundary.md)):
see [Rehearsal mode](#rehearsal-mode-the-free-build). The founder's
step-by-step guide, in Turkish, is
[docs/local/ucretsiz-kurulum.md](local/ucretsiz-kurulum.md).

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
the final identifier applies, then switch to the Screen Time build:
[Membership day 1](#membership-day-1-the-screen-time-build).

## Membership day 1: the Screen Time build

The project has two app targets and two schemes, built from the same
`App/` sources:

| Scheme | Signs with | Entitlements | Extensions | Screen Time |
|---|---|---|---|---|
| **Pofu** (default) | A free Personal Team or the paid team | None | None | Simulated: [Rehearsal mode](#rehearsal-mode-the-free-build) |
| **PofuLive** | The paid team only | Family Controls, App Group `group.com.erendenizk.pofu` | Shield configuration, shield action, device activity monitor | On: permission plus picker, the shield, measured usage ([ADR-0013](adr/0013-zero-setup-default-gate.md)) |

`PofuLive` also sets the compilation condition `POFU_SCREEN_TIME_LIVE`, which
is the only switch in the code (`ScreenTimeGate.isLiveBuild`). Without it,
the app never touches FamilyControls, ManagedSettings, or DeviceActivity at
run time; the free build runs the gate in Rehearsal mode instead. A free Personal Team
cannot sign the Family Controls entitlement, which is why the entitlements
and extensions live only in `PofuLive` and never in the default scheme.

Development builds can use Family Controls as soon as the paid team exists;
only TestFlight and the App Store wait for Apple's **Family Controls
(Distribution)** approval. To switch on day 1:

1. `Config/Local.xcconfig`: set `DEVELOPMENT_TEAM` to the paid team ID and
   delete the `PRODUCT_BUNDLE_IDENTIFIER` line. (`PofuLive` ignores that
   line anyway: it always uses `POFU_BUNDLE_ID_BASE`, `com.erendenizk.pofu`,
   and derives the extensions' identifiers from it.)
2. `xcodegen generate` and open the project.
3. Choose the **PofuLive** scheme and the iPhone, then Run. Xcode's
   automatic signing registers the four identifiers, the App Group, and
   Family Controls (Development).

| Target | Bundle identifier |
|---|---|
| `PofuLive` | `com.erendenizk.pofu` |
| `PofuShieldConfiguration` | `com.erendenizk.pofu.ShieldConfiguration` |
| `PofuShieldAction` | `com.erendenizk.pofu.ShieldAction` |
| `PofuActivityMonitor` | `com.erendenizk.pofu.DeviceActivityMonitor` |

The full script, with the distribution request and a device checklist, is
[docs/local/membership-day-1.md](local/membership-day-1.md).

How the live gate works:

- **Onboarding** asks for Screen Time access (`AuthorizationCenter`,
  `.individual`) and shows the system app picker; the Shortcuts setup is a
  fallback and, in Settings, "Live Pofu (optional)".
- **The shield** (`ManagedSettingsStore` named `pofu.gate`) covers the
  picked apps. "Skip it" counts a resist; "Talk to Pofu" posts a local
  notification, because the shield cannot open Pofu. Tapping it (or opening
  Pofu within 10 minutes) starts Hop! for that app.
- **A pass from that Hop!** lifts the shield from that app until the pass
  ends. A one-off DeviceActivity monitor puts it back (on the interval's
  warning for passes under DeviceActivity's 15-minute minimum), and the app
  re-checks on every foreground.
- **Usage** is measured by DeviceActivity events at 15, 30, 45, and 60
  guarded minutes a day; 60 is the breath limit of
  [ADR-0015](adr/0015-care-over-currency.md).
- **Extensions and the app talk only through the App Group:** each
  extension writes small, versioned records (`ScreenTimeRecord`), one file
  each, to `Pofu/ScreenTimeInbox/`; the app ingests them into its state and
  event log on every foreground. The app writes the shield state
  (`Pofu/screen-time-gate.json`) for the monitor to rebuild shields.

## Rehearsal mode: the free build

Rehearsal mode (Prova modu) is the Screen Time product with the system
parts simulated inside the app, so the whole day-1 loop runs on a free
Personal Team. It is the default in the **Pofu** scheme and a developer
toggle (Settings, Developer), off by default, in **PofuLive**. The toggle
applies from the next launch.

- **Onboarding** is gate v2's (O1 to O8), with labelled stand-ins for
  Apple's Screen Time alert and app picker; notifications are real. The
  Shortcuts setup is reachable only from Settings.
- **The Prova panel** (glass, draggable, collapsible) reaches for
  Instagram, YouTube or TikTok. A reach shows a replica of the shield
  drawn by `ShieldExtensionCore`, the code the shield extensions run, in
  the extension's colors and icon (`Extensions/Shared`). Its buttons write
  the same inbox records, so ingestion, the event log and the game take
  them in exactly as live. "Pofu'yla aç" posts the real local
  notification, which opens Hop!; a pass hands off to a stand-in of the
  app, and the shield returns when the pass ends.
- **Time controls:** "+15 dk kullanım" crosses the usage thresholds
  through `SimulatedScreenTimeService`; "1 saat ileri" and "Gece/Sabah"
  move a saved clock offset as time away from Pofu (inside an app, only up
  to the moment the shield returns); "Sıfırla" starts over.
- **Honesty:** Rehearsal mode keeps its own store
  (`Application Support/Pofu-Rehearsal`), never the App Group, and tags
  every event it logs `simulated`. The developer readout filters the log
  by source and labels simulated numbers.
- **Ayar** (debug builds only): the Prova panel's "Ayar" row opens a
  tuning panel over the bottom half of the screen, with the world still
  visible above it. Every value is a key of `PofuTuning`'s
  `TuningValues`, whose defaults are the bundled `tuning.json`; sliders
  come from `TuningSpec`. Live today: the grade trims per time of day
  (with the hour pinnable to day, golden hour or night) and the HD-2D and
  depth-in-motion switches. The camera springs, depth strengths and
  Pofu's breath and blinks have previews in the panel and are read by the
  scene in a follow-up; haptics have a "Dene" button. "Dışa aktar"
  shares JSON with the changed keys and the complete values: commit
  `values` as the new `tuning.json`. Changes persist on the device until
  "Sıfırla".

## Use Pofu daily (free account)

> **Legacy path (2026-11-02).** The product targets Screen Time (ADR-0013;
> [membership day 1](local/membership-day-1.md)). The Shortcuts path gets
> no new features and is kept only for the free build with Rehearsal mode
> off. Setup guide v2 in the app replaces the old guided steps.

These Shortcuts steps apply with Rehearsal mode turned off (Settings,
Developer).

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

1. Open **Shortcuts** and tap **Automation** at the bottom. Do not use
   search: it finds actions, not the **App** trigger.
2. Tap **+** (or **New Automation**).
3. Scroll down and tap **App**.
4. Tap **Choose**, pick **Instagram**, then **Done**. Keep **Is Opened**
   selected.
5. Choose **Run Immediately** and turn **Notify When Run** off. Tap
   **Next**.
6. Tap **New Blank Automation**, then **Add Action**. Search **Hop**
   (only here, inside the action list) and tap **Hop in**.
7. Tap **App** in the action and pick the same app (Instagram). Tap
   **Done**.

Repeat for YouTube and TikTok. Each automation must pass its own app: the
app identity never comes from Shortcuts input, so a mismatch makes Pofu
guard the wrong app.

Then, in Pofu, tap **Test it: open Instagram** in the setup guide. Hop!
should appear within about a second; the guide then shows "It works".

The labels above are the English iOS 26 ones. With the phone in Turkish,
Shortcuts is **Kestirmeler**. The guide's Turkish labels live in
`App/Resources/ShortcutsLabels.xcstrings`; the ones no source confirmed
are marked `VERIFY ON DEVICE` there and in `SetupGuideView`. Device
screenshots named `SetupStep-<step>` in the asset catalog replace the
guide's drawn schematics. No documented URL opens Shortcuts on the
Automation tab, so the guide opens `shortcuts://`.

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
  needs the paid membership and the `PofuLive` scheme.
- **Foreground behavior is unproven on a device.** `CheckInIntent` asks
  the system to continue in the foreground (`IntentModes` with
  `.foreground(.dynamic)`), and the reopen during a pass is meant to stay
  in the background. If either misbehaves on iOS 26, that is a
  launch-blocking finding to report.
- **Vitality freezes on days without any check-in**, because Pofu cannot
  tell a quiet day from a deleted automation without DeviceActivity.
- **One notification: the pass-expiry reminder.** Pofu asks for
  notification permission at the first pass and reminds you when a pass
  ends. Nothing closes the app at expiry; if you stay in it, the time
  until you tap the reminder, open Pofu, or open a guarded app again is
  unobserved and earns no quiet seeds.
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
4. The same for the PofuLive scheme, which also builds the three Screen
   Time extensions. It proves they compile; signing them needs the paid
   team, and running them needs a device.
5. `xcodebuild test` of the PofuWorldScreenshots scheme in an iPhone 17
   class simulator, uploading the island's PNGs as the `world-screenshots`
   artifact.
6. The motion review: `MotionBeatTests` in the same scheme plays scripted
   beats live (Home idle, Home to Island and back, Collect, Build, the
   shield then Hop!) while `.github/scripts/record-beats.sh` records the
   simulator screen with `xcrun simctl io recordVideo`, one clip per
   beat, uploaded as the `motion-beats` artifact. The test and the
   recorder hand off through files in `MOTION_BEATS_DIR`; without it the
   test skips. CI machines drop frames, so judge choreography and timing
   from the clips, and smoothness only on a phone.

**When screenshots run.** The macOS build and tests run for any Swift or
app change; the screenshot render, the motion-beat recording and
`publish-screenshots` run only when `App/`, `PofuWorld`, `PofuCompanion`,
`PofuGames`, `PofuDesignSystem`, `PofuCore/Rehearsal`, `Tests/WorldScreenshots`,
`project.yml` or `.github/scripts` change, or when the PR has the `screens`
label (adding the label re-runs CI). Need pictures of a PR that skipped
them? Add the label.

**Screenshot branches.** After a green macOS job, `publish-screenshots`
converts those PNGs to JPEGs about 1000 px tall, adds a `contact.jpg`
grid, encodes the motion beats as phone-friendly MP4s in `beats/`
(H.264, 720 px wide, at most 10 s and 8 MB each, with a poster JPEG;
`.github/scripts/encode-beats.py`), writes a `README.md` index with a
playable link per clip, and force-pushes everything as a single-commit orphan branch named
`screenshots/<head branch, with / replaced by ->` (for example
`screenshots/feat-pofu-world`). Anyone who can run git can review them
with `git fetch origin screenshots/feat-pofu-world`, even where the
artifact host is unreachable. The branch is rewritten on every run and is
never merged; it does not run for pull requests from forks.

A newer push to the same branch cancels the run in progress. A pull request
must be green before it merges.

## The cloud agent environment

The lead agent runs on Linux without Xcode and cannot download a Swift
toolchain (swift.org is blocked), so the compile and test loop is: push,
then read the GitHub Actions results. PyPI and Ubuntu apt are reachable
(`bpy` from PyPI works for Blender); Chromium and Playwright are
preinstalled for rendering and inspecting prototypes. The repository has
been **public** since 2026-11-01, so Actions minutes are free; if it ever
goes private again, macOS bills at 10x (about 30 minutes a run) against
3,000 a month, so batch pushes. CI skips the macOS job when only `docs/`,
`design/`, `tools/`, `content/` or Markdown change, and treats Swift
warnings as errors. Public means: never commit secrets, team IDs, or
private data. The island's art is baked by
`design/prototypes/interactions/tools/preblur.py app`.

## Conventions worth knowing

- **Swift 6 language mode with complete strict concurrency** everywhere.
- **Time is injected.** Domain code takes `Date` parameters; the app asks a
  `WallClock` for "now". Only `SystemWallClock` calls `Date()`.
- **Every economy constant lives in `EconomyConfiguration`.** The rules
  are documented in [economy.md](product/economy.md); change both together.
- **No Screen Time framework imports** outside `LiveScreenTimeService.swift`
  in `PofuScreenTime`, the `App/ScreenTime/` views (the picker), and the
  extensions. Run-time use is gated by `ScreenTimeGate.isLiveBuild`.
- **Extensions stay small.** They link `PofuCore`, `PofuPersistence`, and
  `PofuScreenTime` (plus `PofuDesignSystem` for the shield's colors), never
  `PofuCompanion`, and never read the app's snapshot.
- **The soft gate's decisions are pure.** `CheckInIntent` only asks
  `CheckInRouter` (PofuCore) what to do and then does it; test routing
  changes there, not through the intent.
- **URL schemes live in one place.** `ProtectedApp.allQueriedSchemes`
  and `LSApplicationQueriesSchemes` in `Config/Info.plist` must match; a
  test fails when they drift.
- **User-facing strings** go through the String Catalog
  (`App/Resources/Localizable.xcstrings`) with English and natively
  written Turkish.
