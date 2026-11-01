# 0003. Modular architecture and a Screen Time boundary

- **Status:** Accepted
- **Date:** 2026-10-31
- **Amended by:** [0007](0007-product-name-pofu.md) (module prefix `Rot` becomes `Pofu`); see also the 2026-11-01 note at the end

## Context

- Screen Time code cannot run on device until the paid developer membership
  is active, and it never runs reliably in the simulator.
- Extensions run under tight memory and time budgets and must not link the
  app's UI or rendering stack.
- The economy and companion logic is the heart of the product and must be
  exhaustively testable, including from the Linux-based agent environment,
  which has no Xcode.

## Decision

Organize the code as an Xcode app project plus local Swift packages:

| Module | Responsibility | Depends on |
|---|---|---|
| `RotCore` | Pure domain: economy, pricing, friction ladder, streaks, companion state machine, event log types. No Apple-only imports. | Foundation only |
| `RotScreenTime` | `ScreenTimeService` protocol with two implementations: `LiveScreenTimeService` (FamilyControls, ManagedSettings, DeviceActivity) and `SimulatedScreenTimeService` (deterministic, scriptable). | `RotCore` |
| `RotPersistence` | App Group storage: shared state and the append-only event log written by extensions and ingested by the app. | `RotCore` |
| `RotDesignSystem` | Tokens (color, type, spacing, motion, haptics), components. | SwiftUI |
| `RotCompanion` | Companion rendering and animation. | `RotCore`, `RotDesignSystem` |
| Feature modules | Onboarding, Home, Block, Earn, Store, Friends, Settings. | All of the above |

Extensions link only `RotCore` and `RotPersistence`.

**Extension-to-app communication** uses an append-only event log in the App
Group container: extensions append small, immutable events
(`thresholdReached`, `shieldShown`, `unlockRequested`), and the app ingests
them on launch and on background refresh. Extensions never read or write the
app's main database.

The simulated Screen Time service is selected by a launch argument and is the
default on free provisioning, so the entire app is usable on device before the
membership is active.

## Consequences

- Product work proceeds at full speed during the pre-membership window.
- `RotCore` gets fast unit tests on Linux and macOS; CI covers it on every PR.
- The boundary adds a thin layer of indirection, which is a fair price for
  testability and extension safety.

## Note (2026-11-01): the live implementation

Built for membership day 1 (`feat/screen-time-gate`). Two refinements,
neither a change of direction:

- Extensions link `PofuScreenTime` as well as `PofuCore` and
  `PofuPersistence`, because the monitor rebuilds shields with the same
  code the app uses (`LiveShieldEnforcer`). It has no UI. The shield
  configuration extension also links `PofuDesignSystem` for its colors.
  None links `PofuCompanion`.
- The simulated service is not selected at run time. The live service
  exists only in the `PofuLive` build (compilation condition
  `POFU_SCREEN_TIME_LIVE`), because a free team cannot sign the
  entitlement at all; the default build runs the soft gate alone.
