import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The payoff at the door (ui-v3 section 3b): seals pressed onto the earth
/// beside Pofu's round door, projected from H1. Day at 0.3 s, 1.0 s and 2.0 s
/// with three new seals; night at rest with five.
final class PayoffScreenshotTests: XCTestCase {
    @MainActor
    func testRenderThePayoffAtTheDoor() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let start = Date()
        for time in [0.3, 1.0, 2.0] {
            // Two earlier seals are already there; three are new.
            var tally = ResistSealTally(total: 5, fresh: 3, start: start)
            tally.pinnedTime = time
            let image = try await render(hour: 12, tally: tally, in: scene)
            try write(image, name: "payoff-door-day-\(Int(time * 10))")
        }
        let night = try await render(hour: 22, tally: ResistSealTally(total: 5), in: scene)
        try write(night, name: "payoff-door-night-rest-5")
        let many = try await render(hour: 12, tally: ResistSealTally(total: 11), in: scene)
        try write(many, name: "payoff-door-day-rest-11")
    }

    @MainActor
    private func render(hour: Double, tally: ResistSealTally, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: .home)
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        let view = IslandScene(world: IslandSamples.grownIsland(wellbeing: 78), model: model)
            .environment(\.worldLook, look)
            .environment(\.worldStillFrame, true)
            .environment(\.resistSeals, tally)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = hour > 20 ? .dark : .light
        window.rootViewController = UIHostingController(rootView: AnyView(view))
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(1200))
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

    private func write(_ image: UIImage, name: String) throws {
        let folder: URL
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            folder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            folder = FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try XCTUnwrap(image.pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
