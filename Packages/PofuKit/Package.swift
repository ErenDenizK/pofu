// swift-tools-version: 6.2

import PackageDescription

// PofuKit: the local package that holds everything below the app target.
// One package, several targets: module boundaries are enforced by the
// compiler, while versioning and tooling stay in one place. See
// docs/adr/0003-modular-architecture-and-screen-time-boundary.md and
// docs/adr/0009-xcodegen-and-package-layout.md.
let package = Package(
    name: "PofuKit",
    // PofuWorld's string catalog is in English with Turkish translations.
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        // macOS is a test host only: it lets `swift test` run on any Mac
        // (and on CI runners) without a simulator. The app ships on iOS.
        .macOS(.v15),
    ],
    products: [
        .library(name: "PofuCore", targets: ["PofuCore"]),
        .library(name: "PofuScreenTime", targets: ["PofuScreenTime"]),
        .library(name: "PofuPersistence", targets: ["PofuPersistence"]),
        .library(name: "PofuDesignSystem", targets: ["PofuDesignSystem"]),
        .library(name: "PofuCompanion", targets: ["PofuCompanion"]),
        .library(name: "PofuWorld", targets: ["PofuWorld"]),
        .library(name: "PofuGames", targets: ["PofuGames"]),
        .library(name: "PofuTuning", targets: ["PofuTuning"]),
        .library(name: "PofuSound", targets: ["PofuSound"]),
    ],
    targets: [
        // Pure domain: economy, friction ladder, passes, metrics, vitality.
        // Foundation only, zero dependencies. Extensions may link it.
        .target(name: "PofuCore"),

        // The Screen Time boundary: the protocol, the simulated
        // implementation, and the live one (iOS only), which is the only
        // code in the package that imports FamilyControls, ManagedSettings,
        // and DeviceActivity. The Screen Time extensions link it to put
        // shields back; it has no UI.
        .target(name: "PofuScreenTime", dependencies: ["PofuCore", "PofuPersistence"]),

        // File storage: an atomically written JSON snapshot and an
        // append-only event log, in the App Group container when the build
        // is entitled to one. Foundation only, so extensions may link it.
        .target(name: "PofuPersistence", dependencies: ["PofuCore"]),

        // Design tokens and small SwiftUI building blocks.
        .target(name: "PofuDesignSystem"),

        // The living companion: motion simulation (pure, testable), the
        // SwiftUI view, and its Metal deformation shader. Xcode compiles
        // the .metal resource into default.metallib; command-line builds
        // copy it, and the view falls back to a SwiftUI approximation.
        // See docs/design/companion-motion.md.
        .target(
            name: "PofuCompanion",
            dependencies: ["PofuDesignSystem"],
            resources: [.process("Resources")]
        ),

        // Pofu's island: the camera rail, the depth lens and the layout are
        // pure and tested on any platform; the SwiftUI scene (`IslandScene`)
        // is iOS only. The world art is an asset catalog that the pipeline
        // writes (design/prototypes/interactions/tools/preblur.py app);
        // Xcode compiles it, and command-line builds only copy it.
        .target(
            name: "PofuWorld",
            dependencies: ["PofuCore", "PofuDesignSystem", "PofuCompanion"],
            resources: [.process("Resources")]
        ),

        // The island minigames. The rules (board, pieces, rounds, yields,
        // the fair generator, feel math) are pure and tested on any
        // platform; the SpriteKit scene and its SwiftUI shell are iOS only.
        // Sprites are baked from the art masters by
        // design/games/bake_garden_art.py. See docs/product/minigames.md.
        .target(
            name: "PofuGames",
            dependencies: ["PofuDesignSystem", "PofuTuning"],
            resources: [.process("Resources")]
        ),

        // Every number that decides feel, as data: the bundled
        // `tuning.json` defaults and the live store the Ayar panel in
        // Rehearsal mode edits and exports. Foundation only.
        .target(
            name: "PofuTuning",
            resources: [.process("Resources")]
        ),

        // Pofu's tiny sounds: pre-rendered cues (tools/sound/render.py),
        // a pentatonic-safe cue API, rate limits and the mute. The policy
        // is pure and tested on any platform; the AVAudioEngine player is
        // behind canImport(AVFoundation). Only the app target links it:
        // the shield and the other extensions never play audio.
        .target(
            name: "PofuSound",
            dependencies: ["PofuGames", "PofuTuning"],
            resources: [.copy("Resources")],
        ),

        .testTarget(name: "PofuCoreTests", dependencies: ["PofuCore"]),
        .testTarget(name: "PofuScreenTimeTests", dependencies: ["PofuScreenTime", "PofuCore", "PofuPersistence"]),
        .testTarget(name: "PofuPersistenceTests", dependencies: ["PofuPersistence", "PofuCore"]),
        .testTarget(name: "PofuDesignSystemTests", dependencies: ["PofuDesignSystem"]),
        .testTarget(name: "PofuCompanionTests", dependencies: ["PofuCompanion"]),
        .testTarget(name: "PofuWorldTests", dependencies: ["PofuWorld", "PofuCore"]),
        .testTarget(name: "PofuGamesTests", dependencies: ["PofuGames", "PofuTuning"]),
        .testTarget(name: "PofuSoundTests", dependencies: ["PofuSound", "PofuGames", "PofuTuning"]),
        .testTarget(name: "PofuTuningTests", dependencies: ["PofuTuning"]),
    ],
    swiftLanguageModes: [.v6]
)
