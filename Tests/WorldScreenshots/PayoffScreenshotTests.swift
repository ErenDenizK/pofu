import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The payoff at the door (ui-v3 section 3b): three seals pressed on the
/// round door's plaque over Home, day and night, at 0.3 s, 1.0 s, 1.8 s
/// (fading) and 2.0 s (the world settled). The screen haze before and after
/// `part()` is `WeatherScreenshotTests`' `screen-haze` / `screen-haze-parted`.
final class PayoffScreenshotTests: XCTestCase {
    @MainActor
    func testRenderThePayoffAtTheDoor() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let times: [Double] = [0.3, 1.0, 1.8, 2.0]
        for (label, hour, night) in [("day", 12.0, false), ("night", 22.0, true)] {
            for time in times {
                let image = try await render(hour: hour, night: night, time: time, in: scene)
                try write(image, name: "payoff-door-\(label)-\(Int(time * 10))")
            }
        }
    }

    @MainActor
    private func render(hour: Double, night: Bool, time: Double, in scene: UIWindowScene) async throws -> UIImage {
        let model = IslandSceneModel(framing: .home)
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        let run = DoorStampRun(stamp: DoorStamp(resists: 3))
        let view = ZStack {
            IslandScene(world: IslandSamples.grownIsland(wellbeing: 78), model: model)
                .environment(\.worldLook, look)
                .environment(\.worldStillFrame, true)
            DoorStampOverlay(run: run, frozenAt: time)
                .environment(\.pofuNight, night)
        }
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = night ? .dark : .light
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
