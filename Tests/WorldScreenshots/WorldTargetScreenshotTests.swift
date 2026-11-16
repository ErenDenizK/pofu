import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The three frames of the world-presentation spec (docs/design/world-presentation-build-spec.md,
/// WP3) at 12:00 in clear weather, island level 10, every station at level 5, Koke and
/// Çağlayan arrived: the frames WP1's CI step measures against the picked targets
/// (`tools/proof/composition_check.py`, rules C1 to C6). They show today's camera, so they are
/// the starting gap, not the goal.
///
/// - `world-target-map-1200`: the Map framing;
/// - `world-target-mid-1200`: the Home framing with its chrome;
/// - `world-target-near-1200`: near at rest on Pofu (ADR-0027).
final class WorldTargetScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func world() -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: nil,
            tendedDays: 60,
            levels: [.garden: 5, .teaStall: 5, .pond: 5, .windmill: 5, .workshop: 5, .bagelCart: 5, .pier: 5, .lighthouse: 5],
            jar: Energy(214),
            islands: [.home, .harbor],
            islandLevel: 10,
            wellbeing: 84
        )
        world.koke = WonderStatus(phase: .arrived, stage: 1)
        world.caglayan = WonderStatus(phase: .arrived, stage: 1)
        return world
    }

    private var noon: WorldLook {
        var look = WorldLook(hourOverride: 12)
        look.weatherOverride = .clear
        return look
    }

    @MainActor
    func testRenderTheWorldTargets() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let snapshot = world()

        // Map: the scene alone, as the Map shows it.
        let map = IslandSceneModel(framing: .map)
        let mapView = IslandScene(world: snapshot, model: map)
            .environment(\.worldLook, noon)
            .environment(\.worldStillFrame, true)
        try write(try await render(AnyView(mapView), scene: scene, settle: 1400, before: { XCTAssertNotNil(map.homePlate) }), name: "world-target-map-1200", to: folder)

        // Mid: Home with the real chrome.
        let mid = IslandSceneModel(framing: .mid)
        try write(try await render(homeView(snapshot, mid), scene: scene, settle: 2100, before: {}), name: "world-target-mid-1200", to: folder)

        // Near: rest on Pofu (ADR-0027), his feet at 0.60 of the height; the back control alone.
        let near = IslandSceneModel(framing: .mid)
        try write(try await render(homeView(snapshot, near), scene: scene, settle: 2100, after: 2100, before: { near.holdNearRest() }), name: "world-target-near-1200", to: folder)
    }

    @MainActor
    private func homeView(_ snapshot: WorldSnapshot, _ island: IslandSceneModel) -> AnyView {
        let clock = self.clock
        let home = WorldHomeModel(now: { clock }, schedulesCues: false)
        let inputs = VisitInputs(now: clock, world: snapshot, lastSettled: clock.addingTimeInterval(-5 * 60), calendar: .current)
        home.beginVisit(VisitQueue.plan(inputs))
        home.acknowledgeCurrentBeat()
        return AnyView(
            WorldHome(
                world: snapshot,
                today: TodaySummary(beads: [false, true, false, true], guardedMinutes: 22, dailyHourMinutes: 60),
                scene: island,
                home: home,
                actions: WorldHome.Actions(collect: { nil }, build: { _ in nil }, openSettings: {}, repair: {}, openToday: {})
            )
            .environment(\.worldLook, noon)
            .environment(\.worldStillFrame, true)
        )
    }

    /// Draws `view` in a window of the host app, waits `settle` ms (the last 900 after `before`,
    /// which holds the camera), and returns the frame at the device's own resolution.
    @MainActor
    /// `after`: the wait from `before` to the capture. The near frame waits as long as the other near frames
    /// settle (2.1 s): its first frames at near draw the lens's blur levels, slow on CI's GPU-less simulator, and at
    /// 0.9 s the chrome's fade had not run yet (the zoom is the same as main's: s 4.5, chrome opacity 0).
    private func render(_ view: AnyView, scene: UIWindowScene, settle: Int, after: Int = 900, before: () -> Void) async throws -> UIImage {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 5
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(max(settle - 900, 600)))
        before()
        try await Task.sleep(for: .milliseconds(after))
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.traitCollection.displayScale
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        try await Task.sleep(for: .milliseconds(150))
        return image
    }

    private func write(_ image: UIImage, name: String, to folder: URL) throws {
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
