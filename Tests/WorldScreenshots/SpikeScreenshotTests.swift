import PofuCore
import PofuDesignSystem
import PofuWorld
import SwiftUI
import UIKit
import XCTest
@testable import Pofu

/// The graphics spike's before and after, on one scene (Ayçiçeği Home:
/// Pofu, the çay ocağı and Mochi):
///
/// - `spike-light-{day,golden,night}-{baked,lit}`: the painted art alone,
///   and with the key, fill, ember and rim computed from baked normal maps;
/// - `spike-dof-{old,new}`: whole-layer blur, and blur from a per-pixel
///   depth map focused on Pofu;
/// - `spike-debug-normals` and `spike-debug-depth`: what the shaders read.
final class SpikeScreenshotTests: XCTestCase {
    private func world() -> WorldSnapshot {
        IslandSamples.world(
            clock: Date(timeIntervalSinceReferenceDate: 815_000_000),
            tendedDays: 4,
            levels: [.cay: 1],
            jar: Energy(60),
            islands: [.aycicegi]
        )
    }

    private func look(hour: Double, spike: GraphicsSpike = .off) -> WorldLook {
        var look = WorldLook(hourOverride: hour)
        look.spike = spike
        return look
    }

    @MainActor
    func testRenderTheSpike() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var shots: [(String, WorldLook)] = []
        for (id, hour) in [("day", 12.0), ("golden", 18.5), ("night", 22.0)] {
            shots.append(("spike-light-\(id)-baked", look(hour: hour)))
            shots.append(("spike-light-\(id)-lit", look(hour: hour, spike: GraphicsSpike(normalLighting: true, depthOfField: false))))
        }
        shots.append(("spike-dof-old", look(hour: 12)))
        shots.append(("spike-dof-new", look(hour: 12, spike: GraphicsSpike(depthOfField: true))))
        shots.append(("spike-debug-normals", look(hour: 12, spike: GraphicsSpike(debug: .normals))))
        shots.append(("spike-debug-depth", look(hour: 12, spike: GraphicsSpike(debug: .depth))))

        // The same looks again at the Island pan settled on the çay ocağı, so
        // the stall, Mochi and Pofu share the frame.
        let pan = shots.filter { !$0.0.hasPrefix("spike-debug") }.map { ($0.0 + "-pan", $0.1) }
        for (name, look) in shots + pan {
            let model = IslandSceneModel(framing: name.hasSuffix("-pan") ? .island : .home)
            if name.hasSuffix("-pan") {
                model.holdPan(start: 0, velocity: -1100, at: 2.0)
            }
            let view = AnyView(SpikeScene(world: world(), model: model).environment(\.worldLook, look))
            let image = try await render(view, in: scene, settle: 1600)
            try write(image, name: name, to: folder)
        }
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ view: AnyView, in scene: UIWindowScene, settle: Int) async throws -> UIImage {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 3
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(settle))
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

/// The Home scene without the framing control, still, so frames compare.
private struct SpikeScene: View {
    let world: WorldSnapshot
    let model: IslandSceneModel

    var body: some View {
        IslandScene(world: world, model: model) {
            EmptyView()
        }
        .environment(\.worldStillFrame, true)
    }
}
