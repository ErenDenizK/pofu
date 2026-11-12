import PofuCore
import PofuWorld
import SwiftUI
import UIKit
import XCTest

/// Koke, the first wonder island (docs/design/koke-prototype.md), with the
/// code placeholders the Codex art will replace by name:
///
/// - `koke-rumour-harbor`: the harbor stop under Home's painted sky (the code
///   hump on the far sky is gone with the code sky), with Pofu's line;
/// - `koke-stage-0` to `koke-stage-4`: the island at the same camera, the
///   colour coming back (`koke-stages` lays them side by side);
/// - `koke-beat-3`: the stage 3 beat, Mochi reading the carved stone;
/// - `koke-gift-home`: the moss gift on the home lawn and Koke's light on
///   the harbor horizon.
final class KokeScreenshotTests: XCTestCase {
    private let clock = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func world(koke: WonderStatus, level: Int = 5) -> WorldSnapshot {
        var world = IslandSamples.world(
            clock: clock, tendedDays: 12, levels: [.garden: 3, .teaStall: 2, .pond: 2, .workshop: 1],
            jar: IslandSamples.midWeekJar, islands: [.home, .harbor], islandLevel: level, isBedtime: false
        )
        world.koke = koke
        return world
    }

    @MainActor
    func testRenderKoke() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "the test needs the host app's window scene"
        )
        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // The rumour: the hump on the harbor's horizon.
        let rumour = IslandSceneModel(framing: .island)
        rumour.holdIsle(.harbor)
        rumour.koke.show(.rumour)
        try write(try await render(world(koke: WonderStatus(phase: .rumoured)), model: rumour, in: scene), name: "koke-rumour-harbor", to: folder)

        // Koke at each stage, the same camera.
        var stages: [UIImage] = []
        for stage in 0...4 {
            let model = IslandSceneModel(framing: .island)
            model.holdIsle(.koke)
            let status = WonderStatus(phase: .arrived, stage: stage, canAdvance: stage < 4)
            let image = try await render(world(koke: status), model: model, in: scene)
            try write(image, name: "koke-stage-\(stage)", to: folder)
            stages.append(image)
        }
        try write(
            grid([stages], titles: [(0...4).map { "Koke · stage \($0)" }]),
            name: "koke-stages", to: folder
        )

        // The stage 3 beat: Mochi reads the stone.
        let beat = IslandSceneModel(framing: .island)
        beat.holdIsle(.koke)
        beat.koke.show(.stage(3))
        let status = WonderStatus(phase: .arrived, stage: 3, canAdvance: true)
        try write(try await render(world(koke: status), model: beat, in: scene), name: "koke-beat-3", to: folder)

        // Healed: the moss at home.
        let home = IslandSceneModel(framing: .home)
        let healed = WonderStatus(phase: .arrived, stage: 4)
        try write(try await render(world(koke: healed), model: home, in: scene), name: "koke-gift-home", to: folder)
    }

    // MARK: - Rendering

    @MainActor
    private func render(_ world: WorldSnapshot, model: IslandSceneModel, hour: Double = 12, in scene: UIWindowScene) async throws -> UIImage {
        let view = IslandScene(world: world, model: model)
            .environment(\.worldLook, WorldLook.islandStop(hour: hour))
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

    /// Images in a row, each with a title above it.
    @MainActor
    private func grid(_ rows: [[UIImage]], titles: [[String]], cell: CGSize = CGSize(width: 402, height: 874)) -> UIImage {
        let pad: CGFloat = 16, label: CGFloat = 34
        let cols = rows.map(\.count).max() ?? 0
        let size = CGSize(
            width: pad + CGFloat(cols) * (cell.width + pad),
            height: pad + CGFloat(rows.count) * (cell.height + label + pad)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.5
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(white: 0.95, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor(white: 0.15, alpha: 1),
            ]
            for (r, row) in rows.enumerated() {
                for (c, image) in row.enumerated() {
                    let x = pad + CGFloat(c) * (cell.width + pad)
                    let y = pad + CGFloat(r) * (cell.height + label + pad)
                    let title = r < titles.count && c < titles[r].count ? titles[r][c] : ""
                    (title as NSString).draw(at: CGPoint(x: x, y: y + 8), withAttributes: attrs)
                    image.draw(in: CGRect(x: x, y: y + label, width: cell.width, height: cell.height))
                }
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
