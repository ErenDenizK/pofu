import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The approved art that reached the app (docs/design/asset-integration.md), on screen: the island
/// with every station built as far as its art goes, by day and at bedtime (the glows, the residents'
/// poses), the map with the harbor built (the cart, the pier, the lighthouse, their dressing, Simit's
/// poses), and the build pop (Mochi startled).
///
/// PNGs go to `WORLD_SCREENSHOTS_DIR` like the other shots, named `integration-*`.
final class IntegrationScreenshotTests: XCTestCase {
    private struct Shot {
        var id: String
        var framing: WorldFraming
        var hour: Double
        var bedtime = false
        var focus: StationID?
    }

    private let shots: [Shot] = [
        Shot(id: "integration-island-day", framing: .island, hour: 12),
        Shot(id: "integration-island-night", framing: .island, hour: 22, bedtime: true),
        Shot(id: "integration-home-night", framing: .home, hour: 22, bedtime: true),
        Shot(id: "integration-map-day", framing: .map, hour: 12),
        Shot(id: "integration-map-night", framing: .map, hour: 22, bedtime: true),
        Shot(id: "integration-windmill-5", framing: .island, hour: 12, focus: .windmill),
        Shot(id: "integration-pond-5-night", framing: .island, hour: 22, bedtime: true, focus: .pond),
    ]

    @MainActor
    func testRenderTheIntegratedArt() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var written = 0
        for shot in shots {
            let model = IslandSceneModel(framing: shot.framing)
            if let station = shot.focus {
                model.focusStation(station, animated: false)
            }
            let view = IslandScene(world: IslandSamples.fullArt(isBedtime: shot.bedtime), model: model) {
                EmptyView()
            }
            .environment(\.worldStillFrame, true)
            .environment(\.worldLook, WorldLook(hourOverride: shot.hour))

            let window = UIWindow(windowScene: scene)
            window.overrideUserInterfaceStyle = .light
            window.rootViewController = UIHostingController(rootView: view)
            window.windowLevel = .alert + 3
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(shot.focus == nil ? 1500 : 2200))

            let format = UIGraphicsImageRendererFormat()
            format.scale = window.traitCollection.displayScale
            format.opaque = true
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let data = try XCTUnwrap(image.pngData())
            try data.write(to: folder.appendingPathComponent("\(shot.id).png"))
            let attachment = XCTAttachment(image: image)
            attachment.name = shot.id
            attachment.lifetime = .keepAlways
            add(attachment)
            written += 1

            window.isHidden = true
            window.rootViewController = nil
            try await Task.sleep(for: .milliseconds(150))
        }
        XCTAssertEqual(written, shots.count)
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("integration-screenshots", isDirectory: true)
    }
}
