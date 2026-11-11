import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Çağlayan drawn from its painted plates (ADR-0022): the island at the Island stop in every
/// state the package paints, at the simulator's full device resolution (CI keeps the PNGs as
/// written, `caglayan-plate-full-` in the publish job; `tools/plate/harmony_check.py --island
/// caglayan` measures Damla in them):
///
/// - `caglayan-plate-full-s0-day` to `-s4-day`: the five story stages by day;
/// - `caglayan-plate-full-s2-night` and `-s3-night`: the painted nights;
/// - `caglayan-plate-full-s4-golden` and `-s4-rain`: the healed island at golden hour and in rain;
/// - `caglayan-plate-sprite-s4-night`: a state no plate paints, still the sprite island.
final class CaglayanPlateScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func world(stage: Int) -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: clock, tendedDays: 16, levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1],
            jar: IslandSamples.midWeekJar, islands: [.home, .harbor], islandLevel: 5, isBedtime: false
        )
        world.koke = WonderStatus(phase: .arrived, stage: 4)
        world.caglayan = WonderStatus(phase: .arrived, stage: stage, canAdvance: false)
        return world
    }

    @MainActor
    func testRenderTheCaglayanPlates() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let rain = WeatherConditions(weather: .lightRain)
        let states: [(name: String, stage: Int, hour: Double, weather: WeatherConditions, light: String?)] = [
            ("s0-day", 0, 12, .clear, "day"), ("s1-day", 1, 12, .clear, "day"), ("s2-day", 2, 12, .clear, "day"),
            ("s3-day", 3, 12, .clear, "day"), ("s4-day", 4, 12, .clear, "day"),
            ("s2-night", 2, 22.5, .clear, "night"), ("s3-night", 3, 22.5, .clear, "night"),
            ("s4-golden", 4, 18, .clear, "golden"), ("s4-rain", 4, 12, rain, "rain"),
        ]
        for state in states {
            try write(
                try await render(stage: state.stage, hour: state.hour, weather: state.weather, expecting: state.light, in: scene),
                name: "caglayan-plate-full-\(state.name)", to: folder
            )
        }
        // No plate paints the healed island at night: the sprite island stays.
        try write(
            try await render(stage: 4, hour: 22.5, weather: .clear, expecting: nil, in: scene),
            name: "caglayan-plate-sprite-s4-night", to: folder
        )
    }

    @MainActor
    private func render(stage: Int, hour: Double, weather: WeatherConditions, expecting light: String?, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: .island)
        model.holdIsle(.caglayan)
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = weather
        let view = IslandScene(world: world(stage: stage), model: model)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 4
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1600))
        XCTAssertEqual(model.caglayanPlate?.light, light, "stage \(stage) at \(hour): the painted state")
        if light != nil {
            XCTAssertEqual(model.caglayanPlate?.stage, stage)
        }
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
