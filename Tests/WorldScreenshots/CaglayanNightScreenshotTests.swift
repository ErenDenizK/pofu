import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Çağlayan's first two nights, painted (`caglayan-plate-full-s0-night`, `-s1-night`): the island
/// the day it arrives, lit, at the Island stop. `tools/plate/harmony_check.py --island caglayan
/// --reference s4-day` measures Damla in them.
final class CaglayanNightScreenshotTests: XCTestCase {
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
    func testRenderTheCaglayanEarlyNights() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for stage in 0...1 {
            try write(
                try await render(stage: stage, hour: 22.5, weather: .clear, expecting: "night", in: scene),
                name: "caglayan-plate-full-s\(stage)-night", to: folder
            )
        }
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
