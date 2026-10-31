# 0002. Native Swift and SwiftUI, iOS first

- **Status:** Accepted
- **Date:** 2026-10-31

## Context

The product's core capability, blocking apps and observing usage, exists only
through Apple's Screen Time frameworks, which require native app extensions
(monitor, shield configuration, shield action, report). The founder's
initial audience uses iPhones almost exclusively. The founder develops on an
M1 Pro MacBook Pro with Xcode and tests on an iPhone 17.

## Options considered

1. **Native Swift + SwiftUI.** First-class access to every framework,
   widgets, Live Activities, App Intents, and the newest design language. iOS
   only.
2. **React Native or Flutter.** A shared codebase for a future Android
   version, but every extension must still be written natively. Adds a bridge
   layer, a second toolchain, and an uncanny-valley feel for the platform-native
   polish we aim for.
3. **Kotlin Multiplatform for shared logic.** Keeps domain logic portable, but
   adds toolchain complexity before there is any Android demand.

## Decision

Build natively with **Swift 6 (strict concurrency)** and **SwiftUI** using the
Observation framework. Minimum deployment target: **iOS 26**, built with the
latest stable Xcode and SDK. This gives us one design language (Liquid Glass)
with no legacy fallback paths. iOS 26 supports iPhone 11 and later.

Domain logic (economy, streaks, companion state) is written as pure Swift with
no Apple-only dependencies, which keeps a future port cheap without paying the
cost of a cross-platform framework today.

## Consequences

- Best possible fidelity and performance on the platform that matters now.
- Android is a separate project if and when it is justified. The Android
  equivalents (UsageStatsManager, AccessibilityService) are architecturally
  different anyway and face strict Play Store policy review.
- Users on iOS 18 and earlier are excluded. This is an accepted cost given the
  young, iPhone-heavy target audience.
