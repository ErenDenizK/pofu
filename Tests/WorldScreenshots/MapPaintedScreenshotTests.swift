import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The Map and a flight in the painted world (R4 and R5 of docs/research/route-2026-11-12-codex-pause.md):
/// Home's painted sky of the hour behind them, Home cut from its level's own painting, Koke and Çağlayan
/// as their stage art with a name, no sprite isle. All frames at the simulator's full device
/// resolution, never reduced:
///
/// - `map-plate-l2-day`: day 2 of the demo, Home alone at IL2;
/// - `map-plate-l5-day`: IL5 by day, the harbor open, Koke arrived at stage 1;
/// - `map-plate-l7-night`: IL7 at bedtime, Koke healed, Çağlayan healed;
/// - `flight-home-koke-mid`: halfway from Home's Island stop to Koke's, over the sea at the apex.
final class MapPaintedScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func world(
        level: Int, tendedDays: Int, levels: [StationID: Int], islands: [IslandID],
        koke: WonderStatus = WonderStatus(), caglayan: WonderStatus = WonderStatus(), bedtime: Bool = false
    ) -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: clock, tendedDays: tendedDays, levels: levels,
            jar: IslandSamples.midWeekJar, islands: islands, islandLevel: level, isBedtime: bedtime
        )
        world.koke = koke
        world.caglayan = caglayan
        return world
    }

    @MainActor
    func testRenderThePaintedMap() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let l2 = world(level: 2, tendedDays: 2, levels: [.garden: 1, .teaStall: 1], islands: [.home])
        try write(try await render(l2, model: IslandSceneModel(framing: .map), hour: 12, in: scene), name: "map-plate-l2-day", to: folder)

        let l5 = world(
            level: 5, tendedDays: 9, levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1], islands: [.home, .harbor],
            koke: WonderStatus(phase: .arrived, stage: 1, canAdvance: true)
        )
        try write(try await render(l5, model: IslandSceneModel(framing: .map), hour: 12, in: scene), name: "map-plate-l5-day", to: folder)

        let l7 = world(
            level: 7, tendedDays: 16, levels: [.garden: 4, .teaStall: 3, .pond: 3, .workshop: 2, .windmill: 1], islands: [.home, .harbor],
            koke: WonderStatus(phase: .arrived, stage: 4), caglayan: WonderStatus(phase: .arrived, stage: 4), bedtime: true
        )
        try write(try await render(l7, model: IslandSceneModel(framing: .map), hour: 23, in: scene), name: "map-plate-l7-night", to: folder)

        let flight = IslandSceneModel(framing: .island)
        flight.holdFlight(to: .koke, progress: 0.5)
        try write(try await render(l5, model: flight, hour: 12, in: scene), name: "flight-home-koke-mid", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ world: WorldSnapshot, model: IslandSceneModel, hour: Double, in scene: UIWindowScene) async throws -> UIImage {
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        let view = IslandScene(world: world, model: model)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 5
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1400))
        XCTAssertNotNil(model.homePlate, "Home is its painting on the Map")
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
