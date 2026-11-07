import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Concept match shots (docs/research/concept-match.md): Home in the light
/// and weather of each single-image home concept, so every run can be laid
/// beside its concept. `tools/assets/concept_match.py` (run by CI's publish
/// job) puts each pair on `concept-match.jpg` with its numbers.
///
/// - `concept-<state>-home`: the Home framing;
/// - `concept-<state>-whole`: the whole-island shot, the concepts' framing.
///
/// States: `day` (12:00, clear), `golden` (18:30, clear), `night` (22:30,
/// clear), `rain` (12:00, light rain) and `mist` (08:00, mist).
final class ConceptMatchScreenshotTests: XCTestCase {
    private let states: [(id: String, hour: Double, weather: WeatherConditions)] = [
        ("day", 12, .clear),
        ("golden", 18.5, .clear),
        ("night", 22.5, .clear),
        ("rain", 12, WeatherConditions(weather: .lightRain)),
        ("mist", 8, WeatherConditions(weather: .mist)),
    ]

    @MainActor
    func testRenderTheConceptMatchStates() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for state in states {
            for whole in [false, true] {
                let image = try await render(hour: state.hour, weather: state.weather, whole: whole, in: scene)
                try write(image, name: "concept-\(state.id)-\(whole ? "whole" : "home")", to: folder)
            }
        }
    }

    // MARK: - Rendering

    @MainActor
    private func render(hour: Double, weather: WeatherConditions, whole: Bool, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: .home)
        if whole { model.holdEstablishingShot() }
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = weather
        let view = IslandScene(world: IslandSamples.grownIsland(wellbeing: 78), model: model)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1400))
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
