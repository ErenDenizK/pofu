import PofuCompanion
import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// The life pass on screen (docs/tracker.md, "Half-finished" 2 and 3):
///
/// - `life-pofu-moods`: Pofu's face in each mood (the rig parts over the
///   base: mouths, ears, a paw), blinks off;
/// - `life-residents-walk`: the island at 0.0, 1.6, 3.2, 4.8 and 6.4 s of
///   one residents' cycle, pinned to a day on which both residents walk, so
///   the sequence shows the ease out, the far end and the walk back.
///
/// PNGs go to `WORLD_SCREENSHOTS_DIR` like the other shots.
final class LifeScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    @MainActor
    func testRenderTheLifePass() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // Pofu's moods.
        let moods = PofuMood.allCases
        let sheet = LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(moods, id: \.self) { mood in
                VStack(spacing: 0) {
                    CompanionView(vitality: 0.8, energy: 0.3)
                        .environment(\.companionBlinks, false)
                        .environment(\.companionMood, mood)
                    Text(mood.rawValue).font(.system(size: 15, weight: .semibold)).foregroundStyle(.black)
                }
            }
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(white: 0.97))
        try write(try await render(AnyView(sheet), in: scene), name: "life-pofu-moods", to: folder)

        // A day on which both residents walk in cycle 0.
        let walkable = IslandFootprint.walkable
        let specs = IslandLayout.residents.map { ResidentLife.Spec(id: $0.id.rawValue, home: $0.feet) }
        var day = 0
        while day < 400 {
            let plans = ResidentLife.plans(for: specs, day: day, cycle: 0, walkable: walkable, avoid: [IslandLayout.pofu])
            if plans.allSatisfy({ if case .walk = $0.activity { true } else { false } }) { break }
            day += 1
        }
        let world = IslandSamples.world(
            clock: clock, tendedDays: 60, levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 2],
            jar: IslandSamples.midWeekJar, islands: [.home, .harbor], islandLevel: 6
        )
        var frames: [UIImage] = []
        let times = [0.0, 1.6, 3.2, 4.8, 6.4]
        for t in times {
            let model = IslandSceneModel(framing: .island)
            model.holdPan(start: IslandFraming.panValue(lookX: 92))
            let view = IslandScene(world: world, model: model)
                .environment(\.worldLook, WorldLook(hourOverride: 12))
                .environment(\.worldStillFrame, true)
                .environment(\.worldResidentPin, ResidentLife.Pin(day: day, elapsed: t))
            let image = try await render(AnyView(view), in: scene)
            try write(image, name: String(format: "life-residents-walk-%.1fs", t), to: folder)
            frames.append(image)
        }
        try write(grid(frames, titles: times.map { String(format: "%.1f s", $0) }), name: "life-residents-walk", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ view: AnyView, in scene: UIWindowScene) async throws -> UIImage {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: view)
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

    /// Images in a row, each with a title above it.
    private func grid(_ images: [UIImage], titles: [String], cell: CGSize = CGSize(width: 402, height: 874)) -> UIImage {
        let pad: CGFloat = 16, label: CGFloat = 34
        let size = CGSize(width: pad + CGFloat(images.count) * (cell.width + pad), height: pad + cell.height + label + pad)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(white: 0.95, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor(white: 0.15, alpha: 1),
            ]
            for (i, image) in images.enumerated() {
                let x = pad + CGFloat(i) * (cell.width + pad)
                (titles[i] as NSString).draw(at: CGPoint(x: x, y: pad + 8), withAttributes: attrs)
                image.draw(in: CGRect(x: x, y: pad + label, width: cell.width, height: cell.height))
            }
        }
    }

    private func outputFolder() -> URL {
        if let path = ProcessInfo.processInfo.environment["WORLD_SCREENSHOTS_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("world-screenshots", isDirectory: true)
    }
}
