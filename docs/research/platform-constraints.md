# Platform Constraints: Apple Screen Time APIs

_Last updated: 2026-10-31._

The whole product depends on Apple's Screen Time frameworks. They are
powerful but heavily sandboxed for privacy, and several product ideas that
look trivial on a whiteboard are impossible or need non-obvious workarounds.
This document is the reference for what we can and cannot do.

## The frameworks

| Framework | What it gives us | Where it runs |
|---|---|---|
| **FamilyControls** | Authorization (`AuthorizationCenter`, `.individual` mode for self-management) and the `FamilyActivityPicker`, which returns **opaque tokens** for the apps, categories, and web domains the user selects. | Main app |
| **ManagedSettings** | Applying restrictions: shielding apps, categories, and web domains through `ManagedSettingsStore`. | Main app and extensions |
| **DeviceActivity** | Scheduling monitoring windows and usage-threshold events (`DeviceActivityCenter`). | Main app schedules; extension receives callbacks |
| **DeviceActivityMonitor** (extension) | Callbacks such as `intervalDidStart`, `intervalDidEnd`, and `eventDidReachThreshold`, run by the system even when our app is not running. | Extension |
| **ShieldConfiguration** (extension) | Customizing the shield shown over a blocked app: icon, title, subtitle, colors, button labels. | Extension |
| **ShieldAction** (extension) | Handling taps on the shield's primary and secondary buttons. | Extension |
| **DeviceActivityReport** (extension) | Rendering usage data (screen time, pickups, per-app usage) as SwiftUI views embedded in our app. | Extension, sandboxed |

## Hard constraints and our workarounds

### 1. Free developer accounts cannot use Family Controls

Personal Teams (free Apple accounts) do not support the Family Controls
capability, not even the development variant. A paid Apple Developer Program
membership is required to run any blocking code on a device.

**Impact:** until the membership is active, nothing touching Screen Time can
run on device.

**Workaround:** all Screen Time access sits behind a protocol boundary with a
simulated implementation (ADR-0003). Everything else (design system,
companion, economy, onboarding, activities, streaks) is built and tested on
device with the free account in the meantime.

### 2. Distribution requires a separately approved entitlement, per target

Development builds can use Family Controls immediately with a paid account.
Shipping to TestFlight or the App Store requires the **Family Controls
(Distribution)** entitlement, which Apple reviews manually. Developer reports
describe waits from about three weeks to well over a month, and approval is
needed **for every bundle identifier**: the app and each extension. A
partially approved set makes the build unsubmittable.

**Mitigation:** request distribution approval for every target on the first
day of the paid membership, long before we need it. Finalize bundle
identifiers before requesting.

### 3. App identities are opaque

The picker returns `ApplicationToken`s, not bundle IDs or names. We cannot
know that a token means "Instagram" in code. We can only render it with
SwiftUI's `Label(token)`, which the system resolves for display.

**Impact:** no per-app logic such as "Instagram costs more than YouTube"
unless the user assigns apps to groups we define. Presets like "Social" must
be built from the user's own selection or from system categories.

### 4. The report extension cannot export data

The `DeviceActivityReport` extension can read rich usage data (total screen
time, pickups, per-app durations), but it is sandboxed: it cannot write to
shared containers or communicate with the app. Its output is display-only.

**Impact:** a "companion health" score cannot be computed from report data.

**Workaround:** compute health from **threshold events** instead. The app
schedules a ladder of `DeviceActivityEvent`s on the user's distracting
selection (for example every 5 minutes of cumulative use). The monitor
extension receives `eventDidReachThreshold`, records the step in the shared
App Group, and the app derives the companion's state from it. Display-only
statistics (pickups, top apps) are rendered inside the report extension and
embedded in our UI, which is exactly how the reference apps show them.

### 5. The shield cannot open our app

The shield UI is a fixed template (icon, title, subtitle, up to two buttons)
with no custom SwiftUI, no animation, and no text input. `ShieldAction` can
only respond with close, defer, or no-op. It cannot launch the app.

**Workaround:** when the user taps "Spend energy" or "Ask a friend" on the
shield, the action extension posts a local notification. Tapping it deep-links
into the corresponding flow in the main app. This is the established pattern
in the category. The shield's copy and icon can still change dynamically per
friction rung, since the configuration extension reads state from the App
Group.

### 6. Extensions run on tight budgets

Monitor and shield extensions run with very small memory limits (reported at
a few megabytes) and short execution windows. They must not load the
companion's rendering stack, large assets, or heavy dependencies.

**Impact:** extensions depend only on a minimal shared core module (ADR-0003).

### 7. The simulator is not a test environment for blocking

Authorization and shielding behave unreliably or not at all in the simulator.
Every Screen Time feature must be verified on a physical device. Developer
forums also report regressions in recent iOS 26 point releases (report
extension not launching on 26.4; `intervalDidStart` not firing on 26.3.1). We
track the current iOS release on device.

### 8. Free provisioning has short lifetimes

Apps signed with a free account expire after seven days and are limited in
number. This is acceptable for the pre-membership window but not for friends'
testing, which waits for TestFlight.

## Verification capabilities (for ADR-0004)

| Signal | Source | Friction for the user | Availability |
|---|---|---|---|
| Steps, walking and running distance | HealthKit | None (passive) | Any iPhone; Apple Watch improves accuracy |
| Workouts | HealthKit | None if logged by Watch or another app | Broad |
| Mindful minutes, sleep | HealthKit | None (passive) | Broad |
| Focus session completed without opening blocked apps | DeviceActivity + ManagedSettings | None; the session itself is the proof | Paid account required |
| Exercise reps (push-ups, squats) | Vision body-pose detection, on-device | Medium: phone placement and framing | Any recent iPhone |
| Study, chores, music practice | Timer (self-reported) | Low | Always |

## Sources

- [Family Controls on Personal Teams (Apple Developer Forums)](https://developer.apple.com/forums/thread/852204)
- [Testing Family Controls without a paid account (Apple Developer Forums)](https://developer.apple.com/forums/thread/803362)
- [Distribution entitlement wait times (Apple Developer Forums)](https://developer.apple.com/forums/thread/818553)
- [Distribution timeline report (Apple Developer Forums)](https://developer.apple.com/forums/thread/820811)
- [Entitlement not applied to extensions (Apple Developer Forums)](https://developer.apple.com/forums/thread/819573)
- [The Device Activity Report extension sandbox (Medium)](https://letvar.medium.com/time-after-screen-time-part-2-the-device-activity-report-extension-10eeeb595fbd)
- [Report extension not launching on iOS 26.4 (Apple Developer Forums)](https://developer.apple.com/forums/thread/821625)
- [`intervalDidStart` not called on iOS 26.3.1 (Apple Developer Forums)](https://developer.apple.com/forums/thread/819224)
- [react-native-device-activity, a reference implementation of the shield and notification patterns](https://github.com/kingstinct/react-native-device-activity)
