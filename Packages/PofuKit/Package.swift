// swift-tools-version: 6.2

import PackageDescription

// PofuKit: the local package that holds everything below the app target.
// One package, several targets: module boundaries are enforced by the
// compiler, while versioning and tooling stay in one place. See
// docs/adr/0003-modular-architecture-and-screen-time-boundary.md and
// docs/adr/0009-xcodegen-and-package-layout.md.
let package = Package(
    name: "PofuKit",
    platforms: [
        .iOS(.v26),
        // macOS is a test host only: it lets `swift test` run on any Mac
        // (and on CI runners) without a simulator. The app ships on iOS.
        .macOS(.v15),
    ],
    products: [
        .library(name: "PofuCore", targets: ["PofuCore"]),
        .library(name: "PofuScreenTime", targets: ["PofuScreenTime"]),
        .library(name: "PofuDesignSystem", targets: ["PofuDesignSystem"]),
        .library(name: "PofuCompanion", targets: ["PofuCompanion"]),
    ],
    targets: [
        // Pure domain: economy, friction ladder, passes, metrics, vitality.
        // Foundation only, zero dependencies. Extensions may link it.
        .target(name: "PofuCore"),

        // The Screen Time boundary: protocol plus simulated implementation.
        // FamilyControls, ManagedSettings, and DeviceActivity are imported
        // only by the future live implementation.
        .target(name: "PofuScreenTime", dependencies: ["PofuCore"]),

        // Design tokens and small SwiftUI building blocks.
        .target(name: "PofuDesignSystem"),

        // The living companion: motion simulation (pure, testable).
        // See docs/design/companion-motion.md.
        .target(name: "PofuCompanion", dependencies: ["PofuDesignSystem"]),

        .testTarget(name: "PofuCoreTests", dependencies: ["PofuCore"]),
        .testTarget(name: "PofuScreenTimeTests", dependencies: ["PofuScreenTime", "PofuCore"]),
        .testTarget(name: "PofuCompanionTests", dependencies: ["PofuCompanion"]),
    ],
    swiftLanguageModes: [.v6]
)
