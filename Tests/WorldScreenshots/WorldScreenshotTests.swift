import Observation
import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Renders Home and the island in the simulator and writes PNGs for review:
/// the founder reviews screenshots, never web prototypes.
///
/// The world is `IslandSamples.playedWeek()`, played minute by minute
/// through `WorldClock`; Collect and Build here call `WorldClock.collect`
/// and `WorldClock.build`. The scene is hosted in a real window of the Pofu
/// app, so sheets, native glass and Pofu's Metal shader draw as they do on
/// a phone. Still-frame rendering stops the clouds and Pofu's blinks, and
/// the build moment is frozen at a chosen instant, so runs are comparable.
///
/// The PNGs go to `WORLD_SCREENSHOTS_DIR` (CI passes it as
/// `TEST_RUNNER_WORLD_SCREENSHOTS_DIR`), or a temporary folder, and are
/// attached to the test result too.
final class WorldScreenshotTests: XCTestCase {
    private enum Shot: String, CaseIterable {
        case homeVisit = "01-home-visit"
        case homeSettled = "02-home-settled"
        case island = "03-island"
        case stationBuild = "04-station-build"
        case buildPop = "05-build-pop"
        case buildAfter = "06-build-after"
        case map = "07-map"
        case residentCard = "08-resident-card"
        /// The same Home with the crafted skin (clay and paper).
        case homeCrafted = "09-home-crafted"
        /// Home at the largest accessibility text size: the glance wraps.
        case homeAX3 = "10-home-ax3"
        /// The collect beat at the instant the paws press the cheeks.
        case collectPaws = "11-collect-paws"
        /// The collect beat as the seeds arc into the jar.
        case collectFlight = "12-collect-flight"

        var framing: WorldFraming {
            switch self {
            case .homeVisit, .homeSettled, .homeCrafted, .homeAX3, .collectPaws, .collectFlight: .home
            case .map: .map
            case .island, .stationBuild, .buildPop, .buildAfter, .residentCard: .island
            }
        }

        /// The shots also rendered in dark mode.
        static let dark: [Shot] = [.homeVisit, .homeSettled, .homeCrafted, .island, .stationBuild, .map]
    }

    @MainActor
    func testRenderTheWorld() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written: [String] = []

        let runs = Shot.allCases.map { ($0, UIUserInterfaceStyle.light) } + Shot.dark.map { ($0, UIUserInterfaceStyle.dark) }
        for (shot, style) in runs {
            let name = "\(shot.rawValue)-\(style == .dark ? "dark" : "light")"
            let world = ScreenshotWorld(game: IslandSamples.playedWeek())
            let island = IslandSceneModel(framing: shot.framing)
            let home = WorldHomeModel(now: { world.game.now })

            // The visit as the app would land it.
            switch shot {
            case .homeSettled:
                // After the visit: collected, and back within 15 minutes.
                world.game.collect()
                home.beginVisit(VisitQueue.plan(world.inputs(lastSettled: world.game.now.addingTimeInterval(-5 * 60))))
            case .stationBuild, .buildPop, .buildAfter:
                world.game.collect()
                home.beginVisit(VisitQueue.plan(world.inputs()))
            default:
                home.beginVisit(VisitQueue.plan(world.inputs()))
            }

            let host = UIHostingController(rootView: ScreenshotHome(
                world: world,
                island: island,
                home: home,
                skin: shot == .homeCrafted ? .crafted : .glass,
                typeSize: shot == .homeAX3 ? .accessibility3 : .large
            ))
            let window = UIWindow(windowScene: scene)
            window.overrideUserInterfaceStyle = style
            window.rootViewController = host
            window.windowLevel = .alert + 1
            window.makeKeyAndVisible()

            // Let the scene lay out (the camera needs the viewport).
            try await Task.sleep(for: .milliseconds(700))
            switch shot {
            case .homeVisit, .homeSettled, .homeCrafted, .homeAX3, .island, .map:
                try await Task.sleep(for: .milliseconds(500))
            case .collectPaws, .collectFlight:
                try await Task.sleep(for: .milliseconds(500))
                // The jar is where the seeds land, relative to Pofu's feet.
                let feet = island.screenPoint(of: IslandLayout.pofu)
                let jar = HomeObjectsLayout.jarCenter(
                    feet: MomentPoint(x: feet.x, y: feet.y),
                    screenWidth: Double(window.bounds.width)
                )
                home.collectSeeds(
                    jarBefore: world.game.snapshot.jar.units,
                    sources: [MomentPoint(x: feet.x, y: feet.y - 40)],
                    target: jar
                ) { world.game.collect() }
                // Paws pressed at 0.2 s; seeds mid-arc at 0.55 s.
                home.freeze(at: shot == .collectPaws ? 0.2 : 0.55)
                try await Task.sleep(for: .milliseconds(900))
            case .residentCard:
                island.focusResident(.mochi, animated: false)
                try await Task.sleep(for: .milliseconds(1600))
            case .stationBuild, .buildPop, .buildAfter:
                let station = world.buildableStation ?? .teaStall
                island.focusStation(station, animated: false)
                try await Task.sleep(for: .milliseconds(1400))
                if shot != .stationBuild {
                    let maxLevel = world.game.snapshot.stations.first { $0.id == station }?.maxLevel ?? 5
                    home.buildStation(station, maxLevel: maxLevel) { world.game.build($0) }
                    // At the pop: the swap has happened, puffs and sparkles
                    // are out, the tag is about to pop. After: the sheet is
                    // back at medium and the tag still shows.
                    home.freeze(at: shot == .buildPop ? 0.5 : 2.2)
                }
                try await Task.sleep(for: .milliseconds(1700))
            }

            let format = UIGraphicsImageRendererFormat()
            format.scale = window.traitCollection.displayScale
            format.opaque = true
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let data = try XCTUnwrap(image.pngData())
            try data.write(to: folder.appendingPathComponent("\(name).png"))
            written.append("\(name): \(Int(window.bounds.width))×\(Int(window.bounds.height)) pt @\(Int(format.scale))x")

            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)

            // Close the sheet without animation and drop the window.
            if host.presentedViewController != nil {
                host.dismiss(animated: false)
            }
            window.isHidden = true
            window.rootViewController = nil
            try await Task.sleep(for: .milliseconds(150))
        }

        let summary = written.joined(separator: "\n")
        try summary.write(to: folder.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
        print("World screenshots in \(folder.path):\n\(summary)")
        XCTAssertEqual(written.count, runs.count)
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}

/// The sample game, observable so Collect and Build redraw the world.
@MainActor
@Observable
private final class ScreenshotWorld {
    var game: SampleGame

    init(game: SampleGame) {
        self.game = game
    }

    func inputs(lastSettled: Date? = nil) -> VisitInputs {
        VisitInputs(now: game.now, world: game.snapshot, lastSettled: lastSettled, calendar: .current)
    }

    /// The cheapest level the jar covers now.
    var buildableStation: StationID? {
        let world = game.snapshot
        if case .build(let station, _)? = VisitQueue.affordableBuild(in: world, seeds: world.jar) {
            return station
        }
        return nil
    }
}

/// Home as the app shows it, in still-frame mode.
private struct ScreenshotHome: View {
    let world: ScreenshotWorld
    let island: IslandSceneModel
    let home: WorldHomeModel
    var skin: PofuSkin = .glass
    var typeSize: DynamicTypeSize = .large

    var body: some View {
        WorldHome(
            world: world.game.snapshot,
            today: world.game.today,
            scene: island,
            home: home,
            actions: WorldHome.Actions(
                collect: { world.game.collect() },
                build: { world.game.build($0) },
                openSettings: {},
                repair: {}
            )
        )
        .environment(\.worldStillFrame, true)
        .environment(\.pofuSkin, skin)
        .dynamicTypeSize(typeSize)
    }
}
