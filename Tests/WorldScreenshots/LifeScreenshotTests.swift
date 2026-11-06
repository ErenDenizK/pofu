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

        // Home framing at IL6, settled: Pofu's own door (H1) is on screen on the left.
        let settled = IslandScene(world: world, model: IslandSceneModel(framing: .home))
            .environment(\.worldLook, WorldLook(hourOverride: 12))
            .environment(\.worldStillFrame, true)
        try write(try await render(AnyView(settled), in: scene), name: "life-home-il6-settled", to: folder)

        // Mochi's gait: four consecutive 1/6 s frames in the middle of her walk, cropped to her.
        let mochi = try XCTUnwrap(IslandLayout.resident(.mochi))
        var mochiDay = 0
        var mochiPlan: ResidentLife.Plan?
        while mochiDay < 400 {
            let plans = ResidentLife.plans(for: specs, day: mochiDay, cycle: 0, walkable: walkable, avoid: [IslandLayout.pofu])
            if let plan = plans.first(where: { $0.spec.id == "mochi" }), case .walk = plan.activity { mochiPlan = plan; break }
            mochiDay += 1
        }
        let plan = try XCTUnwrap(mochiPlan)
        guard case .walk(_, let start, _, _) = plan.activity else { return }
        let stop = IslandFraming.homeStop()
        var strip: [UIImage] = []
        let gaitTimes = (0..<4).map { start + 1.0 + Double($0) / ResidentLife.walkFPS }
        for t in gaitTimes {
            let step = ResidentLife.step(of: plan, at: t)
            let model = IslandSceneModel(framing: .home)
            let view = IslandScene(world: world, model: model)
                .environment(\.worldLook, WorldLook(hourOverride: 12))
                .environment(\.worldStillFrame, true)
                .environment(\.worldResidentPin, ResidentLife.Pin(day: mochiDay, elapsed: t))
            let image = try await render(AnyView(view), in: scene)
            let x = 201 + (mochi.feet.x + step.dx - stop.look.x) * stop.scale
            let y = stop.anchorY + (mochi.feet.y + step.dy - IslandLayout.pofu.y) * stop.scale
            let rect = CGRect(x: x - 60, y: y - 100, width: 120, height: 120).applying(CGAffineTransform(scaleX: image.scale, y: image.scale))
            if let cropped = image.cgImage?.cropping(to: rect) {
                strip.append(UIImage(cgImage: cropped, scale: image.scale, orientation: .up))
            }
        }
        try write(grid(strip, titles: gaitTimes.map { String(format: "%.2f s", $0) }, cell: CGSize(width: 240, height: 240)), name: "life-mochi-gait", to: folder)
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
